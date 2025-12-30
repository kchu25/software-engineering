@def title = "PostgreSQL Basics for Your DeSci Platform"
@def published = "30 December 2025"
@def tags = ["sql"]

# PostgreSQL Basics for Your DeSci Platform

## What Is PostgreSQL?

Think of PostgreSQL as **a fancy Excel spreadsheet that your app can talk to**. But instead of clicking cells, you write questions in a language called SQL.

**Why PostgreSQL for DeSci?**
- Free and reliable (powers Instagram, Spotify, Reddit)
- Great for relationships (experiments → users → payments)
- Easy to learn the basics
- Works perfectly with Next.js/React

---

## The Core Concepts

### Tables = Spreadsheets

Each "thing" in your app gets its own table:

```sql
users table:
| id  | email                  | role    | created_at |
|-----|------------------------|---------|------------|
| 1   | jane@uni.edu          | user    | 2025-01-15 |
| 2   | admin@platform.com    | admin   | 2025-01-10 |

experiments table:
| id  | title              | user_id | status    | arweave_id |
|-----|--------------------|---------|-----------|------------|
| 1   | Brown fat study    | 1       | published | xY9kL...   |
| 2   | Sleep research     | 1       | draft     | null       |
```

### Columns = Properties

Each column has a **type** (like TypeScript):

```sql
CREATE TABLE experiments (
  id SERIAL PRIMARY KEY,           -- Auto-incrementing number
  title VARCHAR(255) NOT NULL,     -- Text (max 255 chars)
  user_id INTEGER NOT NULL,        -- Whole number
  status VARCHAR(50),              -- Text
  arweave_id TEXT,                 -- Longer text (optional)
  created_at TIMESTAMP DEFAULT NOW() -- Date/time
);
```

**Common types you'll use:**
- `INTEGER` or `SERIAL` - Numbers (user IDs, counts)
- `VARCHAR(n)` or `TEXT` - Strings (titles, descriptions)
- `BOOLEAN` - True/false (is_published)
- `TIMESTAMP` - Dates/times (created_at)
- `DECIMAL(10,2)` - Money (\$123.45)

---

## The 4 Operations You'll Use Daily

### 1. CREATE (Insert Data)

**Adding a new experiment:**

```sql
INSERT INTO experiments (title, user_id, status)
VALUES ('New experiment', 1, 'draft');
```

**In JavaScript (with a library like `pg` or an ORM):**

```javascript
const experiment = await db.experiments.create({
  title: 'New experiment',
  userId: 1,
  status: 'draft'
});
```

### 2. READ (Query Data)

**Get all experiments:**

```sql
SELECT * FROM experiments;
```

**Get specific experiment:**

```sql
SELECT * FROM experiments WHERE id = 1;
```

**Get user's experiments:**

```sql
SELECT * FROM experiments 
WHERE user_id = 1 AND status = 'published';
```

**In JavaScript:**

```javascript
// Get all
const experiments = await db.experiments.findAll();

// Get by ID
const exp = await db.experiments.findOne({ where: { id: 1 } });

// Filter
const published = await db.experiments.findAll({
  where: { userId: 1, status: 'published' }
});
```

### 3. UPDATE (Modify Data)

**Change experiment status:**

```sql
UPDATE experiments 
SET status = 'published', arweave_id = 'xY9kL...'
WHERE id = 1;
```

**In JavaScript:**

```javascript
await db.experiments.update(
  { status: 'published', arweaveId: 'xY9kL...' },
  { where: { id: 1 } }
);
```

### 4. DELETE (Remove Data)

```sql
DELETE FROM experiments WHERE id = 1;
```

**In JavaScript:**

```javascript
await db.experiments.destroy({ where: { id: 1 } });
```

---

## Relationships (The Magic Part)

This is where SQL shines over Excel - connecting tables together.

### One-to-Many: User Has Many Experiments

```sql
-- Get user with their experiments
SELECT users.email, experiments.title
FROM users
JOIN experiments ON users.id = experiments.user_id
WHERE users.id = 1;
```

**Visual:**
```
User (jane@uni.edu)
  ├── Experiment 1: "Brown fat study"
  ├── Experiment 2: "Sleep research"
  └── Experiment 3: "Metabolism test"
```

**In JavaScript (with proper ORM setup):**

```javascript
const user = await db.users.findOne({
  where: { id: 1 },
  include: [db.experiments] // Automatically joins!
});

console.log(user.experiments); // Array of all their experiments
```

### Foreign Keys (The Connection)

```sql
CREATE TABLE experiments (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id), -- Links to users table
  title VARCHAR(255)
);
```

