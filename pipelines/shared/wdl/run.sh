#!/bin/bash
set -e

install_pixi() {
    echo "Pixi not found. Installing Pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
    echo "Pixi installed successfully!"
}

if ! command -v pixi &> /dev/null; then
    install_pixi
fi

if [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if [ -f "$SHELL_PROFILE" ]; then
    echo "Sourcing $SHELL_PROFILE before running pixi..."
    source "$SHELL_PROFILE"
fi

mkdir -p data

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Attempting to install..."
  if [ "$(uname)" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      brew install --cask docker
      echo "Please start Docker Desktop manually on macOS."
    else
      echo "Homebrew not found. Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop/"
    fi
  elif [ -f /etc/debian_version ]; then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \ \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  elif [ -f /etc/redhat-release ]; then
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
  else
    echo "Unsupported OS for automatic Docker installation. Please install Docker manually."
  fi
fi


if command -v docker >/dev/null 2>&1; then
  if ! groups $USER | grep -q '\bdocker\b'; then
    echo "Adding $USER to docker group (you may need to log out and back in for this to take effect)"
    sudo usermod -aG docker $USER
  fi
fi

if [ ! -f data/sample_R1.fastq ]; then
  echo -e "@SEQ_ID\nGATTTGGGGTTTAAAGGG\n+\n!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65" > data/sample_R1.fastq
fi
if [ ! -f data/sample_R2.fastq ]; then
  echo -e "@SEQ_ID\nCCCTTTAAACCCCAAATC\n+\n!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65" > data/sample_R2.fastq
fi

if [ ! -f data/test.bam ]; then
    pixi run samtools faidx data/genome.fa
    REFNAME=$(head -1 data/genome.fa | sed 's/>//')
    echo -e "@HD\tVN:1.0\tSO:unsorted\n@SQ\tSN:${REFNAME}\tLN:1000\nread1\t0\t${REFNAME}\t1\t255\t10M\t*\t0\t0\tACGTACGTAC\t*" > data/minimal.sam
    pixi run samtools view -bS data/minimal.sam > data/test.bam
    rm data/minimal.sam
  else
    echo "Reference genome data/genome.fa not found. Cannot create test.bam."
    exit 1
fi


echo "Running Tracer WDL Minimal pipeline with miniwdl"
pixi run pipeline