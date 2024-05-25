// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    
    uint256 entranceFee; 
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether; 

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee, 
            interval, 
            vrfCoordinator, 
            gasLane,
            subscriptionId,
            callbackGasLimit
         ) = helperConfig.activeNetworkConfig();
    }

      modifier funded() {
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        _; // Continue execution of the function if the requirement is met
    }

    function testRaffleInitializesInOpenState() public view {
        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);

        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public funded {
        vm.prank(PLAYER);
    
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }
}