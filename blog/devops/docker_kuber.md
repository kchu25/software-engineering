@def title = "MLOps Skills for ML Engineers: The Real Deal"
@def published = "25 November 2025"
@def tags = ["devops"]


# MLOps Skills for ML Engineers: The Real Deal

## Is This Actually Real?

**Yes, 100%.** The ChatGPT response is spot-on. Here's the truth: most ML engineers don't need to be DevOps wizards. You need to know *just enough* to deploy your models and not completely break production. That's it.

The secret? Most MLOps work is:
- Copy a working example
- Adjust it for your use case
- Understand what's happening (so you can debug)
- Ship it

Let me walk you through each skill with real "hello world" examples.

---

## 1. Docker: Your First Container

### What It Actually Does
Packages your Python app + dependencies into a box that runs anywhere. No more "works on my machine" problems.

### Hello World Example

**Step 1: Create a simple Python app**
```python
# app.py
print("Hello from Docker!")
```

**Step 2: Write a Dockerfile**
```dockerfile
# Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
CMD ["python", "app.py"]
```

**Step 3: Build and run**
```bash
docker build -t my-first-app .
docker run my-first-app
```

**Output:** `Hello from Docker!`

### That's It
You just containerized an app. For ML, swap `app.py` with your model serving code and add `requirements.txt`:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "serve_model.py"]
```

---

## 2. Kubernetes: Running Containers at Scale

### What It Actually Does
Runs your Docker containers, restarts them if they crash, exposes them to the internet, and scales them up/down.

### Hello World Example

**Create a deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-model
spec:
  replicas: 2  # Run 2 copies
  selector:
    matchLabels:
      app: ml-model
  template:
    metadata:
      labels:
        app: ml-model
    spec:
      containers:
      - name: model
        image: my-ml-model:latest
        ports:
        - containerPort: 8000
```

**Deploy it:**
```bash
kubectl apply -f deployment.yaml
kubectl get pods  # See your running containers
```

### ML Engineer Level K8s
You only need to know:
- **Pod**: One instance of your container
- **Deployment**: Manages multiple pods
- **Service**: Exposes your pods to the network
- **Job**: Runs a one-time task (like training)

Copy these YAML templates, adjust the image name and ports. Done.

---

## 3. CI/CD: Auto-Deploy on Git Push

### What It Actually Does
Every time you push code, automatically run tests, build Docker images, and deploy.

### Hello World Example (GitHub Actions)

**Create `.github/workflows/deploy.yml`:**
```yaml
name: Deploy ML Model

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker image
        run: docker build -t my-model .
      
      - name: Run tests
        run: docker run my-model pytest
      
      - name: Deploy to cloud
        run: |
          echo "Deploying..."
          # Your deployment command here
```

**That's it.** Push to `main` → tests run → model deploys.

Most ML engineers literally copy this template and just change the deployment command.

---

## 4. Cloud Basics: Just Enough to Deploy

### What You Actually Need

**S3 / Google Cloud Storage:**
```python
# Upload model to S3
import boto3
s3 = boto3.client('s3')
s3.upload_file('model.pkl', 'my-bucket', 'model.pkl')
```

**Deploy on EC2 / GCE:**
```bash
# Start a VM
gcloud compute instances create ml-server \
  --image-family=ubuntu-2004-lts \
  --machine-type=n1-standard-4

# SSH in and run your Docker container
ssh ml-server
docker run -p 8000:8000 my-model
```

**SageMaker / Vertex AI:**
These have tutorials that are literally copy-paste. You:
1. Upload your model
2. Create an endpoint
3. Get a URL to call

---

## 5. Airflow: Scheduling ML Pipelines

### What It Actually Does
Runs your Python functions on a schedule. Like cron, but fancier.

### Hello World Example

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def train_model():
    print("Training model...")

def deploy_model():
    print("Deploying model...")

with DAG('ml_pipeline', start_date=datetime(2024, 1, 1), 
         schedule_interval='@daily') as dag:
    
    train = PythonOperator(task_id='train', python_callable=train_model)
    deploy = PythonOperator(task_id='deploy', python_callable=deploy_model)
    
    train >> deploy  # train runs first, then deploy
```

**That's a pipeline.** It runs daily. Real ML pipelines just have more steps.

---

## How to Actually Learn This

### Week 1: Docker + Basics
- **Day 1-2:** Docker tutorial (official docs)
- **Day 3-4:** Containerize a simple Flask API
- **Day 5-7:** Containerize a real model (scikit-learn or PyTorch)

### Week 2: K8s + CI/CD
- **Day 1-3:** Kubernetes basics (minikube locally)
- **Day 4-5:** Deploy your containerized model to K8s
- **Day 6-7:** Set up GitHub Actions to auto-build your image

### Week 3-4: Cloud + Orchestration
- **Day 1-4:** AWS/GCP basics (S3, EC2/GCE, IAM)
- **Day 5-7:** Deploy to cloud, set up basic Airflow DAG
- **Week 4:** Build an end-to-end project

---

## The Real Secret

**You don't learn by reading. You learn by:**
1. Finding a working example
2. Running it yourself
3. Breaking it
4. Fixing it
5. Adjusting it for your use case

After you've done this 3-4 times for each tool, you're "hire-able enough."

---

## Resources That Actually Work

**Docker:**
- Official "Get Started" tutorial (1-2 hours)
- YouTube: "Docker in 100 Seconds" by Fireship

**Kubernetes:**
- Official "Kubernetes Basics" interactive tutorial
- "Kubernetes for Beginners" by TechWorld with Nana (YouTube)

**GitHub Actions:**
- GitHub's own quickstart guide
- Copy someone's workflow file and modify it

**Cloud:**
- AWS "Getting Started with EC2" (free tier)
- Google "Vertex AI Quickstart"

**Airflow:**
- Official "Quick Start" docs
- "Airflow in 5 Minutes" tutorials

---

## Bottom Line

Is it real? **Absolutely.** 

Companies list "Kubernetes, Docker, CI/CD" because that's what DevOps people know. But for ML roles, they really just want you to:
- Not be scared of these tools
- Deploy your models without hand-holding
- Fix basic issues when things break

You're not building the next Netflix infrastructure. You're wrapping your model in Docker and hitting deploy.

**Start today:** Pick Docker, follow the official tutorial, containerize a simple Python script. You'll see how easy it actually is.