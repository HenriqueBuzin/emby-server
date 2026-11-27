# emby-server

Emby Server com a biblioteca do Google Drive montada em modo somente leitura pelo rclone. O Nginx serve as páginas públicas de apresentação e privacidade.

## Ambientes

- A branch `main` implanta o projeto `emby-server`, com as portas de recuperação acessíveis pelo loopback em `127.0.0.1:8096`.
- A branch `dev` implanta o projeto `emby-server-dev`, com loopback em `127.0.0.1:8097`.
- Os projetos usam diretórios de configuração, mídia montada e cache próprios em `/root/projects/volumes/<projeto>`.
- O Nginx Proxy Manager alcança os serviços pela rede externa `proxy-network`. Os aliases de produção são `emby-server:8096` e `emby-pages:80`. Em DEV, são `emby-server-dev:8096` e `emby-pages-dev:80`.

## Configuração na VPS

Crie o env a partir de `.env.example` no diretório do ambiente. Produção usa `/root/projects/envs/emby-server/prod/emby-server-prod.env` e DEV usa `/root/projects/envs/emby-server/dev/emby-server-dev.env`.

Coloque o `rclone.conf` em `secrets/rclone.conf` no mesmo diretório. O arquivo deve conter o remoto especificado em `RCLONE_REMOTE`, com escopo de leitura do Drive. Preencha `RCLONE_DRIVE_ROOT_FOLDER_ID` com a pasta do ambiente. O rclone usa a montagem gravável da pasta de configuração para persistir a renovação do token OAuth.

O script de deploy cria o link simbólico `.env` e o ponto de montagem `media/drive`, verifica o Compose e aguarda a montagem do Drive e o HTTP do Emby. A VPS precisa ter `/dev/fuse`, a rede Docker `proxy-network` e a propagação compartilhada no diretório `media` de cada ambiente.

## Jenkins

Configure um Multibranch Pipeline para este repositório com o `Jenkinsfile` da raiz. O agente precisa ter acesso ao Docker e à montagem de `/root/projects` da VPS.

Para verificar o Compose com valores de exemplo, execute:

```sh
docker compose --env-file .env.example config --quiet
```