**What this does:**
- Can't delete a user if they have experiments (data integrity!)
- Can easily find all experiments by a user
- Database enforces the relationship

---

## Your DeSci Database Schema

Here's what you'd actually build:

```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  role VARCHAR(50) DEFAULT 'user',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Experiments table
CREATE TABLE experiments (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  user_id INTEGER REFERENCES users(id),
  status VARCHAR(50) DEFAULT 'draft',
  arweave_id TEXT,
  reward_amount DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT NOW(),
  published_at TIMESTAMP
);

-- Payments table
CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  experiment_id INTEGER REFERENCES experiments(id),
  user_id INTEGER REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Audit log table
CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  admin_id INTEGER REFERENCES users(id),
  action VARCHAR(100),
  experiment_id INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Common Queries You'll Write

### 1. Get pending experiments for admin dashboard

```sql
SELECT e.*, u.email as author_email
FROM experiments e
JOIN users u ON e.user_id = u.id
WHERE e.status = 'pending'
ORDER BY e.created_at DESC;
```

### 2. Find experiments ready for Arweave

```sql
SELECT * FROM experiments
WHERE status = 'published' 
  AND arweave_id IS NULL;
```

### 3. Calculate user earnings

```sql
SELECT u.email, SUM(p.amount) as total_earned
FROM users u
JOIN payments p ON u.id = p.user_id
WHERE p.status = 'completed'
GROUP BY u.id, u.email;
```

Result:
```
email               | total_earned
--------------------|-------------
jane@uni.edu        | 450.00
bob@lab.com         | 320.50
```

### 4. Admin activity report

```sql
SELECT admin_id, COUNT(*) as actions_taken
FROM audit_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY admin_id;
```

---

## Indexes (Making It Fast)

Without indexes, finding data is like searching through every page of a book. With indexes, you jump straight to the page.

**Add indexes for fields you search often:**

```sql
CREATE INDEX idx_experiments_user ON experiments(user_id);
CREATE INDEX idx_experiments_status ON experiments(status);
CREATE INDEX idx_payments_user ON payments(user_id);
```

**Rule of thumb:** Index any column you use in `WHERE`, `JOIN`, or `ORDER BY`.

---

## Working With Timestamps

**Useful patterns:**

```sql
-- Experiments published in the last 30 days
SELECT * FROM experiments
WHERE published_at > NOW() - INTERVAL '30 days';

-- Format dates nicely
SELECT title, 
       TO_CHAR(created_at, 'YYYY-MM-DD') as date
FROM experiments;

-- Group by month
SELECT DATE_TRUNC('month', created_at) as month,
       COUNT(*) as experiment_count
FROM experiments
GROUP BY month;
```

---

## Transactions (Keep Data Consistent)

When multiple things need to happen together (like money + ownership), use transactions:

```sql
BEGIN;
  -- Deduct from escrow
  UPDATE experiments SET reward_amount = reward_amount - 100
  WHERE id = 1;
  
  -- Create payment record
  INSERT INTO payments (experiment_id, user_id, amount)
  VALUES (1, 5, 100);
COMMIT; -- Only save if BOTH succeed
```

**In JavaScript:**

```javascript
await db.transaction(async (t) => {
  await db.experiments.update(
    { rewardAmount: rewardAmount - 100 },
    { where: { id: 1 }, transaction: t }
  );
  
  await db.payments.create(
    { experimentId: 1, userId: 5, amount: 100 },
    { transaction: t }
  );
}); // Auto-commits or rolls back if anything fails
```

---

## Using an ORM (Skip Raw SQL)

**Most people use an ORM like Prisma or Sequelize** instead of writing SQL:

**With Prisma:**

```javascript
// Define schema in schema.prisma
model User {
  id         Int      @id @default(autoincrement())
  email      String   @unique
  experiments Experiment[]
}

model Experiment {
  id        Int      @id @default(autoincrement())
  title     String
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
}

