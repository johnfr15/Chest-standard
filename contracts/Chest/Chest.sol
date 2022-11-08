// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ChestHolder.sol";
import "./IChest.sol";

contract Chest is IChest, ChestHolder, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for address;

    struct Metadata {
      Counters.Counter opennedCounter;
      uint256 lastTimeOpenned;
      address creator;
      string name;
      string type_;
    }

    // Information about the chest
    Metadata public chest;

    /***********************************|
   |            Constructor             |
   |__________________________________*/

    /**
     * @dev Sets the values for {name} and {type_}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory type_) {
        chest.name = name;
        chest.type_ = type_;
        chest.creator = msg.sender;
    }

    /***********************************|
   |           Write Functions          |
   |__________________________________*/

    /**
     * @dev Deposit a set of {ERC20}, {ERC721}, {ERC1155} white listed by the owner 
     * of the chest.
     *
     * @param items: The addresses of the tokens to be deposited.
     *
     * @param tokenIds: The id of token to be deposited. 
     * @notice For ERC20 token which don't have id any value will fit.
     *
     * @param amounts: The quantities of the tokens to be deposited.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * WARNING: items <=> tokenIds <=> amounts {indexes} much match each others.
     *
     * Example: Alice want to deposit 10 DAI token and 1 GOTCHI (21345), here is her input
     *  items = ["0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", "0x86935F11C86623deC8a25696E1C19a8659CbF95d"],
     *  tokenIds = [{whatever id as it is a ERC20}, 21345],
     *  amounts = ["10", "1"]  
     *
     * Requirements:
     * 
     * - {msg.sender} must be the owner of the chest.
     * - If The length of the 3 params are not equal the Tx will revert.
     * - If the address of one token is not white listed, the Tx will revert.
     *
     */
    function batchDeposit(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external virtual onlyOwner notLocked returns(bool success) {
        require(items.length == tokenIds.length && 
                items.length == amounts.length,
                "Chest: length of items and ids and amounts are not the same.");
        
        for (uint i; i < items.length; i++) {
            if (tokenType[items[i]] == Token.ERC20) {
                IERC20(items[i]).transferFrom(msg.sender, address(this), amounts[i]);
                onERC20Received(address(this), msg.sender, amounts[i], items[i]);
            } else if (tokenType[items[i]] == Token.ERC721) {
                IERC721(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenType[items[i]] == Token.ERC1155) {
                IERC1155(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            } else {
                revert(string(abi.encodePacked("Chest: token ", items[i].toHexString(), " is not white listed to be in this chest.")));
            }
        }

        success = true;
    }

    /**
     * @dev Loot a single token in the chest
     *
     * @param item: The address of the token.
     *
     * @param tokenId: The id of token. 
     * @notice For ERC20 token any value will fit.
     *
     * @param amount: The quantity of the token.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * Requirements:
     * 
     * - The token specified in params must be inside the chest.
     * - The amount specified in params must not exceed the amount present in the chest.
     *
     * Emits a {Looted} event.
     */
    function loot(address item, uint256 tokenId, uint256 amount) external virtual nonReentrant notLocked returns (
    address[] memory items, 
    uint256[] memory tokenIds, 
    uint256[] memory amounts, 
    uint8[] memory type_) 
    {
        require(isInside[item][tokenId], "loot: item is not in the chest");
        require(_amountIn[item][tokenId] >= amount, "loot: amount exceed the quantity available in the chest");

        items = new address[](1);
        tokenIds = new uint256[](1);
        amounts = new uint256[](1);
        type_ = new uint8[](1);

        
        if (tokenType[item] == Token.ERC20) {
            IERC20(item).transfer(msg.sender, amount);
        } else if (tokenType[item] == Token.ERC721) {
            IERC721(item).safeTransferFrom(address(this), msg.sender, tokenId);
        } else if (tokenType[item] == Token.ERC1155) {
            IERC1155(item).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        }

        items[0] = item;
        tokenIds[0] = tokenId;
        amounts[0] = amount;
        type_[0] = uint8(tokenType[item]);

        chest.opennedCounter.increment();
        chest.lastTimeOpenned = block.timestamp;

        emit Looted(msg.sender, items, tokenIds, amounts);

        _removeTokenFromChest(items, tokenIds, amounts);
    }

    /**
     * @dev Loot a batch of tokens in the chest
     *
     * @param items: The addresses of the tokens to be deposited.
     *
     * @param tokenIds: The id of token to be deposited. 
     * @notice For ERC20 token which don't have id any value will fit.
     *
     * @param amounts: The quantities of the tokens to be deposited.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * WARNING: items <=> tokenIds <=> amounts {indexes} much match each others.
     *
     * Example: Bob want to withdraw 10 DAI token and 1 (ERC721) GOTCHI {id: 21345} and 2 (ERC1155) Aave boat {id: 35}, here is his input.
     * - items = [
        "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", 
        "0x86935F11C86623deC8a25696E1C19a8659CbF95d", 
        "0x86935F11C86623deC8a25696E1C19a8659CbF95d"
        ],
     * - tokenIds = [{whatever id as it is a ERC20}, 21345, 35],
     * - amounts = ["10", "1", "2"]  
     *
     * Requirements:
     * 
     * - If The length of the 3 params are not equal the Tx will revert.
     * - The token specified in params must be inside the chest.
     * - The amount specified in params must not exceed the amount present in the chest.
     *
     * Emits a {Looted} event.
     */
    function batchLoot(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external virtual nonReentrant notLocked returns(
        address[] memory items_, 
        uint256[] memory tokenIds_, 
        uint256[] memory amounts_, 
        uint8[] memory type_)
    {
        require(items.length == tokenIds.length && 
                items.length == amounts.length,
                "batchDeposit: length of items and ids and amounts are not the same.");

        items_ = new address[](items.length);
        tokenIds_ = new uint256[](items.length);
        amounts_ = new uint256[](items.length);
        type_ = new uint8[](items.length);
        
        for (uint i; i < items.length; i++) 
        {
            require(isInside[items[i]][tokenIds[i]], 
                    string(
                        abi.encodePacked(
                            "Chest: token ", 
                            items[i].toHexString(), 
                            "id ", 
                            tokenIds[i].toString(), 
                            " is not white listed to be in this chest."
                        )
                    )
            );
            require(_amountIn[items[i]][tokenIds[i]] >= amounts[i], 
                    string(
                        abi.encodePacked(
                            "Chest: Amount of token ", 
                            items[i].toHexString(), 
                            "id ", 
                            tokenIds[i].toString(), 
                            " exceed the amount present in the chest"
                        )
                    )
            );

            if (tokenType[items[i]] == Token.ERC20) {
                IERC20(items[i]).transfer(msg.sender, amounts[i]);
            } else if (tokenType[items[i]] == Token.ERC721) {
                IERC721(items[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            } else {
                IERC1155(items[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i], amounts[i], "");
            }

            items_[i] = items[i];
            tokenIds_[i] = tokenIds[i];
            amounts_[i] = amounts[i];
            type_[i] = uint8(tokenType[items[i]]);
        }

        chest.opennedCounter.increment();
        chest.lastTimeOpenned = block.timestamp;

        emit Looted(msg.sender, items_, tokenIds_, amounts_);

        _removeTokenFromChest(items_, tokenIds_, amounts_);
    }

    /***********************************|
   |           Read Functions           |
   |__________________________________*/

    /**
     * @dev Returns the tokens and their amounts in the chest.
     */
   function look() external view returns (
    address[] memory items, 
    uint256[] memory tokenIds, 
    uint256[] memory amounts, 
    uint8[] memory type_) 
    {
        items = new address[](_allTokens.length);
        tokenIds = new uint256[](_allTokens.length);
        amounts = new uint256[](_allTokens.length);
        type_ = new uint8[](_allTokens.length);

        items = _allTokens;
        for (uint i; i < _allTokens.length; i++) {
            tokenIds[i] = _allTokensId[items[i]][i];
            amounts[i] = _amountIn[items[i]][tokenIds[i]];
            type_[i] = uint8(tokenType[items[i]]);
        }    
    }

    /**
     * @dev Support IChest interface.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IChest).interfaceId;
    }

    /***********************************|
   |        Internal Functions          |
   |__________________________________*/

    /**
     * @dev Remove tokens's all datas from the chest if their amount reach 0.
     * this function is called after a successfull loot.
     *
     * @notice This function is inspired by openzeppelin ERC721 enumerable (openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol)
     */
    function _removeTokenFromChest(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) internal virtual {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        for (uint i; i < items.length; i++) {

            if (_amountIn[items[i]][tokenIds[i]] - amounts[i] == 0) {
                uint256 tokenIndex = _allTokensIndex[items[i]][tokenIds[i]];

                // Get all datas of the last token as this one will be swapped with the to-delete current token.
                // if the to-delete token is also the last one, it will be swapped by himself and still deleted by the pop function.
                uint256 lastTokenIndex = _allTokens.length - 1;
                address lastTokenAddress = _allTokens[lastTokenIndex];
                uint256 lastTokenId = _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens[tokenIndex] = lastTokenAddress; // Move the last token to the slot of the to-delete token
                _allTokensIndex[lastTokenAddress][lastTokenId] = tokenIndex; // Update the moved token's index
                _allTokensId[lastTokenAddress][tokenIndex] = lastTokenId; // Update the moved token's id

                // Delete all the datas of the to-delete "items[i]" token.
                delete _allTokensIndex[items[i]][tokenIds[i]];
                delete _amountIn[items[i]][tokenIds[i]];
                delete isInside[items[i]][tokenIds[i]];
                
                // delete the previous mapping of the token that has been swapped by the to-delete token.
                delete _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens.pop();
            } else {
                _amountIn[items[i]][tokenIds[i]] -= amounts[i];
            }
        }
    }
}