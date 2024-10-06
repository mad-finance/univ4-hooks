// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

import {IERC721} from "./interfaces/IERC721.sol";

/**
 * @title DefaultSettings
 * @author @c0rv0s
 * @notice This hook is applied to all liquidity pools that are created from the Bonsai trading app. Effects include:
 * 1. calculating a swap fee based on how many bonsai NFTs you hold
 */
contract DefaultSettings is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    IERC721 immutable bonsaiNFT;

    constructor(IPoolManager _poolManager, address _bonsaiNFT) BaseHook(_poolManager) {
        bonsaiNFT = IERC721(_bonsaiNFT);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Get the balance of Bonsai NFTs in the user's wallet
        uint256 nftBalance = bonsaiNFT.balanceOf(sender);

        // Calculate the protocol fee percentage
        uint24 protocolFeePercentage;
        if (nftBalance == 0) {
            protocolFeePercentage = 18000; // 1.8% (in hundredths of a bip)
        } else if (nftBalance == 1) {
            protocolFeePercentage = 12000; // 1.2% (in hundredths of a bip)
        } else if (nftBalance == 2) {
            protocolFeePercentage = 6000; // 0.6% (in hundredths of a bip)
        } else {
            protocolFeePercentage = 2500; // 0.25% (in hundredths of a bip)
        }

        // The protocol fee will be applied as part of the LP fees in the PoolManager
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, protocolFeePercentage);
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4, int128)
    {
        return (BaseHook.afterSwap.selector, 0);
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        return BaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        return BaseHook.beforeRemoveLiquidity.selector;
    }
}
