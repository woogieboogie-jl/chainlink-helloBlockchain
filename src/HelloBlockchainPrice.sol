// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// for string concatenation
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract HelloBlockchainWithPrice {
    using Strings for uint256;
    AggregatorV3Interface internal priceFeed;
    string public blockchainName;

    mapping(string => address) public priceFeedRegistry;

    constructor() {
        priceFeedRegistry["Avalanche"] = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD;
        priceFeedRegistry["Chainlink"] = 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470;
    }

    // Explain difference between external vs public
    // Explain difference between calldata and memory
    function setBlockchainName(string calldata _blockchainName) external {
        blockchainName = _blockchainName;
        
        // Explain logic - Set priceFeed & revert if the name is not found in our registry.
        address feedAddress = priceFeedRegistry[blockchainName];
        require(feedAddress != address(0), "Price feed not found for this name");
        // Explain logic - Set the active priceFeed to the new address.
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    function sayHelloWithPrice() external view returns (string memory) {        
        // Explain Logic - how we're mapping the received price feed information to int256 price
        (
            /* uint80 roundID */, 
            int256 price,
            /* uint256 startedAt */, /* uint256 timeStamp */, /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        
        // Deriving price values that are actually readable
        uint256 readablePrice = uint256(price) / uint256((10**priceFeed.decimals()));
        return string.concat(
            "Hello! ", 
            blockchainName, 
            "'s Price is: $", 
            readablePrice.toString(),
            "!"
        );
    }
    }
