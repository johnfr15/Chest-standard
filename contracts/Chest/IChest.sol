// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

interface IChest {

    event Looted(
        address indexed looter, 
        address[] indexed items, 
        uint256[] indexed tokenIds, 
        uint256[] amounts
    );
    event Deposit(
        address indexed depositor, 
        address[] indexed items, 
        uint256[] indexed tokenIds, 
        uint256[] amounts,
        uint8[] type_
    );
    
    function batchDeposit(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external returns(bool success);
    function loot(address item, uint256 tokenId, uint256 amount) external returns(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts, 
        uint8[] memory type_
    );
    function batchLoot(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external returns(
        address[] memory items_, 
        uint256[] memory tokenIds_, 
        uint256[] memory amounts_, 
        uint8[] memory type_
    );
    function look() external view returns(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts, 
        uint8[] memory type_
    );
}