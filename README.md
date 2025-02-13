# MS-IL

_This multisig implementation is not secure and should not be used in production._

This contract is a vanilla implementation of a multisig wallet. Transaction proposals are stored in an array and can be voted on by owners, by picking the index of the transaction in the array.

**Transaction lifecycle:**

- Anyone can propose a transaction
- Only owners can vote on a transaction
- A threshold of votes is required to execute a transaction
- Anyone can execute a transaction

**Transaction functions:**

- Owners can be added or removed through multisig transactions
- The threshold can be modified through multisig transactions

## Prerequisites

### Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Clone the repository

```bash
git clone https://github.com/fdemiramon/ms-il.git
```

### Install dependencies

```bash
cd ms-il && forge install
```

## Run tests

```bash
forge test
```

## Deployment

**Available env_vars:**

- `OWNERS`: comma separated list of owner addresses
- `THRESHOLD`: threshold for transaction execution
- `PRIVATE_KEY`: private key of the deployer

### To Anvil

```bash
anvil
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast -vvvv
```

### To a remote network

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url http://rpc.url --broadcast -vvvv
```

## Run example

```bash
forge script script/RunExample.s.sol:RunExample --rpc-url http://localhost:8545 --broadcast -vvvv
```
