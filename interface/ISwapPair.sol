pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./IERC20.sol";

interface ISwapPair is IERC20 {
    function token0() external view returns(address);
    function token1() external view returns(address);
    
    function getReserves() external view returns(uint112, uint112, uint32);
}