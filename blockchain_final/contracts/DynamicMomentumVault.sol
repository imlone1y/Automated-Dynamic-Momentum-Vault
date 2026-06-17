// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DynamicMomentumVault {
    address public owner; // contract admin
    
    enum MarketState { BULL, BEAR, FLASH_CRASH }
    MarketState public currentMarketState; // state machine: control market state, withdraw, deposit function.
    
    uint256 public marketPrice;
    uint256 public constant CRASH_THRESHOLD = 500;
    uint256 public constant EARLY_WITHDRAW_PENALTY_TIME = 3 days; 
    uint256 public totalVaultShares;
    uint256 public accumulatedPenaltyPool; // (分紅池）：用來動態記錄和儲存所有「未滿 3 天提款者」被扣除的 5% 罰款總額。

    // 時光旅行時間偏移量（秒數）
    uint256 public timeOffset;

    struct UserInfo {
        uint256 shares;
        uint256 depositTimestamp; // record final deposit time
    }
    
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 penaltyPaid, uint256 bonusReceived);
    event MarketStateChanged(MarketState newState, uint256 newPrice);
    event CircuitBreakerActivated(uint256 timestamp);
    event TimeTraveled(uint256 totalOffset);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the vault owner");
        _;
    }

    modifier whenNotCrashed() {
        require(currentMarketState != MarketState.FLASH_CRASH, "Vault is frozen due to Flash Crash!");
        _;
    }

    constructor() {
        owner = msg.sender;
        marketPrice = 1000; 
        currentMarketState = MarketState.BULL;
    }

    function cheatForwardTime(uint256 _seconds) external onlyOwner {
        timeOffset += _seconds;
        emit TimeTraveled(timeOffset);
    }

    function getVirtualTimestamp() public view returns (uint256) {
        return block.timestamp + timeOffset;
    }

    function setMarketPrice(uint256 _newPrice) external onlyOwner { // set the market state BULL / BEAR / FLASH_CRASH
        marketPrice = _newPrice;
        
        if (_newPrice <= CRASH_THRESHOLD) {
            currentMarketState = MarketState.FLASH_CRASH;
            emit CircuitBreakerActivated(getVirtualTimestamp()); 
        } else if (_newPrice < 800) {
            currentMarketState = MarketState.BEAR;
        } else {
            currentMarketState = MarketState.BULL;
        }
        
        emit MarketStateChanged(currentMarketState, _newPrice);
    }

    function deposit() external payable whenNotCrashed { // 非崩盤時才能使用
        require(msg.value > 0, "Cannot deposit 0");
        
        uint256 shareMultiplier = 100;
        if (currentMarketState == MarketState.BEAR) {
            shareMultiplier = 80; 
        }
        
        uint256 sharesToMint = (msg.value * shareMultiplier) / 100;
        
        userInfo[msg.sender].shares += sharesToMint;
        userInfo[msg.sender].depositTimestamp = getVirtualTimestamp(); 
        totalVaultShares += sharesToMint;

        emit Deposit(msg.sender, msg.value, sharesToMint);
    }

    function withdraw(uint256 _sharesToWithdraw) external whenNotCrashed { // 非崩盤時才能使用
        UserInfo storage user = userInfo[msg.sender];
        require(_sharesToWithdraw > 0, "Cannot withdraw 0 shares");
        require(user.shares >= _sharesToWithdraw, "Not enough shares to withdraw");

        uint256 baseAmount = _sharesToWithdraw; 
        uint256 penalty = 0;
        uint256 bonus = 0;

        if (getVirtualTimestamp() - user.depositTimestamp < EARLY_WITHDRAW_PENALTY_TIME) {
            penalty = (baseAmount * 5) / 100; 
            accumulatedPenaltyPool += penalty;
        } else {
            if (accumulatedPenaltyPool > 0 && totalVaultShares > 0) {
                // 分紅會根據你「這次提領的份額」按比例計算，非常公平
                bonus = (accumulatedPenaltyPool * _sharesToWithdraw) / totalVaultShares;
                accumulatedPenaltyPool -= bonus;
            }
        }

        uint256 finalWithdrawAmount = baseAmount - penalty + bonus;
        
        // ⚡ 修改重點：用減法扣除份額，不再直接歸零
        totalVaultShares -= _sharesToWithdraw;
        user.shares -= _sharesToWithdraw;

        payable(msg.sender).transfer(finalWithdrawAmount);

        emit Withdraw(msg.sender, finalWithdrawAmount, penalty, bonus);
    }

    // 緊急退款保持「全額撤退」設定，因為災難發生時不該還讓用戶慢慢填數字
    function emergencyRefund() external {
        require(currentMarketState == MarketState.FLASH_CRASH, "Emergency refund not active");
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares > 0, "No assets to refund");

        uint256 refundAmount = user.shares; 
        totalVaultShares -= user.shares;
        user.shares = 0;

        payable(msg.sender).transfer(refundAmount);
    }

    receive() external payable {}
}