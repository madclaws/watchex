import Config

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :watchex, WatchexWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("WATCHEX_PORT")),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :watchex, WatchexWeb.Endpoint, server: true
