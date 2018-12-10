defmodule StixServerWeb.UserController do
  use StixServerWeb, :controller

  def sign_up(conn, params) do
    changeset = StixServer.Schemas.User.changeset(%StixServer.Schemas.User{}, params)

    case StixServer.Repo.insert(changeset) do
      {:ok, user} ->
        json(conn |> put_status(:created), user)

      {:error, _changeset} ->
        json(conn |> put_status(:bad_request), %{errors: ["unable to create user"]})
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    import Ecto.Query, only: [from: 2]

    alias StixServer.Schemas.User

    query = from u in User, where: u.email == ^email and u.password == ^password, select: u
    results = StixServer.Repo.one(query)
    case results do
      %User{} ->
        json(conn |> put_status(200), %{loggined: true,
            user_body: results})
      _ ->
        json(conn |> put_status(:bad_request),
          %{loggined: false,
            errors: ["invalid email or password", "user not exists"]})
    end
  end

  def send_message(conn, params) do
    changeset = StixServer.Schemas.Message.changeset(%StixServer.Schemas.Message{}, params)

    case StixServer.Repo.insert(changeset) do
      {:ok, msg} ->
        json(conn |> put_status(:message_sent), msg)

      {:error, _changeset} ->
        json(conn |> put_status(:bad_request), %{errors: ["unable to send message"]})
    end
  end
end
