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
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
        ] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATIC
        priceFeeds[
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
        ] = 0x327E23A4855b6f663A28C5161541Ded4b5757A1a; // WETH
        priceFeeds[
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        ] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDT
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
