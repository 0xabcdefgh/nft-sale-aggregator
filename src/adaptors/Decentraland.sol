// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IMarketPlaceV2 } from "../interfaces/IMarketPlaceV2.sol";
import { SafeERC20, IERC20 } from  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ICollectionStore, IERC721CollectionV2, ItemToBuy } from "../interfaces/IDecentralandCollectionStore.sol";

contract Decentraland is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    //---------------- Errors -------------------//
    error ZeroAddressBeneficary();

    //-----------------State Variables -----------//

    /// Contract which get used to facilitate the primary sale of NFTs
    /// on decentraland ecosystem.
    ICollectionStore immutable primarySaleContract;
    /// Contract which get used to facilitate the secondary sale of NFTs
    /// on decentraland ecosystem.
    IMarketPlaceV2 immutable secondarySaleContract;
    /// Accepted ERC20 token by the primary and secondary sale contracts.
    IERC20 immutable acceptedToken;

    //------------ Events ------------------//
    event ItemPurchased(address beneficiary, address nftContract, uint256 tokenId, uint256 price);

    /// Initializer of the contract
    /// @param collectionStore Address of the contract that facilitates the primary sales.
    /// @param marketplaceV2   Address of the contract that facilitates the secondary sales.
    constructor(address collectionStore, address marketplaceV2) {
        primarySaleContract   = ICollectionStore(collectionStore);
        secondarySaleContract = IMarketPlaceV2(marketplaceV2);
        // It is knowns that primarySale acceptedToken and secondary sale token is MANA.
        acceptedToken = primarySaleContract.acceptedToken(); 
        // Provide approval.
        acceptedToken.approve(collectionStore, type(uint256).max);
        acceptedToken.approve(marketplaceV2, type(uint256).max);
    }

    /// @notice Provide the approval to the given `spender`.
    /// @param spender who is allowed to spend the funds of the contract.
    /// @param amt Amount of funds allowed to spend by the `spender`.
    function setApprovals(address spender, uint256 amt) external onlyOwner {
        acceptedToken.safeApprove(spender, uint256(0));
        acceptedToken.safeApprove(spender, amt);
    }

    /// @notice Allow to sweep asset (ERC20/ERC721) from the contract by the owner.
    /// @param beneficiary Who is going to receive tokens.
    /// @param asset Address of the asset,i.e. ERC20 or ERC721.
    /// @param tokenId Identifier of the NFT.
    /// @param amount Amount of token swept from the contract.
    function sweepAsset(address beneficiary, address asset, uint256 tokenId, uint256 amount) external onlyOwner {
        if (beneficiary == address(0)) {
            revert ZeroAddressBeneficary();
        }
        if (tokenId != uint256(0) && amount == uint256(0)) {
            IERC721(asset).safeTransferFrom(address(this), beneficiary, tokenId);
        } else {
            IERC20(asset).safeTransferFrom(address(this), beneficiary, amount);
        }
    }

    /// @notice Allows to purchase the NFT in the primary sales.
    /// @param beneficiary Who is going to receive tokens.
    /// @param nftContract Address of the asset,i.e. ERC721.
    /// @param tokenId Identifier of the NFT which needs to purchased.
    /// @param price Price of the tokenId that is user willing to pay,
    ///        It can be passed as zero by the dApp but prices can be set
    ///        by quering the item price from the collection store.
    function purchaseItem(
        address beneficiary,
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        if (beneficiary == address(0)) {
            revert ZeroAddressBeneficary();
        }
        if (price == uint256(0)) {
            (price,) = primarySaleContract.getItemBuyData(IERC721CollectionV2(nftContract), tokenId);
        }
        if (price > uint256(0)) {
            // Transfer the fund from the msg.sender to the contract
            acceptedToken.safeTransferFrom(msg.sender, address(this), price);
        }
        // Convert the details in non ItemsToBuy struct.
        ItemToBuy[] memory _itemsToBuy = _generateInput(beneficiary, nftContract, tokenId, price); 
        primarySaleContract.buy(_itemsToBuy);
        emit ItemPurchased(beneficiary, nftContract, tokenId, price);
    }

    /// @notice Allows to purchase the NFT in the secondary sales.
    /// @param beneficiary Who is going to receive tokens.
    /// @param nftContract Address of the asset,i.e. ERC721.
    /// @param tokenId Identifier of the NFT which needs to purchased.
    /// @param price Price of the tokenId that is user willing to pay,
    ///        It can be passed as zero by the dApp but prices can be set
    ///        by quering the item price from the collection store.
    function purchaseOrder(
        address beneficiary,
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        if (beneficiary == address(0)) {
            revert ZeroAddressBeneficary();
        }
        if (price == uint256(0)) {
            price = secondarySaleContract.orderByAssetId(nftContract, tokenId).price;
        }
        if (price > uint256(0)) {
            // Transfer the fund from the msg.sender to the contract
            acceptedToken.safeTransferFrom(msg.sender, address(this), price);
        }
        // Purchase the order.
        secondarySaleContract.executeOrder(nftContract, tokenId, price);
        // Transfer the tokenId to the beneficiary.
        IERC721(nftContract).safeTransferFrom(address(this), beneficiary, tokenId);
        // Emit event.
        emit ItemPurchased(beneficiary, nftContract, tokenId, price);
    }

    function _generateInput(
        address beneficiary,
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) internal pure returns(ItemToBuy[] memory itemsToBuy) {
        address[] memory beneficiaries = new address[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory prices = new uint256[](1);
        beneficiaries[0] = beneficiary;
        ids[0] = tokenId;
        prices[0] = price;
        itemsToBuy[0] = ItemToBuy(IERC721CollectionV2(nftContract), ids, prices, beneficiaries);
    }

}