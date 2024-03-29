// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "src/SolarPunk.sol";
import "src/ISolarPunk.sol";
import "src/vectors/shapes/IShape.sol";
import "src/vectors/shapes/Kiwi.sol";
import "src/vectors/shapes/Dragonfly.sol";
import "src/vectors/shapes/Onion.sol";

abstract contract BaseSolarPunk {
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
                                STATES
    /////////////////////////////////////////////////////////////*/

    SolarPunk internal solar;

    address internal KIWI;
    address internal DRAGONFLY;
    address internal ONION;
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

    function _deploy_onion() internal {
        ONION = address(new Onion());
    }
}
