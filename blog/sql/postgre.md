@def title = "PostgreSQL Basics for Your DeSci Platform"
@def published = "30 December 2025"
@def tags = ["sql"]

# DeSci Platform Tech Stack - Your Friendly Roadmap 🧬

Hey! So you want to build something meaningful in the DeSci space while keeping your day job. Here's the good news: **you don't need to learn everything at once**. Think of this as a "choose your own adventure" - start simple, add complexity only when you need it.

## The Core Philosophy

**Make blockchain invisible to scientists. They want to do science, not learn Web3.**

---

## Tech Stack Overview

### 🎯 Phase 1: MVP (Weeks 1-6) - No Blockchain Yet!

Start here. Prove the concept works before adding crypto complexity.

| Layer | Technology | Why This One | Learning Curve |
|-------|-----------|--------------|----------------|
| **Frontend** | Next.js or SvelteKit | Modern, fast, great docs | Medium (but lots of tutorials) |
| **Styling** | Tailwind CSS | Clean academic look, minimal code | Easy |
| **Database** | PostgreSQL | Reliable, free tier available | Easy (if you know basic SQL) |
| **Auth** | Email/password | Simple start, no crypto wallets | Easy |
| **Hosting** | Vercel or Netlify | One-click deploy, free tier | Very Easy |
| **Payments** | Stripe | Scientists get paid in real money | Medium (great docs) |

**Weekend project vibes**: You could have a working prototype in 4-6 weekends. Really.

