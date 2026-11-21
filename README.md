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
- **DBC Genesis Token:** `0x40CA93d7e4783672f3d12c48e7260E09F3CDfd4d`
- **SimpleDEX (AMM):** `0x7b618CEa67D5c3030304fe6A7B9d891Ea61bd7d8`
- **FlashLoanRouter (0% Fee):** `0x148C334B3127F2D255c1d2007D78683708430D6b`
- **StakingVault (USDC Yield):** `0x835Cea47CD6041a5C446261A225669cD5099E5E3`
- **FounderVesting (20% Lock):** `0xf22D8b8d56C303D92CCCBC5a183c23bAA71adB3B`
