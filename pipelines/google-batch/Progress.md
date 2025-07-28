## 🧭 GCP Tracer Boot Image Setup (Phase 1)

This guide documents how to create a custom GCP boot image with the Tracer client preinstalled and auto-started using `systemd`. The goal is to support Tracer usage in GCP Batch environments (e.g., for Nextflow pipelines like FastQuorum).

---

### ✅ Phase 1: Prepare the GCP VM

1. **Create a VM (Debian or Ubuntu)**
   Launch a new Compute Engine VM with sufficient permissions and SSH access.

2. **Install Tracer Client**

   Inside the VM:

   ```bash
   curl -sSL https://install.tracer.cloud | bash
   ```

   This installs the Tracer binary into `/usr/local/bin/tracer`.

---

### ✅ Phase 2: Setup `systemd` for Auto-Init

Create the file `/etc/systemd/system/tracer.service`:

```ini
[Unit]
Description=Tracer Init on Boot
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true
EnvironmentFile=/etc/tracer.env
ExecStart=/usr/local/bin/tracer-bootstrap.sh
ExecStop=/usr/local/bin/tracer terminate
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tracer.service
```

---

### ✅ Phase 3: Create Bootstrap Script

Create the file `/usr/local/bin/tracer-bootstrap.sh`:

```bash
#!/bin/bash
set -e

echo "Installing tracer..." | tee -a /var/log/tracer.log
curl -sSL https://install.tracer.cloud | bash >> /var/log/tracer.log 2>&1

# Optionally derive a dynamic run name
BASE_RUN_NAME="${TRACER_RUN_NAME:-run}"
INSTANCE_ID=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H "Metadata-Flavor: Google")
TRACER_RUN_NAME="${BASE_RUN_NAME}__${INSTANCE_ID}.batch"

echo "Running tracer init..." | tee -a /var/log/tracer.log
TRACER_PIPELINE_NAME="${TRACER_PIPELINE_NAME:-TestGCPBoot}" \
TRACER_ENVIRONMENT="${TRACER_ENVIRONMENT:-gcp_batch}" \
TRACER_PIPELINE_TYPE="${TRACER_PIPELINE_TYPE:-rnaseq}" \
TRACER_USER_ID="${TRACER_USER_ID:-gcp_batch}" \
TRACER_RUN_NAME="${TRACER_RUN_NAME}" \
tracer init --non-interactive >> /var/log/tracer.log 2>&1
```

Make it executable:

```bash
chmod +x /usr/local/bin/tracer-bootstrap.sh
```

---

### ✅ Phase 4: Environment Variables

Create the file `/etc/tracer.env` with:

```env
TRACER_PIPELINE_NAME=PipelineName
TRACER_ENVIRONMENT=gcp_batch
TRACER_PIPELINE_TYPE=rnaseq
TRACER_USER_ID=gcp_batch
TRACER_RUN_NAME=debug-run
```

> ✅ You can change these at any time before snapshotting the image or let Terraform override them dynamically.

---

### 🔄 Optional: Test + Stop

To test:

```bash
sudo systemctl start tracer.service
journalctl -u tracer.service -f
```

To gracefully shut down Tracer:

```bash
sudo systemctl stop tracer.service
```

---

## 🚀 What's Next

### 🧱 Step 1: Create Custom Image

After everything is tested and working:

```bash
gcloud compute images create tracer-boot-image \
  --source-disk=tracer-image-builder \
  --source-disk-zone=us-central1-a \
  --family=tracer-base \
  --guest-os-features=GVNIC
```

---

### 📦 Step 2: Update Terraform Script

Update your `Terraform` config to use:

```hcl
bootDisk {
  image = "projects/<your-project-id>/global/images/tracer-boot-image"
}
```

Ensure you pass `tracer_env_vars` via container job creation (which is already in your existing script). These will override the default `/etc/tracer.env` values inside the boot image.

---



```
# 1. Write the tracer bootstrap script
sudo tee /usr/local/bin/tracer-bootstrap.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

echo "Installing tracer..." | tee -a /var/log/tracer.log
curl -sSL https://install.tracer.cloud | bash >> /var/log/tracer.log 2>&1

# Optionally derive a dynamic run name
BASE_RUN_NAME="${TRACER_RUN_NAME:-run}"
INSTANCE_ID=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H "Metadata-Flavor: Google")
TRACER_RUN_NAME="${BASE_RUN_NAME}__${INSTANCE_ID}.batch"

echo "Running tracer init..." | tee -a /var/log/tracer.log
TRACER_PIPELINE_NAME="${TRACER_PIPELINE_NAME:-TestGCPBoot}" \
TRACER_ENVIRONMENT="${TRACER_ENVIRONMENT:-gcp_batch}" \
TRACER_PIPELINE_TYPE="${TRACER_PIPELINE_TYPE:-rnaseq}" \
TRACER_USER_ID="${TRACER_USER_ID:-gcp_batch}" \
TRACER_RUN_NAME="${TRACER_RUN_NAME}" \
tracer init --non-interactive >> /var/log/tracer.log 2>&1
EOF

sudo chmod +x /usr/local/bin/tracer-bootstrap.sh

# 2. Create the tracer systemd service
sudo tee /etc/systemd/system/tracer.service > /dev/null <<'EOF'
[Unit]
Description=Tracer Init on Boot
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true
EnvironmentFile=/etc/tracer.env
ExecStart=/usr/local/bin/tracer-bootstrap.sh
ExecStop=/usr/local/bin/tracer terminate
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 3. Create the env file (can be edited anytime)
sudo tee /etc/tracer.env > /dev/null <<'EOF'
TRACER_PIPELINE_NAME=TestBatchGCPImpl
TRACER_ENVIRONMENT=gcp_batch
TRACER_PIPELINE_TYPE=rnaseq
TRACER_USER_ID=gcp_batch
TRACER_RUN_NAME=run
EOF

# 4. Reload systemd and start tracer
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable tracer.service
sudo systemctl start tracer.service
sudo systemctl status tracer.service
sudo systemctl stop tracer.service

```