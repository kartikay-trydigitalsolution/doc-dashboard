#!/bin/bash
source .env.prod && MIX_ENV=prod mix ecto.migrate