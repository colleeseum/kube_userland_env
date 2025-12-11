#!/bin/bash -x

CWD=`pwd`

# ------------------------------------------------------------------------------
# Check if user is running against a private AKS where kubectl/helm will fail
# ------------------------------------------------------------------------------
if [ "$ACC_CLOUD" != "" ]; then
    echo "You appear to be using Azure ACC_CLOUD mode."

    echo ""
    echo "Are you using a *private AKS* cluster?"
    echo "If YES, kubectl and helm commands will NOT work from here because:"
    echo "  - kubectl cannot reach the private API endpoint"
    echo "  - helm will also fail"
    echo ""
    echo "Proceed anyway? [Y/n] "

    read -r ans
    ans="${ans:-Y}"

    case "$ans" in
        [Yy]*)
            echo "Continuing..."
            ;;
        [Nn]*)
            echo "Aborting setup by user request."
            exit 1
            ;;
        *)
            echo "Invalid choice. Aborting."
            exit 1
            ;;
    esac
fi

mkdir -p ~/bin

# --- Detect OS (your block, unchanged) ---
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    EXT=""
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
    EXT=""
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Git Bash or Cygwin on Windows
    OS="windows"
    EXT=".exe"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi


# --- Detect ARCH (Helm expects 'amd64' or 'arm64') ---
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

if ! type kubectl &> /dev/null; then
	# Get latest stable version
	KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
	echo "Installing kubectl version: $KUBECTL_VERSION"

	# Create bin directory if it doesn't exist
	mkdir -p "$HOME/bin"

	# Download correct binary
	URL="https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${OS}/amd64/kubectl${EXT}"

	echo "Downloading: $URL"
	curl -Lo "$HOME/bin/kubectl${EXT}" "$URL"

	# Make executable (safe on Windows too)
	chmod +x "$HOME/bin/kubectl${EXT}"

	echo "kubectl installed at $HOME/bin/kubectl${EXT}"
fi

if ! type kubectx &> /dev/null; then
	git clone https://github.com/ahmetb/kubectx.git /tmp/kubectx

	cp /tmp/kubectx/kubectx ~/bin/kubectx
	cp /tmp/kubectx/kubens ~/bin/kubens
fi

if ! type kubetail &> /dev/null; then
	cd ~/bin
	curl -Lo ~/bin/kubetail https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
	chmod a+x kubetail
	cd $CWD
fi

if ! type k9s &> /dev/null; then
    echo "Installing k9s..."

    # Latest version
    K9S_VERSION=$(
        curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
        | grep '"tag_name"' | head -n1 | cut -d'"' -f4
    )

    if [ -z "$K9S_VERSION" ]; then
        echo "Unable to determine latest k9s version from GitHub."
        exit 1
    fi

    # Convert your existing OS (linux/darwin/windows) → Linux/Darwin/Windows
    K9S_OS="$(printf '%s' "$OS" | sed 's/.*/\u&/')"

    if [[ "$OS" == "windows" ]]; then
        K9S_ARCHIVE_EXT="zip"
    else
        K9S_ARCHIVE_EXT="tar.gz"
    fi

    ARCHIVE="k9s_${K9S_OS}_${ARCH}.${K9S_ARCHIVE_EXT}"
    URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${ARCHIVE}"

    echo "Downloading k9s from: $URL"

    mkdir -p "$HOME/bin"
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"

    if ! curl -fsSL -o "$ARCHIVE" "$URL"; then
        echo "Download failed"
        cd "$CWD"
        rm -rf "$TMPDIR"
        exit 1
    fi

    if [[ "$K9S_ARCHIVE_EXT" == "zip" ]]; then
        unzip -qo "$ARCHIVE" || { echo "Extract failed"; cd "$CWD"; rm -rf "$TMPDIR"; exit 1; }
    else
        tar -xzf "$ARCHIVE" || { echo "Extract failed"; cd "$CWD"; rm -rf "$TMPDIR"; exit 1; }
    fi

    # k9s or k9s.exe depending on OS
    SRC_BIN="k9s"
    [ -f k9s.exe ] && SRC_BIN="k9s.exe"

    mv "$SRC_BIN" "$HOME/bin/k9s${EXT}"
    chmod +x "$HOME/bin/k9s${EXT}"

    cd "$CWD"
    rm -rf "$TMPDIR"

    echo "k9s installed at $HOME/bin/k9s${EXT}"
fi



if ! type helm &> /dev/null; then
	cd /tmp


	# --- Get latest Helm version ---
	HELM_VERSION=$(
	    curl -s https://api.github.com/repos/helm/helm/releases/latest \
	    | grep '"tag_name"' | head -n1 | cut -d'"' -f4
	)


	# --- Install directory ---
	mkdir -p "$HOME/bin"


	# --- Download Helm depending on OS ---
	if [[ "$OS" == "windows" ]]; then
	    echo "Detected Git Bash on Windows --> using ZIP package"

	    TMPDIR=$(mktemp -d)
	    URL="https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${ARCH}.zip"

	    echo "Downloading: $URL"
	    curl -fsSL -o "$TMPDIR/helm.zip" "$URL"

	    (cd "$TMPDIR" && unzip -q helm.zip)

	    mv "$TMPDIR/windows-${ARCH}/helm.exe" "$HOME/bin/helm.exe"
	    echo "Helm installed --> $HOME/bin/helm.exe"

	else
	    echo "Detected $OS --> using tar.gz package"

	    URL="https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz"

	    echo "Downloading: $URL"
	    curl -fsSL -o helm.tar.gz "$URL"

	    tar -xzf helm.tar.gz

	    mv "${OS}-${ARCH}/helm" "$HOME/bin/helm"
	    chmod +x "$HOME/bin/helm"

	    echo "Helm installed --> $HOME/bin/helm"
	fi

