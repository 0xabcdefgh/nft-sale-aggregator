// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct PriceDetails {
    address token;
    uint256 price;
}

struct NFTDetails {
    PriceDetails priceDetails;
    string name;
    string symbol;
    string tokenURI;
    string metadata;
    string contentHash;
}