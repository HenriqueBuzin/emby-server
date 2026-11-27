#!/bin/sh
set -eu

case "${1:-}" in
    main)
        environment=prod
        project=emby-server
        pages=emby-pages
        port=8096
        ;;
    dev)
        environment=dev
        project=emby-server-dev
        pages=emby-pages-dev
        port=8097
        ;;
    *)
        echo 'Deploy disponível para main e dev.' >&2
        exit 1
        ;;
esac

source_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_root=/root/projects
project_dir="$project_root/$project"
env_dir="$project_root/envs/emby-server/$environment"
env_file="$env_dir/emby-server-$environment.env"
compose_file="$project_dir/docker-compose.yml"
env_link="$project_dir/.env"

export EMBY_PROJECT_NAME="$project"
export EMBY_VOLUME_ROOT="$project_root/volumes/$project"
export EMBY_PROXY_ALIAS="$project"
export EMBY_PAGES_ALIAS="$pages"
export EMBY_LOOPBACK_PORT="$port"
export RCLONE_CONFIG_DIR="$env_dir/secrets"

if [ ! -r "$env_file" ] || [ ! -s "$RCLONE_CONFIG_DIR/rclone.conf" ]; then
    echo "Configure o env e o arquivo rclone.conf de $environment em $env_dir." >&2
    exit 1
fi
if [ -e "$env_link" ] || [ -L "$env_link" ]; then
    if [ "$(readlink "$env_link" || true)" != "$env_file" ]; then
        echo "O caminho $env_link já aponta para outra configuração." >&2
        exit 1
    fi
fi

compose() {
    docker compose --project-name "$project" --project-directory "$project_dir" \
        --env-file "$env_file" "$@"
}

mkdir -p "$project_dir" "$EMBY_VOLUME_ROOT/config" "$EMBY_VOLUME_ROOT/cache" \
    "$EMBY_VOLUME_ROOT/media/drive" "$project_dir/site/about" "$project_dir/site/privacy"
docker network inspect proxy-network >/dev/null
compose -f "$source_root/docker-compose.yml" config --quiet
compose -f "$source_root/docker-compose.yml" pull

previous=$(mktemp "$project_dir/.compose-previous.XXXXXX")
candidate=$(mktemp "$project_dir/.compose-candidate.XXXXXX")
trap 'rm -f -- "$previous" "$candidate"' EXIT
if [ -f "$compose_file" ]; then
    cp -p -- "$compose_file" "$previous"
fi

install -m 0644 "$source_root/site/about/index.html" "$project_dir/site/about/index.html"
install -m 0644 "$source_root/site/privacy/index.html" "$project_dir/site/privacy/index.html"
ln -sfn -- "$env_file" "$env_link"
install -m 0644 "$source_root/docker-compose.yml" "$candidate"
mv -f -- "$candidate" "$compose_file"

if ! compose -f "$compose_file" up -d --wait --wait-timeout 180; then
    compose -f "$compose_file" ps --all --format 'table {{.Name}}\t{{.State}}\t{{.Health}}' || true
    if [ -s "$previous" ]; then
        cp -p -- "$previous" "$compose_file"
        compose -f "$compose_file" up -d --wait --wait-timeout 180
    else
        compose -f "$compose_file" down
    fi
    exit 1
fi

compose -f "$compose_file" ps