// Use in code
const user = await prisma.user.create({
  data: {
    email: 'jane@uni.edu',
    experiments: {
      create: [
        { title: 'Brown fat study' }
      ]
    }
  }
});
```

**Pros of ORMs:**
- Type-safe (catches errors before runtime)
- Less SQL to write
- Handles relationships automatically
- Migrations built-in

**Cons:**
- Slightly slower for complex queries
- Another thing to learn
- Sometimes need raw SQL anyway

---

## Your Weekend Learning Plan

**Saturday Morning (2 hours):**
1. Install PostgreSQL locally
2. Create your first database
3. Make a `users` table and insert 3 rows
4. Query them back

**Saturday Afternoon (2 hours):**
1. Add `experiments` table with foreign key
2. Try JOINs to get user + their experiments
3. Practice UPDATE and DELETE

**Sunday (3 hours):**
1. Install Prisma or Sequelize
2. Define your schema
3. Build a simple API route that saves/fetches data
4. Deploy to a free Postgres host (Railway, Supabase)

**You'll know the basics by Monday morning.** 🎉

---

## Quick Reference Card

| Task | SQL | JavaScript (ORM) |
|------|-----|------------------|
| Insert | `INSERT INTO table (col) VALUES (val)` | `db.table.create({col: val})` |
| Select All | `SELECT * FROM table` | `db.table.findAll()` |
| Select One | `SELECT * WHERE id=1` | `db.table.findOne({where: {id:1}})` |
| Update | `UPDATE table SET col=val WHERE id=1` | `db.table.update({col:val}, {where:{id:1}})` |
| Delete | `DELETE FROM table WHERE id=1` | `db.table.destroy({where:{id:1}})` |
| Join | `SELECT * FROM a JOIN b ON a.id=b.a_id` | `db.a.findAll({include: [db.b]})` |

---

## The PostgreSQL Mental Model

$$\text{PostgreSQL} = \text{Excel} + \text{Relationships} + \text{Speed} + \text{Multi-user}$$

- **Tables** are spreadsheets
- **Rows** are records
- **Columns** are fields
- **Foreign keys** are connections between spreadsheets
- **Indexes** are page numbers in a book
- **Transactions** are "all or nothing" operations

**Start simple. You'll get the hang of it in a weekend.** 🚀

---

Now that you understand how PostgreSQL works, you might be wondering: where does this database actually live when I deploy my app? Let's clear that up.

---

## Deployment: Where Does PostgreSQL Actually Live?

### The Short Answer

**No, you don't install PostgreSQL on the same server as your web app.** They live separately and talk to each other over the internet.

**Think of it like this:**
- Your web app = The restaurant
- PostgreSQL = The kitchen/warehouse (separate building)
- They're connected, but not in the same place

### How It Actually Works

```
User's Browser
    ↓
Your Web App (Vercel/Netlify)
    ↓ (makes database queries)
PostgreSQL Database (Separate service)
```

**When you deploy:**

1. **Your web app goes to Vercel/Netlify/Railway**
   - They handle your Next.js code
   - Just HTML/CSS/JavaScript serving
   - No database installed here

2. **Your PostgreSQL goes to a database host**
   - Supabase (easiest for beginners)
   - Railway (simple, generous free tier)
   - Neon (modern, serverless Postgres)
   - AWS RDS (enterprise, overkill for MVP)

3. **You connect them with a connection string:**

```javascript
// In your web app code
const DATABASE_URL = "postgresql://user:password@db.host.com:5432/mydb"

// Your app makes requests to that URL
const experiments = await db.experiments.findAll();
```

### Why They're Separate

**Imagine if they were together:**
- ❌ Every time you update your code, database gets reset
- ❌ Can't scale them independently
- ❌ If web app crashes, database goes down too
- ❌ Multiple web servers can't share one database

**With them separate:**
- ✅ Update your code anytime, data stays safe
- ✅ Web app crashes? Database is fine
- ✅ Can scale web servers without touching database
- ✅ Database stays running 24/7, web app can restart

---

## Is PostgreSQL Free?

### Yes! (With Caveats)

**PostgreSQL the software is 100% free and open source.** But hosting it costs money (like how WordPress is free, but web hosting isn't).

### Free Tier Options (Perfect for MVP)

**1. Supabase (Most Beginner-Friendly)**
- ✅ 500 MB storage free
- ✅ Unlimited API requests
- ✅ 2 GB bandwidth/month
- ✅ Built-in auth, realtime features
- 💰 Upgrade: \$25/month for 8 GB storage

**Good for:** ~10,000 experiments + 1,000 users

**2. Railway (Developer Favorite)**
- ✅ \$5 free credit/month
- ✅ Simple setup, great DX
- ✅ Auto-scaling
- 💰 Pay-as-you-go after free credit

**Good for:** Testing + early users

**3. Neon (Modern Serverless)**
- ✅ 0.5 GB storage free
- ✅ 3 GB "compute" per month
- ✅ Scales to zero (no cost when idle)
- 💰 \$19/month for more

**Good for:** Side projects, scales efficiently

**4. Vercel Postgres**
- ✅ 256 MB free (tiny but enough to start)
- ✅ Integrated with Vercel hosting
- 💰 \$20/month for 2 GB

**Good for:** All-in-one if you're on Vercel

### What "Free Tier" Actually Means

**500 MB storage = approximately:**
- 50,000 experiments (with descriptions)
- 10,000 users
- 100,000 payment records
- Your entire MVP + first 6 months

**Database math:**
```
1 experiment row ≈ 1 KB (1,000 bytes)
500 MB = 500,000 KB
500,000 KB ÷ 1 KB = 500,000 experiments
```

**You won't hit limits for months.**

### When You'll Need to Pay

**Free tier is enough until:**
- 10,000+ active users
- Millions of records
- High traffic (1000s of queries/second)
- Need backups/replicas
- Need 99.99% uptime guarantees

**Cost at scale (rough estimates):**
- 100,000 users: \$25-50/month
- 1,000,000 users: \$100-200/month
- Instagram scale: \$1000s/month (but you'd have funding by then)

---

## Local Development vs. Production

**During development (on your laptop):**

```bash
# Option 1: Install PostgreSQL locally
brew install postgresql  # Mac
# Your database runs on localhost:5432

