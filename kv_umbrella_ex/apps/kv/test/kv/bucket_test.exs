defmodule Kv.BucketTest do
  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(Kv.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert Kv.Bucket.get(bucket, "milk") == nil

    Kv.Bucket.put(bucket, "milk", 1)
    assert Kv.Bucket.get(bucket, "milk") == 1

    assert Kv.Bucket.delete(bucket, "milk") == 1
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(Kv.Bucket, []).restart == :temporary
  end
end
