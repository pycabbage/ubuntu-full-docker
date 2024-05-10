# ubuntu-full-docker

> Unminized and installed standard packages
> Created for interactive use

## Feature

- [x] nonroot user: `ubuntu` (included in nopasswd `sudo` group)
- [x] Installed package: inatalled in Ubuntu Server
- [x] Language: `ja_JP.UTF-8`
- [x] Docker outside of Docker
- [x] Rust via rustup
- [ ] Python with pyenv

## Usage

```bash
docker compose up -d
docker compose exec ubuntu /bin/bash
```
