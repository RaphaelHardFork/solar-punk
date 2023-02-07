// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISolarPunk {
    /*/////////////////////////////////////////////////////////////
                                EVENTS
    /////////////////////////////////////////////////////////////*/
    event RequestCreated(
        address indexed owner,
        uint256 blockNumber,
        uint256 amount
    );

    event AssetAdded(uint256 index, address shapeAddr);

    event RequestPostponed(address indexed owner, uint256 newBlockNumber);

    event RequestFulfilled(address indexed owner, uint256 tokenId);

    /*/////////////////////////////////////////////////////////////
                                ERRORS
    /////////////////////////////////////////////////////////////*/
    error OutOfBlockRange(uint256 blockNumber);
    error ValueBelowExpected(uint256 value);
    error NoAvailableItems();
    error RequestListTooLong();
    error NoRequestToFulfill();
    error InexistantIndex(uint256 index);
    error InexistantAsset(uint256 index);

    /*/////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    /////////////////////////////////////////////////////////////*/

    function requestMint(uint256 blockNumber, uint256 amount) external payable;

    function fulfillRequest(bool onlyOwnerRequest) external;

    function mintPendingItems() external;

    function addAsset(address assetAddr) external;

    /*/////////////////////////////////////////////////////////////
                                GETTERS
    /////////////////////////////////////////////////////////////*/

    function cost() external view returns (uint256);

    function requestList()
        external
        view
        returns (address[] memory addresses, uint256[] memory blocksNumber);

    function pendingMints(address account)
        external
        view
        returns (uint256[] memory);

    function numberOfShapes() external view returns (uint256);

    function availableItems() external view returns (uint256);

    function remainningItemOfShape(uint256 index)
        external
        view
        returns (uint256);

    function totalRemainingItems() external view returns (uint256 totalItem);

    function contractURI() external pure returns (string memory);
}
