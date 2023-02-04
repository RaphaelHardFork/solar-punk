// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {ArtifactWriter} from "script/utils/ArtifactWriter.sol";
import {SolarPunkDestructible} from "script/test_contracts/SolarPunkDestructible.sol";
import {Kiwi} from "src/vectors/shapes/Kiwi.sol";

contract deploy is Script, ArtifactWriter {
    using Strings for uint256;

    address private DEPLOYER;

    function run() public {
        // import `.env` private key
        uint256 pk = vm.envUint("DEPLOYER_GOERLI");
        DEPLOYER = vm.addr(pk);

        _logsDeploymentEnvironment();

        vm.startBroadcast(pk);

        // SolarPunkDestructible solarPunk = new SolarPunkDestructible();
        // Kiwi kiwi = new Kiwi();
        // solarPunk.addAsset(0x51Ab5BACfaBF7Df56D6E845DdF92D6e8cA4C7520);

        SolarPunkDestructible solarPunk = SolarPunkDestructible(
            0x5c70a094856A64a160308526c00e529C60992469
        );
        for (uint256 i; i < 20; i++) {
            solarPunk.requestMint{value: solarPunk.cost()}(block.number + 20);
        }

        vm.stopBroadcast();

        writeArtifact(
            "SolarPunkDestructible",
            DEPLOYER,
            address(solarPunk),
            abi.encode(0),
            false,
            address(0)
        );
    }

    /// @notice util to log the deployment environment
    function _logsDeploymentEnvironment() internal view {
        // network
        console.log(
            string.concat(
                "On network: ",
                _findNetworkAlias(),
                " (",
                block.chainid.toString(),
                ")"
            )
        );

        // block number
        console.log(string.concat("Block number: ", block.number.toString()));

        // deployer
        console.log(
            "Deployer: ",
            DEPLOYER,
            string.concat(" (balance: ", DEPLOYER.balance.toString(), ")")
        );
    }
}
