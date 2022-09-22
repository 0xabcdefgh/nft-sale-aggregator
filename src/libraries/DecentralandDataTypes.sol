// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721BaseCollectionV2} from
    "../interfaces/IERC721BaseCollectionV2.sol";

struct ItemToBuy {
    IERC721BaseCollectionV2 collection;
    uint256[] ids;
    uint256[] prices;
    address[] beneficiaries;
}

struct Order
// Order ID
{
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