#!/bin/bash

function restart_firmtech_api_service_production {
    echo "START firmtech-api-production service"
    # stop tmux/tunnel if running
    sudo systemctl start firmtech-api-production
}

trap restart_firmtech_api_service_production EXIT

sudo systemctl stop firmtech-api-production
set -a

# TODO: change to use the right environment
source ~/environment-production.firmtech_api

# run migrations
MIX_ENV=prod mix ecto.migrate

./_build/prod/rel/firmtech_api/bin/firmtech_api start_iex