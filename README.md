
# Hello Blockchain: From Basic Contract to Chainlink Price Feeds

This guide provides a step-by-step tutorial for deploying a simple Solidity smart contract and then upgrading it to fetch real-world asset prices using Chainlink Data Feeds on the Avalanche Fuji testnet.

## 📋 Prerequisites

1.  **MetaMask Wallet:** A browser extension wallet like MetaMask.
2.  **Fuji Testnet AVAX:** You'll need some testnet AVAX for gas fees. You can get this from the official [Chainlink Faucet](https://faucets.chain.link/fuji).

-----

## Part 1: The Basic Contract (`HelloBlockchain.sol`)

First, we'll deploy a simple contract that can store a name and greet it.

### Step 1.1: The Code 📜

This contract has one variable (`blockchainName`) and two functions: one to set the name and one to say hello.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HelloBlockchain
 * @notice A basic contract to store a blockchain name and greet it.
 */
contract HelloBlockchain {
    // A public string variable to store the name of the blockchain.
    string public blockchainName;

    /**
     * @notice Sets or updates the name of the blockchain.
     * @param _blockchainName The new name to set (e.g., "Avalanche").
     */
    function setBlockchain(string calldata _blockchainName) external {
        blockchainName = _blockchainName;
    }

    /**
     * @notice Returns a greeting message.
     * @return A string that says "Hello {blockchainName}".
     */
    function sayHello() external view returns (string memory) {
        // Concatenates the "Hello " prefix with the stored blockchainName.
        return string.concat("Hello ", blockchainName);
    }
}
```

### Step 1.2: Deployment with Remix IDE 🚀

1.  Navigate to the [Remix IDE](https://remix.ethereum.org/).
2.  Create a new file in the `contracts` folder named `HelloBlockchain.sol`.
3.  Paste the code above into the file.
4.  Go to the **"Solidity Compiler"** tab (second icon on the left) and click **"Compile HelloBlockchain.sol"**.
5.  Go to the **"Deploy & Run Transactions"** tab (third icon).
      * Under **"Environment"**, select **"Injected Provider - MetaMask"**. Your MetaMask wallet will prompt you to connect.
      * Ensure you are on the **Avalanche Fuji Testnet**.
6.  Click the orange **"Deploy"** button and confirm the transaction in MetaMask.

### Step 1.3: Interaction

Once deployed, a new contract interface will appear at the bottom of the "Deploy & Run" panel.

1.  Enter `"Avalanche"` into the `_blockchainName` field next to the `setBlockchain` button and click it. Confirm the transaction.
2.  Click the blue `sayHello` button. It will instantly return `"Hello Avalanche"` below the button.

-----

## Part 2: Upgrading to `HelloBlockchainPrice.sol`

Now, let's create a new, more powerful contract that uses the name to fetch the asset's price from Chainlink.

### Step 2.1: The Concept ⛓️

We will deploy a new contract that uses a `mapping` to store the addresses of Chainlink Price Feed contracts. When you set a name like "Avalanche", it will look up the address for the **AVAX/USD** feed and use the `AggregatorV3Interface` to read the latest price.

### Step 2.2: The Code 📜

This version is more advanced. It imports libraries from OpenZeppelin and Chainlink, handles number-to-string conversion, and correctly calculates the readable price.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This is an "interface". Think of it as a blueprint or a set of rules that
// defines how to interact with Chainlink Price Feed contracts. It tells our
// contract what functions are available, like `latestRoundData()`.
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// This is a "library". It gives us extra tools that Solidity doesn't have
// by default. The `Strings` library provides a tool (`toString`) to convert
// numbers into text (a string), which is needed for string concatenation.
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title HelloBlockchainWithPrice
 * @notice A contract that uses a name to fetch its corresponding asset price.
 */
contract HelloBlockchainWithPrice {
    // This line "attaches" the tools from the `Strings` library to the `uint256`
    // number type. This lets us call functions like `myNumber.toString()`.
    using Strings for uint256;

    // A variable to store the currently active price feed contract we want to talk to.
    AggregatorV3Interface internal priceFeed;
    
    // A variable to store the name the user sets. 'public' automatically creates
    // a "getter" function so anyone can read its value from outside the contract.
    string public blockchainName;

    // This is a "mapping". Think of it like a dictionary or a phonebook.
    // It lets us look up a price feed's on-chain address (the value)
    // using a simple text name like "Avalanche" (the key).
    mapping(string => address) public priceFeedRegistry;

    /**
     * @notice The constructor is a special function that runs only ONCE,
     * when the contract is first deployed.
     */
    constructor() {
        // Here, we pre-fill our 'phonebook' with the known addresses for the
        // AVAX/USD and LINK/USD price feeds on the Avalanche Fuji testnet.
        priceFeedRegistry["Avalanche"] = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD;
        priceFeedRegistry["Chainlink"] = 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470;
    }

    /**
     * @notice Sets the blockchain name and the active price feed for this contract.
     * @param _blockchainName The name of the feed to activate (e.g., "Avalanche").
     *
     * @dev external vs public:
     * `external`: Can ONLY be called from outside this contract. It's more gas-efficient.
     * `public`: Can be called from outside OR by other functions inside this contract.
     * We use `external` here because we don't need to call it internally, saving gas.
     *
     * @dev calldata vs memory:
     * `calldata`: A special, read-only data location for function arguments. It's the
     * cheapest place to store input, so we use it to save gas.
     * `memory`: A temporary place to store data that can be changed. More expensive.
     * We use `calldata` for `_blockchainName` because we only need to read it.
     */
    function setBlockchainName(string calldata _blockchainName) external {
        // First, we save the provided name into our `blockchainName` state variable.
        blockchainName = _blockchainName;
        
        // Next, we use the name as a key to look up its address in our registry mapping.
        address feedAddress = priceFeedRegistry[blockchainName];

        // This is a safety check. If the name wasn't in our registry, the address
        // would be empty (0x0...). This `require` statement stops the function
        // if a valid address wasn't found, returning an error message.
        require(feedAddress != address(0), "Price feed not found for this name");
        
        // Finally, we tell our `priceFeed` variable to point to the contract
        // at the address we just found, making it the 'active' feed.
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    /**
     * @notice Returns a greeting with the latest price from the active feed.
     * @dev `view` means this function only reads data from the blockchain; it
     * does not change any state. This allows it to be called for free from off-chain.
     * `returns (string memory)` means it promises to give back a string.
     */
    function sayHelloWithPrice() external view returns (string memory) {        
        // This is the main call to the Chainlink oracle contract.
        // `latestRoundData()` returns several values about the latest price update.
        // We only care about the second value, which is the price.
        (
            /* uint80 roundID */, 
            int256 price, // We declare a variable `price` to store the second return value.
            /* uint256 startedAt */,
            /* uint256 timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData(); // The other returns are ignored with blank commas.
        
        // Chainlink prices are returned as large integers with no decimal point.
        // For example, a price of $35.12 is returned as 3512000000.
        // The `decimals()` function tells us how many decimal places there are (usually 8).
        // To get a human-readable number, we divide by 10 to the power of `decimals`.
        uint256 readablePrice = uint256(price) / (10**priceFeed.decimals());

        // Here, we build the final output string. We use the `.toString()` function
        // (which we attached from the `Strings` library) to convert our `readablePrice`
        // number into text first, because Solidity cannot directly combine text and numbers.
        return string.concat(
            "Hello! ", 
            blockchainName, 
            "'s Price is: $", 
            readablePrice.toString(),
            "!"
        );
    }
}
```

### Step 2.3: Deployment with Remix IDE

1.  Create a new file in Remix named `HelloBlockchainPrice.sol` and paste the code above.
2.  The `import` statements for OpenZeppelin and Chainlink will be **automatically handled** by Remix.
3.  Compile and deploy this new contract, just as you did in Step 1.2.

### Step 2.4: Interaction

1.  First, call `setBlockchainName` with the input `"Avalanche"`. Confirm the transaction. This tells the contract which price feed to use.
2.  Now, click the `sayHelloWithPrice` button. It will read the latest price from the AVAX/USD feed and return a message like: `"Hello Avalanche's Price is: $35"`.
3.  Try it again\! Call `setBlockchainName` with `"Chainlink"` and confirm. Then click `sayHelloWithPrice`. It will now return a message like: `"Hello Chainlink's Price is: $18"`.
