#!/bin/bash
# Docker entrypoint script.

# Wait until Postgres is ready.
while ! pg_isready --host=$PGHOST --port=$PGPORT --username=$PGUSER --quiet
do
  echo "[ENTRYPOINT] $(date) - waiting for database to start"
  sleep 2
done

# Create database if it doesn't already exist
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "[ENTRYPOINT] Database $PGDATABASE does not exist. Creating..."
  createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0
fi

# Create and migrate database tables.
mix ecto.create
mix ecto.migrate

# The database should still be running. If it's not, quit the process.
if ! pg_isready --host=$PGHOST --port=$PGPORT --username=$PGUSER; then
  echo "[ENTRYPOINT] Database $PGDATABASE is unavailable. Shutting down..."
  exit 1
fi
psql -l

echo "Host: $PGHOST"

# In test mode, only run tests. Otherwise, start the server
if [[ $MODE == "test" ]]; then
  echo "[ENTRYPOINT] Running mix tests..."
  MIX_ENV=test exec mix test --no-compile --cover
else
  echo "[ENTRYPOINT] Starting Phoenix server..."
  MIX_ENV=prod exec mix phx.server --no-compile
fi
