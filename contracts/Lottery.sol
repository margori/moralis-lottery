// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery {
    using SafeMath for uint256;

    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 usdEntryFee;

    constructor(address _ethUsdPriceFeed) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = 50; // 50 USD
    }

    function enter() public payable {
        require(msg.value >= getEntranceFee(), "Not enough ether to enter");
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 precision = 1 * 10**18;
        uint256 price = getLatestEthUsdPrice();
        uint256 costToEnter = (precision / price) *(usdEntryFee * 10 ** 8);
        return costToEnter;
    }

    function getLatestEthUsdPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        return uint256(answer);
    }

    // function startLottery() public{

    // }

    // function endLottery() public{

    // }

    // function pickWinner() public {

    // }
}
