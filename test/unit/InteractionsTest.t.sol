// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../script/HelperConfig.s.sol";
import "../../script/Interactions.s.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol"; 
import "../mocks/LinkToken.sol";

contract ContractTest is Test {
    HelperConfig helperConfig;
    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;

    function setUp() public {
        // Initialize the HelperConfig contract
        createSubscription = new CreateSubscription(deployerKey);
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
    }

  function testAddConsumerForSepolia() public {
        // Simulate Sepolia chain ID
        vm.chainId(11155111);

        // Initialize the HelperConfig contract for Sepolia
        helperConfig = new HelperConfig();
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

        // Deploy or get the necessary contracts
        VRFCoordinatorV2Mock vrfCoordinatorMock = VRFCoordinatorV2Mock(vrfCoordinator);
        LinkToken linkToken = LinkToken(link);
        address raffle = address(this); // Simulating the raffle contract address
        uint64 subId = subscriptionId;

        // If subscriptionId is not set, create a new subscription
        if (subId == 0) {
            subId = vrfCoordinatorMock.createSubscription();
        }

        // Call the addConsumer function
        addConsumer.addConsumer(raffle, address(vrfCoordinatorMock), subId, deployerKey);

        // Verify that the consumer was added
        address[] memory consumers = vrfCoordinatorMock.getConsumers(subId);
        bool consumerAdded = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == raffle) {
                consumerAdded = true;
                break;
            }
        }

        assertTrue(consumerAdded, "Consumer was not added to the subscription");
    }

    function testAddConsumerForAnvil() public {
        // Simulate Anvil chain ID
        vm.chainId(31337);

        // Initialize the HelperConfig contract for Anvil
        helperConfig = new HelperConfig();

        // Get the active network config for Anvil
        helperConfig = new HelperConfig();
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


        // Deploy or get the necessary contracts
        VRFCoordinatorV2Mock vrfCoordinatorMock = VRFCoordinatorV2Mock(vrfCoordinator);
        LinkToken linkToken = LinkToken(link);
        address raffle = address(this); // Simulating the raffle contract address

        // If subscriptionId is not set, create a new subscription
        if (subscriptionId == 0) {
            subscriptionId = vrfCoordinatorMock.createSubscription(deployerKey);
        }

        // Call the addConsumer function
        addConsumer.addConsumer(raffle, address(vrfCoordinatorMock), subscriptionId, deployerKey);

        // Verify that the consumer was added
        address[] memory consumers = vrfCoordinatorMock.getConsumers(uint64(subscriptionId));
        bool consumerAdded = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == raffle) {
                consumerAdded = true;
                break;
            }
        }

        assertTrue(consumerAdded, "Consumer was not added to the subscription");
    }   
}
