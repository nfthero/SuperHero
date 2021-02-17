pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC20.sol";

import "./lib/String.sol";
import "./lib/Util.sol";

import "./ERC721Ex.sol";
import "./Slot.sol";

// nftSign  cardType    skin    rarity tokenAmount  padding mintTime    index
// 1        31          16      16     64           24      40          64
// 255      224         208     192    128          104     64          0

contract Card is ERC721Ex {
    using String for string;
    
    uint256 public constant UPGRADE_LOCK_DURATION = 60 * 60 * 24 * 5;
    
    uint256 public constant ID_PREFIX_MASK = uint256(~uint152(0)) << 104;
    
    struct LockedToken {
        uint256 locked;
        uint256 lockTime;
        int256 unlocked;
    }
    
    mapping(uint256 => int256) public rarityFights;
    
    mapping(address => LockedToken) public upgradeLockedTokens;
    uint256 public burnLockDuration = 60 * 60 * 24 * 2;
    
    mapping(address => bool) public packages;
    
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {
        
        rarityFights[Util.RARITY_WHITE] = 1000;
        rarityFights[Util.RARITY_GREEN] = 2000;
        rarityFights[Util.RARITY_BLUE] = 4000;
        rarityFights[Util.RARITY_PURPLE] = 8000;
        rarityFights[Util.RARITY_ORANGE] = 16000;
        rarityFights[Util.RARITY_GOLD] = 20000;
    }
    
    function setRarityFight(uint256 rarity, int256 fight)
        external CheckPermit("Config") {
        
        rarityFights[rarity] = fight;
    }
    
    function setBurnLockDuration(uint256 duration)
        external CheckPermit("Config") {
        
        burnLockDuration = duration;
    }
    
    function setPackage(address package, bool enable)
        external CheckPermit("Config") {
        
        packages[package] = enable;
    }
    
    function mint(address to, uint256 cardIdPre) external {
        require(packages[msg.sender], "package only");
        
        uint256 cardId = NFT_SIGN_BIT | (cardIdPre & ID_PREFIX_MASK) |
            (block.timestamp << 64) | uint64(totalSupply + 1);
        
        _mint(to, cardId);
    }
    
    function batchMint(address to, uint256[] memory cardIdPres) external {
        require(packages[msg.sender], "package only");
        
        uint256 length = cardIdPres.length;
        
        for (uint256 i = 0; i != length; ++i) {
            uint256 cardId = NFT_SIGN_BIT | (cardIdPres[i] & ID_PREFIX_MASK) |
                (block.timestamp << 64) | uint64(totalSupply + 1);
            
            _mint(to, cardId);
        }
    }
    
    function burn(uint256 cardId) external {
        address owner = tokenOwners[cardId];
		
        require(msg.sender == owner
            || msg.sender == tokenApprovals[cardId]
            || approvalForAlls[owner][msg.sender],
            "msg.sender must be owner or approved");
        
        uint256 mintTime = uint40(cardId >> 64);
        require(mintTime + burnLockDuration < block.timestamp, "card has not unlocked");
        
        _burn(cardId);
        
        uint256 tokenAmount = uint64(cardId >> 128);
        // not check result to save gas
        IERC20(manager.members("token")).transfer(owner, tokenAmount);
    }
    
    function burnForSlot(uint256[] memory cardIds) external {
        uint256 length = cardIds.length;
        address owner = msg.sender;
        uint256 tokenAmount = 0;
        
        for (uint256 i = 0; i != length; ++i) {
            uint256 cardId = cardIds[i];
            require(owner == tokenOwners[cardId], "you are not owner");
            _burn(cardId);
            tokenAmount += uint64(cardId >> 128);
        }
        
        LockedToken storage lt = upgradeLockedTokens[owner];
        uint256 _now = block.timestamp;
        
        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            uint256 amount = lt.locked * (_now - lt.lockTime)
                / UPGRADE_LOCK_DURATION;
            lt.locked = lt.locked - amount + tokenAmount;
            lt.unlocked += int256(amount);
        } else {
            lt.unlocked += int256(lt.locked);
            lt.locked = tokenAmount;
        }
        
        lt.lockTime = _now;
        
        Slot(manager.members("slot")).upgrade(owner, cardIds);
    }
    
    function withdraw() external {
        LockedToken storage lt = upgradeLockedTokens[msg.sender];
        int256 available = lt.unlocked;
        uint256 _now = block.timestamp;
        
        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            available += int256(lt.locked * (_now - lt.lockTime)
                / UPGRADE_LOCK_DURATION);
        } else {
            available += int256(lt.locked);
        }
        
        require(available > 0, "no token available");
        
        lt.unlocked -= available;
        
        // not check result to save gas
        IERC20(manager.members("token")).transfer(msg.sender, uint256(available));
    }
    
    function getFight(uint256 cardId) external view returns(int256) {
        return rarityFights[uint16(cardId >> 192)];
    }
    
    function tokenURI(uint256 cardId)
        external view override returns(string memory) {
        
        bytes memory bs = abi.encodePacked(cardId);
        
        return uriPrefix.concat("card/").concat(Util.base64Encode(bs));
    }
}
