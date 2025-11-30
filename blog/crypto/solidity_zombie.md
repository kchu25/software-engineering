@def title = "Understanding Solidity Through a Zombie Factory"
@def published = "29 November 2025"
@def tags = ["crypto", "smart-contract", "block-chain", "eth"]

# Understanding Solidity Through a Zombie Factory

Hey! Let me walk you through Solidity using this zombie creation code. Think of it like learning a new language by reading a fun story.

## The Complete Code

```solidity
pragma solidity >=0.5.0 <0.6.0;

contract ZombieFactory {
    event NewZombie(uint zombieId, string name, uint dna);
    
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    
    struct Zombie {
        string name;
        uint dna;
    }
    
    Zombie[] public zombies;
    
    // declare mappings here
    
    function _createZombie(string memory _name, uint _dna) private {
        uint id = zombies.push(Zombie(_name, _dna)) - 1;
        emit NewZombie(id, _name, _dna);
    }
    
    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }
    
    function createRandomZombie(string memory _name) public {
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }
}
```

## The Contract Declaration

```solidity
pragma solidity >=0.5.0 <0.6.0;
contract ZombieFactory {
```

Every Solidity program starts with `pragma` - this is like saying "Hey, I wrote this code for Solidity version 0.5.x, so use that to compile it." Then `contract` is basically like a class in other languages. It's your main container for all the code.

## Events: Broadcasting to the World

```solidity
event NewZombie(uint zombieId, string name, uint dna);
```

Events are super cool! They're like announcements that get logged on the blockchain. When you create a zombie, this event fires off and anyone watching can see "Hey, zombie #42 named 'Fluffy' just got created with DNA 1234567890123456!" Front-end apps listen to these to update in real-time.

When you `emit` an event, it gets permanently written to the blockchain's transaction logs - like an immortal newspaper that everyone can read. It's way cheaper than storing in state variables, and off-chain apps can search through all historical events. The catch? Your contract can't read its own events - they're write-only, meant for the outside world to observe what happened.

> **Why no `memory` keyword for the string here?**
> 
> Great catch! Events are special - they're not actually executable code, they're just *definitions* of what data to log. When you define an event, you're creating a template that says "when this event fires, log these types of data." You only specify data location keywords (`memory`, `storage`, `calldata`) when you're dealing with actual function parameters that need to be stored somewhere during execution.
> 
> Think of it like this: the event definition is like designing a form ("Name: _____, DNA: _____"), while function parameters are like actually filling out that form and needing a desk (memory) to write on. The event itself doesn't need to know *where* the data lives - it just cares *what type* it is. When you later `emit NewZombie(id, _name, _dna)`, Solidity figures out where that data is coming from and logs it appropriately.

## State Variables: Your Contract's Memory

```solidity
uint dnaDigits = 16;
uint dnaModulus = 10 ** dnaDigits;
```

These live permanently on the blockchain. `uint` means "unsigned integer" (no negative numbers). Here we're saying DNA will be 16 digits long, and `dnaModulus` (10^16) helps us keep random numbers in that range. Every time you read or write these, you're literally reading/writing to the Ethereum blockchain!

## Structs: Custom Data Types

```solidity
struct Zombie {
    string name;
    uint dna;
}
Zombie[] public zombies;
```

A `struct` is like creating your own custom data type. Think of it as a blueprint: "Every zombie has a name and DNA." The `Zombie[]` creates a dynamic array - a list that can grow forever. The `public` keyword automatically creates a getter function, so anyone can look up zombie info!

## Functions: Where the Action Happens

### Private Function (Internal Use Only)

```solidity
function _createZombie(string memory _name, uint _dna) private {
```

The underscore `_` is a naming convention for private functions. `private` means only this contract can call it. The `memory` keyword says "_name is temporary, just keep it in memory during this function call." Parameters prefixed with `_` help avoid naming conflicts.

### The Push Trick

```solidity
uint id = zombies.push(Zombie(_name, _dna)) - 1;
emit NewZombie(id, _name, _dna);
```

