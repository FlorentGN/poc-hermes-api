#!/usr/bin/env bash
set -euo pipefail

echo "======================================================"
echo "⚡ Démarrage de l'environnement de développement..."
echo "======================================================"

# 0. Prise en compte des secrets Docker (/run/secrets/...)
# Certificat CA racine
if [ -f "/run/secrets/ca_cert" ]; then
    echo "🔒 Installation du certificat CA racine depuis le secret Docker..."
    cp /run/secrets/ca_cert /usr/local/share/ca-certificates/hermes-root-ca.crt
    update-ca-certificates > /dev/null 2>&1 || true
elif [ -f "/workspace/.secrets/ca.crt" ]; then
    echo "🔒 Installation du certificat CA racine depuis .secrets/..."
    cp /workspace/.secrets/ca.crt /usr/local/share/ca-certificates/hermes-root-ca.crt
    update-ca-certificates > /dev/null 2>&1 || true
fi

# Token GitLab
TOKEN=""
if [ -f "/run/secrets/gitlab_token" ]; then
    TOKEN=$(cat /run/secrets/gitlab_token | tr -d '\r\n')
elif [ -n "${GITLAB_TOKEN:-}" ]; then
    TOKEN="${GITLAB_TOKEN}"
fi

if [ -n "${TOKEN}" ] && [ "${TOKEN}" != "REPLACE_WITH_YOUR_GITLAB_TOKEN" ]; then
    echo "🔑 Configuration Git insteadOf pour GitLab hermes.lan via secret..."
    git config --global url."https://oauth2:${TOKEN}@gitlab.hermes.lan/".insteadOf "https://gitlab.hermes.lan/"
fi

# Mise à jour pip
pip install --no-cache-dir --upgrade pip > /dev/null 2>&1

# 1. Installation de la bibliothèque en mode éditable si le dossier monté existe
if [ -d "/workspace/hermes-math" ]; then
    echo "📦 Installation de hermes-math en mode éditable (-e)..."
    pip install --no-cache-dir -e /workspace/hermes-math
else
    echo "⚠️  Dossier /workspace/hermes-math non trouvé, utilisation de la version GitLab si présente."
fi

# 2. Installation de l'application FastAPI en mode éditable
if [ -d "/workspace/hermes-api" ]; then
    echo "🚀 Installation de hermes-api en mode éditable (-e)..."
    # --no-deps permet d'éviter de tenter de cloner gitlab si hermes-math est déjà monté localement
    pip install --no-cache-dir --no-deps -e /workspace/hermes-api
    # On installe les dépendances tierces (fastapi, uvicorn...)
    pip install --no-cache-dir fastapi uvicorn[standard]
fi

echo "======================================================"
echo "🔥 Lancement de Uvicorn avec Hot Reload sur le port 8000"
echo "   (Toute modification dans hermes-api OU hermes-math rechargera le serveur)"
echo "======================================================"

cd /workspace/hermes-api
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --reload \
    --reload-dir /workspace/hermes-api \
    --reload-dir /workspace/hermes-math

