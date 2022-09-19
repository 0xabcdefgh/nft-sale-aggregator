// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IMarketPlaceV2 } from "../interfaces/IMarketPlaceV2.sol";
import { SafeERC20, IERC20 } from  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ICollectionStore, IERC721CollectionV2, ItemToBuy } from "../interfaces/IDecentralandCollectionStore.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { NFTDetails, PriceDetails } from "../libraries/GetterTypes.sol";

contract Decentraland is Ownable, ReentrancyGuard, IERC721Receiver {

    using SafeERC20 for IERC20;

    //---------------- Errors -------------------//
    error ZeroAddressBeneficary();

    //-----------------State Variables -----------//

    /// Contract which get used to facilitate the primary sale of NFTs
    /// on decentraland ecosystem.
    ICollectionStore public immutable primarySaleContract;
    /// Contract which get used to facilitate the secondary sale of NFTs
    /// on decentraland ecosystem.
    IMarketPlaceV2 public immutable secondarySaleContract;
    /// Accepted ERC20 token by the primary and secondary sale contracts.
    IERC20 public immutable acceptedToken;

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
        acceptedToken.safeIncreaseAllowance(spender, amt);
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

    /// @notice Returns the details about the NFT.
    /// @param nftAddress Address of the NFT whose data need to queried.
    /// @param tokenId Identitifer of the NFT.
    function getNFTData(address nftAddress, uint256 tokenId) external view returns(NFTDetails memory) {
        uint256 nftPrice = secondarySaleContract.orderByAssetId(nftAddress, tokenId).price;
        try IERC721CollectionV2(nftAddress).items(uint256(0)) returns (string memory,uint256,uint256,uint256 price,address,string memory metadata, string memory contentHash) {
           return _returnNFTData(nftPrice, price, nftAddress, tokenId, metadata, contentHash);
        } catch Panic(uint /*errorCode*/) {
            try IERC721CollectionV2(nftAddress).items(uint256(1)) returns (string memory,uint256,uint256,uint256 price,address,string memory metadata, string memory contentHash) {
                return _returnNFTData(nftPrice, price, nftAddress, tokenId, metadata, contentHash);
            } catch Panic(uint /**errorCode */) {
                (,,,uint256 price,,string memory metadata, string memory contentHash) = IERC721CollectionV2(nftAddress).items(tokenId);
                return _returnNFTData(nftPrice, price, nftAddress, tokenId, metadata, contentHash);
            }
        }
    }

    function _returnNFTData(uint256 nftPrice, uint256 itemPrice, address nftAddress, uint256 tokenId, string memory metadata, string memory contentHash) internal view returns (NFTDetails memory){
        string memory name = IERC721Metadata(nftAddress).name();
        string memory symbol = IERC721Metadata(nftAddress).symbol();
        string memory tokenURI;
        try IERC721Metadata(nftAddress).tokenURI(tokenId) returns(string memory _tokenURI) {
            tokenURI = _tokenURI;
        } catch Error(string memory /** errorStatement */) {
            tokenURI = "";
        }
        if (nftPrice == 0) {
            nftPrice = itemPrice;
        }
        PriceDetails memory priceDetails = PriceDetails({token: address(acceptedToken), price: nftPrice});
        return NFTDetails(priceDetails, name, symbol, tokenURI, metadata, contentHash);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    function _generateInput(
        address beneficiary,
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public pure returns(ItemToBuy[] memory) {
        address[] memory beneficiaries = new address[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory prices = new uint256[](1);
        ItemToBuy[] memory itemsToBuy = new ItemToBuy[](1);
        beneficiaries[0] = beneficiary;
        ids[0] = tokenId;
        prices[0] = price;
        itemsToBuy[0] = ItemToBuy(IERC721CollectionV2(nftContract), ids, prices, beneficiaries);
        return itemsToBuy;
    }

}