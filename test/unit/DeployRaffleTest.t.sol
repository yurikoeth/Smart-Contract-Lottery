// SPDX-License-Identifier: MIT

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {Test} from "forge-std/Test.sol";

pragma solidity ^0.8.18;

contract DeployRaffleTest is Test {
    DeployRaffle deployRaffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;

    event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);

    function setUp() public {
        deployRaffle = new DeployRaffle();
        (Raffle raffle, HelperConfig config) = deployRaffle.run();
        helperConfig = config;
        (
            entranceFee,
            interval,
            vrfCoordinator,
            ,
            subscriptionId,
            callbackGasLimit,
            link,
            deployerKey
        ) = helperConfig.activeNetworkConfig();
    }

    function testDeployRaffle() public {
        (Raffle raffle, HelperConfig config) = deployRaffle.run();
        assert(address(raffle) != address(0));
        assert(address(config) != address(0));
    }

    function testCreateSubscription() public {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 newSubscriptionId = createSubscription.createSubscription(
            vrfCoordinator,
            deployerKey
        );

        assertTrue(newSubscriptionId != 0, "Subscription ID should not be zero.");
    }

    function testFundSubscriptionSuccess() public {
        // Create a new subscription
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 newSubscriptionId = createSubscription.createSubscription(
            vrfCoordinator,
            deployerKey
        );

        // Assume deployerKey has sufficient LINK balance
        // Simulate dealing LINK to the contract
        deal(link, address(this), 3 ether);

        uint256 oldBalance = 0; // Example value, replace with actual logic
        uint256 newBalance = 3 ether; // Example value, replace with actual logic

        FundSubscription fundSubscription = new FundSubscription();
        vm.expectEmit(true, true, true, true);
        emit SubscriptionFunded(newSubscriptionId, oldBalance, newBalance);

        // Fund the subscription
        fundSubscription.fundSubscription(
            vrfCoordinator,
            newSubscriptionId,
            link,
            deployerKey
        );
    }
}
