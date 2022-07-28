// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { Order } from "../libraries/DecentralandDataTypes.sol";

interface IMarketPlaceV2 {

    function orderByAssetId(address, uint256) external view returns(Order memory);

    /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
    function createOrder(
        address nftAddress,
        uint256 assetId,
        uint256 priceInWei,
        uint256 expiresAt
    )
        external;

    
    /**
    * @dev Executes the sale for a published NFT and checks for the asset fingerprint
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    * @param fingerprint - Verification info for the asset
    */
    function safeExecuteOrder(
        address nftAddress,
        uint256 assetId,
        uint256 price,
        bytes memory fingerprint
    ) external;

    /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    */
    function executeOrder(
        address nftAddress,
        uint256 assetId,
        uint256 price
    )external;
    
}