# Option 2: Use Docker (easier)
docker run -p 5432:5432 -e POSTGRES_PASSWORD=mysecret postgres

# Option 3: Just use the cloud immediately
# Point your local dev to Supabase/Railway
```

**I recommend Option 3 for beginners:** Just use Supabase from day 1. No local installation needed. Your dev environment and production use the same database host (but different databases).

**Production (when deployed):**

```javascript
// .env.local (development)
DATABASE_URL="postgresql://localhost:5432/myapp_dev"

// .env.production (deployed)
DATABASE_URL="postgresql://user:pass@db.supabase.co:5432/myapp_prod"
```

### The Typical Setup

**What most developers do:**

1. **Week 1:** Use Supabase free tier for everything
2. **Month 3:** Create separate dev/prod databases on Supabase
3. **Month 6:** Still on free tier or paying \$25/month
4. **Year 2:** Maybe upgrade to dedicated hosting

**You probably won't pay for PostgreSQL hosting for 6-12 months.**

---

## Quick Start: Get Your Database Running in 5 Minutes

**Using Supabase (recommended for beginners):**

1. Go to supabase.com → Sign up (free)
2. Click "New Project"
3. Copy the connection string they give you
4. Paste into your `.env` file:

```bash
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.xxx.supabase.co:5432/postgres"
```

5. Done! Your app can now talk to the database.

**No installation. No configuration. Just works.**

---

## The Database Hosting Mental Model

**Think of databases like email:**

- Gmail (the service) is free
- But Google pays for servers to run it
- You just access it over the internet
- Your phone doesn't "install Gmail's servers"

**Same with PostgreSQL:**

- PostgreSQL (the software) is free
- But hosting it needs servers
- Your web app just accesses it over the internet
- Your web app doesn't "install the database"

**Separate services, connected by a URL.** That's it!

---

## Deployment FAQ

**Q: Do I install PostgreSQL where I deploy my web app?**  
**A:** No. They're separate services that talk over the internet.

**Q: Is PostgreSQL free?**  
**A:** The software is free. Hosting it has free tiers (Supabase, Railway, Neon) that are enough for your MVP + first 10,000 users. You probably won't pay for 6-12 months.

**Q: What should I use?**  
**A:** Supabase. Create an account, get a connection string, paste it in your code. Done in 5 minutes. Free until you have serious traction.

**Q: Do ALL modern web apps separate database from web hosting?**  
**A:** Yes, 95% of them. It's the standard architecture. Even small startups do this.

**Start with Supabase's free tier. Don't overthink it.** 🚀

---

## Wait, Do ALL Modern Web Apps Separate Database and Web Server?

### The Short Answer

**Yes, almost universally.** This is the standard architecture in 2025, from tiny startups to Google.

### Why This Became Standard

**The old way (1990s-2000s):**
```
One Server Does Everything
├── Web server (Apache/Nginx)
├── App code (PHP/Python)
└── Database (MySQL/PostgreSQL)
```

**Problems:**
- Server crashes → Everything goes down
- Need more database power? Must upgrade entire server
- Want to restart app? Database restarts too
- Hard to backup without downtime
- Can't have multiple web servers sharing one database

**The modern way (2010s-now):**
```
Web Server (Vercel)          Database Server (Supabase)
├── Handles HTTP requests    ├── Stores data
├── Runs your app code       ├── Always running
└── Stateless (no data)      └── Separate scaling
        ↕ (connected via internet)
