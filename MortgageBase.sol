pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC20.sol";

import "./Member.sol";

abstract contract MortgageBase is Member {
    uint256 public startTime;
    uint256 public totalDuration;
    uint256 public totalReward;
    
    int256 public mortgageMax = 10 ** 30;
    
    mapping(address => int256) public mortgageAmounts;
    mapping(address => int256) public mortgageAdjusts;
    
    int256 public totalAmount;
    int256 public totalAdjust;
    
    constructor(uint256 _startTime, uint256 _duration, uint256 _reward) {
        startTime = _startTime;
        totalDuration = _duration;
        totalReward = _reward;
    }
    
    function setMortgageMax(int256 max) external CheckPermit("Config") {
        mortgageMax = max;
    }
    
    function getMineInfo(address owner) external view
        returns(uint256, uint256, uint256, int256, int256, int256, int256) {
        
        return (startTime, totalDuration, totalReward,
            totalAmount, totalAdjust,
            mortgageAmounts[owner], mortgageAdjusts[owner]);
    }
    
    function _mortgage(address owner, int256 amount) internal {
        int256 newAmount = mortgageAmounts[owner] + amount;
        require(newAmount >= 0 && newAmount < mortgageMax, "invalid amount");
        
        uint256 _now = block.timestamp;
        
        if (_now > startTime && totalAmount != 0) {
            int256 reward;
            if (_now < startTime + totalDuration) {
                reward = int256(totalReward * (_now - startTime) / totalDuration)
                    + totalAdjust;
            } else {
                reward = int256(totalReward) + totalAdjust;
            }
            
            int256 adjust = reward * amount / totalAmount;
            mortgageAdjusts[owner] += adjust;
            totalAdjust += adjust;
        }
        
        mortgageAmounts[owner] = newAmount;
        totalAmount += amount;
    }
    
    function calcReward(address owner) public view returns(int256) {
        uint256 _now = block.timestamp;
        if (_now <= startTime) {
            return 0;
        }
        
        int256 amount = mortgageAmounts[owner];
        int256 adjust = mortgageAdjusts[owner];
        
        if (amount == 0) {
            return -adjust;
        }
        
        int256 reward;
        
        if (_now < startTime + totalDuration) {
            reward = int256(totalReward * (_now - startTime) / totalDuration)
                + totalAdjust;
        } else {
            reward = int256(totalReward) + totalAdjust;
        }
        
        return reward * amount / totalAmount - adjust;
    }
    
    function _withdraw() internal returns(uint256) {
        int256 reward = calcReward(msg.sender);
        require(reward > 0, "no reward");
        
        mortgageAdjusts[msg.sender] += reward;
        return uint256(reward);
    }
    
    function stopMortgage() external CheckPermit("Admin") {
        uint256 _now = block.timestamp;
        require(_now < startTime + totalDuration, "mortgage over");
        
        uint256 tokenAmount;
        
        if (_now < startTime) {
            tokenAmount = totalReward;
            totalReward = 0;
            totalDuration = 1;
        } else {
            uint256 reward = totalReward * (_now - startTime) / totalDuration;
            tokenAmount = totalReward - reward;
            totalReward = reward;
            totalDuration = _now - startTime;
        }
        
        IERC20(manager.members("token")).transfer(
            manager.members("cashier"), tokenAmount);
    }
}
