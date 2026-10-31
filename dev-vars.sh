export GITHUB_TOKEN=$(gh auth token)
sudo sysctl fs.inotify.max_user_instances=1280                      
sudo sysctl fs.inotify.max_user_watches=655360

setopt shwordsplit

PROJECT_NAME="ananke"
ORG_DOMAIN="${PROJECT_NAME}.com"
port=6440
mgmt_cluster="${PROJECT_NAME}-mgmt"
SUB_DOMAINS=(argocd dashboard qotm emojivoto v-ananke-dev)