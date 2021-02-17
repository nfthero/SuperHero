 pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC721TokenReceiverEx.sol";

import "./lib/Address.sol";
import "./lib/Util.sol";

import "./ERC721.sol";
import "./Member.sol";

abstract contract ERC721Ex is ERC721, Member {
    using Address for address;
    
    uint256 public constant NFT_SIGN_BIT = 1 << 255;
    
    uint256 public totalSupply = 0;
    
    string public uriPrefix = "http://api.dgqxyc.com/";
    
    function _mint(address to, uint256 tokenId) internal {
        _addTokenTo(to, tokenId);
        
        ++totalSupply;
        
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal {
        address owner = tokenOwners[tokenId];
        _removeTokenFrom(owner, tokenId);
        
        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }
        
        emit Transfer(owner, address(0), tokenId);
    }
    
    function safeBatchTransferFrom(address from, address to,
        uint256[] memory tokenIds) external {
        
        safeBatchTransferFrom(from, to, tokenIds, "");
    }
    
    function safeBatchTransferFrom(address from, address to,
        uint256[] memory tokenIds, bytes memory data) public {
        
        batchTransferFrom(from, to, tokenIds);
        
        if (to.isContract()) {
            require(IERC721TokenReceiverEx(to)
                .onERC721ExReceived(msg.sender, from, tokenIds, data)
                == Util.ERC721_RECEIVER_EX_RETURN,
                "onERC721ExReceived() return invalid");
        }
    }
    
    function batchTransferFrom(address from, address to,
        uint256[] memory tokenIds) public {
        
        require(from != address(0), "from is zero address");
        require(to != address(0), "to is zero address");
        
        uint256 length = tokenIds.length;
        address sender = msg.sender;
        
        bool approval = from == sender || approvalForAlls[from][sender];
        
        for (uint256 i = 0; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
			
            require(from == tokenOwners[tokenId], "from must be owner");
            require(approval || sender == tokenApprovals[tokenId],
                "sender must be owner or approvaled");
            
            if (tokenApprovals[tokenId] != address(0)) {
                delete tokenApprovals[tokenId];
            }
            
            _removeTokenFrom(from, tokenId);
            _addTokenTo(to, tokenId);
            
            emit Transfer(from, to, tokenId);
        }
    }
    
    function setUriPrefix(string memory prefix)
        external CheckPermit("Config") {
        
        uriPrefix = prefix;
    }
}
