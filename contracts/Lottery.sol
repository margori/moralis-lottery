// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    using SafeMath for uint256;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATIN_WINNER
    }

    LOTTERY_STATE public lotteryState;

    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public usdEntryFee;
    address payable[] public players;
    address public recentWinner;

    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyHash;

    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _ethUsdPriceFeed,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = 50; // 50 USD
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = 10**17; // 0.1 LINK
        keyHash = _keyHash;
    }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open yet");
        require(msg.value >= getEntranceFee(), "Not enough ether to enter");

        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 precision = 1 * 10**18;
        uint256 price = getLatestEthUsdPrice();
        uint256 costToEnter = (precision / price) * (usdEntryFee * 10**8);
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

    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery already open");
        lotteryState = LOTTERY_STATE.OPEN;
        randomness = 0;
    }

    function endLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        lotteryState = LOTTERY_STATE.CALCULATIN_WINNER;
        pickWinner();
    }

    function pickWinner() private returns (bytes32) {
        require(
            lotteryState == LOTTERY_STATE.CALCULATIN_WINNER,
            "Lottery not calculating"
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 _randomness)
        internal
        override
    {
        require(_randomness > 0);
        uint256 index = randomness % players.length;
        players[index].transfer(address(this).balance);
        recentWinner = players[index];
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
