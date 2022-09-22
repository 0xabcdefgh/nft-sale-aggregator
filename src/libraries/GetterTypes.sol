// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct PriceDetails {
    address token;
    uint256 price;
}

struct OrderDetails {
    MarketplaceType marketType;
    bool orderIsStillValid;
}

struct NFTDetails {
    PriceDetails priceDetails;
    OrderDetails orderDetails;
    string name;
    string symbol;
    string tokenURI;
    string metadata;
    string contentHash;
}

enum MarketplaceType {
    Primary,
    Secondary
}