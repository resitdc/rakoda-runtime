# Rakoda Runtime

Repositori resmi untuk melakukan *cross-compilation* runtime (PHP, Node.js, dll) agar dapat diunduh oleh ekosistem RPL Studio di berbagai *platform* (Windows, Linux, macOS, Android).

## Struktur Repositori

- `build/`: Entrypoint script build CI.
- `builders/`: Logika spesifik build tiap runtime (Dockerfile, flags).
- `scripts/`: Helper scripts (generate manifest, compress).
- `manifest/`: Hasil akhir `runtime.json` yang dikonsumsi oleh RPL Studio.
