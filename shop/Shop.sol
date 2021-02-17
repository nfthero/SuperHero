pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IERC20.sol";

import "../lib/UInteger.sol";
import "../lib/Util.sol";

import "../Member.sol";
import "../Package.sol";

abstract contract Shop is Member {
    using UInteger for uint256;
    
    uint256 public quantityMax;
    uint256 public quantityCount = 0;
    
    uint16[] public cardTypes;
    
    function setQuantityMax(uint256 max) external CheckPermit("Config") {
        quantityMax = max;
    }
    
    function calcCardType(bytes memory seed)
        public view returns(uint256) {
        
        return cardTypes[Util.randomUint(seed, 0, cardTypes.length - 1)];
    }
    
    function addCardType(uint16 cardType) external CheckPermit("Config") {
        cardTypes.push(cardType);
    }
    
    function addCardTypes(uint16[] memory cts) external CheckPermit("Config") {
        uint256 length = cts.length;
        
        for (uint256 i = 0; i != length; ++i) {
            cardTypes.push(cts[i]);
        }
    }
    
    function setCardTypes(uint16[] memory cts) external CheckPermit("Config") {
        cardTypes = cts;
    }
    
    function removeCardType(uint256 index) external CheckPermit("Config")  {
        cardTypes[index] = cardTypes[cardTypes.length - 1];
        cardTypes.pop();
    }
    
	// must be high -> low
    function removeCardTypes(uint256[] memory indexs)
        external CheckPermit("Config")  {
        
        uint256 indexLength = indexs.length;
        uint256 ctLength = cardTypes.length;
        
        for (uint256 i = 0; i != indexLength; ++i) {
            cardTypes[indexs[i]] = cardTypes[--ctLength];
            cardTypes.pop();
        }
    }
    
    function removeAllCardTypes()
        external CheckPermit("Config")  {
        
        delete cardTypes;
    }
    
    function _buy(address to, address tokenSender, uint256 tokenAmount,
        uint256 quantity, uint256 padding) internal {
        
        quantityCount += quantity;
        require(quantityCount <= quantityMax, "quantity exceed");
        
        // not check result to save gas
        if (tokenSender == address(0)) {
            IERC20(manager.members("token")).transfer(
                manager.members("card"), tokenAmount.mul(quantity));
        } else {
            IERC20(manager.members("token")).transferFrom(tokenSender,
                manager.members("card"), tokenAmount.mul(quantity));
        }
        
        Package(manager.members("package")).mint(
            to, tokenAmount, quantity, padding);
    }
    
    function stopShop() external CheckPermit("Admin") {
        IERC20 token = IERC20(manager.members("token"));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(manager.members("cashier"), balance);
        quantityMax = quantityCount;
    }
    
    function onOpenPackage(address to, uint256 packageId, bytes32 bh)
        external virtual returns(uint256[] memory);
        
    function getRarityWeights(uint256 packageId)
        external view virtual returns(uint256[] memory);
}
