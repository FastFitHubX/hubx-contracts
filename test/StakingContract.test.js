const { expect } = require('chai');
const sinon = require('sinon');

/**
 * Mocking the HubXToken and StakingContract behavior for testing.
 * Since we are in a sandbox without a full Hardhat/Truffle environment,
 * we will simulate the contract logic in JavaScript to verify the algorithm and state transitions.
 */

class MockHubXToken {
    constructor() {
        this.balances = {};
        this.allowances = {};
    }

    mint(to, amount) {
        this.balances[to] = (this.balances[to] || 0) + amount;
    }

    balanceOf(account) {
        return this.balances[account] || 0;
    }

    transfer(to, amount) {
        if (this.balances['contract'] < amount) return false;
        this.balances['contract'] -= amount;
        this.balances[to] = (this.balances[to] || 0) + amount;
        return true;
    }

    transferFrom(from, to, amount) {
        if (this.balances[from] < amount) return false;
        this.balances[from] -= amount;
        this.balances[to] = (this.balances[to] || 0) + amount;
        return true;
    }
}

class StakingContractJS {
    constructor(token) {
        this.hubxToken = token;
        this.REWARD_RATE = 100;
        this.SECONDS_IN_DAY = 86400;
        this.userStakes = {};
        this.totalStaked = 0;
        this.currentTime = Math.floor(Date.now() / 1000);
    }

    _updateRewards(user) {
        if (!this.userStakes[user]) {
            this.userStakes[user] = { amount: 0, lastUpdateTimestamp: this.currentTime, pendingRewards: 0 };
            return;
        }
        const stakeInfo = this.userStakes[user];
        if (stakeInfo.amount > 0) {
            const duration = this.currentTime - stakeInfo.lastUpdateTimestamp;
            const reward = Math.floor((stakeInfo.amount * this.REWARD_RATE * duration) / this.SECONDS_IN_DAY);
            stakeInfo.pendingRewards += reward;
        }
        stakeInfo.lastUpdateTimestamp = this.currentTime;
    }

    stake(user, amount) {
        if (amount <= 0) throw new Error("Cannot stake 0");
        this._updateRewards(user);
        if (this.hubxToken.transferFrom(user, 'contract', amount)) {
            this.userStakes[user].amount += amount;
            this.totalStaked += amount;
            return true;
        }
        return false;
    }

    calculateReward(user) {
        const stakeInfo = this.userStakes[user] || { amount: 0, lastUpdateTimestamp: this.currentTime, pendingRewards: 0 };
        let reward = stakeInfo.pendingRewards;
        if (stakeInfo.amount > 0) {
            const duration = this.currentTime - stakeInfo.lastUpdateTimestamp;
            reward += Math.floor((stakeInfo.amount * this.REWARD_RATE * duration) / this.SECONDS_IN_DAY);
        }
        return reward;
    }

    claimRewards(user) {
        this._updateRewards(user);
        const reward = this.userStakes[user].pendingRewards;
        if (reward <= 0) throw new Error("No rewards to claim");
        this.userStakes[user].pendingRewards = 0;
        return this.hubxToken.transfer(user, reward);
    }

    withdraw(user, amount) {
        const stakeInfo = this.userStakes[user];
        if (!stakeInfo || stakeInfo.amount < amount) throw new Error("Insufficient staked balance");
        this._updateRewards(user);
        stakeInfo.amount -= amount;
        this.totalStaked -= amount;
        return this.hubxToken.transfer(user, amount);
    }

    setBlockTimestamp(timestamp) {
        this.currentTime = timestamp;
    }
}

describe('StakingContract Logic Verification', () => {
    let token;
    let staking;
    const user = 'user1';

    beforeEach(() => {
        token = new MockHubXToken();
        staking = new StakingContractJS(token);
        token.mint(user, 10000);
    });

    it('should allow staking tokens', () => {
        staking.stake(user, 1000);
        expect(staking.userStakes[user].amount).to.equal(1000);
        expect(token.balanceOf(user)).to.equal(9000);
        expect(token.balanceOf('contract')).to.equal(1000);
    });

    it('should accrue rewards over time', () => {
        staking.stake(user, 1000);
        // Advance time by 1 day (86400 seconds)
        staking.setBlockTimestamp(staking.currentTime + 86400);
        
        const reward = staking.calculateReward(user);
        // reward = 1000 * 100 * 86400 / 86400 = 100000
        expect(reward).to.equal(100000);
    });

    it('should allow claiming rewards', () => {
        staking.stake(user, 1000);
        staking.setBlockTimestamp(staking.currentTime + 86400);
        
        // Mint some tokens to the contract for rewards
        token.mint('contract', 200000);
        
        staking.claimRewards(user);
        expect(token.balanceOf(user)).to.equal(9000 + 100000);
        expect(staking.userStakes[user].pendingRewards).to.equal(0);
    });

    it('should allow partial withdrawal', () => {
        staking.stake(user, 1000);
        staking.withdraw(user, 400);
        
        expect(staking.userStakes[user].amount).to.equal(600);
        expect(token.balanceOf(user)).to.equal(9400);
    });

    it('should allow full withdrawal', () => {
        staking.stake(user, 1000);
        staking.withdraw(user, 1000);
        
        expect(staking.userStakes[user].amount).to.equal(0);
        expect(token.balanceOf(user)).to.equal(10000);
    });

    it('should maintain reward accounting after withdrawal', () => {
        staking.stake(user, 1000);
        staking.setBlockTimestamp(staking.currentTime + 43200); // 0.5 day
        
        staking.withdraw(user, 500);
        // Rewards accrued for 0.5 day: 1000 * 100 * 0.5 = 50000
        expect(staking.userStakes[user].pendingRewards).to.equal(50000);
        
        staking.setBlockTimestamp(staking.currentTime + 43200); // another 0.5 day
        // Rewards accrued for another 0.5 day on 500: 500 * 100 * 0.5 = 25000
        // Total: 50000 + 25000 = 75000
        expect(staking.calculateReward(user)).to.equal(75000);
    });
});
