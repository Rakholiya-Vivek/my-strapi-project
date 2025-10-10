# Task 14: Unleash Setup for React Application

## 📘 Introduction
**Unleash** is an open-source **Feature Management and Feature Flag** platform that helps developers control feature rollouts, enable A/B testing, and safely deploy new features in production.  
It allows toggling features **on or off** dynamically without redeploying code — enabling continuous delivery and experimentation.

Then how to:
- Set up **Unleash Server**, **PostgreSQL Database**, and **Unleash Proxy** using Docker.
- Connect it with a **React frontend application** using environment variables.
- Verify that the Unleash setup works locally.

---

## ⚙️ Prerequisites
- Docker & Docker Compose installed.
- Basic knowledge of React environment variables.
- Internet access to pull Docker images.

---

## 🧩 Step 1: Start Unleash Server and Database
Run the following commands to start **PostgreSQL** and **Unleash Server** containers:

```bash
# Create a dedicated directory
mkdir unleash-server && cd unleash-server

# Start PostgreSQL
sudo docker run -d \
  --name unleash-db \
  -e POSTGRES_USER=unleash_user \
  -e POSTGRES_PASSWORD=unleash_pass \
  -e POSTGRES_DB=unleash \
  postgres:15

# Start Unleash Server
sudo docker run -d \
  --name unleash-server \
  -p 4242:4242 \
  -e DATABASE_HOST=unleash-db \
  -e DATABASE_NAME=unleash \
  -e DATABASE_USERNAME=unleash_user \
  -e DATABASE_PASSWORD=unleash_pass \
  --link unleash-db \
  unleashorg/unleash-server
```

- Access the Unleash dashboard at:

 👉 http://<your-server-ip>:4242
    Username: admin
    Password: unleash4all

## 🧱 Step 2: Create API Tokens in Unleash

Inside the Unleash dashboard:

- Go to "API Access" → "New API Token"

- Create two tokens:

- Backend SDK Token → Used by the Unleash Proxy

- Frontend SDK Token → Used by the React app

Example:
        development.6dbbdb100fa1435e79447fb000a513d187c020f9669fe17212b662f1



## ⚙️ Step 3: Run Unleash Proxy

The Unleash Proxy acts as a secure bridge between your frontend and backend.

```bash

sudo docker run -d \
  --name unleash-proxy \
  -p 3000:3000 \
  -e UNLEASH_URL=http://<your-server-ip>:4242/api/ \
  -e UNLEASH_API_TOKEN=development.6dbbdb100fa1435e79447fb000a513d187c020f9669fe17212b662f1 \
  -e UNLEASH_INSTANCE_ID=react-proxy \
  -e UNLEASH_PROXY_CLIENT_KEYS=development.b47b794b4d066014380deb2627f82ad7a35eed585b8f596de85272d7 \
  unleashorg/unleash-proxy

```

- Check logs
    sudo docker logs -f unleash-proxy

- Expected message:
    Unleash-proxy is listening on port 3000!

## ⚛️ Step 4: Configure React Application

- In your React project root, create a .env file:

    REACT_APP_UNLEASH_URL=http://<your-server-ip>:3000/proxy
    REACT_APP_UNLEASH_CLIENT_KEY=development.b47b794b4d066014380deb2627f82ad7a35eed585b8f596de85272d7
    REACT_APP_UNLEASH_APP_NAME=my-react-app

- Then in your unleashClient.js:

```bash

import { UnleashClient } from 'unleash-proxy-client';

const unleash = new UnleashClient({
  url: process.env.REACT_APP_UNLEASH_URL,
  clientKey: process.env.REACT_APP_UNLEASH_CLIENT_KEY,
  appName: process.env.REACT_APP_UNLEASH_APP_NAME,
});

unleash.start();
export default unleash;

```

## 🧪 Step 5: Verify Feature Flags

In the Unleash dashboard, create a New Feature Toggle (e.g., new_feature_toggle).

Enable it for the development environment.

In your React app, use it like this:

```bash

import unleash from './unleashClient';
import { useEffect, useState } from 'react';

function App() {
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    const listener = () => setEnabled(unleash.isEnabled('new_feature_toggle'));
    unleash.on('update', listener);
    return () => unleash.off('update', listener);
  }, []);

  return (
    <div>
      {enabled ? <h2>🚀 New Feature Enabled!</h2> : <h2>🔒 Feature Disabled</h2>}
    </div>
  );
}

export default App;

```

## 🧹 Step 7: Clean Up

To stop and remove all containers:
    sudo docker rm -f unleash-server unleash-db unleash-proxy

