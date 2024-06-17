// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol"; 
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    //events
    event RequestedRaffleWinner(uint256 indexed requestId);
    event EnteredRaffle(address indexed winner);
    event WinnerPicked(address indexed player);

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
    uint256 deployerKey;

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
            ,
            subscriptionId,
            callbackGasLimit,
            link,
            deployerKey
         ) = helperConfig.activeNetworkConfig();
    }

    // modifier to ensure the test address is funded.
    modifier funded() {
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        _; 
    }

    modifier raffleEntered() {
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        vm.prank(PLAYER);
    
        raffle.enterRaffle{value: entranceFee}();
        _; 
    }

    modifier raffleEnteredAndTimeHasPassed() {
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        vm.prank(PLAYER);
    
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _; 
    }

    /////////////////////////
    // enterRaffle         //
    /////////////////////////

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
    function testRaffleRecordsPlayerWhenTheyEnter() public raffleEntered {
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
    function testCantEnterWhenRaffleIsCalculating() public raffleEnteredAndTimeHasPassed() {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();  
    }

    
    /////////////////////////
    // checkUpkeep         //
    /////////////////////////

    function testCheckUpkeepReturnsFalseIfhasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public raffleEnteredAndTimeHasPassed {
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public raffleEntered {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testUpkeepReturnsTrueIfParamsAreGood() public raffleEnteredAndTimeHasPassed {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }
    
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEnteredAndTimeHasPassed {
            raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0; 
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector, 
                currentBalance, 
                numPlayers, 
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeep() public raffleEnteredAndTimeHasPassed {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    /////////////////////////
    // fufillRandomWords   //
    /////////////////////////

    modifier skipFork() {
        if (block.chainid !=  33137){
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
        ) public raffleEnteredAndTimeHasPassed skipFork {
            vm.expectRevert("nonexistent request");
            VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
                randomRequestId, 
                address(raffle)
            );
        }

     function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() 
        public raffleEntered {
            uint256 additionalEntrants = 5;
            uint256 startingIndex = 1;
            for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++)
                {
                    address player = address(uint160(i)); // address(1)
                    hoax(player, STARTING_USER_BALANCE);
                    raffle.enterRaffle{value: entranceFee}();
                }

            uint256 prize = entranceFee * (additionalEntrants + 1);

            vm.warp(block.timestamp + interval + 1);

            vm.recordLogs();
            raffle.performUpkeep("");
            Vm.Log[] memory entries = vm.getRecordedLogs();
            bytes32 requestId = entries[1].topics[1];

            uint256 previousTimeStamp = raffle.getLastTimeStamp();

            VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
                uint256(requestId), 
                address(raffle)
            );
            //assert(uint256(raffle.getRaffleState()) == 0);
            //assert(raffle.getRecentWinner() != address(0));
            //assert(raffle.getLengthOfPlayers() == 0);
            //assert(previousTimeStamp < raffle.getLastTimeStamp());
            console.log(raffle.getRecentWinner().balance);
            console.log(prize + STARTING_USER_BALANCE);
            assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
        }
}