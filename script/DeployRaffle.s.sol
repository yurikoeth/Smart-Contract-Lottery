// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

pragma solidity ^0.8.18;

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee, 
            uint256 interval, 
            address vrfCoordinator, 
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            subscriptionId = createAndFundSubscription(vrfCoordinator, link, deployerKey);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        addRaffleConsumer(address(raffle), vrfCoordinator, subscriptionId, deployerKey);
        return (raffle, helperConfig);   
    }

    function createAndFundSubscription(
        address vrfCoordinator,
        address link,
        uint256 deployerKey
    ) internal returns (uint64) {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 subscriptionId = createSubscription.createSubscription(
            vrfCoordinator,
            deployerKey
        );

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            vrfCoordinator, 
            subscriptionId, 
            link,
            deployerKey
        );

        return subscriptionId;
    }

    function addRaffleConsumer(
        address raffleAddress,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint256 deployerKey
    ) internal {
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            raffleAddress, 
            vrfCoordinator, 
            subscriptionId,
            deployerKey
        );
    }
}
