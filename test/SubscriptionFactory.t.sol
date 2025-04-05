// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SubscriptionFactory.sol";

contract SubscriptionFactoryTest is Test {
    SubscriptionFactory factory;

    address provider = address(0xABCD);
    address[] paymentTokens;

    function setUp() public {
        factory = new SubscriptionFactory();
    }

    function testCreateSubscriptionSuccess() public {
        vm.prank(provider);
        factory.createSubscription("Netflix", "NFX", 30 days, 1 ether, paymentTokens);

        address[] memory allSubs = factory.getAllSubscriptions();
        assertEq(allSubs.length, 1);

        string memory name = factory.getNameByContract(allSubs[0]);
        assertEq(name, "Netflix");

        address contractAddr = factory.getContractByName("Netflix");
        assertEq(contractAddr, allSubs[0]);
    }

    function testRevertOnDuplicateName() public {
        vm.prank(provider);
        factory.createSubscription("Spotify", "SPT", 30 days, 1 ether, paymentTokens);

        vm.expectRevert("Name already used");
        vm.prank(address(0xDEAD));
        factory.createSubscription("Spotify", "MUSIC", 30 days, 1 ether, paymentTokens);
    }

    event SubscriptionCreated(address indexed provider, address contractAddress);
}