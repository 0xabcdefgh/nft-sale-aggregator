// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { 
    Decentraland,
    IERC721,
    ICollectionStore,
    ItemToBuy,
    IERC721CollectionV2,
    IERC20,
    NFTDetails,
    PriceDetails    
} from "../src/adaptors/Decentraland.sol";

contract DecentralandTest is Test {

    using stdStorage for StdStorage;
    
    // Polygon mainnet address of the collectionStore & MarketplaceV2 contracts
    // ref- CollectionStore - https://polygonscan.com/address/0x214ffC0f0103735728dc66b61A22e4F163e275ae#code
    // ref- Marketplace V2 - https://polygonscan.com/address/0x480a0f4e360e8964e68858dd231c2922f1df45ef#code

    address public collectionStore = 0x214ffC0f0103735728dc66b61A22e4F163e275ae;
    address public marketplaceV2 = 0x480a0f4e360E8964e68858Dd231c2922f1df45Ef;

    // Polygon address of the NFT to sell.
    address public nft1 = 0x210cF28A18306E136Eb0908Ad68f14b6E1e756C6;

    // Order details on mainnet 
    /**
    {
        "nftAddress": "0x08cbc78c1b2e2eea7627c39c8adf660d52e3d82c",
        "assetId": "443",
        "priceInWei": "27900000000000000000",
        "expiresAt": "1661990400000"
    }
    */
    address public nftAddress = 0x08cbc78c1b2E2eeA7627c39C8aDF660D52e3d82c;
    Decentraland public decentralandAdapter;
    address public buyer;

    function setUp() public {
        // Deploy the Decentraland contract.
        decentralandAdapter = new Decentraland(collectionStore, marketplaceV2);
        buyer = vm.addr(999 << 225);
    }

    function testPurchaseItem() public {
        vm.prank(buyer);
        decentralandAdapter.purchaseItem(buyer, nft1, uint256(0), uint256(0));
        assertEq(IERC721(nft1).ownerOf(3676), buyer, "Transfer of NFT failed");
    }

    function testPurchaseOrder() public {
        IERC20 manaToken = decentralandAdapter.acceptedToken();
        // Add MANA token in buyer's account.
        deal(address(manaToken), buyer, 200000000000000000000);
        // verify the balance of the buyer.
        assertEq(manaToken.balanceOf(buyer), 200000000000000000000, "Incorrect value set in storage");
        vm.startPrank(buyer);
        manaToken.approve(address(decentralandAdapter), 27900000000000000000);
        decentralandAdapter.purchaseOrder(buyer, nftAddress, 443, 27900000000000000000);
        vm.stopPrank();
        assertEq(IERC721(nftAddress).ownerOf(443), buyer, "Transfer of NFT failed");
        uint256 remainingBalance = 200000000000000000000 - 27900000000000000000;
        assertEq(manaToken.balanceOf(buyer), remainingBalance, "Incorrect balance accounting");
    }

    function testGetNFTDataWhenNFTIsNotMintedYet() public {
        NFTDetails memory details = decentralandAdapter.getNFTData(nft1, 3676);
        assertEq(details.priceDetails.price, uint256(0), "Incorrect price fetch");
        assertEq(details.priceDetails.token, address(decentralandAdapter.acceptedToken()), "Incorrect token address");
        assertEq(details.name, "Dojo Fish Wearables", "Incorrect name");
        assertEq(details.symbol, "DCL-DJFSHWRBLS", "Incorrect symbol");
        assertEq(details.tokenURI, "", "Incorrect tokenURI");
        assertEq(details.metadata, "1:w:Dojo Fish Shirt::upper_body:BaseFemale,BaseMale", "Incorrect metadata");
        assertEq(details.contentHash, "QmNqPJg6PjR9zJ8brjyy2XEQkBJcSv2FcsGZPx4bnMERz6", "Incorrect contentHash");
    }

    function testGetNFTDataWhenNFTIsMinted() public {
        NFTDetails memory details = decentralandAdapter.getNFTData(nft1, 3675);
        assertEq(details.priceDetails.price, uint256(0), "Incorrect price fetch");
        assertEq(details.priceDetails.token, address(decentralandAdapter.acceptedToken()), "Incorrect token address");
        assertEq(details.name, "Dojo Fish Wearables", "Incorrect name");
        assertEq(details.symbol, "DCL-DJFSHWRBLS", "Incorrect symbol");
        assertEq(details.tokenURI, "https://peer.decentraland.org/lambdas/collections/standard/erc721/137/0x210cf28a18306e136eb0908ad68f14b6e1e756c6/0/3675", "Incorrect tokenURI");
        assertEq(details.metadata, "1:w:Dojo Fish Shirt::upper_body:BaseFemale,BaseMale", "Incorrect metadata");
        assertEq(details.contentHash, "QmNqPJg6PjR9zJ8brjyy2XEQkBJcSv2FcsGZPx4bnMERz6", "Incorrect contentHash");
    }

    function testGetNFTDataWhenNFTIsOnOrder() public {
        NFTDetails memory details = decentralandAdapter.getNFTData(nftAddress, 443);
        assertEq(details.priceDetails.price, uint256(27900000000000000000), "Incorrect price fetch");
        assertEq(details.priceDetails.token, address(decentralandAdapter.acceptedToken()), "Incorrect token address");
        assertEq(details.name, "Blue santa hat", "Incorrect name");
        assertEq(details.symbol, "DCL-BLSNTHT", "Incorrect symbol");
        assertEq(details.tokenURI, "https://peer.decentraland.org/lambdas/collections/standard/erc721/137/0x08cbc78c1b2e2eea7627c39c8adf660d52e3d82c/0/443", "Incorrect tokenURI");
        assertEq(details.metadata, "1:w:Blue santa hat:It's A Blue santa hat:hat:BaseMale,BaseFemale", "Incorrect metadata");
        assertEq(details.contentHash, "QmXggx8reuohcxZRvMRjEJPYAkr7C7xWSKTX4iTdNuqxo4", "Incorrect contentHash");
    }

    function testSafeApprove() public {
        IERC20(decentralandAdapter.acceptedToken()).approve(collectionStore, type(uint256).max);
        assertEq(IERC20(decentralandAdapter.acceptedToken()).allowance(address(decentralandAdapter), collectionStore), type(uint256).max, "Incorrect allowance");
        decentralandAdapter.setApprovals(collectionStore, 5);
        assertEq(IERC20(decentralandAdapter.acceptedToken()).allowance(address(decentralandAdapter), collectionStore), 5, "Incorrect allowance");
    }
}
