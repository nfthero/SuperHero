pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC721TokenReceiverEx.sol";

import "./lib/Util.sol";

import "./Card.sol";
import "./CardMine.sol";
import "./Member.sol";

contract Slot is Member, IERC721TokenReceiverEx {
    struct SlotInfo {
        uint256 level;
        uint256 exp;
        
        uint256 cardId;
        int256 fightBase;
        int256 bondBuffer;
    }
    
    struct UserInfo {
        SlotInfo[] slots;
        uint256 count;
        int256 fight;
        
        mapping(uint256 => bool) bondActives;
    }
    
    struct BondInfo {
        uint256[] cardTypes;
        int256 buffer;
    }
    
    struct LevelConfig {
        uint256 exp;
        int256 buffer;
    }
    
    event Upgrade(address indexed owner, uint256 indexed cardType, uint256 level);
    
    mapping(address => UserInfo) public ownerUserInfos;
    
    uint256[] public rarityExps = [100, 200, 300, 400, 500, 600];
    LevelConfig[] public levelConfigs;
    
    BondInfo[] public bonds;
    mapping(uint256 => uint256[]) public cardTypeBonds;
    
    int256[] public countBuffers = [
        0, Util.SDENO * 10 / 100, Util.SDENO * 20 / 100,
        Util.SDENO * 30 / 100, Util.SDENO * 40 / 100, Util.SDENO * 50 / 100,
        Util.SDENO * 60 / 100, Util.SDENO * 70 / 100, Util.SDENO * 80 / 100,
        Util.SDENO * 100 / 100
    ];
    
    constructor() {
        levelConfigs.push(LevelConfig({
            exp: 0,
            buffer: 0
        }));
        levelConfigs.push(LevelConfig({
            exp: 100,
            buffer: Util.SDENO * 10 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 300,
            buffer: Util.SDENO * 20 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 500,
            buffer: Util.SDENO * 30 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 700,
            buffer: Util.SDENO * 40 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 900,
            buffer: Util.SDENO * 50 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 1100,
            buffer: Util.SDENO * 60 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 1300,
            buffer: Util.SDENO * 70 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 1500,
            buffer: Util.SDENO * 80 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 1700,
            buffer: Util.SDENO * 90 / 100
        }));
        levelConfigs.push(LevelConfig({
            exp: 1900,
            buffer: Util.SDENO * 100 / 100
        }));
    }
    
    function setRarityExp(uint256 rarity, uint256 exp)
        external CheckPermit("Config") {
        
        for (uint256 i = rarityExps.length; i <= rarity; ++i) {
            rarityExps.push(0);
        }
        
        rarityExps[rarity] = exp;
    }
    
    function setLevelConfig(uint256 level, uint256 exp, int256 buffer)
        external CheckPermit("Config") {
        
        for (uint256 i = levelConfigs.length; i <= level; ++i) {
            levelConfigs.push(LevelConfig({
                exp: 0,
                buffer: 0
            }));
        }
        
        LevelConfig storage lc = levelConfigs[level];
        lc.exp = exp;
        lc.buffer = buffer;
    }
    
    function addBond(uint256[] memory cardTypes, int256 buffer)
        external CheckPermit("Config") {
        
        uint256 index = bonds.length;
        
        bonds.push(BondInfo({
            cardTypes: cardTypes,
            buffer: buffer
        }));
        
        uint256 length = cardTypes.length;
        for (uint256 i = 0; i != length; ++i) {
            cardTypeBonds[cardTypes[i]].push(index);
        }
    }
    
    function addBonds(uint256[][] memory cardTypess, int256[] memory buffers)
        external CheckPermit("Config") {
        
        uint256 cardTypesLength = cardTypess.length;
        uint256 index = bonds.length;
        
        for (uint256 i = 0; i != cardTypesLength; ++i) {
            uint256[] memory cardTypes = cardTypess[i];
            
            bonds.push(BondInfo({
                cardTypes: cardTypes,
                buffer: buffers[i]
            }));
            
            uint256 cardTypeLength = cardTypes.length;
            for (uint256 j = 0; j != cardTypeLength; ++j) {
                cardTypeBonds[cardTypes[j]].push(index);
            }
            
            ++index;
        }
    }
    
    function getUserInfo(address owner) external view
        returns(SlotInfo[] memory, int256 fight) {
        
        UserInfo storage ui = ownerUserInfos[owner];
        
        return (ui.slots, ui.fight);
    }
    
    function getSlotInfo(address owner, uint256 cardType)
        external view returns(SlotInfo memory) {
        
        return ownerUserInfos[owner].slots[cardType];
    }
    
    function onERC721Received(address, address from,
        uint256 cardId, bytes memory data)
        external override returns(bytes4) {
        
        if (msg.sender == manager.members("card")) {
            uint256 operate = uint8(data[0]);
            
            if (operate == 1) {
                uint256[] memory cardIds = new uint256[](1);
                cardIds[0] = cardId;
                _addCards(from, cardIds);
            } else {
                return 0;
            }
        }
        
        return Util.ERC721_RECEIVER_RETURN;
    }
    
    function onERC721ExReceived(address, address from,
        uint256[] memory cardIds, bytes memory data)
        external override returns(bytes4) {
        
        if (msg.sender == manager.members("card")) {
            uint256 operate = uint8(data[0]);
            
            if (operate == 1) {
                _addCards(from, cardIds);
            } else {
                return 0;
            }
        }
        
        return Util.ERC721_RECEIVER_EX_RETURN;
    }
    
    function _onFightChanged(address owner) internal {
        UserInfo storage ui = ownerUserInfos[owner];
        
        uint256 countIndex = ui.count / 12;
        int256 buffer = countIndex < countBuffers.length ?
            countBuffers[countIndex] : countBuffers[countBuffers.length - 1];
            
        int256 fight = ui.fight * (Util.SDENO + buffer) / (Util.SDENO ** 3);
        
        CardMine(manager.members("cardMine")).updateFight(owner, fight);
    }
    
    function _addCards(address owner, uint256[] memory cardIds) internal {
        UserInfo storage ui = ownerUserInfos[owner];
        SlotInfo[] storage slots = ui.slots;
        
        Card card = Card(manager.members("card"));
        int256 delta = 0;
        
        uint256 lengthMax = ~uint256(0);
        
        for (uint256 c = cardIds.length - 1; c != lengthMax; --c) {
            uint256 cardId = cardIds[c];
            uint256 cardType = (cardId ^ (1 << 255)) >> 224;
            
            for (uint256 i = slots.length; i <= cardType; ++i) {
                slots.push(SlotInfo({
                    level: 0,
                    exp: 0,
                    cardId: 0,
                    
                    fightBase: 0,
                    bondBuffer: Util.SDENO
                }));
            }
            
            SlotInfo storage si = slots[cardType];
            
            int256 fightBase = card.getFight(cardId) *
                (Util.SDENO + levelConfigs[si.level].buffer);
            
            if (si.cardId == 0) {
                si.cardId = cardId;
                ui.count++;
                
                si.fightBase = fightBase;
                delta += fightBase * Util.SDENO;
                
                uint256[] storage cbs = cardTypeBonds[cardType];
                
                for (uint256 i = cbs.length - 1; i != lengthMax; --i) {
                    BondInfo storage bi = bonds[cbs[i]];
                    
                    uint256[] storage cardTypes = bi.cardTypes;
                    
                    bool active = true;
                    for (uint256 j = cardTypes.length - 1; j != lengthMax; --j) {
                        if (cardTypes[j] >= slots.length || slots[cardTypes[j]].cardId == 0) {
                            active = false;
                            break;
                        }
                    }
                    
                    if (active) {
                        ui.bondActives[cbs[i]] = true;
                        
                        for (uint256 j = cardTypes.length - 1; j != lengthMax; --j) {
                            SlotInfo storage slotInfo = slots[cardTypes[j]];
                            
                            delta += slotInfo.fightBase * bi.buffer;
                            
                            slotInfo.bondBuffer += bi.buffer;
                        }
                    }
                }
            } else {
                delta += (fightBase - si.fightBase) * si.bondBuffer;
                si.fightBase = fightBase;
                
                card.transferFrom(address(this), owner, si.cardId);
                si.cardId = cardId;
            }
        }
        
        ui.fight += delta;
        _onFightChanged(owner);
    }
    
    function removeCard(uint256 cardType) external {
        UserInfo storage ui = ownerUserInfos[msg.sender];
        SlotInfo[] storage slots = ui.slots;
        require(cardType < slots.length, "no card in slot");
        
        SlotInfo storage si = slots[cardType];
        require(si.cardId != 0, "no card in slot");
            
        uint256[] storage cbs = cardTypeBonds[cardType];
        uint256 cbsLength = cbs.length;
        
        int256 delta = si.fightBase * Util.SDENO;
        
        for (uint256 i = 0; i != cbsLength; ++i) {
            uint256 bondIndex = cbs[i];
            if (!ui.bondActives[bondIndex]) {
                continue;
            }
            ui.bondActives[bondIndex] = false;
            
            BondInfo storage bi = bonds[bondIndex];
            uint256[] storage cardTypes = bi.cardTypes;
            uint256 ctLength = cardTypes.length;
            
            for (uint256 j = 0; j != ctLength; ++j) {
                SlotInfo storage slotInfo = slots[cardTypes[j]];
                
                delta += slotInfo.fightBase * bi.buffer;
                slotInfo.bondBuffer -= bi.buffer;
            }
        }
        
        ui.fight -= delta;
        
        Card(manager.members("card")).transferFrom(
            address(this), msg.sender, si.cardId);
        si.cardId = 0;
        ui.count--;
        
        _onFightChanged(msg.sender);
    }
    
    function removeAllCards() external {
        address owner = msg.sender;
        UserInfo storage ui = ownerUserInfos[owner];
        
        Card card = Card(manager.members("card"));
        
        SlotInfo[] storage slots = ui.slots;
        uint256 slotLength = slots.length;
        
        for (uint256 cardType = 0; cardType != slotLength; ++cardType) {
            SlotInfo storage si = slots[cardType];
            if (si.cardId == 0) {
                continue;
            }
            
            card.transferFrom(address(this), owner, si.cardId);
            si.cardId = 0;
            si.bondBuffer = Util.SDENO;
            
            uint256[] storage cbs = cardTypeBonds[cardType];
            uint256 cbsLength = cbs.length;
            
            for (uint256 i = 0; i != cbsLength; ++i) {
                ui.bondActives[cbs[i]] = false;
            }
        }
        
        ui.fight = 0;
        ui.count = 0;
        
        _onFightChanged(owner);
    }
    
    function upgrade(address owner, uint256[] memory cardIds) external {
        address cardAddr = manager.members("card");
        require(msg.sender == cardAddr, "card only");
        Card card = Card(cardAddr);
        
        UserInfo storage ui = ownerUserInfos[owner];
        SlotInfo[] storage slots = ui.slots;
        
        uint256 cardIdLength = cardIds.length;
        
        for (uint256 i = 0; i != cardIdLength; ++i) {
            uint256 cardId = cardIds[i];
            uint256 cardType = (cardId ^ (1 << 255)) >> 224;
            
            for (uint256 j = slots.length; j <= cardType; ++j) {
                slots.push(SlotInfo({
                    level: 0,
                    exp: 0,
                    cardId: 0,
                    
                    fightBase: 0,
                    bondBuffer: Util.SDENO
                }));
            }
            
            SlotInfo storage si = slots[cardType];
            uint256 levelLength = levelConfigs.length;
            require(si.level + 1 < levelLength, "slot level full");
            
            si.exp += rarityExps[uint16(cardId >> 192)];
            
            uint256 level = si.level;
            while (level + 1 < levelLength) {
                uint256 cost = levelConfigs[level + 1].exp;
                
                if (si.exp >= cost) {
                    si.exp -= cost;
                    ++level;
                } else {
                    break;
                }
            }
            
            if (si.level == level) {
                continue;
            }
            
            si.level = level;
            emit Upgrade(owner, cardType, level);
            
            if (si.cardId == 0) {
                continue;
            }
            
            int256 fightBase = card.getFight(si.cardId)
                * (Util.SDENO + levelConfigs[level].buffer);
                
            ui.fight += (fightBase - si.fightBase) * si.bondBuffer;
            
            si.fightBase = fightBase;
        }
        
        _onFightChanged(owner);
    }
}
