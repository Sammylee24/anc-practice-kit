# ANC Practice Kit
## The Adebayo Network Challenge — Pre-Challenge Environment

This kit gives you a working lab environment identical in technology to the actual challenge. Use it to get comfortable with the topology, tools, and SSH workflow before challenge day.

---

## What's Inside

| Device | Role | Management IP |
|--------|------|---------------|
| RTR1   | IOS-XE Router | 172.31.31.11 |
| SW1    | IOS-XE L2 Switch | 172.31.31.21 |
| PC1    | Linux host (netshoot) | 172.31.31.31 |

Connections:
```
RTR1 Ethernet0/1 ── SW1 Ethernet0/1
SW1  Ethernet0/2 ── PC1 eth1
```

---

## System Requirements

- **Linux** (Ubuntu 20.04+, Debian 11+, Fedora, RHEL/CentOS 8+)
  or **macOS** (with Homebrew)
- **Windows**: Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and run everything inside it
- At least 4 GB RAM free
- At least 5 GB disk space (for the Docker images)
- Internet access (for initial Docker/containerlab installation)
- The two required Cisco IOL Docker image tarballs (see below)

---

## Before You Start: IOL Docker Images

The lab uses Cisco IOL (IOS on Linux) images, which are proprietary and cannot be included in this kit. For this practice lab, they are distributed as Docker images packaged into `.tar` files.

You need two files:

| File | Description |
|------|-------------|
| `images/iol-l3.tar` | L3 Router Image (`adebayyo/cisco_iol:17.16.01a`) |
| `images/iol-l2.tar` | L2 Switch Image (`adebayyo/cisco_iol:L2-17.16.01a`) |

**How to get them:**
Download `iol-l3.tar` and `iol-l2.tar` from the link provided by your lab administrator or lecturer.

Place them in the `images/` folder before running setup:

```
practice-kit/
├── images/
│   ├── iol-l3.tar     ← L3 router image tarball
│   └── iol-l2.tar     ← L2 switch image tarball
├── configs/
├── setup.sh
└── topology.clab.yml
```

---

## Setup

```bash
bash setup.sh
```

The script will automatically:
1. Detect your OS.
2. Install Docker if not present.
3. Install `containerlab` if not present.
4. Load the IOL Docker images from the `.tar` files in `images/` (first run only).
5. Deploy the lab topology.
6. Wait for devices to boot.
7. Print connection info.

The first time you run it, loading the images might take a minute. Subsequent runs that deploy in under 30 seconds.

---

## Connecting to Devices

All credentials: **admin / admin** (or **root / admin** for PC1)

```bash
# Router
ssh admin@172.31.31.11

# Switch
ssh admin@172.31.31.21

# Linux PC
ssh root@172.31.31.31
```

Devices boot with only SSH access configured. Everything else is yours to build.

---

## Stopping the Lab

```bash
sudo containerlab destroy --topo topology.clab.yml --cleanup
```

## Restarting the Lab

```bash
bash setup.sh
```

> Note: Each restart reloads devices from their startup config. Any configuration you applied in the previous session will be lost unless you saved it with `write memory` (IOS) — but even then, the container is recreated from the base image on restart. Use the practice kit to build muscle memory, not to save progress.

---

## Troubleshooting

**`setup.sh` fails with "Docker image tarballs not found"**
Ensure that you have downloaded `iol-l3.tar` and `iol-l2.tar` and placed them correctly inside the `images/` directory.

**Docker permission denied**
If you see this error when running `setup.sh`, you may need to log out and back in for the `docker` group permissions to apply to your user. Alternatively, run the script with `sudo`: `sudo bash setup.sh`.

**containerlab: permission denied**
Run containerlab commands with `sudo`, for example:
```bash
sudo containerlab destroy --topo topology.clab.yml --cleanup
```

**RTR1/SW1 not responding to SSH after setup**
IOL can take 60–90 seconds to fully boot. The script waits for them, but if it timed out, just wait another minute and try connecting again.

**PC1 SSH fails with "Connection refused"**
The `sshd` service inside the PC1 container takes a few seconds to start. Retry after 10 seconds.

---

## Questions

Contact your ANC lab administrator or post in the challenge Discord.
# anc-practice-kit
