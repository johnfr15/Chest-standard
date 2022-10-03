// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./extensions/ChestHolder.sol";
import "./IChest.sol";

contract Chest is IChest, ChestHolder {
    using Counters for Counters.Counter;

    struct Metadata {
      Counters.Counter opennedCounter;
      uint256 lastTimeOpenned;
      address creator;
      string name;
      string type_;
      string note;
    }

    // Information about the chest
    Metadata public chest;

    /***********************************|
   |            Constructor             |
   |__________________________________*/

    constructor(string memory name, string memory type_, string memory note) {
        chest.name = name;
        chest.type_ = type_;
        chest.creator = msg.sender;
        chest.note = note;
    }

    /***********************************|
   |           Write Functions          |
   |__________________________________*/

    function batchDeposit(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external onlyOwner returns(bool success) {
        require(items.length == tokenIds.length && 
                items.length == tokenIds.length &&
                items.length == amounts.length,
                "batchDeposit: length of items and ids and amounts are not the same.");
        
        for (uint i; i < items.length; i++) {
            if (tokenType[items[i]] == Token.ERC20) {
                IERC20(items[i]).transferFrom(msg.sender, address(this), amounts[i]);
                onERC20Received(address(this), msg.sender, amounts[i], items[i]);
            } else if (tokenType[items[i]] == Token.ERC721) {
                IERC721(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenType[items[i]] == Token.ERC1155) {
                IERC1155(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            } else {
                revert("batchDeposit: token not white listed to get in this chest.");
            }
        }

        success = true;
    }

    function loot(address item, uint256 tokenId, uint256 amount) external returns (
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

        emit Looted(msg.sender, items, tokenIds, amounts);

        _removeTokenFromChest(items, tokenIds, amounts);
    }

    function batchLoot(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external returns(
        address[] memory items_, 
        uint256[] memory tokenIds_, 
        uint256[] memory amounts_, 
        uint8[] memory type_)
    {
        require(items.length == tokenIds.length && items.length == amounts.length,
                "batchDeposit: length of items and ids and amounts are not the same.");

        items_ = new address[](items.length);
        tokenIds_ = new uint256[](items.length);
        amounts_ = new uint256[](items.length);
        type_ = new uint8[](items.length);
        
        for (uint i; i < items.length; i++) 
        {
            require(isInside[items[i]][tokenIds[i]], "Chest: Token is not in the chest");
            require(_amountIn[items[i]][tokenIds[i]] >= amounts[i], "Chest: amount exceed the quantity available in the chest");

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
        emit Looted(msg.sender, items_, tokenIds_, amounts_);

        _removeTokenFromChest(items_, tokenIds_, amounts_);
    }

    /***********************************|
   |           Read Functions           |
   |__________________________________*/

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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IChest).interfaceId;
    }

    /***********************************|
   |        Internal Functions          |
   |__________________________________*/

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
                // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
                // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
                // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
                uint256 lastTokenIndex = _allTokens.length - 1;
                address lastTokenAddress = _allTokens[lastTokenIndex];
                uint256 lastTokenId = _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens[tokenIndex] = lastTokenAddress; // Move the last token to the slot of the to-delete token
                _allTokensIndex[lastTokenAddress][lastTokenId] = tokenIndex; // Update the moved token's index
                _allTokensId[lastTokenAddress][tokenIndex] = lastTokenId; // Update the moved token's id

                // This also deletes the contents at the last position of the array
                delete _allTokensIndex[items[i]][tokenIds[i]];
                delete _amountIn[items[i]][tokenIds[i]];
                delete isInside[items[i]][tokenIds[i]];

                delete _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens.pop();
            } else {
                _amountIn[items[i]][tokenIds[i]] -= amounts[i];
            }
        }
    }
}