// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
// for this version of solidity, we dont need to import safeMath, for lower versions, it is necessary

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; //this line helps me to import interfaces

contract FundMe {
    //this sentence is for check overflows for uint256:
    // using SafeMathChainlink for uint256;
    mapping(address => uint256) public addressToAmountFunded; //who sent us some money
    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 7 * 10**15; //in wei -->0.007 eth
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //msg.sender = who sent us money
        //msg.value = value sent
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //the address comes from https://docs.chain.link/docs/ethereum-addresses/#:~:text=ethereum
        //rinkeby testnet, pail ETH/USD
        return priceFeed.version(); //this is an interface
    }

    function getPrice() public view returns (uint256) {
        //tuple(below): list of objects of potentially different types whose number is a constant at compile-time
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //this is another one interface
        return uint256(answer * 10000000000);
        //193776175340 --> really the value is 1937.76175340 considering 8 decimals
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        //0.000001937761753400
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; //first do the code mentioned above.
    }

    function withdraw() public payable {
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance); //this is the contract that you're currently in
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }
}
