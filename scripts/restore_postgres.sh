#!/bin/bash

# Restore the entire dump
psql --host=firmtech-db-cluster-01.cluster-ccabatk4bhhl.us-east-1.rds.amazonaws.com --username=firmtech_staging_user --dbname=firmtech_staging < database_dump.sql