```

**Benefits:**
- ✅ Web server crashes? Database is fine
- ✅ Scale them independently
- ✅ Multiple web servers → One database
- ✅ Easy backups (database unaffected by deploys)
- ✅ Restart/update app without touching data

### Who Does This?

**Everyone:**
- **Twitter**: Web servers on AWS EC2, Database on AWS RDS
- **Instagram**: Django on servers, PostgreSQL on separate cluster
- **Airbnb**: Rails on Kubernetes, PostgreSQL on managed service
- **Your startup**: Next.js on Vercel, PostgreSQL on Supabase

**Even tiny side projects do this now** because hosting companies made it trivial.

### The Pattern That 95% of Apps Use

```
Frontend (React/Next.js)
    ↓
Backend API (Node.js/Python/Go)
    ↓
Database (PostgreSQL/MySQL/MongoDB)
```

**All three can be on different services:**
- Frontend: Vercel, Netlify, Cloudflare Pages
- Backend: Railway, Render, Fly.io, AWS Lambda
- Database: Supabase, PlanetScale, MongoDB Atlas

**They talk to each other over HTTPS/TCP connections.**

### The Only Exceptions

**When database IS on the same server:**

1. **SQLite apps** (database is just a file)
   - Small tools, embedded apps
   - Example: Apps with <1000 users that use SQLite
   - Still rare for web apps

2. **Legacy/monolithic deployments**
   - Old companies that haven't modernized
   - Government systems from the 2000s
   - Increasingly rare

3. **Specific performance needs**
   - Ultra-low latency requirements (finance, gaming)
   - Even then, usually just means "same datacenter"

**But these are <5% of modern web apps.**

### Why Connection String Is Standard

**This is how 99% of apps connect to databases:**

```javascript
// App reads this from environment variables
const DATABASE_URL = process.env.DATABASE_URL;
// "postgresql://user:pass@db.host.com:5432/mydb"

// Library uses it to connect
const db = new Database(DATABASE_URL);
```

**Every major framework/language does this:**
- Next.js: ✅
- Django: ✅
- Rails: ✅
- Laravel: ✅
- Express: ✅
- Flask: ✅

**It's the universal standard.**

### The Architecture Diagram

**What your DeSci platform actually looks like in production:**

```
┌─────────────────────────────────────────────────┐
│  User's Browser (anywhere in the world)        │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ↓
┌─────────────────────────────────────────────────┐
│  Vercel Edge Network (CDN)                     │
│  - Serves HTML/CSS/JS                          │
│  - Routes API requests                         │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ↓
┌─────────────────────────────────────────────────┐
│  Your Next.js API Routes (Vercel Functions)    │
│  - Handles /api/experiments                    │
│  - Processes user requests                     │
│  - Business logic                              │
└──────────────────┬──────────────────────────────┘
                   │ PostgreSQL Protocol (TCP)
                   ↓
