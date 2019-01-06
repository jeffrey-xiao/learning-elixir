defmodule Kv.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    start_supervised!({Kv.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert Kv.Registry.lookup(registry, "shopping") == :error

    Kv.Registry.create(registry, "shopping")
    assert {:ok, bucket} = Kv.Registry.lookup(registry, "shopping")

    Kv.Bucket.put(bucket, "milk", 1)
    assert Kv.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    Kv.Registry.create(registry, "shopping")
    assert {:ok, bucket} = Kv.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)
    # Do a bogus create call to ensure registry has processed DOWN message.
    Kv.Registry.create(registry, "bogus")
    assert Kv.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    Kv.Registry.create(registry, "shopping")
    assert {:ok, bucket} = Kv.Registry.lookup(registry, "shopping")
    Agent.stop(bucket, :shutdown)
    # Do a bogus create call to ensure registry has processed DOWN message.
    Kv.Registry.create(registry, "bogus")
    assert Kv.Registry.lookup(registry, "shopping") == :error
  end
end