fi

if ! type mo &> /dev/null; then
	curl -Lo ~/bin/mo https://raw.githubusercontent.com/tests-always-included/mo/master/mo
	chmod +x ~/bin/mo
fi

if ! type terraform &> /dev/null; then
    echo "Installing Terraform..."

    TF_VERSION=$(
        curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest \
        | grep '"tag_name"' | head -n1 | cut -d'"' -f4 | sed 's/^v//'
    )

    if [ -z "$TF_VERSION" ]; then
        echo "Failed to detect latest Terraform release."
        exit 1
    fi

    mkdir -p "$HOME/bin"

    TMPDIR=$(mktemp -d)
    TF_ZIP="${TMPDIR}/terraform.zip"
    TF_URL="https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${OS}_${ARCH}.zip"

    echo "Downloading Terraform ${TF_VERSION} from: $TF_URL"
    if ! curl -fsSL -o "$TF_ZIP" "$TF_URL"; then
        echo "Download failed."
        rm -rf "$TMPDIR"
        exit 1
    fi

    if ! unzip -qo "$TF_ZIP" -d "$TMPDIR"; then
        echo "Failed to unzip Terraform package."
        rm -rf "$TMPDIR"
        exit 1
    fi

    SRC_TF="${TMPDIR}/terraform${EXT}"
    if [ ! -f "$SRC_TF" ]; then
        echo "Terraform binary ${SRC_TF} not found after extraction."
        rm -rf "$TMPDIR"
        exit 1
    fi

    mv "$SRC_TF" "$HOME/bin/terraform${EXT}"
    chmod +x "$HOME/bin/terraform${EXT}"
    rm -rf "$TMPDIR"

    echo "Terraform installed at $HOME/bin/terraform${EXT}"
fi

if ! type zsh  &> /dev/null; then
	if [ ! -d ~/.oh-my-bash ]; then
		curl -fsSL -o /tmp/install-ohmybash.sh https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh
		sed -i 's/exec bash/echo ""/' /tmp/install-ohmybash.sh
		bash /tmp/install-ohmybash.sh
		grep -q 'plugins=.*kubectl' ~/.bashrc || sed -i 's/^plugins=(\(.*\))/plugins=(\1 kubectl)/' ~/.bashrc
		echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
		~/bin/helm completion bash >> ~/.bash_helm_completion

		ln -s $CWD/../infra/env.sh ~/.env
		echo 'source ~/.env' >> ~/.bashrc

		if [ ! -f ~/.jfrog ]; then
			read -p 'Please enter you jFrog username: ' JFROG_USER
			read -sp 'Please enter your jFrog password: ' JFROG_PWD
			echo ""
			echo "export JFROG_USER=$JFROG_USER" > ~/.jfrog
			echo "export JFROG_PWD=$JFROG_PWD" >> ~/.jfrog
		fi

		read -p 'Do you wish to use tmux? (y/n): ' yn
		
		if [[ "$yn" == [Yy] ]]; then
			ln -sf $CWD/start_tmux ~/.start_tmux
			ln -sf $CWD/tmux.conf ~/.tmux.conf
		fi
		ln -sf $CWD/kubectl.bash ~/.kubectl.bash

		echo 'source ~/.kubectl.bash' >> ~/.bashrc
		echo 'source ~/.start_tmux' >> ~/.bashrc
		exec bash 
	fi
else 
	if [ ! -d ~/.oh-my-zsh ]; then
		# Install oh-my-zsh without auto-switching the shell
		curl -fsSL -o /tmp/install-ohmyzsh.sh \
		https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

		# Prevent the script from running "exec zsh -l" at the end
		sed -i 's/exec zsh -l/echo ""/' /tmp/install-ohmyzsh.sh

		# Run installer (CHSH/RUNZSH disabled so it just installs files)
		ZSH=~/.oh-my-zsh RUNZSH=no CHSH=no KEEP_ZSHRC=no bash /tmp/install-ohmyzsh.sh

		----------------------------------------
		# Install Powerlevel10k
		# ----------------------------------------
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
		${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k


		sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
 
		# add kubectl + helm if not already present
		sed -i 's/plugins=(\(.*\))/plugins=(\1 kubectl helm)/' ~/.zshrc



		# Basic PATH + completions
		echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc

		# Project env file
		ln -s "$CWD/../infra/env.sh" ~/.env 2>/dev/null || true
		echo 'source ~/.env' >> ~/.zshrc

		# JFrog credentials
		if [ ! -f ~/.jfrog ]; then
			read -p 'Please enter your jFrog username: ' JFROG_USER
			read -sp 'Please enter your jFrog password: ' JFROG_PWD
			echo ""
			{
			echo "export JFROG_USER=$JFROG_USER"
			echo "export JFROG_PWD=$JFROG_PWD"
			} > ~/.jfrog
		fi
		# (optional) source it automatically
		grep -q 'source ~/.jfrog' ~/.zshrc 2>/dev/null || echo 'source ~/.jfrog' >> ~/.zshrc

		# Optional tmux integration
		read -p 'Do you wish to use tmux? (y/n): ' yn
		if [[ "$yn" == [Yy] ]]; then
			# zsh_tmux can be identical to your bash_tmux contents
			ln -sf "$CWD/start_tmux" ~/.start_tmux
			ln -sf "$CWD/tmux.conf" ~/.tmux.conf
			echo 'source ~/.start_tmux' >> ~/.zshrc
		fi

		if [ "$ACC_CLOUD" != "" ]; then
			ln -sf "$CWD/bash2zshrc" ~/.bash2zshrc
			echo 'source ~/.bash2zshrc' >> ~/.bashrc
		fi

		exec zsh
	fi
fi
