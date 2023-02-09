// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {SolarPunk} from "src/SolarPunk.sol";
import {Kiwi} from "src/vectors/shapes/Kiwi.sol";
import {Dragonfly} from "src/vectors/shapes/Dragonfly.sol";

contract assets is Script {
    using Strings for uint256;

    address internal constant OWNER = address(501);
    uint256 internal constant NUMBER_OF_TOKEN = 100;
    uint256 internal constant TARGET_BLOCK = 2000;

    function run() public {
        require(block.chainid == 31337, "Only on test blockchain");
        vm.startPrank(OWNER);
        vm.deal(OWNER, 10000 ether);
        vm.roll(100_000);
        try vm.readFile("cache/assets/raw/0") {} catch {
            revert(
                "Run `node utils/render.js` before to create the file structure"
            );
        }

        // deploy token contract
        SolarPunk solar = new SolarPunk(OWNER);

        // add shapes
        solar.addAsset(address(new Kiwi()));
        solar.addAsset(address(new Dragonfly()));

        // mint X number of token
        solar.requestMint{value: 10 ether}(
            block.number + TARGET_BLOCK,
            NUMBER_OF_TOKEN
        );
        vm.roll(block.number + 5 + TARGET_BLOCK);
        console.log(
            string.concat(
                "Blockhash: ",
                uint256(blockhash(TARGET_BLOCK + 100_000)).toString()
            )
        );
        solar.fulfillRequest(false);

        // print tokenURI in cache => PATH cache/assets/raw need to be created
        for (uint256 i; i < NUMBER_OF_TOKEN; i++) {
            uint256 tokenId = solar.tokenOfOwnerByIndex(OWNER, i);
            vm.writeFile(
                string.concat("cache/assets/raw/", i.toString()),
                solar.tokenURI(tokenId)
            );
        }
        vm.writeFile("cache/assets/raw/contract", solar.contractURI());
    }
}
