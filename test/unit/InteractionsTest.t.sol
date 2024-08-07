// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import necessary contracts and libraries
import {Test, Vm} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../mocks/LinkToken.sol";

// Mock contract that always reverts, used for error handling tests
contract MockAlwaysRevert {
    error MockAlwaysRevertError();
    function createSubscription() external pure {
        revert MockAlwaysRevertError();
    }
}

// Main test contract
contract InteractionsTest is Test {
    // Declare public variables for the contracts we'll be testing
    CreateSubscription public createSubscription;
    FundSubscription public fundSubscription;
    AddConsumer public addConsumer;
    HelperConfig public helperConfig;
    VRFCoordinatorV2Mock public vrfCoordinatorMock;
    LinkToken public linkToken;

    // Variables to store configuration values
    address vrfCoordinator;
    uint64 subId;
    address link;
    uint256 deployerKey;

    // Events that we expect to be emitted
    event SubscriptionCreated(uint256 chainId, uint64 subId);
    event UpdateHelperConfig();

    // Setup function that runs before each test
    function setUp() public {
        // Create new instances of the contracts
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
        helperConfig = new HelperConfig();
        
        // Get the active network configuration
        (,, vrfCoordinator,, subId,, link, deployerKey) = helperConfig.activeNetworkConfig();

        // Cast addresses to their respective contract types
        vrfCoordinatorMock = VRFCoordinatorV2Mock(vrfCoordinator);
        linkToken = LinkToken(link);
    }

    // Test the CreateSubscription function
    function testCreateSubscription() public {
        uint64 expectedSubId = 1; // Expected subscription ID
        
        // Expect a call to the createSubscription function on the mock
        vm.expectCall(
            address(vrfCoordinatorMock),
            abi.encodeWithSelector(VRFCoordinatorV2Mock.createSubscription.selector)
        );

        // Call the createSubscription function and get the returned subId
        uint64 returnedSubId = createSubscription.createSubscription(address(vrfCoordinatorMock), deployerKey);

        // Assert that the returned subId matches the expected subId
        assertEq(returnedSubId, expectedSubId, "Returned subId should match the expected subId");

        // Get the subscription details and check the owner
        (,, address owner,) = vrfCoordinatorMock.getSubscription(expectedSubId);
        address expectedOwner = vm.addr(deployerKey);
        assertEq(owner, expectedOwner, "Subscription owner should be the address derived from deployerKey");
    }

    // Test the logging of CreateSubscription
    function testCreateSubscriptionLogging() public {
        uint256 expectedChainId = block.chainid;
        uint64 expectedSubId = 1;

        // Expect specific events to be emitted
        vm.expectEmit(true, true, false, true);
        emit SubscriptionCreated(expectedChainId, 0);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionCreated(expectedChainId, expectedSubId);
        vm.expectEmit(true, true, false, true);
        emit UpdateHelperConfig();

        // Call createSubscription
        uint64 returnedSubId = createSubscription.createSubscription(address(vrfCoordinatorMock), deployerKey);

        // Assert that the returned subId matches the expected subId
        assertEq(returnedSubId, expectedSubId, "Returned subId should match the expected subId");
    }   

    // Test error handling in CreateSubscription
   function testCreateSubscriptionErrorHandling() public {
    // Test with invalid (zero) address
    vm.expectRevert();
    createSubscription.createSubscription(address(0), deployerKey);

    // Test with a contract that always reverts
    MockAlwaysRevert mockAlwaysRevert = new MockAlwaysRevert();
    vm.expectRevert();
    createSubscription.createSubscription(address(mockAlwaysRevert), deployerKey);
}
    // Test the FundSubscription function
    function testFundSubscription() public {
    // Ensure we're on a local chain
    assertEq(block.chainid, 31337, "This test must be run on a local chain");

    // Create a subscription and get its initial balance
    subId = createSubscription.createSubscription(vrfCoordinator, deployerKey);
    
    // Get the initial balance
    (uint96 initialBalance,,,) = vrfCoordinatorMock.getSubscription(subId);
    
    // Call fundSubscription
    fundSubscription.fundSubscription(vrfCoordinator, subId, address(linkToken), deployerKey);

    // Check the new balance
    (uint96 finalBalance,,,) = vrfCoordinatorMock.getSubscription(subId);
    
    // Assert that the balance has increased by the expected amount (3 ether)
    assertEq(finalBalance, initialBalance + 3 ether, "Subscription balance did not increase as expected");
}

    // Test FundSubscription with an invalid VRF coordinator
    function testFundSubscriptionWithInvalidVrfCoordinator() public {
        vm.expectRevert();
        fundSubscription.fundSubscription(address(0), 1, address(linkToken), vm.envUint("PRIVATE_KEY"));
    }

    // Test FundSubscription with an invalid subscription ID
    function testFundSubscriptionWithInvalidSubId() public {
        (,, address validVrfCoordinator,,,,address validLink, uint256 validDeployerKey) = helperConfig.activeNetworkConfig();

        vm.expectRevert(abi.encodeWithSignature("InvalidSubscription()"));
        fundSubscription.fundSubscription(validVrfCoordinator, 999, validLink, validDeployerKey);
    }

    // Test FundSubscription with insufficient LINK balance
    function testFundSubscriptionWithInsufficientLinkBalance() public {
        (,, address validVrfCoordinator,, uint64 validSubId,, address validLink, uint256 validDeployerKey) = helperConfig.activeNetworkConfig();

        // Set the LINK balance to 0
        deal(validLink, address(this), 0);

        vm.expectRevert();
        fundSubscription.fundSubscription(validVrfCoordinator, validSubId, validLink, validDeployerKey);
    }

    function testFundAmountConstant() public {
        // Verify FUND_AMOUNT is set correctly to 3 ether
        assertEq(
            fundSubscription.FUND_AMOUNT(), 
            3 ether, 
            "FUND_AMOUNT should be 3 ether"
        );
    }
}