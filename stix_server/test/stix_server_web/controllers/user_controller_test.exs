defmodule StixServerWeb.UserControllerTest do
  use StixServerWeb.ConnCase

  alias StixServer.Accounts
  alias StixServer.Chat

  test "Create user", %{conn: conn} do
    params = %{"nickname" => "user_1", "password" => "123456"}

    %{"user" => user} = 
      conn
      |> post(Routes.user_path(conn, :sign_up, params))
      |> json_response(:created)

    %{"nickname" => response} = 
      conn
      |> get(Routes.user_path(conn, :get_user, %{"nickname" => user["nickname"]}))
      |> json_response(:ok)

    assert response == user["nickname"]
  end

  test "Create user with blank nickname field", %{conn: conn} do
    params = %{"nickname" => "", "password" => "123456"}

    %{"error" => msg} = 
      conn
      |> post(Routes.user_path(conn, :sign_up, params))
      |> json_response(:bad_request) 

    assert msg == "unable to create user"
  end
  
  test "Log in user", %{conn: conn} do
    params = %{"nickname" => "user_1", "password" => "123456"}
    %{"user" => _user} = 
      conn
      |> post(Routes.user_path(conn, :sign_up, params))
      |> json_response(:created)

    %{"user" => user} = 
      conn
      |> post(Routes.user_path(conn, :sign_in, params))
      |> json_response(:ok)

    %{"nickname" => response} = 
      conn
      |> get(Routes.user_path(conn, :get_user, %{"nickname" => user["nickname"]}))
      |> json_response(:ok)

    assert response == user["nickname"]
  end

  test "log in with wrong password", %{conn: conn} do
    params = %{"nickname" => "user_1", "password" => "123456"}
    %{"user" => _user} = 
      conn
      |> post(Routes.user_path(conn, :sign_up, params))
      |> json_response(:created)

    wrong_params = %{"nickname" => "user_1", "password" => "12345z"}
    %{"error" => msg} = 
      conn
      |> post(Routes.user_path(conn, :sign_in, wrong_params))
      |> json_response(:bad_request)
    
    assert msg == "invalid password"
  end

  test "sending message", %{conn: conn} do
    users = [%{"nickname" => "user_1", "password" => "123456"}, 
             %{"nickname" => "user_2", "password" => "123456"}]

    [{:ok, user1},{:ok, user2}] = Enum.map(users, &Accounts.create_user(&1))

    dialogue = 
      conn
      |> post(Routes.user_path(conn, :create_dialogue, %{"sender_id" => user1.id, "receiver_id" => user2.id}))
      |> json_response(:ok)

    message_params = %{"sender_id" => user1.id, "receiver_id" => user2.id,
                       "dialogue_id" => dialogue["dialogue"]["id"], "message_body" => "Test message!"}
     
    %{"msg" => message} = 
      conn
      |> post(Routes.user_path(conn, :send_message, message_params))
      |> json_response(:ok)

    assert message["message_body"] == "Test message!"
  end

  test "Get user by id", %{conn: conn} do
    {:ok, user} = Accounts.create_user(%{"nickname" => "user_1", "password" => "123456"})

    response = 
      conn
      |> get(Routes.user_path(conn, :get_user, %{"id" => user.id}))
      |> json_response(:ok)

    assert response["nickname"] == user.nickname
  end

  test "Get user by nickname", %{conn: conn} do
    {:ok, user} = Accounts.create_user(%{"nickname" => "user_1", "password" => "123456"})

    response = 
      conn
      |> get(Routes.user_path(conn, :get_user, %{"nickname" => user.nickname}))
      |> json_response(:ok)

    assert response["nickname"] == user.nickname
  end

  test "Get last messages", %{conn: conn} do
    users = [%{"nickname" => "user_1", "password" => "123456"}, 
             %{"nickname" => "user_2", "password" => "123456"},
             %{"nickname" => "user_3", "password" => "123456"}]

    [{:ok, user1},{:ok, user2}, {:ok, user3}] = Enum.map(users, &Accounts.create_user(&1))

    dialogues = [[user1.id, user2.id],
                 [user2.id, user3.id],
                 [user1.id, user3.id]]

    [{:ok, %{dialogue: dialogue1}}, {:ok, %{dialogue: dialogue2}}, {:ok, %{dialogue: dialogue3}}] = 
      Enum.map(dialogues, &Chat.create_dialogue(Enum.at(&1, 0), Enum.at(&1, 1)))

    messages = [%{"sender_id" => user1.id, "receiver_id" => user2.id,
                  "dialogue_id" => dialogue1.id, "message_body" => "Test message!"},
                %{"sender_id" => user2.id, "receiver_id" => user1.id,
                  "dialogue_id" => dialogue1.id, "message_body" => "Test response message!"},
                %{"sender_id" => user1.id, "receiver_id" => user3.id,
                  "dialogue_id" => dialogue3.id, "message_body" => "Test message!"},
                %{"sender_id" => user1.id, "receiver_id" => user3.id,
                  "dialogue_id" => dialogue3.id, "message_body" => "lates message"}]

    Enum.map(messages, &Chat.create_message(&1))

    response = 
      conn
      |> get(Routes.user_path(conn, :get_last_messages, %{"user_id" => user1.id}))
      |> json_response(:ok)

    assert Enum.count(response) == 2
  end

  test "Get messages of dialogue", %{conn: conn} do
    users = [%{"nickname" => "user_1", "password" => "123456"}, 
             %{"nickname" => "user_2", "password" => "123456"}]

    [{:ok, user1},{:ok, user2}] = Enum.map(users, &Accounts.create_user(&1))

    dialogue = 
      conn
      |> post(Routes.user_path(conn, :create_dialogue, %{"sender_id" => user1.id, "receiver_id" => user2.id}))
      |> json_response(:ok)

    messages = [%{"sender_id" => user1.id, "receiver_id" => user2.id,
                  "dialogue_id" => dialogue["dialogue"]["id"], "message_body" => "Test message!"},
                %{"sender_id" => user2.id, "receiver_id" => user1.id,
                  "dialogue_id" => dialogue["dialogue"]["id"], "message_body" => "Test response message!"},
                %{"sender_id" => user1.id, "receiver_id" => user2.id,
                  "dialogue_id" => dialogue["dialogue"]["id"], "message_body" => "Test message!"},
                %{"sender_id" => user1.id, "receiver_id" => user2.id,
                  "dialogue_id" => dialogue["dialogue"]["id"], "message_body" => "lates message"}]

    Enum.map(messages, &Chat.create_message(&1))

    response = 
      conn
      |> get(Routes.user_path(conn, :get_messages_of_dialog, %{"dialogue_id" => dialogue["dialogue"]["id"]}))
      |> json_response(:ok)

    assert Enum.count(response) == 4
  end

  test "Get unexisted user", %{conn: conn} do
    %{"errors" => message} = 
      conn
      |> get(Routes.user_path(conn, :get_user, %{"id" => -1}))
      |> json_response(404)

    assert message == ["user not found"]
  end

  test "Sign in with invalid parameters", %{conn: conn} do
    %{"error" => msg} =
      conn
      |> post(Routes.user_path(conn, :sign_in, %{"invalid" => "parameters"}))
      |> json_response(:bad_request)

    assert msg == "invalid_parameters"
  end
end
