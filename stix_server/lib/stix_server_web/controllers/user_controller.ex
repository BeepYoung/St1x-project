defmodule StixServerWeb.UserController do
  use StixServerWeb, :controller

  alias StixServer.Accounts
  alias StixServer.Chat

  def sign_up(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        json(conn |> put_status(:created), %{ok: "signed_up", user: user})

      {:error, _changeset} ->
        json(conn |> put_status(:bad_request), %{error: "unable to create user"})
    end
  end

  def sign_in(conn, params) do
    case Accounts.verify_user(params) do
      {:ok, user} ->
        json(conn |> put_status(200), %{ok: "signed_in", user: user})

      {:error, msg} ->
        json(conn |> put_status(:bad_request), %{error: msg})

      nil -> 
        json(conn |> put_status(:bad_request), %{error: "invalid_parameters"})
    end
  end
  
  def send_message(conn, params) do
    case Chat.create_message(params) do
      {:ok, msg} ->
        json(conn |> put_status(200), %{message_sent: ["ok"], msg: msg})

      {:error, changeset} ->
        json(conn |> put_status(:bad_request), %{errors: ["unable to send message"], changeset: changeset})
    end
  end

  def get_user(conn, params) do
    user = Chat.get_user(params)

    case user do
      nil -> json(conn |> put_status(404), %{errors: ["user not found"]})
      _ -> json(conn |> put_status(200), user)
    end
  end

  # TODO
  def get_last_messages(conn, %{"user_id" => user_id}) do
    last_messages = Chat.get_last_messages(user_id)

    case last_messages  do
      nil -> json(conn |> put_status(404), %{errors: ["no messages in current dialog"]})
      _ -> json(conn |> put_status(200), last_messages)
    end
  end

  def get_messages_of_dialog(conn, %{"dialogue_id" => dialogue_id}) do
    messages = Chat.get_messages(dialogue_id)

    case messages do
      nil -> json(conn |> put_status(404), %{errors: ["no messages in current dialog"]})
      _ -> json(conn |> put_status(200), messages)
    end
  end

  def create_dialogue(conn, %{"sender_id" => sender_id, "receiver_id" => receiver_id}) do
    Chat.create_dialogue(sender_id,receiver_id)
    |> case do
      {:ok, response} -> json(conn |> put_status(:ok), response)
      {:error, msg} -> json(conn |> put_status(:error), %{status: "error", msg: msg})
    end
  end
end
