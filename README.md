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
- At least 4 GB disk space
- Internet access (for Docker and containerlab installation)
- Cisco IOL binary files (see below)

---

## Before You Start: IOL Binary Files

The lab uses Cisco IOL (IOS on Linux) images. These are proprietary Cisco binaries and **cannot be included** in this kit.

You need two files:

| File | Description |
|------|-------------|
| `bin/iol.bin` | IOS on Linux — L3 router image |
| `bin/iol_l2.bin` | IOS on Linux — L2 switch image (filename must contain `l2`) |

Place them in the `bin/` folder before running setup:

```
practice-kit/
├── bin/
│   ├── iol.bin        ← your L3 router image
│   └── iol_l2.bin     ← your L2 switch image
├── configs/
├── setup.sh
└── topology.clab.yml
```

**Where to get them:** Contact your lab administrator or lecturer. Your institution may provide access through its Cisco licensing agreement.

> The filenames don't have to be exactly `iol.bin` / `iol_l2.bin` — the setup script will find them automatically. The L3 image can be any `.bin` or `.image` file in `bin/` that does **not** contain `l2` or `L2` in its name. The L2 image must contain `l2` or `L2` in its filename.

---

## Setup

```bash
bash setup.sh
```

The script will:
1. Detect your OS
2. Install Docker if not present
3. Install containerlab if not present
4. Build the IOL Docker images from your binary files (first run only — takes a few minutes)
5. Deploy the lab
6. Wait for devices to come up
7. Print connection info

The first time you run it, image building takes **3–5 minutes**. Subsequent runs deploy in under a minute.

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

**Docker permission denied**
```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

**containerlab: permission denied**
```bash
sudo containerlab deploy --topo topology.clab.yml --reconfigure
```

**RTR1/SW1 not responding to SSH after setup**
IOL takes 60–90 seconds to fully boot. Wait a moment and try again.

**PC1 SSH fails with "Connection refused"**
The sshd startup in PC1 takes a few seconds. Retry after 10 seconds.

**Images already built but setup is rebuilding them**
The script checks for images named `vrnetlab/cisco_iol:17.16.01a` and `vrnetlab/cisco_iol:L2-17.16.01a`. If those images exist, building is skipped automatically.

---

## Questions

Contact your ANC lab administrator or post in the challenge Discord.
# anc-practice-kit
