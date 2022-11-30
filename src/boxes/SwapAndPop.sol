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
        uint256 itemsAmount = box.itemsAmount;
        require(itemsAmount > 0, "SwapAndPop: empty");
        uint256 index = randNum % itemsAmount;
        itemId = box.itemsId[index];

        if (itemId == 0) {
            itemId = index;
        }

        box.itemsId[index] = itemsAmount - 1;
        --box.itemsAmount;
    }
}
