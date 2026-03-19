# Agrochain Protocol Smart Contract

## Overview

The **Agrochain Protocol (ATP)** enables the tokenization of agricultural produce into tradeable digital shares on the Stacks blockchain. This contract allows a farmer to register a produce batch, sell tokens to investors, and manage harvest and refund processes in a transparent, decentralized way.

---

## Features

- **Produce Registration:** Farmer initializes a token sale for a produce batch.
- **Token Purchase:** Investors buy tokens representing shares of the produce.
- **Harvest Completion:** Farmer marks the harvest as complete, closing sales.
- **Token Redemption:** Investors redeem tokens after harvest (off-chain delivery/payout).
- **Refunds:** Investors can claim refunds if the harvest fails.
- **Farmer Management:** Farmer/contract owner can be updated securely.

---

## Contract Functions

### Public Functions

- `set-farmer(new-farmer)`  
  Update the contract owner (farmer). Only the current farmer can call this.

- `register-produce(supply, price)`  
  Register a new produce batch and start a token sale. Only the farmer can call this.

- `buy-tokens(quantity)`  
  Purchase tokens during an open sale.

- `mark-harvest-complete()`  
  Mark the harvest as complete and close the sale. Only the farmer can call this.

- `redeem-tokens()`  
  Redeem tokens after harvest is complete.

- `refund()`  
  Claim a refund if the harvest is not completed.

### Read-Only Functions

- `get-balance(user)`  
  Get the token balance of a user.

- `get-token-details()`  
  Get contract state: farmer, total supply, remaining supply, price per token, sale status, and harvest status.

---

## Error Codes

- `ERR-NOT-FARMER (u100)`: Caller is not the farmer/owner.
- `ERR-INSUFFICIENT-TOKENS (u102)`: Not enough tokens available.
- `ERR-HARVEST-INCOMPLETE (u103)`: Harvest not yet completed.
- `ERR-HARVEST-ALREADY-COMPLETED (u104)`: Harvest already marked as complete.
- `ERR-SALES-CLOSED (u105)`: Token sale is closed.
- `ERR-NO-TOKENS (u106)`: Caller has no tokens.

---

## Usage

1. **Deploy the contract** to the Stacks blockchain.
2. **Farmer calls `register-produce`** to start a token sale.
3. **Investors call `buy-tokens`** to purchase tokens.
4. **Farmer calls `mark-harvest-complete`** when harvest is done.
5. **Investors call `redeem-tokens`** to redeem their share, or `refund` if the harvest fails.

---

## Notes

- All STX transfers are handled by the contract using `stx-transfer?`.
- Off-chain delivery or payout is handled manually after redemption.
- Only the farmer can update contract ownership or register new produce.

---

## License

MIT
