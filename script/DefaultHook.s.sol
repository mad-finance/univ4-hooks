// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Constants} from "./base/Constants.sol";
import {DefaultSettings} from "../src/utils/DefaultSettings.sol";
import {DefaultHook} from "../src/DefaultHook.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

/// @notice Mines the address and deploys the Counter.sol Hook contract
contract DefaultHookScript is Script, Constants {
    function setUp() public {}

    function run() public {
        IPoolManager BS_POOLMANAGER = IPoolManager(address(0xf242cE588b030d0895C51C0730F2368680f80644));

        // get the private key and address
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // deploy default settings contract (disable this if there is already a deployment)
        address bonsaiNFT = 0xE9d2FA815B95A9d087862a09079549F351DaB9bd; // base sepolia
        vm.broadcast(deployerPrivateKey);
        DefaultSettings defaultSettings = new DefaultSettings(bonsaiNFT);
        console2.log("defaultSettings address:", address(defaultSettings));

        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(BS_POOLMANAGER, address(defaultSettings));
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(DefaultHook).creationCode, constructorArgs);

        console2.log("mined hook address:", hookAddress);

        // Deploy the hook using CREATE2
        vm.broadcast(deployerPrivateKey);
        DefaultHook defaultHook = new DefaultHook{salt: salt}(IPoolManager(BS_POOLMANAGER), address(defaultSettings));
        console2.log("deployed hook address:", address(defaultHook));
        require(address(defaultHook) == hookAddress, "CounterScript: hook address mismatch");
    }
}
