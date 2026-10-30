#!/bin/bash

# Dump entire database (structure and data) except for data in preprocess table
pg_dump --host=firmtech-db-cluster-01.cluster-ccabatk4bhhl.us-east-1.rds.amazonaws.com --username=postgres --dbname=firmtech \
  --exclude-table-data=preprocess \
  --no-owner \
  --no-privileges \
  --file=database_dump.sql