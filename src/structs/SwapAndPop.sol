// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SwapAndPop {
    struct Box {
        uint256 itemsAmount;
        mapping(uint256 => uint256) itemsId;
    }

    function draw(Box storage box, uint256 randNum)
        internal
        returns (uint256 itemId)
    {
        // check if items remainning
        uint256 itemsAmount = box.itemsAmount;
        require(itemsAmount > 0, "SwapAndPop: empty");

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
