# Extend from official Elixir image
FROM elixir:1.14.2-slim

EXPOSE 8080

RUN apt-get update && \
  apt-get install -y inotify-tools && \
  apt-get install -y postgresql-client

# Install Hex package manager
RUN mix local.hex --force
RUN mix local.rebar --force

# Use production environment config
ENV MIX_ENV prod

# Install dependencies
WORKDIR /app
COPY mix.* /app
RUN mix do deps.get --force

# Copy Elixir project into App directory
COPY . /app

RUN rm -rf /app/.mix
RUN mix do compile --force

# Set the entrypoint to this bash script, and enable it to be run
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
