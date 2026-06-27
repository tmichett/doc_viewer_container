# RHCI VT Tools — RHTLC Instructor Guide

**Audience:** Red Hat Certified Instructors teaching VT classes with RHTLC-enabled lab environments  
**RHTLC version:** 5.0.9+ (pre-installed in the container image)  
**Updated:** June 2026

---

## What this toolkit does

RHCI VT Tools gives you a **single container** with everything needed to manage a virtual training class:

- **RHTLC** connections to every student lab (inside the container)
- **Ansible** playbooks for classroom automation
- **Training dashboard** at **https://localhost:8443** with one-click access to each student environment

**Your laptop only needs Podman.** You do not install RHTLC, Ansible, Python, or other VT Tools on the host. Pull the pre-built image from Quay.io, mount two files, and run setup inside the container.

```text
YOUR LAPTOP                         VT TOOLS CONTAINER
───────────                         ──────────────────
Podman                              RHTLC CLI (in image)
RHCI Foundation instructor SSH key  rhtlc connect per student
Instructor Dashboard enrollment CSV Ansible + playbooks
                                    Training dashboard :8443
```

---

## What you need before class

| Item | Source | Typical location |
|------|--------|------------------|
| **Podman** | Install on your laptop | macOS: `brew install podman` then `podman machine start` · Fedora/RHEL: `dnf install podman` · Windows: [Podman Desktop](https://podman-desktop.io/) |
| **Instructor SSH key** | Provided as part of your **RHCI Foundation** build | `~/.ssh/gls_instructor_id_rsa` (Linux/macOS) or `%USERPROFILE%\.ssh\gls_instructor_id_rsa` (Windows) |
| **Enrollment CSV** | Download from the **Instructor Dashboard** for your VT class | Save to a working folder on your laptop (see [Step 1](#step-1--start-the-container-rhtlc-mode)) |
| **Quay.io access** | Red Hat Training registry | Login when prompted on first pull |

### Enrollment CSV

Download the enrollment export from the **Instructor Dashboard** for your offering. For RHTLC-enabled classes, the export includes an **`RHTLC`** column with each student's full OLE lab URL.

Example:

```csv
Name,Username,Email,offeringId,Status,Completed,Public_IP,RHTLC
Jane Doe,jdoe,jdoe@example.com,71416324,attended,,,https://lab-xxx.na100.labs.ole.redhat.com/lab?token=...
```

- Rows **without** an `RHTLC` URL are skipped (use the IP workflow for those students — see [Instructor_User_Guide.md](Instructor_User_Guide.md#workflow-a-ip-address-legacy)).
- **SKU** (connection name) is derived from the `Username` column (sanitized, lowercase).

### Instructor SSH key

Use the **instructor SSH private key** from your **RHCI Foundation** environment. The container uses this key for Ansible and SSH to student classroom and workstation systems. It is **not** the same as your personal Red Hat SSO credentials.

### Labs not yet RHTLC-enabled

If student lab URLs do not connect with RHTLC yet, complete one-time lab enablement first. See the [RHTLC v5.0.9 Quickstart](https://github.com/RedHatTraining/dle-office-hours/blob/main/Docs/RHTLCv5_0_9-Quickstart.md#enabling-rhtlc-on-any-classroom-web-app-environment) in the dle-office-hours documentation.

---

## One-time: get the launch script

Download the management script from the **ws-ole binary repository** into the **same folder** where you save your Instructor Dashboard enrollment CSV (or into a directory on your `PATH`). You do **not** need to clone the RHCIVT_Tools repository for normal classroom use.

| Platform | Download URL |
|----------|--------------|
| **Linux / macOS** | https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.sh |
| **Windows** | https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.ps1 |

### Download and make executable

**Linux / macOS:**

```bash
cd ~/path/to/your-class-enrollments    # folder containing the CSV from Instructor Dashboard
curl -LO https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.sh
chmod +x manage-vt-tools.sh
```

**Windows (PowerShell):**

```powershell
cd C:\path\to\your-class-enrollments   # folder containing the CSV from Instructor Dashboard
curl -LO https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.ps1
```

On Windows, `.ps1` files do not use `chmod`; ensure your execution policy allows running local scripts (e.g. `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` if needed).

### Optional: add to PATH

If the script is on your `PATH`, you can run it **without** `./` (Linux/macOS) or `.\` (Windows).

**Linux / macOS example:**

```bash
sudo cp manage-vt-tools.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/manage-vt-tools.sh
# verify:
manage-vt-tools.sh --help
```

**Windows example:** add the folder containing `manage-vt-tools.ps1` to your user `PATH`, then open a new PowerShell window and run `manage-vt-tools.ps1 -?`.

Whether you use `./manage-vt-tools.sh` or `manage-vt-tools.sh`, always **`cd` to your enrollment CSV folder** before `run --rhtlc` so the CSV and `/mnt` mount resolve correctly.

The script pulls `quay.io/redhattraining/vt-tools:latest` automatically when you run it.

---

## Class day workflow

### Step 1 — Start the container (RHTLC mode)

**Important:** Run the management script from the **directory where your enrollment CSV is stored**. That folder is mounted at `/mnt` inside the container, and the CSV path you enter at the prompt must resolve correctly from that working directory.

**Linux / macOS:**

```bash
cd ~/path/to/your-class-enrollments    # same folder as your CSV file
./manage-vt-tools.sh run --rhtlc      # or: manage-vt-tools.sh run --rhtlc  (if on PATH)
```

**Windows:**

```powershell
cd C:\path\to\your-class-enrollments   # same folder as your CSV file
.\manage-vt-tools.ps1 run -Rhtlc      # or: manage-vt-tools.ps1 run -Rhtlc  (if on PATH)
```

When prompted:

| Prompt | What to provide |
|--------|-----------------|
| **SSH key path** | Path to your RHCI Foundation instructor key (default shown) |
| **Enrollments CSV** | Filename or path to your CSV **relative to the directory above** (e.g. `enrollments.csv` or `./tm-enrollments.csv`) |

The script pulls the image from Quay.io if needed, mounts your files, and opens a shell **inside** the container. A **Next steps** box reminds you to run `ContainerSetupRHTLC`.

**Apple Silicon (M1/M2/M3):** The script uses `linux/amd64` automatically because RHTLC in the image is x86_64. Expect slightly slower performance; functionality is the same.

### Step 2 — Connect all students (inside the container)

```bash
ContainerSetupRHTLC
```

This is where **all RHTLC connections happen**. The script:

1. Configures your instructor SSH key and RHTLC settings
2. For each CSV row with an `RHTLC` URL: disconnects, runs `rhtlc connect`, and **waits until the tunnel is ACTIVE**
3. Builds Ansible inventory at `/tmp/inventory_rhtlc`
4. Runs connectivity tests
5. Starts the training dashboard at **https://localhost:8443**

**First-time authentication:** `rhtlc connect` may prompt for credentials in the container terminal. Complete the login when prompted.

When setup finishes, note the connect summary: `active=N, skipped=N, failed=N`.

**Options:**

```bash
ContainerSetupRHTLC --skip-connect    # Regenerate inventory only (tunnels already ACTIVE)
ContainerSetupRHTLC --no-reconnect  # Keep existing healthy tunnels (same session)
```

### Step 3 — Verify

Inside the container:

```bash
rhtlc list
system-test WORKSTATION
system-test CLASSROOM
system-test SERVERA              # after Add_VM
system-test servera-jescott30    # single host
```

Every expected student SKU should show **ACTIVE** in `rhtlc list` before you run playbooks.

`system-test` wraps `ansible -m ping`. Pass a **group** (`WORKSTATION`, `SERVERA`), a **host name** (`servera-jescott30`), or **`all`**. Defaults to `/tmp/inventory_rhtlc` (or `$ANSIBLE_INVENTORY`). Use `-i` to override. Run `system-test --help` inside the container.

### Step 4 — Open the training dashboard

On your **host browser** (not inside the container):

**https://localhost:8443**

- Each student appears as a card on the hub page.
- Click **Access Dashboard** on an RHTLC card to open that student's classroom UI.
- Links use `https://localhost:8443/classroom/{sku}/v1/login` — proxied through the container. **No browser SOCKS extension required.** (Login first avoids expired-token errors from hitting `/v1/dashboard` directly.)

Accept the self-signed HTTPS certificate if your browser warns about it.

### Step 5 — Work with student environments

Inside the container:

```bash
# SSH to a student workstation
ssh workstation-<sku>

# SSH to classroom VM (instructor user, port 22022)
ssh classroom-<sku>

# Run a playbook
cd Playbooks
ansible-playbook VT_Connect_Test.yml -i /tmp/inventory_rhtlc
```

Replace `<sku>` with the sanitized username from your enrollment CSV (shown in `rhtlc list`).

---

## Day-to-day operations

| Task | Command |
|------|---------|
| Reconnect all students | `ContainerSetupRHTLC` (default disconnects and reconnects each SKU) |
| Check tunnel status | `rhtlc list` |
| Test Ansible reachability | `system-test WORKSTATION`, `system-test CLASSROOM`, `system-test SERVERA`, or `system-test servera-<sku>` (see `system-test --help`) |
| Add an extra lab VM for all students | `Add_VM --vm-name servera --vm-ip 172.25.250.10` (auto-detects RHTLC) or `VT_RHTLC_Add_VM.py` — see [RHTLC_VT_Add_VM.md](RHTLC_VT_Add_VM.md) |
| Regenerate dashboard only | `/opt/TrainingDashboardLocal/generate_dashboard.sh` (auto-detects RHTLC) |

If lab tokens expire or tunnels go **INACTIVE**, re-run `ContainerSetupRHTLC`.

---

## Troubleshooting

| Problem | What to do |
|---------|------------|
| `rhtlc list` shows **INACTIVE** | Re-run `ContainerSetupRHTLC`. If stuck: exit container, `podman volume rm vt-tools-rhtlc-data`, start container again |
| Ansible `Ncat: Proxy connection failed` | SOCKS tunnel is down — check `rhtlc list`, re-run `ContainerSetupRHTLC` |
| Some students reachable, others not | Partial tunnel failure — only ACTIVE SKUs are in inventory; fix failed SKUs and re-run setup |
| Enrollments CSV missing or wrong in container | Run `manage-vt-tools.sh` from the directory where the CSV is stored; enter the correct filename at the prompt |
| `No RHTLC rows` in CSV | Ensure the Instructor Dashboard export includes the `RHTLC` column with full `https://lab-...` URLs |
| Login page loads but submit fails (`POST /v1/login` 404) | Hard-refresh the page; re-run `ContainerSetupRHTLC` to restart `dashboard_server.py` |
| Dashboard HTTP noise in terminal | Access logs go to `/var/log/vt-tools/vt-dashboard.log` (`tail -f /var/log/vt-tools/vt-dashboard.log`). Override: `export VT_DASHBOARD_ACCESS_LOG=/path/to/log` before setup |
| Access Dashboard times out / 502 | Confirm SKU is ACTIVE in `rhtlc list` |
| Permission denied on SSH | Verify Foundation instructor key path; re-run setup |
| Image pull fails | Log in: `podman login quay.io` |
| Slow on Apple Silicon | Expected with amd64 emulation |

Full troubleshooting tables: [Instructor_User_Guide.md](Instructor_User_Guide.md#troubleshooting).

---

## Quick reference

| Item | Value |
|------|-------|
| Container image | `quay.io/redhattraining/vt-tools:latest` |
| Start (RHTLC) | `cd` to enrollment CSV folder; `manage-vt-tools.sh run --rhtlc` (or `./manage-vt-tools.sh` if not on PATH) |
| Launch script URLs | [manage-vt-tools.sh](https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.sh) · [manage-vt-tools.ps1](https://pypi.apps.tools.dev.nextcle.com/repository/ws-ole/binary/manage-vt-tools.ps1) |
| Setup (inside container) | `ContainerSetupRHTLC` |
| Ansible inventory | `/tmp/inventory_rhtlc` |
| RHTLC state volume | `vt-tools-rhtlc-data` → `/home/vtuser/.rhtlc` |
| Training dashboard | `https://localhost:8443` |
| Student classroom (RHTLC) | `https://localhost:8443/classroom/{sku}/v1/login` |
| Dashboard access log | `/var/log/vt-tools/vt-dashboard.log` (`VT_DASHBOARD_ACCESS_LOG`) |
| Lab analyzer | `https://localhost:8501` |
| Max concurrent tunnels | ~20 |
| SSH patterns | `workstation-{sku}`, `classroom-{sku}`, `{vm}-{sku}` |

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [Instructor_User_Guide.md](Instructor_User_Guide.md) | Full guide including IP (legacy) workflow |
| [RHTLC_vs_IP_Workflow.md](RHTLC_vs_IP_Workflow.md) | When to use RHTLC vs `Public_IP` |
| [Container_RHTLC_Run_Playbooks.md](Container_RHTLC_Run_Playbooks.md) | Playbook examples inside the container |
| [Instructor_Ansible_Developer_Guide.md](Instructor_Ansible_Developer_Guide.md) | Custom playbooks, inventory, file copy, Python + Ansible |
| [RHTLC_VT_Add_VM.md](RHTLC_VT_Add_VM.md) | Add extra lab systems per student |
| [RHTLC v5.0.9 Quickstart](https://github.com/RedHatTraining/dle-office-hours/blob/main/Docs/RHTLCv5_0_9-Quickstart.md) | Standalone RHTLC client and legacy lab enablement |

---

## Appendix A — Building the image locally (developers only)

Instructors should use the pre-built registry image. Build locally only if you are developing or testing changes to VT Tools.

```bash
git clone https://github.com/tmichett/RHCIVT_Tools.git
cd RHCIVT_Tools/Container
./build-vt-tools.sh build
./build-vt-tools.sh run --rhtlc
# inside container:
ContainerSetupRHTLC
```

To publish: `./push-vt-tools.sh` (requires Quay.io write access).

---

## Appendix B — Platform notes

### macOS

```bash
brew install podman
podman machine init    # first time only
podman machine start
cd ~/path/to/your-class-enrollments
manage-vt-tools.sh run --rhtlc    # or ./manage-vt-tools.sh if not on PATH
```

### Windows

Use Podman Desktop or WSL2 with Podman. Open PowerShell in the **folder containing your enrollment CSV**, then run `manage-vt-tools.ps1 run -Rhtlc` (or `.\manage-vt-tools.ps1` if not on PATH).

### Fedora / RHEL

```bash
sudo dnf install podman
cd ~/path/to/your-class-enrollments
manage-vt-tools.sh run --rhtlc    # or ./manage-vt-tools.sh if not on PATH
```

---

## Appendix C — CSV column reference

| Column | RHTLC workflow |
|--------|----------------|
| `Username` | Required — becomes connection SKU |
| `RHTLC` | Required — full OLE lab URL per student |
| `Public_IP` | Ignored in RHTLC-only workflow |
| Other columns | Passed through; not used for connectivity |

Sample file in the repository: `Python/enrollments-rhtlc.sample.csv`.
