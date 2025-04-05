// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionNFT.sol";

contract SubscriptionFactory {
    address[] public subscriptionContracts;

    mapping(string => address) public nameToContract;
    mapping(address => string) public contractToName;

    event SubscriptionCreated(address indexed provider, address contractAddress, string name);

    function createSubscription(
        string memory name,
        string memory symbol,
        uint256 duration,
        uint256 price,
        address[] memory paymentTokens
    ) external {
        require(nameToContract[name] == address(0), "Name already used");

        SubscriptionNFT newSubscription = new SubscriptionNFT(
            name,
            symbol,
            msg.sender,
            duration,
            price,
            paymentTokens
        );

        address contractAddress = address(newSubscription);

        subscriptionContracts.push(contractAddress);
        nameToContract[name] = contractAddress;
        contractToName[contractAddress] = name;

        emit SubscriptionCreated(msg.sender, contractAddress, name);
    }

    function getAllSubscriptions() external view returns (address[] memory) {
        return subscriptionContracts;
    }

    function getSubscriptionCount() external view returns (uint256) {
        return subscriptionContracts.length;
    }

    function getContractByName(string memory name) external view returns (address) {
        return nameToContract[name];
    }

    function getNameByContract(address contractAddress) external view returns (string memory) {
        return contractToName[contractAddress];
    }
}