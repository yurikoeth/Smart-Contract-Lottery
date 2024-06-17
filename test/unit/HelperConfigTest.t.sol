// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      State Variables                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    HelperConfig helperConfig;

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // calls the HelperConfig function and sets it to the variable 
    function setUp() public {
        helperConfig = new HelperConfig();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Constructor Tests                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testDefaultAnvilConfig() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getOrCreateAnvilConfig();
        assertEq(config.entranceFee, 0.01 ether);
        assertEq(config.interval, 30);
        assertTrue(config.vrfCoordinator != address(0)); // Ensures a mock coordinator is deployed
        assertEq(config.gasLane, 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae);
        assertEq(config.subscriptionId, 0);
        assertEq(config.callbackGasLimit, 50000);
        assertTrue(config.link != address(0)); // Ensures a mock LINK token is deployed
        assertEq(config.deployerKey, DEFAULT_ANVIL_KEY);
    }

    function testSepoliaEthConfig() public {
        vm.chainId(11155111); // Set the chain ID to Sepolia for testing
        HelperConfig.NetworkConfig memory config = helperConfig.getSepoliaEthConfig();

        assertEq(config.entranceFee, 0.01 ether);
        assertEq(config.interval, 30);
        assertEq(config.vrfCoordinator, 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B);
        assertEq(config.gasLane, 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae);
        assertEq(config.subscriptionId, 0);
        assertEq(config.callbackGasLimit, 50000);
        assertEq(config.link, 0x779877A7B0D9E8603169DdbD7836e478b4624789);
        // PRIVATE_KEY would be set in the environment
        // assertEq(config.deployerKey, vm.envUint("PRIVATE_KEY"));
    }
}
