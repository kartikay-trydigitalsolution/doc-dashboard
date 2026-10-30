#!/bin/bash

function restart_firmtech_api_service_staging {
    echo "START firmtech-api-staging service"
    # stop tmux/tunnel if running
    sudo systemctl start firmtech-api-staging
}

trap restart_firmtech_api_service_staging EXIT

sudo systemctl stop firmtech-api-staging
set -a

# TODO: change to use the right environment
source ~/environment-staging.firmtech_api

# run migrations
MIX_ENV=prod mix ecto.migrate

./_build/prod/rel/firmtech_api/bin/firmtech_api start_iex