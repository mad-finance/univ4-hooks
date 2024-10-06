// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DefaultSettings} from "../src/DefaultSettings.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Fixtures} from "./utils/Fixtures.sol";

contract DefaultSettingsTest is Test, Fixtures {
    DefaultSettings public defaultSettings;
    MockERC721 public bonsaiNFT;
    address public constant USER = address(0x2);

    function setUp() public {
        // Deploy the pool manager and other necessary contracts
        deployFreshManagerAndRouters();

        // Deploy the Bonsai NFT
        bonsaiNFT = new MockERC721("Bonsai NFT", "BNFT");

        // Deploy the hook to an address with the correct flags
        address hookAddress = address(uint160(Hooks.BEFORE_SWAP_FLAG | (0x4444 << 144)));
        bytes memory constructorArgs = abi.encode(address(manager), address(bonsaiNFT));
        deployCodeTo("DefaultSettings.sol:DefaultSettings", constructorArgs, hookAddress);
        defaultSettings = DefaultSettings(hookAddress);
    }

    function testBeforeSwap_NoNFTs() public {
        PoolKey memory key;
        IPoolManager.SwapParams memory params;

        (bytes4 selector, BeforeSwapDelta delta, uint24 fee) = defaultSettings.beforeSwap(USER, key, params, "");

        assertEq(selector, DefaultSettings.beforeSwap.selector);
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), 0);
        assertEq(BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta), 0);
        assertEq(fee, 18000); // 1.8%
    }

    function testBeforeSwap_OneNFT() public {
        bonsaiNFT.mint(USER, 1);

        PoolKey memory key;
        IPoolManager.SwapParams memory params;

        (bytes4 selector, BeforeSwapDelta delta, uint24 fee) = defaultSettings.beforeSwap(USER, key, params, "");

        assertEq(selector, DefaultSettings.beforeSwap.selector);
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), 0);
        assertEq(BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta), 0);
        assertEq(fee, 12000); // 1.2%
    }

    function testBeforeSwap_TwoNFTs() public {
        bonsaiNFT.mint(USER, 1);
        bonsaiNFT.mint(USER, 2);

        PoolKey memory key;
        IPoolManager.SwapParams memory params;

        (bytes4 selector, BeforeSwapDelta delta, uint24 fee) = defaultSettings.beforeSwap(USER, key, params, "");

        assertEq(selector, DefaultSettings.beforeSwap.selector);
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), 0);
        assertEq(BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta), 0);
        assertEq(fee, 6000); // 0.6%
    }

    function testBeforeSwap_ThreeOrMoreNFTs() public {
        bonsaiNFT.mint(USER, 1);
        bonsaiNFT.mint(USER, 2);
        bonsaiNFT.mint(USER, 3);

        PoolKey memory key;
        IPoolManager.SwapParams memory params;

        (bytes4 selector, BeforeSwapDelta delta, uint24 fee) = defaultSettings.beforeSwap(USER, key, params, "");

        assertEq(selector, DefaultSettings.beforeSwap.selector);
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), 0);
        assertEq(BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta), 0);
        assertEq(fee, 2500); // 0.25%
    }
}
