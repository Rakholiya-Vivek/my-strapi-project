# Strapi Local Setup & Sample Content Type

This repository contains my local setup of **Strapi** (cloned from the official repo) with a sample content type created locally.

---

## Project Setup

1. **Clone Strapi repo**
   using following commands:
   
git clone https://github.com/strapi/strapi.git

cd strapi

2. **Install dependencies**

  npm install

3. **Run Strapi**

  npm run setup
  
  npm run develop


4. *Open Admin Panel → http://localhost:1337/admin → Create Admin user.**

Go to Content-Type Builder → Create Collection Type → Article

Add fields:

Title (Text, short, required)

Body (Rich Text / Long Text)

Published (Boolean)

Click Save (Strapi will rebuild automatically)

5. Creating Sample Entry

Go to Content Manager → Article → Create New Entry

Fill in Title, Body, Published → Click Save (and optionally Publish)

## Run with Docker

1. Build image:
   ```bash
   docker build -t my-strapi-app .
2. Run container:

   docker run -it -p 1337:1337 my-strapi-app






  #  Task : 14 — Image Size Reduction of Docker Images

##  Overview

This document explains **how to reduce the size of Docker images**, why it is **important for deployment**, and how it can **save costs** in production environments.  
You’ll also learn **practical steps** and **commands** to build smaller, faster, and more secure Docker images.

---

## Objective

The main goal of this task is to:

1. Understand **why large Docker images are a problem**.
2. Learn **methods to reduce Docker image size**.
3. Apply **practical optimization techniques** to an example Dockerfile.
4. Explain **how it helps in the deployment process**.
5. Understand **cost-saving benefits** of image optimization.

---

##  What is Docker Image Size Reduction?

Docker image size reduction means **optimizing your image** so that it:
- Takes **less storage space**.
- **Builds faster**.
- **Transfers faster** between environments (CI/CD, servers, registries).
- Uses **fewer resources**, which directly impacts cloud cost.

Example:
If your original image is 1.2 GB and you reduce it to 250 MB,  
your build, push, and pull time decreases by ~80%!


---

##  Common Problems with Large Docker Images

- Using **heavy base images** like `ubuntu` or `python:latest`.
- Installing **unnecessary tools/packages**.
- Not using **multi-stage builds**.
- Leaving **cache files**, logs, or temp data** inside the image.
- Copying **too many files** into the image.
- Not cleaning up **apt/yum cache** after installation.

---

##  Techniques to Reduce Docker Image Size

### 1.  Use a Smaller Base Image
Instead of:
```dockerfile
FROM ubuntu:latest
```
Use:

dockerfile
```
Copy code
FROM alpine:latest
```
Alpine is a lightweight Linux distribution (only ~5 MB).

### 2.  Remove Unnecessary Files
Use .dockerignore to exclude files not needed inside the container:

```
.git
node_modules
tmp
*.log
.env
```

### 3.  Combine and Clean Up RUN Layers
Instead of:

dockerfile
```
RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y curl
```
Do this:

dockerfile
```
RUN apt-get update && apt-get install -y \
    python3 \
    curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
 ```
This merges multiple layers and cleans up caches.

### 4. Use Multi-Stage Builds
Multi-stage builds help separate the build environment from the runtime environment, making the final image smaller.

Example:

#### Stage 1: Build stage
```
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main .
```

#### Stage 2: Final stage
```
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
CMD ["./main"]
```
The final image only contains the compiled binary — not the entire Go compiler!

### 5.  Use .dockerignore File
It works like .gitignore and prevents unnecessary files from being copied to the image.

Example .dockerignore:
```
.git
*.log
node_modules
__pycache__
```


### 6.  Use Official Minimal Images

Prefer images like:
```
python:3.12-alpine
node:20-slim
golang:1.21-alpine
debian:bookworm-slim
```



### 7.  Remove Unused Dependencies
Don’t install tools you don’t use inside the container.
Example: If your app doesn’t need curl or vim, don’t install them.

 Practical Example
- Take a Node.js application and compare:

 Before Optimization
Dockerfile:
```
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

$ docker images
REPOSITORY      TAG       SIZE
node-app        latest    1.15GB
 After Optimization
Optimized Dockerfile:
```
# Use smaller base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy only necessary files
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Run app
CMD ["npm", "start"]
```
Result:

$ docker images
REPOSITORY      TAG       SIZE
node-app        latest    184MB
 Image reduced from 1.15 GB → 184 MB (~84% smaller!)

Comparing Performance
```
Metric	Before	After
Image Size	1.15 GB	184 MB
Build Time	2m 45s	40s
Push Time	1m 20s	15s
Pull Time	1m 10s	12s
Startup Time	6s	2s
```




#### Useful Commands Summary
Command	Description
```
docker build -t myapp .	Build the Docker image
docker images	List all images
docker history <image>	Show layer sizes
docker image prune -a	Remove unused images
docker rmi <image>	Remove specific image
docker save -o app.tar myapp	Save image as tar file
docker scan myapp	Scan for vulnerabilities
```