┌─────────────────────────────────────────────────┐
│  Supabase (Database Host)                      │
│  - PostgreSQL database                         │
│  - Always running                              │
│  - Stores all your data                        │
└─────────────────────────────────────────────────┘
```

**They're all in different datacenters**, connected over the internet, but it's so fast users never notice.

### Real-World Connection Latency

**How fast is the database connection?**

If your app is on Vercel (US East) and database on Supabase (US East):
- Connection latency: 1-5ms
- Query time: 1-10ms
- Total: 2-15ms

**Users don't notice.** Rendering the HTML takes longer (50-200ms).

**If they're far apart (app in US, DB in Europe):**
- Connection: 100-150ms
- Still often fine for most apps
- Fix: Put both in the same region

### The Modern DevOps Wisdom

**"Separate things that change at different rates."**

- Web app code changes daily (bug fixes, features)
- Database schema changes monthly (new tables)
- Actual data changes constantly (user activity)

**By separating them:**
- Deploy new code 10x/day without touching database
- Database stays stable and always-on
- Scale each independently based on needs

### Your Mental Model Should Be

**Don't think:**
"I'm building an app with a database inside it"

**Instead think:**
"I'm building an app that talks to a database service"

**Like:**
- Your app talks to Stripe for payments
- Your app talks to SendGrid for emails
- Your app talks to Supabase for data

**Database is just another service.** It happens to be one you control, but it's still separate.

---

## So When You Build Your DeSci Platform...

**What you'll actually do:**

1. **Week 1: Set up Supabase**
   - Create account (2 minutes)
   - Copy connection string (30 seconds)
   - Paste in `.env` file (10 seconds)

2. **Week 2-6: Build your app**
   - Write code on your laptop
   - Code talks to Supabase database (in cloud)
   - Test everything locally

3. **Week 6: Deploy to Vercel**
   - Push code to GitHub (1 minute)
   - Connect GitHub to Vercel (2 minutes)
   - Add database connection string to Vercel (1 minute)
   - Done!

**Your app (on Vercel) and database (on Supabase) talk to each other automatically.**

**You never "install" or "move" the database. It just lives on Supabase forever.**

---

## The Bottom Line

**Yes, separating web hosting from database hosting is:**
- ✅ The standard way (95% of modern apps)
- ✅ What you should do
- ✅ Easier than the old way (companies handle it for you)
- ✅ More reliable
- ✅ Industry best practice since ~2010

**You're not doing anything exotic.** This is how Instagram, Twitter, Airbnb, and literally every startup built in the last 10 years works.

**The connection string pattern (step 3) is universal.** Every web framework, every language, every hosting platform uses it.

**Don't overthink it. Just use Supabase + Vercel like everyone else.** 🚀

---

## "Wait, I Thought Big Companies Put Everything on AWS?"

> **You're not wrong! Many companies DO use AWS for everything.**
>
> But here's the thing: **AWS is huge - it's like saying "I shop at the mall."** Which store? There are hundreds.
>
> **When Twitter uses AWS, they're actually using:**
> - EC2 (servers for web app code)
> - RDS (managed PostgreSQL service)
> - S3 (file storage)
> - CloudFront (CDN)
> - ...and 50 other services
>
> **So even on AWS, the database is still separate from the web servers.** They're different AWS services that talk to each other.
>
> **The pattern is the same everywhere:**
> ```
> Web hosting thing → Database hosting thing
> ```
>
> **Could be:**
> - AWS EC2 → AWS RDS (both AWS, still separate)
> - Vercel → Supabase (different companies)
> - Railway → Railway (same company, still separate services)
>
> **Think of AWS like a shopping mall:**
> - You can buy your shirt and pants from the same mall (both AWS)
> - But they're still from different stores (EC2 vs RDS)
> - They're not sewn together into one garment
>
> **For your DeSci platform:**
> - Using Vercel + Supabase is totally fine (and easier)
> - Using AWS EC2 + AWS RDS is also fine (but more complex)
> - Either way, web and database are separate
>
> **The "everything on AWS" approach is common for big companies** because:
> - They already have AWS accounts
> - Easier billing (one invoice)
> - Services talk faster (same datacenter)
> - But it's more complex to set up
>
> **For beginners:** Vercel + Supabase is simpler and works the same way. You can always move to "all AWS" later if you need to.
>
> **Bottom line:** Whether you use one company (AWS) or multiple companies (Vercel + Supabase), the architecture is the same - web hosting and database hosting are always separate services. 🚀

---

Now here's a question that comes up a lot when building DeSci platforms: if you're going to use Arweave for permanent storage, why bother with PostgreSQL at all? Let's break down how these two very different technologies work together.

---

## PostgreSQL vs Arweave: The Mental Model

### What They Have in Common

Both store data. **That's where the similarity ends.**

Think of them like:
- **PostgreSQL** = Your kitchen (cook, modify, organize food)
- **Arweave** = A museum archive (preserve forever, never change)

### The Comparison Table

| Feature | PostgreSQL | Arweave | Mental Model |
|---------|-----------|---------|--------------|
| **Purpose** | Working database | Permanent archive | Library vs. Stone tablets |
| **Speed** | Milliseconds | Seconds to minutes | RAM vs. engraving in stone |
| **Can update?** | Yes (UPDATE, DELETE) | No (immutable forever) | Whiteboard vs. tattoo |
| **Can query?** | Yes (complex SQL) | No (just retrieve by ID) | Excel vs. filing cabinet |
| **Cost** | Per storage + compute | One-time fee per upload | Rent vs. buy |
| **Data structure** | Tables, rows, columns | JSON blobs with transaction IDs | Spreadsheet vs. numbered envelopes |
| **Relationships** | Foreign keys, JOINs | None (just references) | Connected nodes vs. scattered boxes |

### The Core Difference (This Is Key)

**PostgreSQL = Active workspace**
```javascript
// You can do this:
await db.experiments.update({ status: 'approved' }, { where: { id: 5 } });
await db.experiments.findAll({ where: { status: 'approved' } });
await db.experiments.destroy({ where: { id: 5 } });
```

**Arweave = Write-once archive**
```javascript
// You can only do this:
const txId = await arweave.upload(data); // Write once
const data = await arweave.fetch(txId);  // Read by ID

