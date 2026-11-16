# database-chain-dbc                                                                                                                         # Database Chain ($DBC) — ZK Layer-2 Arbitrage & Real-Yield DeFi Protocol

**Database Chain ($DBC)** is an app-specific Layer-2 financial architecture engineered for high-frequency flash-loan arbitrage routing, zero-friction entry, and sustainable real-yield staking in USDC/ETH.

## Core Tokenomics & Fee Architecture
- **Fixed Supply Cap:** 500,000,000 $DBC (Zero inflation)
- **Founder Allocation:** 20% (100,000,000 $DBC) locked in an on-chain vesting contract (6-month cliff, 24-month linear release)
- **Flash Loan Fee:** **0.00%** via `FlashLoanRouter.sol` to maximize automated arbitrage routing
- **Buy-Leg Swap Fee:** **0.00%** on `SimpleDEX.sol` (USDC/ETH -> $DBC)
- **Sell-Leg Swap Fee:** **0.10%** deducted in USDC/ETH ($DBC -> USDC/ETH):
  - **90%** distributed automatically to `$DBC` stakers in `StakingVault.sol` (Real Yield)
  - **10%** routed to buyback-and-burn reserves

## Live Sepolia Testnet Deployments
- **DBC Genesis Token:** `0xYourDBCAddress`
- **SimpleDEX (AMM):** `0xYourSimpleDEXAddress`
- **FlashLoanRouter (0% Fee):** `0xYourFlashLoanRouterAddress`
- **StakingVault (USDC Yield):** `0xYourStakingVaultAddress`
- **FounderVesting (20% Lock):** `0xYourFounderVestingAddress`
