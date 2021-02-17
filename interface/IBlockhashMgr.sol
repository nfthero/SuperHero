pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

interface IBlockhashMgr {
    function request(uint256 blockNumber) external;
    function request(uint256[] memory blockNumbers) external;
    
    function getBlockhash(uint256 blockNumber) external returns(bytes32);
}
