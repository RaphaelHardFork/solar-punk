// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Allow to use a mapping into an enumerable array of
 * `uint256` used to draw (randomly) items.
 *
 * Declare a set state variables
 * SwapAndPop.Reserve private reserve;
 *
 * Then use box.draw(randNum)
 *
 * @dev WARNING the librairy is permissive, a set of item can
 * overrided by replacing the stock amount
 */
library SwapAndPop {
    error Empty();

    struct Reserve {
        uint256 stock;
        mapping(uint256 => uint256) itemsId;
    }

    /**
     * @notice Use this function to remove one item from
     * the mapping
     *
     * @param reserve Reserve struct stated in your contract
     * @param randNum random number moduled by number of items
     */
    function draw(Reserve storage reserve, uint256 randNum)
        internal
        returns (uint256 itemId)
    {
        // check if items remainning
        uint256 itemsAmount = reserve.stock;
        if (itemsAmount == 0) revert Empty();

        // choose among available index
        uint256 index = randNum % itemsAmount;

        // assign item ID
        itemId = reserve.itemsId[index];
        if (itemId == 0) itemId = index;

        // read last item ID
        uint256 lastItem = reserve.itemsId[itemsAmount - 1];

        // assign last item ID
        if (lastItem == 0) lastItem = itemsAmount - 1;
        reserve.itemsId[index] = lastItem;

        // pop from the list
        delete reserve.itemsId[itemsAmount - 1];
        --reserve.stock;
    }
}
