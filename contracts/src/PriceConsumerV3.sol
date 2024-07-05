// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interface/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: FRAX HoleSky Testnet
     * Aggregator: ETH/USD
     * Address: 0x89e60b56efD70a1D4FBBaE947bC33cae41e37A72
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x89e60b56efD70a1D4FBBaE947bC33cae41e37A72
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function getUSDToETH(
        uint256 _usd,
        uint8 _usdDecimals
    ) public view returns (uint) {
        int _ethUSDPrice = getLatestPrice();
        uint8 _decimals = getDecimals();

        uint256 _eths = ((_usd * uint(_decimals)) / uint(_ethUSDPrice)) *
            uint(_usdDecimals);
        return _eths;
    }
}
