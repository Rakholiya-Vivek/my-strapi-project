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
