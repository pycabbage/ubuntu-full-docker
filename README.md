# ubuntu-full-docker

> Unminized and installed standard packages
> Created for interactive use

## Feature

- nonroot user: `ubuntu` (included in nopasswd `sudo` group)
- Installed package: inatalled in Ubuntu Server
- Language: `ja_JP.UTF-8`
- Docker outside of Docker

## Usage

```bash
docker compose up -d
docker compose exec ubuntu /bin/bash
```
