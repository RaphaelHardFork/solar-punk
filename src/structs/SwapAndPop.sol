// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Allow to use a mapping into an enumerable array of
 * `uint256` used to draw (randomly) items.
 *
 * Declare a set state variables
 * SwapAndPop.Box private box;
 *
 * Then use box.draw(randNum)
 */
library SwapAndPop {
    error Empty();

    struct Box {
        uint256 itemsAmount;
        mapping(uint256 => uint256) itemsId;
    }

    /**
     * @notice Use this function to remove one item from
     * the mapping
     *
     * @param box Box struct stated in your contract
     * @param randNum random number moduled by number of items
     */
    function draw(Box storage box, uint256 randNum)
        internal
        returns (uint256 itemId)
    {
        // check if items remainning
        uint256 itemsAmount = box.itemsAmount;
        if (itemsAmount == 0) revert Empty();

        // choose among available index
        uint256 index = randNum % itemsAmount;

        // assign item ID
        itemId = box.itemsId[index];
        if (itemId == 0) itemId = index;

        // read last item ID
        uint256 lastItem = box.itemsId[itemsAmount - 1];

        // assign last item ID
        if (lastItem == 0) lastItem = itemsAmount - 1;
        box.itemsId[index] = lastItem;

        // pop from the list
        delete box.itemsId[itemsAmount - 1];
        --box.itemsAmount;
    }
}
