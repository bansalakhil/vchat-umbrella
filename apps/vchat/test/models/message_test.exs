defmodule Vchat.MessageTest do
  use Vchat.ModelCase

  alias Vchat.Message

  @valid_attrs %{body: "some content", from_id: 42, info: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Message.changeset(%Message{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Message.changeset(%Message{}, @invalid_attrs)
    refute changeset.valid?
  end
end
