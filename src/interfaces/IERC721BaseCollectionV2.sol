// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721BaseCollectionV2 is IERC721 {
    function COLLECTION_HASH() external view returns (bytes32);

    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }

    function issueTokens(
        address[] calldata _beneficiaries,
        uint256[] calldata _itemIds
    )
        external;
    function setApproved(bool _value) external;

    /// @dev For some reason using the Struct Item as an output parameter fails, but works as an input parameter
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        bool _shouldComplete,
        bool _isApproved,
        address _rarities,
        ItemParam[] memory _items
    )
        external;
    function items(uint256 _itemId)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            string memory,
            string memory
        );

    /**
     * @notice Decode token id
     * @dev itemId (`itemIdBits` bits) + issuedId (`issuedIdBits` bits)
     * @param _id - token id
     * @return itemId uint256 of the item id
     * @return issuedId uint256 of the issued id
     */
    function decodeTokenId(uint256 _id)
        external
        pure
        returns (uint256 itemId, uint256 issuedId);

    
    /**
     * @notice Encode token id
     * @dev itemId (`itemIdBits` bits) + issuedId (`issuedIdBits` bits)
     * @param _itemId - item id
     * @param _issuedId - issued id
     * @return id uint256 of the encoded id
     */
    function encodeTokenId(uint256 _itemId, uint256 _issuedId) external pure returns (uint256 id);
}