// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    //events
    event EnteredRaffle(address indexed player);

    // enums 
    Raffle raffle;
    HelperConfig helperConfig;
    
    // variables used to the vrfCoordinator
    uint256 entranceFee; 
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    // variables for the mock player and the default starting wallet
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether; 

    // assigns a new deployed raffle to the deployer variable. then it runs this deployer
    // the deployer returns the raffle contract, and the helperConfig 
    // we run the activeNetworkConfig function, to get the data for the variables needed to run the vrfCoordinator
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee, 
            interval, 
            vrfCoordinator, 
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
         ) = helperConfig.activeNetworkConfig();
    }

    // modifier to ensure the test address is funded.
    modifier funded() {
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        _; 
    }

    // the raffle starts in an OPEN state and not a CLOSED state (no one can enter)
    function testRaffleInitializesInOpenState() public view {
        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
    }

    // self explanatory
    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);

        raffle.enterRaffle();
    }

    // self explanatory
    function testRaffleRecordsPlayerWhenTheyEnter() public funded {
        vm.prank(PLAYER);
    
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    // self explanatory
    function testEmitsEventOnEntrance() public funded {
        vm.prank(PLAYER);
    
       vm.expectEmit(true,false, false, false, address(raffle));
       emit EnteredRaffle(PLAYER);

       raffle.enterRaffle{value: entranceFee}();
    }

     // player enters raffle
     // raffle enters calculating state
     // next player should get an error (cannot join while calculating)
    function testCantEnterWhenRaffleIsCalculating() public funded {
        vm.prank(PLAYER);
    
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();  
    }
}