// You CANNOT do this:
await arweave.update(txId, newData);     // ❌ Doesn't exist
await arweave.delete(txId);              // ❌ Impossible
await arweave.query({ status: 'approved' }); // ❌ No SQL
```

### How to Transfer Implementation Logic

**The trick: Don't think of "transferring" - think of "mirroring."**

#### Pattern 1: Write to Both

```javascript
// PostgreSQL version (what you start with)
async function saveExperiment(data) {
  const experiment = await db.experiments.create({
    title: data.title,
    protocol: data.protocol,
    status: 'published'
  });
  return experiment;
}

// Hybrid version (add Arweave WITHOUT removing PostgreSQL)
async function saveExperiment(data) {
  // Still save to PostgreSQL (for searching, updating)
  const experiment = await db.experiments.create({
    title: data.title,
    protocol: data.protocol,
    status: 'published'
  });
  
  // ALSO save to Arweave (for permanent record)
  const arweaveTxId = await arweave.upload({
    experimentId: experiment.id,
    protocol: data.protocol,
    timestamp: new Date()
  });
  
  // Link them together
  await db.experiments.update(
    { arweaveId: arweaveTxId },
    { where: { id: experiment.id } }
  );
  
  return experiment;
}
```

**Key insight:** You're not replacing PostgreSQL with Arweave. You're adding Arweave as a permanent backup.

#### Pattern 2: PostgreSQL for Queries, Arweave for Proof

```javascript
// Finding experiments - USE POSTGRESQL
async function findUserExperiments(userId) {
  // This works:
  return await db.experiments.findAll({
    where: { userId: userId, status: 'published' }
  });
  
  // This is impossible on Arweave:
  // No SQL queries, no filtering, no searching
}

// Proving ownership - USE ARWEAVE
async function proveExperimentOwnership(experimentId) {
  const experiment = await db.experiments.findOne({
    where: { id: experimentId }
  });
  
  // Fetch from Arweave (blockchain-verified proof)
  const proof = await arweave.fetch(experiment.arweaveId);
  
  return {
    databaseRecord: experiment,        // Fast, can change
    blockchainProof: proof,           // Slow, permanent, trustless
    verified: proof.experimentId === experimentId
  };
}
```

### What Maps Across (Sort Of)

| PostgreSQL Concept | Arweave Equivalent | Notes |
|-------------------|-------------------|-------|
| `INSERT` | `arweave.upload()` | Similar: both write data |
| `SELECT * WHERE id=X` | `arweave.fetch(txId)` | Need exact ID, no WHERE clauses |
| Primary key (id) | Transaction ID (txId) | Both are unique identifiers |
| Row of data | JSON blob | Structure is similar |
| `UPDATE` | Upload new version + link | No true update, just append |
| `DELETE` | Impossible | Data stays forever |
| Foreign keys | Manual references | You track relationships yourself |
| Indexes | GraphQL (via gateway) | Limited, different approach |

### What Doesn't Map At All

**PostgreSQL has, Arweave doesn't:**
- ❌ JOINs (no relationships)
- ❌ WHERE clauses (no filtering)
- ❌ GROUP BY (no aggregation)
- ❌ Transactions (each upload is separate)
- ❌ UPDATE/DELETE (immutable)

**Arweave has, PostgreSQL doesn't:**
- ✅ Blockchain verification (tamper-proof)
- ✅ Permanent storage (can't be deleted)
- ✅ Decentralized (no single point of failure)
- ✅ One-time payment (not monthly fees)

### The Hybrid Implementation Strategy

**For your DeSci platform, you'd do this:**

```javascript
// experiments.js - Your unified interface

async function createExperiment(data) {
  // 1. Save to PostgreSQL (always)
  const pgRecord = await db.experiments.create(data);
  
  // 2. If published, also save to Arweave
  if (data.status === 'published') {
    const arweaveId = await saveToArweave(data);
    pgRecord.arweaveId = arweaveId;
    await pgRecord.save();
  }
  
  return pgRecord;
}

async function getExperiment(id) {
  // Get from PostgreSQL (fast)
  const experiment = await db.experiments.findOne({ where: { id } });
  
  // Optionally verify against Arweave
  if (experiment.arweaveId) {
    const arweaveData = await arweave.fetch(experiment.arweaveId);
    experiment.blockchainVerified = true;
  }
  
  return experiment;
}

