defmodule DiscussWeb.CommentsChannel do
  use Phoenix.Channel

  alias Discuss.{Comment, Repo, Topic}

  def join("comments:" <> topic_id, _params, socket) do
    topic_id = String.to_integer(topic_id)

    topic =
      Topic
      |> Repo.get(topic_id)
      |> Repo.preload(comments: [:user])

    {:ok, %{comments: topic.comments}, assign(socket, :topic, topic)}
  end

  def handle_in(_name, %{"content" => content}, socket) do
    case socket do
      %{assigns: %{topic: topic, user_id: user_id}} ->
        changeset =
          topic
          |> Ecto.build_assoc(:comments, user_id: user_id)
          |> Repo.preload(:user)
          |> Comment.changeset(%{content: content})

        case Repo.insert(changeset) do
          {:ok, comment} ->
            broadcast!(socket, "comments:#{topic.id}:new", %{comment: comment})
            {:reply, :ok, socket}

          {:error, _reason} ->
            {:reply, {:error, %{errors: changeset}}, socket}
        end

      _ ->
        {:reply, {:error, %{errors: "User is not registered."}}, socket}
    end
  end
end
