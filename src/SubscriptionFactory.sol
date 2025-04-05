// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionNFT.sol";

contract SubscriptionFactory {
    address[] public subscriptionContracts;

    event SubscriptionCreated(address indexed provider, address contractAddress);

    function createSubscription(
        string memory name,
        string memory symbol,
        uint256 duration,
        uint256 price,
        address[] memory paymentTokens
    ) external {
        SubscriptionNFT newSubscription = new SubscriptionNFT(
            name,
            symbol,
            msg.sender,
            duration,
            price,
            paymentTokens
        );
        subscriptionContracts.push(address(newSubscription));
        emit SubscriptionCreated(msg.sender, address(newSubscription));
    }

    function getAllSubscriptions() external view returns (address[] memory) {
        return subscriptionContracts;
    }
}