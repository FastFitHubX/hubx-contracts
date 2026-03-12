# hubx-contracts

Smart contracts for the HUBX protocol, the decentralized backbone of the FastFitHub ecosystem.

## Overview

The `hubx-contracts` repository contains the core smart contracts that power the HUBX protocol. These contracts handle tokenomics, staking, governance, and the distribution of rewards earned through the Proof-of-Workout (PoWk) protocol.

## Repository Structure

- **`hubx-token/`**: Contains the `HubXToken.sol` contract, implementing the HUBX utility token with minting and burning capabilities.
- **`staking/`**: Contains the `StakingContract.sol` contract, allowing users to stake HUBX tokens to earn rewards and participate in governance.
- **`governance/`**: Contains the `Governance.sol` contract, enabling decentralized decision-making through proposals and voting.
- **`reward-distribution/`**: Contains the `RewardDistributor.sol` contract, which manages the distribution of rewards to users based on their verified physical activities.

## Interaction with Proof-of-Workout

The smart contracts in this repository are designed to work in tandem with the Proof-of-Workout (PoWk) protocol. Once a workout is verified and an activity score is calculated by the `hubx-proof-of-workout` backend, the `RewardDistributor` contract is triggered to allocate HUBX tokens to the user's address.

1.  **Verification**: A workout is verified via the PoWk protocol.
2.  **Scoring**: An activity score is generated based on duration and intensity.
3.  **Distribution**: The `RewardDistributor` contract records the pending rewards for the user.
4.  **Claiming**: Users can claim their earned HUBX tokens directly through the smart contract.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
