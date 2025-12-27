@def title = "Node.js Cheatsheet for Solidity Development"
@def published = "27 December 2025"
@def tags = ["node-js"]

# Node.js Cheatsheet for Solidity Development

## Installation (Ubuntu)

**Install Node.js (recommended: use nvm for version management):**
```bash
# Install nvm (check https://github.com/nvm-sh/nvm for latest version)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# Restart terminal or run:
source ~/.bashrc

# Install Node.js LTS (Long Term Support)
nvm install --lts
nvm use --lts

# Verify installation
node --version    # Should show something like v18.x, v20.x, etc.
npm --version     # Comes bundled with Node
```

**Why nvm?** Lets you switch Node versions easily if projects need different versions. Think of it like switching between Solidity compiler versions.

**Alternative (direct install, not recommended):**
```bash
sudo apt update
sudo apt install nodejs npm
```

**Upgrade npm globally (optional but helpful):**
```bash
npm install -g npm@latest
```

## Package Management (npm/yarn)

**Initialize a project:**
```bash
npm init -y                    # Quick setup with defaults
```

**Installing packages:**
```bash
npm install hardhat            # Add to dependencies
npm install -D @nomicfoundation/hardhat-toolbox  # Dev dependency
npm install ethers@5.7.2       # Specific version
```

**Common commands:**
```bash
npm install                    # Install all dependencies
npm run <script>              # Run scripts from package.json
npx hardhat compile           # Run local package binary
```

## Essential Concepts

### 1. **package.json** - Your Project's Brain
This file tracks your dependencies and scripts. Think of it like your smart contract's metadata but for the whole project.

```json
{
  "scripts": {
    "test": "hardhat test",
    "deploy": "hardhat run scripts/deploy.js"
  },
  "dependencies": {
    "ethers": "^5.7.2"
  }
}
```

Run scripts with: `npm run test`

### 2. **node_modules/** - The Library
Where all installed packages live. Never commit this to git (use `.gitignore`). It's like importing OpenZeppelin contracts, but for JavaScript.

### 3. **Async/Await** - Handling Blockchain Calls
Blockchain interactions take time, so we use async/await:

```javascript
// Deploying a contract
async function deploy() {
  const Contract = await ethers.getContractFactory("MyToken");
  const contract = await Contract.deploy();
  await contract.deployed();
  console.log("Deployed to:", contract.address);
}
```

**Rule of thumb:** If it touches the blockchain, it's probably async.

### 4. **require() vs import**
```javascript
// CommonJS (older, still common)
const { ethers } = require("hardhat");

// ES6 (newer, needs "type": "module" in package.json)
import { ethers } from "hardhat";
```

Most Hardhat projects use `require()` by default.

### 5. **Environment Variables** - Keep Secrets Safe
Store private keys and API keys in `.env` files:

```bash
# .env file
PRIVATE_KEY=0xabc123...
ALCHEMY_API_KEY=your_key_here
```

```javascript
// Load them with dotenv
require('dotenv').config();
const privateKey = process.env.PRIVATE_KEY;
```

**Never commit `.env` to git!**

## Hardhat-Specific Commands

```bash
npx hardhat compile            # Compile contracts
npx hardhat test              # Run tests
npx hardhat node              # Start local blockchain
npx hardhat run scripts/deploy.js  # Run deployment
npx hardhat run scripts/deploy.js --network sepolia  # Deploy to testnet
npx hardhat clean             # Clear cache
```

## Essential JavaScript for Solidity Devs

**Working with BigNumbers:**
```javascript
const ethers = require('ethers');

// Solidity: uint256 amount = 1 ether;
const amount = ethers.utils.parseEther("1.0");  // 1000000000000000000

// Solidity: uint256 tokens = 100 * 10**18;
const tokens = ethers.utils.parseUnits("100", 18);

// Converting back
const readable = ethers.utils.formatEther(amount);  // "1.0"
```

**Connecting to contract:**
```javascript
const contract = await ethers.getContractAt(
  "MyToken",      // Contract name
  contractAddress // Deployed address
);

// Call view function (free, like Solidity's view)
const balance = await contract.balanceOf(address);

// Send transaction (costs gas, like Solidity's state-changing functions)
const tx = await contract.transfer(recipient, amount);
await tx.wait();  // Wait for confirmation
```

**Getting signers (wallets):**
```javascript
const [deployer, user1, user2] = await ethers.getSigners();
console.log("Deployer:", deployer.address);

// Use specific signer for transaction
const tx = await contract.connect(user1).transfer(user2.address, amount);
```

## Testing Pattern

```javascript
const { expect } = require("chai");

describe("MyToken", function() {
  let token, owner, addr1;
  
  // Runs before each test (like setUp in Foundry)
  beforeEach(async function() {
    [owner, addr1] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("MyToken");
    token = await Token.deploy();
  });
  
  it("Should transfer tokens", async function() {
    await token.transfer(addr1.address, 50);
    expect(await token.balanceOf(addr1.address)).to.equal(50);
  });
});
```

Run with: `npx hardhat test`

## Key Differences from Solidity

| Concept | Solidity | JavaScript/Node.js |
|---------|----------|-------------------|
| **Typing** | `uint256 x = 5;` | `let x = 5;` (dynamic) |
| **Equality** | `==` | `===` (strict equal) |
| **Strings** | `string memory` | Just `"string"` |
| **Arrays** | `uint[] memory` | `[1, 2, 3]` |
| **Decimals** | No native decimals | Use `parseEther()` |

## Quick Tips

1. **Always await blockchain calls** or you'll get promises instead of values
2. **Use `console.log()` liberally** when debugging (it's free unlike Solidity's gas costs!)
3. **Check transaction receipts:** `await tx.wait()` to ensure transactions succeed
4. **Version lock important packages** (like ethers) to avoid breaking changes
5. **Use `npx` for local packages** instead of global installs

## Common Gotchas

```javascript
// ❌ Wrong - not awaiting
const balance = contract.balanceOf(address);  // Returns Promise

// ✅ Right
const balance = await contract.balanceOf(address);

// ❌ Wrong - JavaScript numbers lose precision
const amount = 1000000000000000000;  // Number

// ✅ Right - Use BigNumber or string
const amount = ethers.utils.parseEther("1.0");
```

---

**Pro tip:** Think of Node.js as your off-chain development environment. Solidity runs on-chain (blockchain), JavaScript runs off-chain (your computer/server) to interact with those contracts.