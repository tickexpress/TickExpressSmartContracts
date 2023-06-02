// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceFeed {
    // Define price feed contract addresses for each token
    mapping(address => address) public priceFeeds;

    constructor() {
        // Initialize price feeds for desired tokens
        // For Mumbai Testnet
        priceFeeds[
            0x0000000000000000000000000000000000001010
        ] = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada; // Polygon (MATIC)
        priceFeeds[
            0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa
        ] = 0x0715A7794a1dc8e42615F059dD6e406A6594651A; // PoS-WETH (ETH)
        priceFeeds[
            0x2d7882beDcbfDDce29Ba99965dd3cdF7fcB10A1e
        ] = 0x92C09849638959196E976289418e5973CC96d645; // ERC20-TestToken (USDT)
    }

    // Get the latest price from the price feed
    function getLatestPrice(address token) public view returns (int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeeds[token]
        );
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
