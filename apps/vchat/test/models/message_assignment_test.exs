defmodule Vchat.MessageAssignmentTest do
  use Vchat.ModelCase

  alias Vchat.MessageAssignment

  @valid_attrs %{message_id: 42, seen: true, to: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = MessageAssignment.changeset(%MessageAssignment{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = MessageAssignment.changeset(%MessageAssignment{}, @invalid_attrs)
    refute changeset.valid?
  end
end
