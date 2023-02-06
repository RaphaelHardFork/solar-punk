// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "src/SolarPunk.sol";
import "src/vectors/shapes/IShape.sol";
import "src/vectors/shapes/Kiwi.sol";
import "src/vectors/shapes/Dragonfly.sol";

abstract contract BaseSolarPunk {
    SolarPunk internal solar;

    address internal KIWI;
    address internal DRAGONFLY;
    address internal SOLAR;

    uint256 internal GAS_PRICE;
    uint256 internal PRICE;

    function _deploy_solarPunk(address owner) internal {
        solar = new SolarPunk(owner);
        SOLAR = address(solar);
        PRICE = solar.cost();
        GAS_PRICE = tx.gasprice;
    }

    function _deploy_kiwi() internal {
        KIWI = address(new Kiwi());
    }

    function _deploy_dragonfly() internal {
        DRAGONFLY = address(new Dragonfly());
    }
}
