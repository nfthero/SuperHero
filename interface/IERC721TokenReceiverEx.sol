pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./IERC721TokenReceiver.sol";

interface IERC721TokenReceiverEx is IERC721TokenReceiver {
    // bytes4(keccak256("onERC721ExReceived(address,address,uint256[],bytes)")) = 0x0f7b88e3
    function onERC721ExReceived(address operator, address from,
        uint256[] memory tokenIds, bytes memory data)
        external returns(bytes4);
}
