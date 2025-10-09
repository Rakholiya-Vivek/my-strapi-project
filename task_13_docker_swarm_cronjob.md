# Task 13: Docker Swarm CronJobs

## 📘 Introduction
Docker Swarm does not natively support scheduled (cron-like) jobs. However, this functionality can be achieved using an external service like **crazymax/swarm-cronjob**, which monitors Docker services with specific labels and triggers tasks based on cron expressions.

In this task, we will learn how to set up **Docker Swarm CronJobs** using `crazymax/swarm-cronjob` and verify the results.

---

## ⚙️ Prerequisites
- Docker Engine installed and running.
- Docker Swarm initialized.
- Internet connectivity to pull Docker images.

---

## 🧩 Step 1: Initialize Docker Swarm
```bash
docker swarm init
```
If your Swarm is already initialized, you can verify using:
```bash
docker node ls
```

---

## 🧱 Step 2: Deploy Swarm CronJob Service
Deploy the cronjob manager which listens for cron labels:
```bash
docker service create \
  --name swarm-cronjob \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  crazymax/swarm-cronjob:latest
```
Check if it’s running:
```bash
docker service ls
docker ps
```

📸 *Screenshot Placeholder:* `![Swarm Cronjob Service Running](images/swarm-cronjob-service.png)`

---

## 🕒 Step 3: Create a Scheduled Job Service
Create a Docker service that executes a command periodically (for example, every minute):
```bash
docker service create \
  --name hello-job \
  --label "swarm.cronjob.enable=true" \
  --label "swarm.cronjob.schedule=*/1 * * * *" \
  --label "swarm.cronjob.task.restart-condition=none" \
  alpine:latest sh -c "echo 'Hello from Swarm at $(date)'"
```

📸 *Screenshot Placeholder:* `![Cronjob Created](images/cronjob-create.png)`

---

## 🔍 Step 4: Verify the Job Execution
You can observe containers being created and exited every minute:
```bash
docker ps -a
```

To view output logs of a recent container:
```bash
# Replace <container_id> with actual ID
docker logs <container_id>
```
Example output:
```
Hello from Swarm at Thu Oct 09 11:15:00 UTC 2025
```

📸 *Screenshot Placeholder:* `![Job Execution Logs](images/job-execution-logs.png)`

---

## ⚠️ Step 5: Troubleshooting Tips
If the cronjob does not execute as expected:
- Check if the `swarm-cronjob` service is running:
  ```bash
  docker service ps swarm-cronjob
  ```
- Verify system time:
  ```bash
  timedatectl
  ```
- Ensure labels are correctly added to the service.
- Recreate the job if stuck:
  ```bash
  docker service rm hello-job
  ```

---

## ✅ Step 6: Clean Up
Remove all created services:
```bash
docker service rm hello-job swarm-cronjob
```

---



### ✅ Task Completed: Docker Swarm CronJobs Documentation

