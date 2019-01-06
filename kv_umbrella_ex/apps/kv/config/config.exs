use Mix.Config

config :kv, :routing_table, [
  {?a..?m, :"foo@olivia-2"},
  {?n..?z, :"bar@olivia-2"}
]
