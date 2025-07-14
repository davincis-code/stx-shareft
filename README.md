# STX-ShareFT: NFT Fractionalization Smart Contract

A Clarity smart contract built on the Stacks blockchain that enables users to split expensive NFTs into smaller, tradeable shares, making premium digital assets more accessible to a broader audience.

## 🚀 Overview

STX-ShareFT allows NFT owners to fractionalize their digital assets by creating "vaults" that contain the original NFT and issue tradeable shares representing fractional ownership. This democratizes access to high-value NFTs while maintaining the ability to reunite shares and reclaim the original asset.

## ✨ Key Features

- **NFT Fractionalization**: Split any NFT into customizable number of shares
- **Share Trading**: Buy and sell shares using STX tokens
- **Flexible Pricing**: Vault owners can update share prices
- **NFT Redemption**: Reunite all shares to reclaim the original NFT
- **Secure Transfers**: Safe peer-to-peer share transfers
- **Emergency Controls**: Contract owner can pause vaults if needed

## 🛠 How It Works

1. **Create Vault**: NFT owner deposits their asset and creates a vault with specified shares and pricing
2. **Buy Shares**: Users purchase fractional ownership using STX tokens
3. **Trade Shares**: Share holders can transfer ownership to other users
4. **Redeem NFT**: When someone owns all shares, they can reclaim the original NFT

## 📋 Contract Functions

### Core Functions

#### `create-vault`
```clarity
(create-vault nft-contract nft-id total-shares share-price name description symbol)
```
Creates a new vault by fractionalizing an NFT.

**Parameters:**
- `nft-contract`: The NFT contract implementing the nft-trait
- `nft-id`: The ID of the NFT to fractionalize
- `total-shares`: Number of shares to create
- `share-price`: Price per share in microSTX
- `name`: Vault name (max 50 characters)
- `description`: Vault description (max 200 characters)
- `symbol`: Vault symbol (max 10 characters)

**Returns:** Vault ID on success

#### `buy-shares`
```clarity
(buy-shares vault-id amount)
```
Purchase shares from a vault using STX tokens.

**Parameters:**
- `vault-id`: The vault to buy shares from
- `amount`: Number of shares to purchase

#### `transfer-shares`
```clarity
(transfer-shares vault-id amount recipient)
```
Transfer shares to another user.

**Parameters:**
- `vault-id`: The vault containing the shares
- `amount`: Number of shares to transfer
- `recipient`: Address of the recipient

#### `redeem-nft`
```clarity
(redeem-nft vault-id)
```
Redeem the original NFT (requires owning ALL shares).

**Parameters:**
- `vault-id`: The vault to redeem from

### Management Functions

#### `update-share-price`
```clarity
(update-share-price vault-id new-price)
```
Update the price per share (vault owner only).

#### `emergency-pause-vault`
```clarity
(emergency-pause-vault vault-id)
```
Emergency pause a vault (contract owner only).

### Read-Only Functions

#### `get-vault-info`
```clarity
(get-vault-info vault-id)
```
Get vault information including NFT details, shares, and owner.

#### `get-share-balance`
```clarity
(get-share-balance vault-id holder)
```
Get the number of shares owned by a specific address.

#### `get-vault-metadata`
```clarity
(get-vault-metadata vault-id)
```
Get vault metadata (name, description, symbol).

## 🔧 Installation & Deployment

### Prerequisites
- Clarinet CLI
- Stacks wallet for testing
- Basic understanding of Clarity smart contracts

### Local Development
1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Create a new Clarinet project: `clarinet new stx-shareft`
4. Add the contract to `contracts/stx-shareft.clar`
5. Test locally: `clarinet test`

### Deployment
1. Configure your deployment settings in `Clarinet.toml`
2. Deploy to testnet: `clarinet deploy --testnet`
3. Deploy to mainnet: `clarinet deploy --mainnet`

## 🧪 Testing

### Unit Tests
```bash
clarinet test
```

### Integration Tests
Test the full workflow:
1. Create a vault with an NFT
2. Buy shares from multiple addresses
3. Transfer shares between users
4. Redeem the NFT when all shares are owned

### Example Test Scenarios
- **Happy Path**: Create vault → Buy shares → Transfer shares → Redeem NFT
- **Edge Cases**: Insufficient balance, invalid amounts, unauthorized access
- **Security**: Owner-only functions, emergency pausing

## 💡 Usage Examples

### Creating a Vault
```clarity
;; Fractionalize an NFT into 1000 shares at 1000 microSTX each
(contract-call? .stx-shareft create-vault 
  .my-nft-contract 
  u42 
  u1000 
  u1000 
  "Cool Art #42" 
  "Fractionalized shares of Cool Art #42" 
  "COOL42")
```

### Buying Shares
```clarity
;; Buy 100 shares from vault 1
(contract-call? .stx-shareft buy-shares u1 u100)
```

### Transferring Shares
```clarity
;; Transfer 50 shares to another user
(contract-call? .stx-shareft transfer-shares u1 u50 'SP1234...ABCD)
```

## 🔒 Security Considerations

- **Access Control**: Only vault owners can update prices and redeem NFTs
- **Balance Validation**: All transfers check sufficient balance
- **Emergency Pause**: Contract owner can pause individual vaults
- **Input Validation**: All parameters are validated before processing
- **Reentrancy Protection**: Uses Clarity's built-in safety features

## 📊 Data Structure

### Vaults Map
```clarity
{
  nft-contract: principal,
  nft-id: uint,
  total-shares: uint,
  share-price: uint,
  owner: principal,
  active: bool
}
```

### Shares Map
```clarity
{
  vault-id: uint,
  holder: principal
} -> {
  amount: uint
}
```

## 🚨 Error Codes

- `u100`: Owner only operation
- `u101`: Vault not found
- `u102`: Insufficient balance
- `u103`: Already exists
- `u104`: Invalid amount
- `u105`: Unauthorized access
- `u106`: Not vault owner

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

**Built with ❤️ on Stacks blockchain using Clarity**