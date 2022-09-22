// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721BaseCollectionV2} from "./IERC721BaseCollectionV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ItemToBuy} from "../libraries/DecentralandDataTypes.sol";

interface ICollectionStore {
    function buy(ItemToBuy[] memory _itemsToBuy) external;

    /**
     * @notice Get item's price and beneficiary
     * @param _collection - collection address
     * @param _itemId - item id
     * @return uint256 of the item's price
     * @return address of the item's beneficiary
     */
    function getItemBuyData(
        IERC721BaseCollectionV2 _collection,
        uint256 _itemId
    )
        external
        view
        returns (uint256, address);

    function acceptedToken() external view returns (IERC20);
}