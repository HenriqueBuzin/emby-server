# emby-server

Emby Server com a biblioteca do Google Drive montada em modo somente leitura pelo rclone. O Nginx serve as páginas públicas de apresentação e privacidade.

## Ambientes

- A branch `main` implanta o projeto `emby-server`, com as portas de recuperação acessíveis pelo loopback em `127.0.0.1:8096`.
- A branch `dev` implanta o projeto `emby-server-dev`, com loopback em `127.0.0.1:8097`.
- Cada ambiente guarda sua configuração em `/srv/vps/projects/volumes/<projeto>/config`. Ambos leem a mesma montagem de mídia em `/media/drive`.
- O Nginx Proxy Manager alcança os serviços pela rede externa `proxy-network`. Os aliases de produção são `emby-server:8096` e `emby-pages:80`. Em DEV, são `emby-server-dev:8096` e `emby-pages-dev:80`.
- A produção usa `emby.henriquebuz.in` e o DEV usa `emby-dev.henriquebuz.in`. Ambos exigem login para acessar a biblioteca.

## Configuração na VPS

Crie o env a partir de `.env.example` no diretório do ambiente. Produção usa `/srv/vps/projects/envs/emby-server/prod/emby-server-prod.env` e DEV usa `/srv/vps/projects/envs/emby-server/dev/emby-server-dev.env`.

O Docker Compose em `/srv/vps/shared-services/rclone` fornece uma montagem compartilhada do Drive em modo somente leitura. A unidade `emby-media-mount.service` prepara a propagação antes do Docker. O arquivo `rclone.conf` fica em `/srv/vps/shared-services/rclone/secrets`, com permissão de gravação para renovar o token OAuth. A configuração faz parte do backup, e os diretórios de mídia e cache são excluídos.

O script de deploy verifica se o Drive já está montado em `/srv/vps/shared-services/volumes/rclone/media/drive` antes de aplicar o Compose. O Emby também espera que o FUSE apareça em `/media/drive` durante a inicialização. A VPS precisa da rede Docker `proxy-network`.

## Jenkins

Configure um Multibranch Pipeline para este repositório com o `Jenkinsfile` da raiz. O agente precisa ter acesso ao Docker e à montagem de `/srv/vps/projects` da VPS.

Para verificar o Compose com valores de exemplo, execute:

```sh
docker compose --env-file .env.example config --quiet
```
