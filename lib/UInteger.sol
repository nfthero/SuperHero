pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

library UInteger {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a,  "add error");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(a >= b,  "sub error");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "mul error");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
    
    function toString(uint256 a, uint256 radix)
        internal pure returns(string memory) {
        
        if (a == 0) {
            return "0";
        }
        
        uint256 length = 0;
        for (uint256 n = a; n != 0; n /= radix) {
            length++;
        }
        
        bytes memory bs = new bytes(length);
        
        for (uint256 i = length - 1; a != 0; --i) {
            uint256 b = a % radix;
            a /= radix;
            
            if (b < 10) {
                bs[i] = bytes1(uint8(b + 48));
            } else {
                bs[i] = bytes1(uint8(b + 87));
            }
        }
        
        return string(bs);
    }
    
    function toString(uint256 a) internal pure returns(string memory) {
        return UInteger.toString(a, 10);
    }
}
