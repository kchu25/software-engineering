@def title = "Docker Explained Like You're 5"
@def published = "15 November 2025"
@def tags = ["devops"]

# Docker Explained Like You're 5

## What is Docker?

Imagine you have a really cool toy that only works with specific batteries and specific accessories. If you want to share this toy with your friend, you'd have to also give them all the right batteries and accessories, or it won't work at their house.

**Docker is like a magic lunchbox that holds your toy AND all the things it needs to work.** When you give your friend the lunchbox, everything just works! They don't need to find the right batteries or accessories themselves.

## What's a Virtual Machine (VM)?

A **Virtual Machine is like building an entire pretend house inside your house.** 

- It has its own pretend walls, pretend electricity, pretend everything
- It's very heavy and takes up a lot of space
- It's like you're running a whole computer inside your computer

## How is Docker Different?

**Docker is like having separate rooms in the same house instead of building a whole new house.**

- It's much lighter and faster
- All the rooms share the same foundation (your computer)
- Each room still keeps its stuff separate from the other rooms

## Running Software Without Dependencies

**Dependencies** are like needing special ingredients to bake a cake. Your program might need:
- A specific version of Python (like needing eggs)
- Certain libraries (like needing flour and sugar)
- Specific settings (like needing the oven at exactly 350°F)

**Docker packages everything together** so you don't have to worry about:
- "Does my friend have Python installed?"
- "Do they have the right version?"
- "Will it work on their computer?"

It's all in the container, ready to go! 🎁

---

# Docker Technical Concepts Explained

## **Container Manager**
Docker is software that creates and manages containers. Like a zookeeper manages animals in different enclosures.

## **Lightweight Virtualisation (shared kernel)**
- **Kernel** = the core of your operating system that talks to hardware
- VMs need their own full kernel (heavy)
- Docker containers share the host's kernel (light)
- It's like roommates sharing one kitchen instead of each building their own kitchen

## **Based on Linux Namespaces and Cgroups**
These are Linux features Docker uses:
- **Namespaces** = isolation (each container thinks it's alone)
- **Cgroups** = resource limits (controls how much CPU/memory each container gets)
- Think: separate bedrooms with locks (namespaces) + rules about electricity usage (cgroups)

## **Massively Copy-on-Write**
- Containers share base files until they need to change something
- Only differences are stored separately
- Like 100 students using the same textbook, but only making personal notes when needed
- Saves tons of disk space!

> **📝 Copy-on-Write Explained:**
> 
> **Normal copying:** You have a file, make a copy → 2 files = 2x space
> 
> **Copy-on-Write:** You make a "copy" but it's just a pointer to the original. Only when you WRITE/change something does it actually copy that specific part.
> 
> **Docker example:** Base Ubuntu image = 200MB. Create 10 containers.
> - Without CoW: 10 × 200MB = 2GB
> - With CoW: All share the same 200MB + only differences stored = ~250MB total!
> 
> **Analogy:** Like a teacher's worksheet - everyone reads from the same master copy, you only write on your own paper when adding answers. The original never changes!

## **Immutable Images**
- Once created, images don't change
- You don't "edit" an image, you build a new version
- Like a recipe card you never modify—you write a new card if you want changes

## **Instant Deployment**
Containers start in seconds (not minutes like VMs) because they're just processes, not full computers.

## **Suitable for Microservices (one process, one container)**
Best practice: each container runs ONE thing
- Container 1: web server
- Container 2: database  
- Container 3: cache

**Not:** one giant container running everything

> **📝 What are Microservices?**
> 
> **Old way (Monolith):** Build one giant application that does everything
> - Like a Swiss Army knife - all tools attached together
> - If one part breaks, the whole thing breaks
> - Hard to update just one feature
> 
> **New way (Microservices):** Break your app into small, independent services
> - Like separate tools in a toolbox
> - Each service does ONE job really well
> - Example e-commerce app:
>   - User service (handles logins)
>   - Product service (manages inventory)
>   - Payment service (processes payments)
>   - Shipping service (tracks orders)
> - Each can be updated, scaled, or fixed independently
> - If payment service crashes, users can still browse products
> 
> **Why Docker loves microservices:** One container = one microservice. Perfect match!

## **Immutable Architecture**
You never change running containers. Instead:
1. Build new image with changes
2. Stop old container
3. Start new container

Like replacing a Lego brick instead of trying to reshape it. Clean, predictable, no "it works on my machine but broke in production" surprises!

> **📝 Wait, how do I modify my code then?**
> 
> Docker has TWO main concepts:
> - **Image** = The blueprint/recipe (immutable, doesn't change)
> - **Container** = The running instance created from an image
> 
> **Your actual code lives in your project folder**, not "in" Docker initially.
> 
> **The workflow:**
> 1. **Write your code** on your computer (`app.py`)
> 2. **Create a Dockerfile** (instructions for building an image)
>    ```
>    FROM python:3.9
>    COPY app.py /app/
>    RUN pip install flask
>    CMD python /app/app.py
>    ```
> 3. **Build an image** from your code: `docker build -t myapp:v1`
>    - This packages your code INTO an image
> 4. **Run a container**: `docker run myapp:v1`
> 
> **When you change your code:**
> 1. Edit `app.py` on your computer (add new feature)
> 2. Build a NEW image: `docker build -t myapp:v2`
> 3. Stop old container
> 4. Start new container from new image
> 
> **The image is like a snapshot of your code at a specific moment.** You modify the source code, then create a new snapshot (new image), then run it!