#!/bin/sh

PORT=8080
DOMAIN="llm.kipras.org"  # optional, for nginx

# Model config
MODEL_REPO="bartowski/zai-org_GLM-4.7-Flash-GGUF"
MODEL_FILE="GLM-4.7-Flash-IQ4_XS.gguf"  # ~16GB, 4-bit quantization

# HuggingFace token (optional, for gated models or faster downloads)
# Get one at: https://huggingface.co/settings/tokens
HF_TOKEN=""

# Server config
PARALLEL_SLOTS=8          # concurrent agent connections
CONTEXT_SIZE=8192         # tokens per slot (keep short)
GPU_LAYERS=99             # offload all layers to GPU

# Flash attention disabled due to llama.cpp bugs with GLM-4.7-Flash
# Track: https://github.com/ggml-org/llama.cpp/issues/18944
#        https://github.com/ggml-org/llama.cpp/issues/18948
FLASH_ATTN="off"
