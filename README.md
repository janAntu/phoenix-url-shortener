# UrlShortener

This repository contains the backend for a URL shortener, created with Elixir and Phoenix.
With this web app, users can create shortened URLs, with customized or auto-generated
aliases.

#### Features:
- PostgreSQL Database for data persistence
- CSV file download for URL statistics
- Unit and integration tests with 100% code coverage (excluding auto-generated code)
- Automated testing and deployment with Docker Compose

Read a step-by-step walkthrough of the source code in [WALKTHROUGH.md](WALKTHROUGH.md).


## Setup Instructions

First, clone the repo into your local environment:

```
git clone https://github.com/janAntu/phoenix-url-shortener.git
```

To set up, run, and test this web app, there are two options: **Docker Compose** or **Mix (manual setup)**:

### Docker Compose

This repo provides a Docker file to automate the setup process (including a Dockerized Postgres database). To build and run it:

```
docker-compose build
docker-compose up
```

Now you can visit [`localhost:8080`](http://localhost:8080) from your browser.

To run the unit and integration tests, do:

```
docker-compose build
MODE=test docker-compose up
```

### Mix (manual setup)

To start your Phoenix server:

1. Start a local Postgres database using a tool like [Postgres.app](https://postgresapp.com/)
2. Install dependencies with `mix deps.get`
3. Create and migrate your database with `mix ecto.setup`
4. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:8080`](http://localhost:8080) from your browser.

To run tests with a coverage report, finish steps 1-3 above and then run `mix test --cover`.