async function searchExperiments(query) {
  // Use PostgreSQL (Arweave can't do this)
  return await db.experiments.findAll({
    where: {
      title: { [Op.like]: `%${query}%` }
    }
  });
}
```

### The Decision Tree: Which One Should I Use?

```
Need to search/filter? → PostgreSQL
Need to update later? → PostgreSQL
Need to delete? → PostgreSQL (only option)
Need complex queries? → PostgreSQL
Want fast access? → PostgreSQL

Need permanent proof? → Arweave
Need blockchain verification? → Arweave
Want data to survive forever? → Arweave
Need decentralization? → Arweave
Want one-time payment? → Arweave

Need both? → Use both! (most common)
```

### Real-World Example: Experiment Lifecycle

```javascript
// Week 1: Scientist creates draft
await db.experiments.create({
  title: "Brown fat study",
  status: "draft"
}); // Only PostgreSQL (it's changing)

// Week 5: Scientist updates protocol
await db.experiments.update(
  { protocol: updatedProtocol },
  { where: { id: experimentId } }
); // Only PostgreSQL (still changing)

// Week 8: Experiment published
const experiment = await db.experiments.findOne({ where: { id } });
const arweaveId = await arweave.upload({
  experimentId: experiment.id,
  protocol: experiment.protocol,
  publishedAt: new Date()
}); // Now on BOTH (frozen in time on Arweave)

await db.experiments.update(
  { status: 'published', arweaveId: arweaveId },
  { where: { id: experimentId } }
);

// Year 2: Need to find this experiment
const results = await db.experiments.findAll({
  where: { userId: 123 }
}); // Use PostgreSQL for searching

// Year 2: Need to prove ownership
const proof = await arweave.fetch(experiment.arweaveId);
// Use Arweave for verification
```

### The Mental Model Shift

**Don't think:**
"I'm migrating from PostgreSQL to Arweave"

**Instead think:**
"PostgreSQL is my working database, Arweave is my notary public"

**Like:**
- You write contracts in Google Docs (PostgreSQL) - edit anytime
- When finalized, you get them notarized (Arweave) - permanent proof
- You keep using Google Docs for drafts
- You reference the notarized version when needed

### The Code Architecture Pattern

```javascript
// storage-layer.js

class StorageLayer {
  // Mutable operations - PostgreSQL only
  async create(data) { return await db.create(data); }
  async update(id, data) { return await db.update(data, {where: {id}}); }
  async delete(id) { return await db.destroy({where: {id}}); }
  async search(query) { return await db.findAll({where: query}); }
  
  // Immutable operations - PostgreSQL + Arweave
  async publish(id) {
    const record = await db.findOne({where: {id}});
    const arweaveId = await arweave.upload(record);
    await db.update({arweaveId}, {where: {id}});
    return {record, arweaveId};
  }
  
  async verify(id) {
    const record = await db.findOne({where: {id}});
    const arweaveData = await arweave.fetch(record.arweaveId);
    return {
      matches: JSON.stringify(record) === JSON.stringify(arweaveData),
      databaseVersion: record,
      blockchainVersion: arweaveData
    };
  }
}
```

### The Bottom Line

**PostgreSQL and Arweave are complementary, not alternatives.**

- PostgreSQL = your daily workspace (fast, flexible, changeable)
- Arweave = your permanent archive (slow, rigid, forever)

**You don't transfer implementations between them.** You use PostgreSQL for 90% of operations, and mirror important final records to Arweave for proof and permanence.

**Think "database + blockchain backup" not "database vs blockchain."** 🚀

---

## Wrapping Up: Your Learning Path

You've just covered a lot of ground! Here's a quick recap of what you now understand:

### PostgreSQL Fundamentals
- Tables, columns, and the 4 CRUD operations (Create, Read, Update, Delete)
- Relationships with foreign keys and JOINs
- Indexes for performance
- Transactions for data consistency

### Deployment Architecture
- Web apps and databases live on separate services
- Connection strings connect them over the internet
- Free tiers (Supabase, Railway) are enough for months

### The Hybrid Approach
- PostgreSQL for fast, queryable, mutable data
- Arweave for permanent, verifiable, immutable records
- They complement each other - use both!

### Your Next Steps

**This Weekend:**
1. Create a Supabase account (5 minutes)
2. Build a simple `experiments` table
3. Practice INSERT, SELECT, UPDATE, DELETE

**Next Week:**
1. Add relationships (users → experiments)
2. Try an ORM like Prisma
3. Connect to a Next.js project

**This Month:**
1. Build your DeSci MVP with PostgreSQL only
2. Get a few users testing it
3. Add Arweave integration for published experiments

The tech stack is ready. The tools are free. Now go build something scientists will actually use. 🧬🚀