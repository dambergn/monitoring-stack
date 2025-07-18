#!/bin/bash

docker compose down
## Check for updates.
docker compose pull

## only restart those that were updated.
docker compose up --build --force-recreate -d

## Clean up old files.