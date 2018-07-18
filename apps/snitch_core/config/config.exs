use Mix.Config

config :snitch_core, ecto_repos: [Snitch.Repo]
config :ecto, :json_library, Jason

import_config "#{Mix.env()}.exs"

config :hydrus,
  repo: Snitch.Repo,
  app: Snitch
