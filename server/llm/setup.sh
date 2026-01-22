#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

# Create models directory
mkdir -p models

cat > init <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$DIRNAME"
docker compose pull
EOF
chmod +x init

cat > start <<EOF
#!/bin/bash
set -xeuo pipefail

docker ps | grep llm-server && ./stop || true
(
	cd "$DIRNAME"
	# Export vars for docker-compose
	export PORT="$PORT"
	export MODEL_FILE="$MODEL_FILE"
	export GPU_LAYERS="$GPU_LAYERS"
	export CONTEXT_SIZE="$CONTEXT_SIZE"
	export PARALLEL_SLOTS="$PARALLEL_SLOTS"
	export FLASH_ATTN="$FLASH_ATTN"
	docker compose up -d
)
EOF
chmod +x start

cat > stop <<EOF
#!/bin/bash
set -xeuo pipefail

(
	cd "$DIRNAME"
	docker compose down
)
EOF
chmod +x stop

cat > deploy <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$DIRNAME"
. "./vars.sh"

# Check if model exists
if [ ! -f "models/\$MODEL_FILE" ]; then
	>&2 printf "Model not found: models/\$MODEL_FILE\n"
	>&2 printf "Run ./download-model first\n"
	exit 1
fi

./init
./start
EOF
chmod +x deploy

cat > logs <<EOF
#!/bin/bash
set -xeuo pipefail

docker logs llm-server -f \$*
EOF
chmod +x logs

cat > "exec" <<EOF
#!/bin/bash

docker exec -it llm-server sh \$*
EOF
chmod +x exec

cat > status <<EOF
#!/bin/bash
set -euo pipefail

# Check if container is running
if docker ps | grep -q llm-server; then
	echo "Container: running"
	
	# Check health endpoint
	if curl -sf http://localhost:$PORT/health >/dev/null 2>&1; then
		echo "Health: ok"
	else
		echo "Health: not ready"
	fi
	
	# Show slots info
	curl -sf http://localhost:$PORT/slots 2>/dev/null | head -20 || true
else
	echo "Container: stopped"
fi
EOF
chmod +x status

cat > download-model <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$DIRNAME"
. "./vars.sh"

echo "Downloading \$MODEL_FILE from \$MODEL_REPO..."

# Use hf cli if available
if command -v hf >/dev/null 2>&1; then
	HF_ARGS=""
	if [ -n "\$HF_TOKEN" ]; then
		HF_ARGS="--token \$HF_TOKEN"
	fi
	hf download "\$MODEL_REPO" "\$MODEL_FILE" \$HF_ARGS --local-dir models
else
	echo "hf cli not found. Install with: pip install huggingface_hub[cli]"
	echo "Or download manually from: https://huggingface.co/\$MODEL_REPO"
	exit 1
fi

echo "Model downloaded to models/\$MODEL_FILE"
EOF
chmod +x download-model

cat > install-nginx <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

# Copy template to domain-named file (required by install_nginx_site_with_replace)
cp nginx.conf "\$DOMAIN"
install_nginx_site_with_replace "\$DOMAIN" "DOMAIN" "PORT"
rm "\$DOMAIN"

echo "Nginx site installed for \$DOMAIN"
EOF
chmod +x install-nginx

>&2 printf "\n"
>&2 printf "========================================\n"
>&2 printf "LLM server setup complete.\n"
>&2 printf "\n"
>&2 printf "Next steps:\n"
>&2 printf "  1. ./download-model    # Download the GGUF model (~16GB)\n"
>&2 printf "  2. ./deploy            # Start the server\n"
>&2 printf "  3. ./status            # Check server status\n"
>&2 printf "\n"
>&2 printf "API will be available at: http://localhost:$PORT/v1/chat/completions\n"
>&2 printf "\n"
>&2 printf "For remote HTTPS access:\n"
>&2 printf "  ./install-nginx        # Install nginx site with SSL\n"
>&2 printf "========================================\n"
