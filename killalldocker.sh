#!/bin/bash
set -eu


if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or not on PATH." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Cannot access Docker daemon. Try: sudo bash $0" >&2
    exit 1
fi

containers="$(docker ps -aq)"

echo "=== REMOVE DOCKER RESOURCES ==="

if [ -n "$containers" ]; then
    docker ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}'
else
    echo "No containers found."
fi

printf "\nThis removes containers and unused Docker resources from the current daemon.\n"
printf "It does not uninstall Docker or delete Docker configuration.\n"
printf "Type KILL to continue: "
read -r confirmation

if [ "$confirmation" != "KILL" ]; then
    echo "Cancelled. Nothing was changed."
    exit 1
fi

echo "Deleting all containers..."
if [ -n "$containers" ]; then
    while IFS= read -r container; do
        [ -n "$container" ] && docker rm -f -v "$container"
    done <<< "$containers"
fi

echo "Deleting unused images, networks, and Docker-managed build cache..."
docker system prune -a -f

echo "Deleting all unused volumes, including named volumes..."
docker volume prune -a -f

if docker buildx version >/dev/null 2>&1; then
    echo "Deleting Buildx cache for the selected builder..."
    docker buildx prune -a -f
fi

printf '\nRemaining containers:\n'
docker ps -a
printf '\nRemaining images:\n'
docker image ls -a
printf '\nRemaining volumes:\n'
docker volume ls
printf '\nRemaining networks (Docker\x27s built-in networks remain):\n'
docker network ls
printf '\nDone.\n'
