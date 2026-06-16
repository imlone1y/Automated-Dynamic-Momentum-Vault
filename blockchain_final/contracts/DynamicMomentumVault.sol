// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DynamicMomentumVault {
    address public owner;
    
    enum MarketState { BULL, BEAR, FLASH_CRASH }
    MarketState public currentMarketState;
    
    uint256 public marketPrice;
    uint256 public constant CRASH_THRESHOLD = 500; 
    uint256 public constant EARLY_WITHDRAW_PENALTY_TIME = 3 days; 
    uint256 public totalVaultShares;
    uint256 public accumulatedPenaltyPool; 

    // ⚡ 核心亮點：時光旅行時間偏移量（秒數）
    uint256 public timeOffset;

    struct UserInfo {
        uint256 shares;
        uint256 depositTimestamp;
    }
    
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 penaltyPaid, uint256 bonusReceived);
    event MarketStateChanged(MarketState newState, uint256 newPrice);
    event CircuitBreakerActivated(uint256 timestamp);
    event TimeTraveled(uint256 totalOffset); // 時光旅行事件

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

    // ⚡ 核心新功能：讓合約時間前進的測試後門 (僅限 Owner 測試使用)
    function cheatForwardTime(uint256 _seconds) external onlyOwner {
        timeOffset += _seconds;
        emit TimeTraveled(timeOffset);
    }

    // ⚡ 內部工具：獲取虛擬的「未來時間戳」
    function getVirtualTimestamp() public view returns (uint256) {
        return block.timestamp + timeOffset;
    }

    function setMarketPrice(uint256 _newPrice) external onlyOwner {
        marketPrice = _newPrice;
        
        if (_newPrice <= CRASH_THRESHOLD) {
            currentMarketState = MarketState.FLASH_CRASH;
            emit CircuitBreakerActivated(getVirtualTimestamp()); // 使用虛擬時間
        } else if (_newPrice < 800) {
            currentMarketState = MarketState.BEAR;
        } else {
            currentMarketState = MarketState.BULL;
        }
        
        emit MarketStateChanged(currentMarketState, _newPrice);
    }

    function deposit() external payable whenNotCrashed {
        require(msg.value > 0, "Cannot deposit 0");
        
        uint256 shareMultiplier = 100;
        if (currentMarketState == MarketState.BEAR) {
            shareMultiplier = 80; 
        }
        
        uint256 sharesToMint = (msg.value * shareMultiplier) / 100;
        
        userInfo[msg.sender].shares += sharesToMint;
        userInfo[msg.sender].depositTimestamp = getVirtualTimestamp(); // ⚡ 記錄虛擬時間
        totalVaultShares += sharesToMint;

        emit Deposit(msg.sender, msg.value, sharesToMint);
    }

    function withdraw() external whenNotCrashed {
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares > 0, "No shares to withdraw");

        uint256 baseAmount = user.shares; 
        uint256 penalty = 0;
        uint256 bonus = 0;

        // ⚡ 用虛擬時間來做減法判斷是否滿 3 天！
        if (getVirtualTimestamp() - user.depositTimestamp < EARLY_WITHDRAW_PENALTY_TIME) {
            penalty = (baseAmount * 5) / 100; 
            accumulatedPenaltyPool += penalty;
        } else {
            if (accumulatedPenaltyPool > 0 && totalVaultShares > 0) {
                bonus = (accumulatedPenaltyPool * user.shares) / totalVaultShares;
                accumulatedPenaltyPool -= bonus;
            }
        }

        uint256 finalWithdrawAmount = baseAmount - penalty + bonus;
        
        totalVaultShares -= user.shares;
        user.shares = 0;

        payable(msg.sender).transfer(finalWithdrawAmount);

        emit Withdraw(msg.sender, finalWithdrawAmount, penalty, bonus);
    }

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