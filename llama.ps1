# context size & vram: 65536 @ 32gb, 32768 @ 10gb

# $env:LLAMA_ARG_CTX_SIZE = "32768"
# $env:LLAMA_ARG_FLASH_ATTN = "on"
# $env:LLAMA_ARG_LOAD_MODE = "mlock"
# $env:LLAMA_ARG_N_GPU_LAYERS = "all"

llama-server `
  --ctx-size 32768 `
  --flash-attn on `
  --load-mode mlock `
  --n-gpu-layers all `
  --hf-repo unsloth/Qwen3.5-9B-GGUF:UD-Q4_K_XL
