#!/bin/bash
set -e

# ─────────────────────────────────────────────
#  ANC Practice Kit — Setup Script
#  The Adebayo Network Challenge
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

CLAB_VERSION="0.74.3"
L3_IMAGE="vrnetlab/cisco_iol:17.16.01a"
L2_IMAGE="vrnetlab/cisco_iol:L2-17.16.01a"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
error()  { echo -e "${RED}[✗]${NC} $*"; }
info()   { echo -e "${BLUE}[i]${NC} $*"; }
header() { echo -e "\n${BOLD}$*${NC}"; }

# ─── OS Detection ───────────────────────────

detect_os() {
    header "Detecting environment..."
    case "$OSTYPE" in
        linux-gnu*)
            OS="linux"
            if command -v apt-get &>/dev/null; then PKG="apt"; fi
            if command -v dnf &>/dev/null;     then PKG="dnf"; fi
            if command -v yum &>/dev/null;     then PKG="yum"; fi
            log "Linux detected (package manager: ${PKG:-unknown})"
            ;;
        darwin*)
            OS="macos"
            log "macOS detected"
            ;;
        msys*|cygwin*|win32*)
            error "Windows is not directly supported."
            echo "  Please install WSL2 (Windows Subsystem for Linux) and re-run this script inside it."
            echo "  Guide: https://learn.microsoft.com/en-us/windows/wsl/install"
            exit 1
            ;;
        *)
            error "Unrecognised OS: $OSTYPE"
            exit 1
            ;;
    esac
}

# ─── Docker ─────────────────────────────────

check_docker() {
    header "Checking Docker..."
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        log "Docker is running ($(docker --version | cut -d' ' -f3 | tr -d ','))"
        return 0
    fi

    if command -v docker &>/dev/null; then
        warn "Docker is installed but not running. Attempting to start..."
        sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
        if docker info &>/dev/null 2>&1; then
            log "Docker started successfully"
            return 0
        fi
    fi

    warn "Docker not found. Installing..."
    install_docker
}

install_docker() {
    if [ "$OS" = "linux" ]; then
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        sudo systemctl enable docker
        sudo systemctl start docker
        # Allow current session to use docker without re-login
        if ! docker info &>/dev/null 2>&1; then
            warn "You may need to log out and back in for docker group permissions."
            warn "For now, continuing with sudo..."
            DOCKER_CMD="sudo docker"
        fi
        log "Docker installed"
    elif [ "$OS" = "macos" ]; then
        error "Docker not found on macOS."
        echo "  Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
        echo "  Then re-run this script."
        exit 1
    fi
}

DOCKER_CMD="${DOCKER_CMD:-docker}"

# ─── Containerlab ───────────────────────────

check_containerlab() {
    header "Checking containerlab..."
    if command -v containerlab &>/dev/null; then
        INSTALLED=$(containerlab version 2>/dev/null | grep -oP 'version\s+\K[\d.]+' | head -1)
        log "containerlab ${INSTALLED} found"
        return 0
    fi

    warn "containerlab not found. Installing..."
    install_containerlab
}

install_containerlab() {
    if [ "$OS" = "linux" ]; then
        bash -c "$(curl -sL https://get.containerlab.dev)" -- -v "$CLAB_VERSION"
        log "containerlab installed"
    elif [ "$OS" = "macos" ]; then
        if command -v brew &>/dev/null; then
            brew install containerlab
            log "containerlab installed via Homebrew"
        else
            error "Homebrew not found on macOS."
            echo "  Install Homebrew first: https://brew.sh"
            echo "  Then re-run this script."
            exit 1
        fi
    fi
}

# ─── IOL Docker Images ──────────────────────

check_images() {
    header "Checking Cisco IOL Docker images..."

    L3_OK=false
    L2_OK=false

    $DOCKER_CMD image inspect "$L3_IMAGE" &>/dev/null 2>&1 && L3_OK=true
    $DOCKER_CMD image inspect "$L2_IMAGE" &>/dev/null 2>&1 && L2_OK=true

    if $L3_OK && $L2_OK; then
        log "IOL images found: $L3_IMAGE, $L2_IMAGE"
        return 0
    fi

    warn "One or more IOL images are missing. Attempting to load from tarballs..."
    load_images
}

