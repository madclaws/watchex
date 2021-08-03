# Watchex

**A barebone MMO server for Watchers**

[![Watchex CI](https://github.com/madclaws/watchex/actions/workflows/elixir.yml/badge.svg)]

## Overview
Watchex is the MMO server for [Watchers](https://github.com/madclaws/watchers).

- Guidelines for trying the production Watcher client is in its readme.
- Server is deployed on Gigalixir
- Used websocket for realtime experience 

## Development
To run the server locally:

```
MIX_ENV=prod mix deps.get

export SECRET_KEY_BASE="$(mix phx.gen.secret)"  

MIX_ENV=prod mix release

MIX_ENV=prod APP_NAME=watchex PORT=4000 _build/prod/rel/watchex/bin/watchex start

```

## Run Tests
``` mix test ```
