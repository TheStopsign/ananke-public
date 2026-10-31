# Grafana Agent
echo "🧵 installing Grafana Agent..."
kubectl create namespace grafana-agent
kubectl annotate namespace grafana-agent linkerd.io/inject=enabled
helm upgrade --install -n grafana-agent grafana-agent-operator grafana/grafana-agent-operator
kubectl apply -f mgmt/grafana-agent.yaml