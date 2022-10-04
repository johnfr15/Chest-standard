// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract ChestHolder is IERC1155Receiver, ERC721Holder, Ownable {
    using Strings for address;

    enum Token { ZERO, ERC20, ERC721, ERC1155 }

    // Check if the token can be stored in the chest (only aavegotchi & GW3S tokens allowed)
    mapping(address => bool) public tokenWhiteListed;

    // Check if ERC20 or ERC721 is in the chest: contract => token id => boolean
    mapping(address => mapping(uint256 => bool)) public isInside;

    // Array with all token address, used for enumeration
    address[] internal _allTokens;

    // Mapping from token address => tokenId => position in the _allTokens array
    mapping(address => mapping(uint256 => uint256)) internal _allTokensIndex;
    
    // Mapping from token address => index in the _allTokens array => tokenId
    mapping(address => mapping(uint256 => uint256)) internal _allTokensId;

    // token address => id => quantity
    mapping(address => mapping(uint256 => uint256)) internal _amountIn;

    // Check if ERC20 or ERC721 is in the chest: contract => token id => boolean
    mapping(address => Token) public tokenType;

    /***********************************|
   |           Write Functions          |
   |__________________________________*/

     /**
     * @dev When ERC721 is deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data ) public virtual override returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onRC721Received: Token is not white listed to be stored in the chest");

      if (!isInside[msg.sender][tokenId]) {
        _allTokensId[msg.sender][_allTokens.length] = tokenId;
        _allTokensIndex[msg.sender][tokenId] = _allTokens.length;
        _allTokens.push(msg.sender);

        isInside[msg.sender][tokenId] = true;
      }
      
      _amountIn[msg.sender][tokenId] += 1;
      return this.onERC721Received.selector;
    }

     /**
     * @dev When ERC1155 is deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     */
    function onERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes calldata data
    ) external virtual returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onERC1155Received: Token is not white listed to be stored in the chest");

      if (!isInside[msg.sender][id]) {
        _allTokensId[msg.sender][_allTokens.length] = id;
        _allTokensIndex[msg.sender][id] = _allTokens.length;
        _allTokens.push(msg.sender);

        isInside[msg.sender][id] = true;
      }
      _amountIn[msg.sender][id] += value;

      return this.onERC1155Received.selector;
    }

    /**
     * @dev When ERC1155 is batch deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     *
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onERC1155BatchReceived: Token is not white listed to be stored in the chest");

      for(uint i; i < ids.length; i++) {

        if (!isInside[msg.sender][ids[i]]) {
          _allTokensId[msg.sender][_allTokens.length] = ids[i];
          _allTokensIndex[msg.sender][ids[i]] = _allTokens.length;
          _allTokens.push(msg.sender);

          isInside[msg.sender][ids[i]] = true;
        }
        _amountIn[msg.sender][ids[i]] += values[i];
      }

      return this.onERC1155Received.selector;
    }

    /**
     * @dev When ERC20 is deposited {batchDeposit} this function is call by this smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address must be white listed to be stored in.
     */
    function onERC20Received(address operator, address from, uint256 value, address token) public virtual returns (bytes4) {
      operator; from;
      require(tokenWhiteListed[token] == true, "onERC20Received: Token is not white listed to be stored in the chest");
      
      if (!isInside[token][0]) {
        _allTokensId[token][_allTokens.length] = 0;
        _allTokensIndex[token][0] = _allTokens.length;
        _allTokens.push(token);

        isInside[token][0] = true;
      }
      _amountIn[token][0] += value;

      return this.onERC20Received.selector;
    }

    /**
     * @dev Authorize tokens to be stored in the chest 
     *
     * @param tokens: An array of all the tokens to be white listed to be stored in.
     * @param tokenType_: An array of types corresponding with the address of token to be whitelisted.
     * @notice The type design of the tokens is as follow.
     * - ERC20 => 1
     * - ERC721 => 2
     * - ERC1155 => 3
     *
     * Requirements:
     *
     * - Only owner can whitelist
     * - Only ERC20, ERC721, ERC1155 accepted
     */
    function addWhiteList(address[] memory tokens, uint8[] memory tokenType_) external onlyOwner {
      require(tokens.length == tokenType_.length, "whiteListTokens: parameters are not the same length");

      for(uint i; i < tokens.length; i++) {
        if (tokenType_[i] == uint8(Token.ERC20)) {
          require(ERC20(tokens[i]).decimals() > 0, "ChestHolder: Not an erc20 token");
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC20;
        }
        else if (tokenType_[i] == uint8(Token.ERC721)) {
          require(IERC721(tokens[i]).supportsInterface(0x80ac58cd), "addWhiteList: token is not a ERC721");
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC721;
        }
        else if (tokenType_[i] == uint8(Token.ERC1155)) {
          require(IERC1155(tokens[i]).supportsInterface(0xd9b67a26), "addWhiteList: token is not a ERC1155");
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC1155;
        }
        else {
          revert(string(abi.encodePacked("ChestHolder: token ", tokens[i].toHexString(), " is not supported. Only ERC20, 721, 1155 is allowed")));
        }
      }
    }

    /**
     * @dev Remove white listed tokens. 
     *
     * @param tokens: An array of all the tokens to be removed of white list.
     *
     * Requirements:
     *
     * - Only owner can remove whitelist
     */
    function removeWhiteList(address[] memory tokens) external onlyOwner {
      for(uint i; i < tokens.length; i++) {
        delete tokenWhiteListed[tokens[i]];
      }
    }
}