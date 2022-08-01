// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Decentraland, IERC721, ICollectionStore, ItemToBuy, IERC721CollectionV2, IERC20 } from "../src/adaptors/Decentraland.sol";

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
        decentralandAdapter.purchaseOrder(buyer, nftAddress, 443, uint256(0));
        vm.stopPrank();
        assertEq(IERC721(nftAddress).ownerOf(443), buyer, "Transfer of NFT failed");
        uint256 remainingBalance = 200000000000000000000 - 27900000000000000000;
        assertEq(manaToken.balanceOf(buyer), remainingBalance, "Incorrect balance accounting");
    }
}
