// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {ArtifactWriter} from "script/utils/ArtifactWriter.sol";
import {SolarPunkDestructible} from "script/test_contracts/SolarPunkDestructible.sol";
import {SolarPunk} from "src/SolarPunk.sol";
import {Kiwi} from "src/vectors/shapes/Kiwi.sol";
import {Dragonfly} from "src/vectors/shapes/Dragonfly.sol";

contract deploy is Script, ArtifactWriter {
    using Strings for uint256;

    address private DEPLOYER;

    function run() public {
        // import `.env` private key
        uint256 pk = vm.envUint("DEPLOYER_ANVIL");
        DEPLOYER = vm.addr(pk);

        _logsDeploymentEnvironment();

        vm.startBroadcast(pk);

        SolarPunk solarPunk = new SolarPunk(DEPLOYER);
        Kiwi kiwi = new Kiwi();
        Dragonfly dragonfly = new Dragonfly();

        solarPunk.addAsset(address(kiwi));
        solarPunk.addAsset(address(dragonfly));

        vm.stopBroadcast();
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