`zombies.push()` adds a new zombie to the array and returns the new length. Subtracting 1 gives us the index (arrays start at 0). Then we `emit` that event we talked about!

### View Functions: Just Looking, Not Touching

```solidity
function _generateRandomDna(string memory _str) private view returns (uint) {
```

`view` means "I promise I'm only reading data, not changing anything." This is important because it means calling this function is FREE - it doesn't cost gas! The `returns (uint)` tells you what data type comes back.

### Hashing for Randomness

```solidity
uint rand = uint(keccak256(abi.encodePacked(_str)));
return rand % dnaModulus;
```

`keccak256` is a cryptographic hash function - give it any input, it spits out a (seemingly) random 256-bit number. `abi.encodePacked` just converts the string to bytes. The `% dnaModulus` operation ensures the result fits within our 16-digit range.

> **⚠️ The Randomness Problem on Blockchain**
> 
> This isn't truly random - miners can manipulate it since everything on-chain is deterministic and public. They can see transactions before confirming them and potentially game the system.
> 
> **When simple hash-based randomness is okay:**
> - Low-stakes games where manipulation doesn't matter much
> - Generating cosmetic traits (like zombie DNA)
> - Any scenario where the cost to manipulate exceeds potential profit
> 
> **When you need real randomness:**
> - Lotteries, gambling, anything with money at stake
> - NFT drops where rarity equals value
> - Fair distribution mechanisms
> 
> For these high-stakes scenarios, you'd use **Chainlink VRF** (the dominant solution) or alternatives like API3 or Band Protocol. These oracle services provide provably random numbers, but add complexity: you make a request, **pay fees in LINK tokens** (yes, every random number costs money!), wait for a callback, then use the random number. The fee covers the oracle nodes doing the work and provides economic security. So that "free" one-line hash? Suddenly becomes an ongoing operational cost. Other approaches include commit-reveal schemes or block hash randomness, but each has tradeoffs.
> 
> Welcome to blockchain: verifiable and deterministic by design, which means random numbers need their own infrastructure! 😅

### Public Functions: The World Can Call These

```solidity
function createRandomZombie(string memory _name) public {
```

`public` means anyone with an Ethereum wallet can call this function! They'll pay gas fees to execute it. This is your main entry point - users call this, it generates random DNA, then calls the private function to actually create the zombie.

## Key Takeaways

- **Contracts** are like classes that live on the blockchain
- **State variables** cost gas to write but stick around forever
- **Events** broadcast important changes to the outside world
- **Function visibility** (`public`, `private`) controls who can call what
- **`view`** functions don't change state and are free to call
- **Memory** vs storage matters for performance and cost
- Everything costs gas except reading/view functions!

## What's Gas Anyway?

Think of gas as the "computation fee" for running code on Ethereum. Every operation (storing data, doing math, creating zombies) costs a tiny amount of ETH. Why? Because your code runs on thousands of computers worldwide - miners/validators need compensation. Writing to storage is expensive, reading is cheap, and view functions are free. When you call `createRandomZombie()`, you pay gas. When someone just looks up a zombie with the auto-generated getter, it's free!

## Putting It All Together: What Happens When You Create a Zombie?

1. User calls `createRandomZombie("Fluffy")` from their wallet (pays gas)
2. Function generates random DNA by hashing "Fluffy"
3. Calls the private `_createZombie()` function with name and DNA
4. New zombie gets pushed to the `zombies` array (stored on blockchain forever)
5. `NewZombie` event fires, broadcasting to the world that zombie #42 was born
6. Your front-end app catches the event and shows "Fluffy has arrived!" 🧟

## Quick Notes

- **The mapping comment**: You'll notice `// declare mappings here` in the code - that's a placeholder for future lessons. Mappings are like dictionaries (key-value pairs) and are super common in Solidity.
- **The underscore convention**: Private functions start with `_` to make them visually distinct from public ones and avoid naming collisions.
- **Solidity version note**: This code uses Solidity 0.5.x where `array.push()` returns the new length. In 0.6.0+, it returns nothing, so you'd write it differently.

Pretty neat, right? You're literally creating immortal zombies on a distributed computer network! 🧟