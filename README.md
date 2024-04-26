# ubuntu-full-docker

> Unminized and installed standard packages
> Created for interactive use

```bash
docker compose up -d
docker compose exec -u ubuntu -w /home/ubuntu -e TERM=xterm-256color ubuntu /bin/bash
```