load_images() {
    L3_TAR="$SCRIPT_DIR/images/iol-l3.tar"
    L2_TAR="$SCRIPT_DIR/images/iol-l2.tar"

    if [ ! -f "$L3_TAR" ] || [ ! -f "$L2_TAR" ]; then
        echo ""
        error "Docker image tarballs not found in ./images/"
        echo ""
        echo "  This lab requires pre-built Cisco IOL Docker images."
        echo "  These are provided as .tar files and must be downloaded separately."
        echo ""
        echo "  ── How to obtain them ──────────────────────────────────────────────────"
        echo "  Download 'iol-l3.tar' and 'iol-l2.tar' from the link provided by"
        echo "  your lab administrator or lecturer."
        echo ""
        echo "  Place the files in the images/ folder like this:"
        echo ""
        echo "    images/"
        echo "    ├── iol-l3.tar     ← L3 router image"
        echo "    └── iol-l2.tar     ← L2 switch image"
        echo ""
        echo "  Then re-run: bash setup.sh"
        echo ""
        exit 1
    fi

    log "Found image tarballs. Loading into Docker..."
    if ! $L3_OK; then
        log "Loading L3 image from $(basename "$L3_TAR")..."
        $DOCKER_CMD load -i "$L3_TAR"
    fi
    if ! $L2_OK; then
        log "Loading L2 image from $(basename "$L2_TAR")..."
        $DOCKER_CMD load -i "$L2_TAR"
    fi

    # Final verification
    $DOCKER_CMD image inspect "$L3_IMAGE" &>/dev/null 2>&1 && L3_OK=true
    $DOCKER_CMD image inspect "$L2_IMAGE" &>/dev/null 2>&1 && L2_OK=true

    if $L3_OK && $L2_OK; then
        log "Images loaded successfully."
    else
        error "Failed to load images from tarballs. Check for errors above."
        exit 1
    fi
}

# ─── Deploy Lab ─────────────────────────────

deploy_lab() {
    header "Deploying practice lab..."

    cd "$SCRIPT_DIR"

    # Tear down any existing instance first
    if $DOCKER_CMD ps --format '{{.Names}}' 2>/dev/null | grep -q "clab-anc-practice"; then
        warn "Existing lab found. Removing it first..."
        sudo containerlab destroy --topo topology.clab.yml --cleanup 2>/dev/null || true
    fi

    sudo containerlab deploy --topo topology.clab.yml --reconfigure

    log "Lab deployed"
}

# ─── Wait for Devices ───────────────────────

wait_for_devices() {
    header "Waiting for devices to come up..."
    echo "  (IOL can take 60–90 seconds to fully boot)"

    local timeout=120
    local elapsed=0

    until sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        admin@172.31.31.11 "show version" &>/dev/null 2>&1; do
        printf "."
        sleep 5
        elapsed=$((elapsed + 5))
        if [ $elapsed -ge $timeout ]; then
            echo ""
            warn "RTR1 is taking longer than expected — it may still be booting."
            warn "Try SSHing in a moment: ssh admin@172.31.31.11"
            return
        fi
    done
    echo ""
    log "Devices are ready"
}

# ─── Print Connection Info ──────────────────

print_info() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ANC Practice Lab — Ready                  ${NC}"
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
    echo ""
    echo "  Connect via SSH from your terminal:"
    echo ""
    echo -e "  ${BOLD}RTR1${NC}  (IOS-XE Router) "
    echo "    ssh admin@172.31.31.11    password: admin"
    echo ""
    echo -e "  ${BOLD}SW1${NC}   (IOS-XE Switch)"
    echo "    ssh admin@172.31.31.21    password: admin"
    echo ""
    echo -e "  ${BOLD}PC1${NC}   (Linux — netshoot)"
    echo "    ssh root@172.31.31.31     password: admin"
    echo ""
    echo "  To stop the lab:"
    echo "    sudo containerlab destroy --topo topology.clab.yml --cleanup"
    echo ""
    echo "  To restart it:"
    echo "    bash setup.sh"
    echo ""
}

# ─── sshpass check ──────────────────────────

ensure_sshpass() {
    if ! command -v sshpass &>/dev/null; then
        if [ "$OS" = "linux" ]; then
            case "$PKG" in
                apt) sudo apt-get install -y sshpass &>/dev/null ;;
                dnf) sudo dnf install -y sshpass &>/dev/null ;;
                yum) sudo yum install -y sshpass &>/dev/null ;;
            esac
        elif [ "$OS" = "macos" ]; then
            brew install hudochenkov/sshpass/sshpass &>/dev/null || true
        fi
    fi
}

# ─── Main ───────────────────────────────────

main() {
    echo ""
    echo -e "${BOLD}  The Adebayo Network Challenge — Practice Kit${NC}"
    echo -e "  Setting up your lab environment..."
    echo ""

    detect_os
    check_docker
    check_containerlab
    check_images
    ensure_sshpass
    deploy_lab
    wait_for_devices
    print_info
}

main
