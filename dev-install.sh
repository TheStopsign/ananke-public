#!/usr/bin/env zsh
set -eu
set +x

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="${PATH:+"$PATH:"}$1"
    fi
}

# kubectl
if ! [ -x "$(command -v kubectl)" ]; then
    echo "🧵 installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "🧵 kubectl installed"
else
    echo "🧵 kubectl already installed..."
fi

# kubectl krew (Plugin Manager)
if [ $(kubectl krew | grep -c "error: unknown command") ];
then
    echo "🧵 krew already installed..."
else
    echo "🧵 installing krew..."
    (
        set -x; cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
    )
    pathadd ${KREW_ROOT:-$HOME/.krew}/bin
    echo "🧵 krew installed."
fi

# kubectx
if [ $(kubectl ctx | grep -c "error: unknown command") ];
then
    echo "🧵 kubectx already installed..."
else
    echo "🧵 installing kubectx..."
    kubectl krew install ctx
    echo "🧵 kubectx installed."
    # alias
    if alias kubectx >/dev/null 2>&1; then
        echo "🧵 kubectx already aliased..."
    else
        echo "🧵 aliasing kubectx..."
        alias kubectx="kubectl ctx"
        echo 'alias kubectx="kubectl ctx"' >> ~/.zshrc
        echo "🧵 aliased kubectx."
    fi
fi

# kubens
if [ $(kubectl ns | grep -c "error: unknown command") ];
then
    echo "🧵 kubens already installed..."
else
    echo "🧵 installing kubens..."
    kubectl krew install ns
    echo "🧵 kubens installed."
    # alias
    if alias kubens >/dev/null 2>&1; then
        echo "🧵 kubens already aliased..."
    else
        echo "🧵 aliasing kubens..."
        alias kubens="kubectl ns"
        echo 'alias kubens="kubectl ns"' >> ~/.zshrc
        echo "🧵 aliased kubens."
    fi
fi

# k3d
if ! [ -x "$(command -v k3d)" ]; then
    echo "🧵 installing k3d..."
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "🧵 k3d installed."
else
    echo "🧵 k3d already installed..."
fi

# kind
if ! [ -x "$(command -v kind)" ]; then
    echo "🧵 installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "🧵 kind installed."
else
    echo "🧵 kind already installed..."
fi


# linkerd
if ! [ -x "$(command -v linkerd)" ]; then
    echo "🧵 installing linkerd..."
    curl -sL https://run.linkerd.io/install | bash
    export PATH=$PATH:$HOME/.linkerd2/bin
    echo "export PATH=\$PATH:\$HOME/.linkerd2/bin" >> ~/.zshrc
    echo "🧵 linkerd installed."
else
    echo "🧵 linkerd already installed..."
fi

# helm
if ! [ -x "$(command -v helm)" ]; then
    echo "🧵 installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "🧵 helm installed."
else
    echo "🧵 helm already installed..."
fi

# clusterctl
if ! [ -x "$(command -v clusterctl)" ]; then
    echo "🧵 installing clusterctl..."
    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.3.5/clusterctl-linux-amd64 -o clusterctl
    chmod +x ./clusterctl
    sudo mv ./clusterctl /usr/local/bin/clusterctl
    clusterctl version
    echo "🧵 installed clusterctl."
else
    echo "🧵 clusterctl already installed..."
fi

# argocd
if ! [ -x "$(command -v argocd)" ]; then
    echo "🧵 installing argocd..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    echo "🧵 installed argocd."
else
    echo "🧵 argocd already installed..."
fi

# hostctl 
if ! [ -x "$(command -v hostctl)" ]; then
    echo "🧵 installing hostctl..."
    TEMP_DEB="$(mktemp)"
    wget -O "$TEMP_DEB" 'https://github.com/guumaster/hostctl/releases/download/v1.1.3/hostctl_1.1.3_linux_amd64.deb'
    sudo dpkg -i "$TEMP_DEB"
    rm -f "$TEMP_DEB"
    echo "🧵 installed hostctl."
else
    echo "🧵 hostctl already installed..."
fi

# step 
if ! [ -x "$(command -v step)" ]; then
    echo "🧵 installing step..."
    wget https://dl.step.sm/gh-release/cli/docs-cli-install/v0.23.1/step-cli_0.23.1_amd64.deb
    sudo dpkg -i step-cli_0.23.1_amd64.deb
    rm -f step-cli_0.23.1_amd64.deb
    echo "🧵 installed step."
else
    echo "🧵 step already installed..."
fi

# yq
if ! [ -x "$(command -v yq)" ]; then
    echo "🧵 installing yq..."
    sudo add-apt-repository ppa:rmescandon/yq
    sudo apt-get install yq
    echo "🧵 installed yq."
else
    echo "🧵 yq already installed..."
fi

# vcluster
if ! [ -x "$(command -v vcluster)" ]; then
    echo "🧵 installing vcluster..."
    curl -L -o vcluster "https://github.com/loft-sh/vcluster/releases/latest/download/vcluster-linux-amd64" \
        && sudo install -c -m 0755 vcluster /usr/local/bin \
        && rm -f vcluster
    echo "🧵 installed vcluster."
else
    echo "🧵 vcluster already installed..."
fi