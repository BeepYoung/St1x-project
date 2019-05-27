defmodule StixServer.AccountsTest do
  use StixServerWeb.ConnCase

  alias StixServer.Accounts

  test "Create user with blank nickname field" do
    params = %{"nickname" => "", "password" => "123456"}

    {:error, changeset} = Accounts.create_user(params)

    assert changeset.valid? == false
  end

  test "verify user with wrong params" do
    params = %{"wrong" => "params"}

    response = Accounts.verify_user(params)

    assert response == nil
  end
end