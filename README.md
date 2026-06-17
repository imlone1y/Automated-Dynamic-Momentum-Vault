# 基於時間與價格波動的自動動態動量保險庫 Automated Dynamic Momentum Vault

本項目為東華大學區塊鏈原理與應用期末作業，未經允許禁止使用、轉買。
---
## The goal of smart contract

The `DynamicMomentumVault` is a next-generation, decentralized, and automated hedge fund protocol designed to optimize user yields while proactively mitigating severe downside risks in highly volatile crypto markets. 

By integrating a built-in state machine and a mock price oracle, the contract achieves three primary objectives:

- **Dynamic Asset Exposure (Adaptive Defense):** The vault continuously monitors oracle price feeds to switch between market states. During a **BULL** market, it adopts an aggressive strategy, minting 100% of asset shares for depositors. During a **BEAR** market, it automatically shifts to a defensive posture, minting only 80% of shares—safeguarding a 20% liquid cash buffer (`address(this).balance`) to lower users' risk exposure.

- **Automated Circuit Breaker (Crisis Exit):** If market prices plummet below the critical threshold ($\le 500$, **FLASH_CRASH**), the contract automatically freezes all standard deposit and withdrawal operations to prevent panic bank-runs. Concurrently, it unlocks a zero-fee, zero-time-lock **Emergency Refund Channel**, allowing users to rescue 100% of their remaining principal instantly.

- **Game-Theoretic Tokenomics (Proportional Dividends):** To discourage short-term predatory arbitrage and reward long-term believers, the vault enforces a 3-day time lock. Users withdrawing within 3 days are penalized with a **5% fee** injected into the `accumulatedPenaltyPool`. Long-term holders withdrawing after 3 days enjoy 0手續費 and can **proportionally share the penalty pool rewards** based on their custom withdrawal amounts.

- **Developer-Friendly Simulation (Time-Travel Hook):** To seamlessly demonstrate time-sensitive fund behavior during evaluation, the contract features a secure `cheatForwardTime` function. This allows the administrator to advance the contract's virtual timeline via standard MetaMask transactions without complex back-end operations.

---

## Run the project

1. Move to workspace folder:
```bash
cd /blockchain_final
```

2. Install dependency [hardhat 3](https://hardhat.org/), [MetaMask](https://metamask.io/):
```bash
npm install
```

3. Create test account, keep terminal open:
```bash
npx hardhat node
```

**In second terminal**

4. Compile smart contract under `/contracts`:
```bash
npx hardhat compile
```

5. Deploy smart contract to active local network:
```bash
npx hardhat run scripts/deploy.ts --network localhost
```

6. Change the contract address in `index.html` file, line `132` to the address that generate by contract:
![contract_address_pic](/pic/contract_address.png)

7. Run website (May need to install `Live Server` extension in VScode):
```bash
python3 -m http.server 5500
```
---

## MetaMask custom network config

- Network Name: `Hardhat Local`
- Default RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`
- Currency Symbol: `ETH`

## Snapshot of contract

- Deposit $100 in `BULL`, 100% amount goes into market
![deposit_bull](/pic/deposit_bull.png)

- Deposit $100 in `BEAR`, 80% amount goes into market, decrease the risk
![deposit_bear](/pic/deposit_bear.png)

- Can't deposit / withdraw in `FLASH_CRASH`, use emergency deposit channel
![state_flash_crash](/pic/state_flash_crash.png)

- Withdraw the money with three days less in the bank, part of the amount goes into penlty pool

    before withdraw
    ![3days_withdraw](/pic/withdraw_3days.png)

    after withdraw
    ![3days_withdraw_after](/pic/after_withdraw_3days.png)

- Withdraw the money with four days more in the bank, gain part of the penlty pool

    before withdraw
    ![4days_withdraw](/pic/withdraw_4days.png)

    after withdraw
    ![4days_withdraw_after](/pic/after_withdraw_4days.png)