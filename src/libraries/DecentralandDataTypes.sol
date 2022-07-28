// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721CollectionV2 } from "../interfaces/IERC721CollectionV2.sol";

struct ItemToBuy {
    IERC721CollectionV2 collection;
    uint256[] ids;
    uint256[] prices;
    address[] beneficiaries;
}

struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address
    address nftAddress;
    // Price (in wei) for the published item
    uint256 price;
    // Time when this sale ends
    uint256 expiresAt;
}