> ### "Wait, Won't Migrating This Data Later Be a Nightmare?"
>
> **Short answer:** Only if you build it wrong. Here's how to build it right from day 1 so you never have to "migrate."
>
> ### The Problem You're Worried About
>
> You're thinking:
> - Week 6: Have 50 experiments in PostgreSQL
> - Week 20: Want to move to Arweave/blockchain
> - Now you need to copy/migrate everything
> - What if data gets corrupted? What if users lose access? What about experiment IDs changing?
>
> **Good news:** You don't need to migrate if you design it as a hybrid system from the start.
>
> ### The "Mirror, Don't Migrate" Approach
>
> Instead of moving data from PostgreSQL to Arweave, do both simultaneously:
>
> **When a scientist submits an experiment:**
> ```javascript
> // Day 1 version (PostgreSQL only)
> const experiment = await saveToPostgres(experimentData);
> 
> // Week 10 version (both, seamlessly)
> const experiment = await saveToPostgres(experimentData);
> const arweaveId = await saveToArweave(experimentData); // Add this line
> experiment.arweaveId = arweaveId; // Link them
> await updatePostgres(experiment);
> ```
>
> **What this means:**
> - PostgreSQL has everything (fast searches, easy queries)
> - Arweave has permanent copies (can't be deleted, blockchain verified)
> - They point to each other
> - No "migration day" needed
> - Old experiments? They stay in PostgreSQL only (that's fine!)
>
> ### The Two-Track Strategy
>
> **Track 1: Operational data (stays in PostgreSQL forever)**
> - User accounts and profiles
> - Login sessions
> - Comments and discussions
> - Search indexes
> - Analytics
> - Anything that changes frequently
>
> **Track 2: Immutable records (goes to Arweave/blockchain)**
> - Final experiment protocols (once published)
> - Result data (once experiments complete)
> - Payment records
> - Ownership claims
> - Anything that should be permanent
>
> **They work together:**
> ```javascript
> // PostgreSQL record
> {
>   id: "exp_123",
>   title: "Brown fat experiment",
>   status: "completed",
>   createdAt: "2025-01-15",
>   arweaveId: "xY9kL..." // <-- Link to permanent storage
> }
>
> // Arweave record (permanent, can't change)
> {
>   experimentId: "exp_123",
>   protocolSteps: [...],
>   rawData: [...],
>   timestamp: "2025-01-15"
> }
> ```
>
> ### The "Start Hybrid" Philosophy
>
> **Instead of:**
> 1. Build everything in PostgreSQL
> 2. Later, "migrate to blockchain"
> 3. Painful transition period
>
> **Do this:**
> 1. Build with PostgreSQL for everything mutable
> 2. Week 1-6: Just PostgreSQL (move fast)
> 3. Week 7+: Add Arweave for important stuff (no migration needed!)
> 4. New data goes to both places
> 5. Old data stays where it is (totally fine)
>
> ### What Actually Needs to Be Permanent?
>
> **Probably doesn't need Arweave:**
> - User profiles (people change emails, universities, etc.)
> - Experiment drafts (they're works in progress)
> - Comments (can be edited/deleted)
> - Search results (generated dynamically)
> - Most day-to-day operations
>
> **Should eventually go to Arweave:**
> - Published experiment protocols (the "paper" version)
> - Final results and datasets
> - Proof of authorship
> - Payment/royalty records
>
> **The rule:** If it's final and shouldn't change, put it on Arweave. If it might need updates, keep it in PostgreSQL.
>
> ### Code Example: How to Build This from Day 1
>
> ```javascript
> // storage.js - Your abstraction layer
> 
> async function saveExperiment(data) {
>   // Always save to PostgreSQL (fast, queryable)
>   const pgRecord = await db.experiments.create(data);
>   
>   // If experiment is published (final), also save to Arweave
>   if (data.status === 'published') {
>     const arweaveId = await saveToArweave({
>       experimentId: pgRecord.id,
>       protocol: data.protocol,
>       timestamp: new Date()
>     });
>     
>     // Link them together
>     pgRecord.arweaveId = arweaveId;
>     await pgRecord.save();
>   }
>   
>   return pgRecord;
> }
> ```
>
> **Day 1:** Just save to PostgreSQL (Arweave function doesn't exist yet)
> 
> **Week 10:** Add the Arweave function, but PostgreSQL keeps working the same
> 
> **No migration needed** - you just start saving new stuff to both places
>
> ### What About Old Data?
>
> **Option A: Leave it (recommended)**
> - Old experiments stay in PostgreSQL only
> - New experiments go to both
> - Over time, more and more data is on Arweave
> - No stress, no migration, no downtime
>
> **Option B: Lazy migration (if you really want)**
> - When someone views an old experiment, check: "Is it on Arweave?"
> - If not, upload it in the background
> - Eventually everything gets there naturally
> - No dedicated migration day needed
>
> **Option C: Never migrate**
> - Experiments before [date] are PostgreSQL only
> - Experiments after [date] are hybrid
> - Both work fine
> - Totally acceptable for an MVP
>
> ### The Mental Model Shift
>
> **Don't think:** "I'm building a centralized app that will become decentralized"
> 
> **Instead think:** "I'm building a hybrid app where some data lives in fast storage (PostgreSQL) and some lives in permanent storage (Arweave)"
>
> It's not centralized vs. decentralized - it's **fast/mutable vs. slow/permanent**.
>
> ### When to Start This Hybrid Approach
>
> **Weeks 1-6:** PostgreSQL only (get something working!)
> - Don't even think about Arweave yet
> - Focus on proving scientists want this
> - Build fast, get feedback
>
> **Week 7-10:** Add Arweave integration
> - Write the `saveToArweave()` function
> - Test with a few experiments
> - Keep PostgreSQL as the source of truth
>
> **Week 11+:** Both systems running
> - New experiments automatically go to both
> - Old experiments stay in PostgreSQL
> - No "migration" ever happens
>
> ### The Reassuring Truth
>
> **You're not building a prototype that you'll throw away.** You're building the first layer of a system that will grow.
>
> - PostgreSQL isn't temporary - it's permanent infrastructure
> - Arweave doesn't replace PostgreSQL - it complements it
> - The code you write in Week 1 still works in Year 2
> - You're just adding capabilities, not replacing them
>
> **Real-world example:** 
> - Twitter stores tweets in a database (fast)
> - But also backs up to cold storage (permanent)
> - They didn't "migrate" from database to storage
> - They just started doing both
>
> That's what you're building. Not a prototype. Not a temporary solution. Just **the first working version of a hybrid system**.

---

### 🚀 Phase 2: Adding the Blockchain Magic (Weeks 7-10)

Once scientists are actually using it, add blockchain under the hood.

| Layer | Technology | What It Does | Complexity |
|-------|-----------|-------------|------------|
| **Wallet Abstraction** | Privy or Magic.link | Scientists log in with email, get crypto wallet automatically | Medium |
| **Account Abstraction** | Biconomy or ZeroDev | Transactions happen without gas fees or wallet pop-ups | Medium-Hard |
| **Blockchain** | Arbitrum or Base | Where smart contracts live (cheap transactions) | Medium |
| **Smart Contracts** | Solidity (keep it simple!) | Handles money escrow, reward distribution | Hard (but use OpenZeppelin templates) |
| **Decentralized Storage** | Arweave (via Bundlr) | Store experiment protocols permanently | Easy (just API calls) |
| **IPFS** | Pinata or Web3.Storage | Store experiment results | Easy |

**The clever bit**: Scientists never see MetaMask, gas fees, or "wallet connection" screens. It all happens in the background.

**Real talk**: You can learn the basics of each in a weekend, but mastering smart contract security takes months. Start with audited templates.

---

### 💰 Phase 3: Making Payments Smooth

| Component | Technology | Purpose | Pro Tips |
|-----------|-----------|---------|----------|
| **Fiat → Crypto** | Stripe + Circle USDC | Scientists pay in dollars, platform receives stablecoins | Medium complexity |
| **Crypto → Fiat** | Circle or Coinbase Commerce | Convert rewards back to USD for scientists | They handle compliance for you |
| **Stablecoins** | USDC | Avoid crypto volatility, scientists see consistent dollar amounts | Just an API integration |

**Why this matters**: A scientist earning usd "500" feels normal. Earning "0.15 ETH" feels like gambling.

---

## The "I Have a Full-Time Job" Strategy

Here's how to make progress without burning out:

### Option A: The Weekend Warrior Path (Recommended)
- **Weeks 1-2**: Build basic web form for experiment submission (no blockchain)
- **Weeks 3-4**: Add user authentication and dashboard
- **Weeks 5-6**: Launch with 5 friends as test users
- **Pause, evaluate**: Does anyone actually use it? If yes, continue. If no, pivot.
- **Weeks 7-10**: Add blockchain features if it's working

### Option B: The Lean Startup Approach
- Month 1: Talk to 20 scientists, understand the problem deeply
- Month 2: Build the simplest possible version
- Month 3: Get 10 real users
- Month 4: Add blockchain only if it actually helps

### Option C: Partner With Existing Projects
- Fork VitaDAO's contracts (they're open source)
- Build just the UX layer they're missing
- Focus 100% on making it easy to use
- Launch in weeks, not months

---

## What You Can Skip (At Least Initially)

| ❌ Don't Build This Yet | ✅ Use This Instead | Why |
|------------------------|-------------------|-----|
| Custom blockchain | Arbitrum or Base | Building a blockchain takes years |
| Token governance | Simple admin controls → DAO later | Premature complexity |
| Custom identity system | Privy or Auth0 | Security is hard, they solved it |
| File uploads from scratch | AWS S3 → IPFS later | S3 is familiar, IPFS can wait |
| Complex tokenomics | Fixed USD rewards → fancy formulas later | Scientists want clarity |

---

## The Honest Difficulty Assessment

Let me be real with you:

### Easy (Learn in a Weekend)
- Next.js basics
- Tailwind CSS
- PostgreSQL queries
- Deploying to Vercel
- IPFS/Arweave API calls

### Medium (Learn in 2-4 Weeks)
- React hooks and state management
- Stripe integration
- Privy wallet abstraction
- Smart contract deployment
- Token conversion logic

### Hard (Takes Months)
- Writing secure smart contracts
- Account abstraction implementation
- Cross-chain architecture
- Gas optimization
- Handling edge cases in crypto payments

### The Trick
**Start with Easy stuff. Add Medium stuff only when you need it. Avoid Hard stuff until you have users and funding.**

---

## Your 90-Day Roadmap (Part-Time)

### Month 1: Validate the Idea
- 🗣️ Interview 10-15 scientists
- ✍️ Sketch the simplest possible tool they'd use
- 🛠️ Build a dead-simple prototype (no blockchain)
- 🧪 Run 1 test experiment with friends

**Time commitment**: 5-10 hours/week  
**Blockchain involved**: 0%

### Month 2: Build the MVP
- 💻 Clean up the prototype
- 🎨 Make it not look terrible
- 🔐 Add basic authentication
- 💳 Add Stripe for payments
- 👥 Get 5-10 real scientists to try it

**Time commitment**: 10-15 hours/week  
**Blockchain involved**: Still 0% (and that's fine!)

### Month 3: Add Blockchain (If Validated)
- 🔗 Integrate Privy for invisible wallets
- 📝 Deploy simple smart contracts (use templates!)
- 💾 Store protocols on Arweave
- 🎉 Launch publicly with "blockchain verified" badge

**Time commitment**: 15-20 hours/week  
**Blockchain involved**: 40% (but abstracted away from users)

---

## The Confidence-Building Formula

Here's what makes this doable:

$$\text{Success} = \text{Small Wins} \times \text{Consistency} - \text{Overengineering}$$

Or in plain English:
1. **Build the smallest thing that works**
2. **Get feedback from real scientists**
3. **Add one feature at a time**
4. **Only add blockchain when it solves a real problem**

---

## Resources to Get Started (No Overwhelm)

### This Week
- 📖 Next.js tutorial (nextjs.org/learn) - 2 hours
- 🎥 Watch one "build a simple app" video - 1 hour
- 💬 Join r/labrats and lurk - see what scientists complain about

### This Month  
- 🛠️ Build something (anything!) and deploy it
- 📝 Write down 3 problems scientists face
- 🤝 Message 5 scientists on LinkedIn and ask about their workflow

### This Quarter
- 🚀 Launch a rough prototype
- 👥 Get 10 people to try it
- 📊 Decide: keep going or pivot?

---

## The Pep Talk You Needed

Look, the DeSci space is full of people with PhDs and millions in funding who *still haven't solved the UX problem*. You don't need to be an expert - you need to care about making scientists' lives easier.

**You have advantages they don't:**
- You can move fast (no committee approvals)
- You understand the problem (you've talked to scientists)
- You're not attached to "blockchain for blockchain's sake"

Start small. This weekend, build a form where someone can submit an experiment description. Next weekend, make it look decent. The weekend after, show it to a scientist friend.

**By Week 4, you'll know if this is worth pursuing. By Week 12, you could have something people actually use.**

The tech stack exists. The tools are free. The scientists are waiting for someone to build something that doesn't suck.

You've got this. 🚀

---

## Admin Controls Explained

> **Admin controls are just the "manager dashboard" of your app** - the place where you (or trusted people) can do important stuff that regular users can't.
>
> ### What Admin Controls Actually Do
>
> Think of it like being a store manager vs. a customer:
> - **Customers** can browse and buy stuff
> - **Managers** can change prices, remove products, refund orders, ban troublemakers
>
> In your DeSci platform:
> - **Scientists** can submit experiments and view results
> - **Admins** can approve experiments, distribute rewards, handle disputes, ban bad actors
>
> ### The Technical Pieces (Simplified)
>
> **1. Role-Based Access Control (RBAC)**
> 
> Just a fancy way of saying "different people have different permissions."
>
> In your database, you add a simple flag to each user:
> ```javascript
> {
>   email: "scientist@university.edu",
>   role: "user"  // or "admin" or "moderator"
> }
> ```
>
> Then in your code, you check before doing sensitive stuff:
> ```javascript
> if (user.role === "admin") {
>   // Allow access to admin dashboard
> } else {
>   // Show "Access Denied"
> }
> ```
>
> **2. The Admin Dashboard (The UI)**
>
> A separate page (like `/admin`) where admins can:
> - See all experiments in one place
> - Click buttons to approve/reject things
> - View user activity and statistics
> - Send messages or warnings to users
> - Manually adjust rewards if something goes wrong
>
> Think of it as the "back office" of your website. Users never see it.
>
> **3. Audit Logs (The "Who Did What" Record)**
>
> Every time an admin does something important, you write it down:
> ```javascript
> {
>   admin: "admin@platform.com",
>   action: "approved_experiment",
>   experimentId: "exp_123",
>   timestamp: "2025-01-15 14:30:00"
> }
> ```
>
> Why? So you can answer questions like:
> - "Who approved this sketchy experiment?"
> - "When did we ban this user?"
> - "Did someone abuse their admin powers?"
>
> It's your paper trail.
>
> **4. Approval Workflows (The Decision Pipeline)**
>
> Instead of things happening automatically, they wait for admin review:
> - Scientist submits experiment → Status: "Pending"
> - Admin reviews it → Clicks "Approve" or "Reject"
> - Status changes to "Active" or "Rejected"
>
> Super simple in code:
> ```javascript
> // Scientist submits
> experiment.status = "pending";
> 
> // Admin approves
> if (user.isAdmin) {
>   experiment.status = "approved";
>   experiment.approvedBy = admin.id;
>   experiment.approvedAt = now();
> }
> ```
>
> ### Why Start With Admin Controls vs. DAO Governance?
>
> **Admin controls (centralized):**
> - ✅ You can fix problems in 5 minutes
> - ✅ No need to explain blockchain voting to scientists
> - ✅ Works while you have 10 users or 10,000 users
> - ✅ Literally just an `if` statement in your code
>
> **DAO governance (decentralized):**
> - ❌ Scientists need to hold tokens and vote
> - ❌ Decisions take days (voting period)
> - ❌ Complex smart contracts you need to audit
> - ❌ Overkill when you're the only person using it
>
> **The Smart Move:**
> - Month 1-6: You (and maybe 2 trusted people) are the admins
> - Month 6-12: Add a "community moderator" role (scientists can vote on this)
> - Year 2+: Transition to DAO governance if the community wants it
>
> ### Real-World Example
>
> Let's say a scientist submits a suspicious experiment (like "test if water is wet" with a usd 1000 reward pool):
>
> **With admin controls:**
> - You log in → see it in pending queue → click "Reject" → add note "Low quality submission" → Done in 2 minutes
>
> **With DAO governance:**
> - Create a proposal "Should we reject experiment #123?"
> - Token holders vote over 3-7 days
> - If 51% agree, smart contract executes rejection
> - By then, 5 scientists already wasted time on it
>
> See the problem? **Speed matters in the early days.** You can decentralize later when processes are stable and the community is mature.
>
> ### What You Actually Build (Week 1)
>
> Day 1: Add `role` field to your user database
> 
> Day 2: Create `/admin` route that only admins can access
> 
> Day 3: Add a table showing all pending experiments
> 
> Day 4: Add "Approve" and "Reject" buttons that update the database
> 
> Day 5: Add basic audit logging (write actions to a log table)
>
> **That's it.** You now have admin controls. Total code: maybe 200-300 lines. Compare that to governance smart contracts which are 1000+ lines and need security audits.
>
> ### The Bottom Line
>
> Admin controls = the training wheels of decentralization. They let you move fast, fix problems quickly, and learn what actually needs to be decentralized. Most successful Web3 projects start centralized and decentralize gradually.
>
> Don't feel bad about having an admin dashboard. Even Uniswap and OpenSea had admin controls when they launched. You're in good company.

---

## "But Wait, Isn't Migrating to Decentralization a Nightmare?"

> **You're absolutely right to worry about this.** The centralized → decentralized transition can be a complete mess if you don't plan for it. Here's the honest truth and how to avoid the pain.
>
> ### Why It Usually Sucks
>
> **The typical disaster scenario:**
> - Year 1: Build everything with admin controls, PostgreSQL, manual approvals
> - Year 2: "Let's decentralize!" → Realize you need to rebuild everything
> - Rewrite admin logic as smart contracts → Months of work
> - Migrate all data to blockchain → Expensive and complex
> - Try to maintain both systems during transition → Everything breaks
> - Users confused about which version to use
> - Team burned out, money running low
> - Either abandon decentralization or abandon the project
>
> **Why this happens:**
> People build for centralization first, then bolt on decentralization later. Like trying to turn a car into a boat - technically possible, but painful.
>
> ### The Smart Architecture (Plan for Both from Day 1)
>
> Instead of thinking "centralized now, decentralized later," think **"decision layer + execution layer"**:
>
> **Decision Layer** (where choices happen):
> - Phase 1: Admin dashboard
> - Phase 2: Smart contract voting
>
> **Execution Layer** (where things get done):
> - Always the same code
> - Doesn't care WHO made the decision
> - Just executes the action
>
> **Code example:**
> ```javascript
> // Execution layer - stays the same forever
> async function approveExperiment(experimentId, approvedBy) {
>   await db.experiments.update({
>     id: experimentId,
>     status: 'approved',
>     approvedBy: approvedBy,
>     approvedAt: new Date()
>   });
>   
>   await logAction({
>     action: 'experiment_approved',
>     experimentId: experimentId,
>     approvedBy: approvedBy
>   });
> }
>
> // Decision layer - this is what changes
> 
> // Phase 1: Admin decides
> app.post('/admin/approve', requireAdmin, (req, res) => {
>   approveExperiment(req.body.experimentId, req.user.id);
> });
>
> // Phase 2: Smart contract decides
> contract.on('ExperimentApproved', async (experimentId, approvedBy) => {
>   approveExperiment(experimentId, approvedBy);
> });
> ```
>
> See? The core logic (`approveExperiment`) never changes. Only the trigger changes from "admin button click" to "smart contract event."
>
> ### The Gradual Migration Path (No Pain Version)
>
> **Month 1-6: Pure centralized, but architected right**
> - Build with clean separation between "decisions" and "actions"
> - Store everything in PostgreSQL
> - But write code like the blockchain is already there
> - Use events/webhooks internally (practice for smart contract events later)
>
> **Month 7-9: Shadow blockchain mode**
> - Deploy smart contracts to testnet
> - Mirror all admin actions to blockchain in the background
> - Users don't see any difference
> - You're testing the contracts with real usage patterns
> - If blockchain breaks, fall back to admin controls seamlessly
>
> **Month 10-12: Opt-in governance**
> - Launch governance token
> - Let power users vote on decisions
> - But keep admin controls as backup
> - Run both systems in parallel
> - "Community voted to approve this" OR "Admin approved this" - both work
>
> **Year 2: Progressive decentralization**
> - More decisions move to smart contracts
> - Admin role becomes "emergency override only"
> - Eventually remove admin controls for most things
> - Keep them for edge cases (fraud, legal issues)
>
> ### What Actually Needs to Be Decentralized?
>
> Here's the dirty secret: **Not everything needs to be on-chain.**
>
> **Should be decentralized (high value):**
> - Money flows (who gets paid what)
> - Ownership records (who created which protocol)
> - Voting on funding decisions
> - Protocol royalty distributions
>
> **Can stay centralized forever (low value):**
> - User interface and website hosting
> - Email notifications
> - Search functionality
> - Analytics and reporting
> - File uploads and preprocessing
> - Most of the boring CRUD operations
>
> **The Pragmatic Split:**
> ```
> Centralized backend (fast, cheap):
> - User accounts and profiles
> - Experiment metadata and search
> - Comments and discussions
> - File storage pointers
> - UI/UX logic
>
> Decentralized smart contracts (slow, expensive, trustless):
> - Escrow and payment distribution
> - Protocol ownership and attribution
> - Governance voting
> - Royalty calculations
> - Immutable experiment records
> ```
>
> ### The "Hybrid Forever" Option
>
> **Plot twist:** You don't have to fully decentralize.
>
> Many successful Web3 projects stay hybrid indefinitely:
> - **OpenSea**: Centralized UI, decentralized NFT ownership
> - **Uniswap**: Centralized interface, decentralized swaps
> - **Coinbase**: Mostly centralized, blockchain for settlements
>
> **For your platform:**
> - Scientists use a normal website (centralized)
> - Money and ownership records live on blockchain (decentralized)
> - Best of both worlds
> - No need for a painful "migration day"
>
> ### The Real Question
>
> **Ask yourself:** "What would break if I disappeared tomorrow?"
>
> - If admins can steal money → needs to be decentralized
> - If admins can erase ownership records → needs to be decentralized
> - If admins can censor experiments → maybe needs governance
> - If admins can change the UI → literally who cares, stay centralized
>
> **Decentralize the valuable/dangerous stuff. Keep the boring stuff centralized.**
>
> ### How to Know You're Building It Right
>
> Good signs:
> - ✅ Your core functions don't mention "admin" in the code
> - ✅ You could swap admin controls for DAO voting in a week
> - ✅ Data models work for both centralized and decentralized
> - ✅ Clear separation between "decision" and "execution"
>
> Bad signs:
> - ❌ Admin logic deeply embedded everywhere
> - ❌ Database schema assumes centralized control
> - ❌ No events/webhooks, just direct function calls
> - ❌ "We'll refactor it later when we decentralize"
>
> ### The Honest Recommendation
>
> **Don't stress about full decentralization in Year 1.**
>
> Build with clean architecture so you *could* decentralize, but only actually decentralize the things that matter:
> 1. Payment escrow (so you can't run away with money)
> 2. Ownership records (so scientists own their protocols)
> 3. Maybe governance (if the community demands it)
>
> Everything else? Keep it centralized until there's a real reason to change. Your scientists don't care if your user authentication is on-chain. They care if the platform works and they get paid fairly.
>
> **The migration pain is real, but it's avoidable with good architecture from day 1.** Think "hybrid by default" not "centralized with a plan to decentralize."

---

## "Wait, Why Keep PostgreSQL at All Then?"

> **Great question - you're thinking like an engineer!** But here's the thing: **you never delete the PostgreSQL line.** Both systems serve completely different purposes and you need both forever.
>
> ### Why PostgreSQL Can't Be Replaced
>
> **Arweave is permanent storage, not a database.** Here's what each is good at:
>
> **PostgreSQL (your operating system):**
> - ⚡ Lightning fast queries: "Show me all experiments by this user"
> - 🔍 Complex searches: "Find experiments with >90% completion rate"
> - ✏️ Can update/edit: "User changed their email"
> - 💰 Cheap: Millions of queries cost pennies
> - 📊 Relationships: "Find all experiments that reference this protocol"
> - 🔄 Real-time: Updates happen instantly
>
> **Arweave (your permanent record):**
> - 🔒 Immutable: Once written, can't be changed or deleted
> - 🌐 Decentralized: No one can take it down
> - ⏰ Slow: Can take minutes to confirm
> - 💸 Expensive: Costs money for every write
> - 🚫 Can't query: No "find all experiments by user X"
> - 📜 Proof: Blockchain-verified permanent record
>
> ### The Real-World Analogy
>
> **Think of it like books and a library:**
>
> **PostgreSQL = The library catalog system**
> - Fast lookup: "Show me all books about biology"
> - Can be updated: Change book location, add reviews
> - Searchable: Find by author, topic, year
> - If the library burns down, the catalog is gone
>
> **Arweave = The actual books on shelves**
> - Permanent: Once published, can't be unpublished
> - Immutable: Can't edit a printed book
> - Slow to access: Need to find the shelf and pull it down
> - If library burns down, the books (should) survive
>
> **You need BOTH.** You can't just have books with no catalog (can't find anything). You can't just have a catalog with no books (nothing to prove the content exists).
>
> ### What Actually Happens (Forever)
>
> ```javascript
> async function saveExperiment(data) {
>   // PostgreSQL - for operations (never goes away!)
>   const pgRecord = await db.experiments.create({
>     id: generateId(),
>     title: data.title,
>     status: data.status,
>     userId: data.userId,
>     create