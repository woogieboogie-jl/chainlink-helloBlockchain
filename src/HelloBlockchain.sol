// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HelloBlockchain {
    string public blockchainName;

    function setBlockchainName(string calldata _blockchainName) public {
        blockchainName = _blockchainName;
    }

    function sayHello() public view returns (string memory) {
        return string.concat("Hello! ", blockchainName, "!");
    }
}
