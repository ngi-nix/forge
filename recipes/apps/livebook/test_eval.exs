Application.load(:livebook)
Application.put_env(:livebook, :serverless, true)
{:ok, _} = Application.ensure_all_started(:livebook)

doc = File.read!(Path.join(System.user_home!(), "test_notebook.livemd"))
{notebook, _} = Livebook.LiveMarkdown.notebook_from_livemd(doc)

{:ok, session} = Livebook.Sessions.create_session(notebook: notebook)
Livebook.Session.subscribe(session.id)
Livebook.Session.connect_runtime(session.pid)

receive do
  {:operations, [{:runtime_connected, _, _}]} -> IO.puts("Livebook runtime connected!")
after
  15000 -> raise "Livebook runtime connection timed out"
end

Livebook.Session.queue_full_evaluation(session.pid, [])

defmodule Waiter do
  def wait(_session, 0), do: :ok

  def wait(session, remaining) do
    receive do
      {:operations, ops} ->
        new_remaining =
          Enum.reduce(ops, remaining, fn
            {:add_cell_evaluation_response, _, cell_id, _, _}, acc ->
              IO.puts("Cell #{cell_id} finished evaluation")
              acc - 1

            _, acc ->
              acc
          end)

        if new_remaining > 0 do
          wait(session, new_remaining)
        else
          :ok
        end
    after
      30000 ->
        data = Livebook.Session.get_data(session.pid)
        IO.inspect(data, label: "Session data on timeout", limit: :infinity)
        raise "Timed out waiting for notebook cell evaluations"
    end
  end
end

Waiter.wait(session, 2)

data = Livebook.Session.get_data(session.pid)

outputs =
  for section <- data.notebook.sections,
      cell <- section.cells,
      {_, out} <- cell.outputs do
    {cell.language, out.text}
  end

IO.inspect(outputs, label: "Cell outputs")

has_output? = fn lang, expected ->
  Enum.any?(outputs, fn {l, text} -> l == lang and String.contains?(text, expected) end)
end

unless has_output?.(:elixir, "30"), do: raise("Elixir output missing or incorrect")
unless has_output?.(:erlang, "70"), do: raise("Erlang output missing or incorrect")

Livebook.Session.close(session.pid)
IO.puts("Notebook executed successfully: Elixir and Erlang cells passed!")
