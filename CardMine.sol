pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC20.sol";

import "./MortgageBase.sol";

contract CardMine is MortgageBase {
    constructor(uint256 _startTime, uint256 _duration, uint256 _reward)
        MortgageBase(_startTime, _duration, _reward) {
    }
    
    function updateFight(address owner, int256 fight) external {
        require(msg.sender == manager.members("slot"),
            "slot update fight only");
        
        int256 amount = fight - mortgageAmounts[owner];
        _mortgage(owner, amount);
    }
    
    function withdraw() external {
        uint256 reward = _withdraw();
        
        // not check result to save gas
        IERC20(manager.members("token")).transfer(msg.sender, reward);
    }
}
