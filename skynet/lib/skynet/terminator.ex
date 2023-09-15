defmodule Skynet.Terminator do
  use GenServer
  require Logger
  # alias __MODULE__

  defstruct [:id, :task_pid]
  @time_for_death_check 10_000
  @chance_of_death 25
  @time_to_spawn_new 5_000
  @chance_spawn_new 20

  def generate_random_id() do
    :crypto.strong_rand_bytes(6) |> Base.encode64(padding: false)
  end

  defp post_death_check(pid) do
    Process.send_after(pid, :check_for_death, @time_for_death_check)
  end

  defp post_spawn_check(pid) do
    Process.send_after(pid, :possibly_spawn_terminator, @time_to_spawn_new)
  end

  def init(init_args) do
    max_retries = Keyword.get(init_args, :max_retries, 5)
    check_for_spawn()
    check_for_death()
    state = %{terminator_list: [], max_retries: max_retries}
    {:ok, state}
  end

  def spawn_terminator() do
    id = generate_random_id()
    {:ok, pid} = GenServer.start(Skynet.Terminator, max_retries: 5)
    %Skynet.Terminator{id: id, task_pid: pid}
  end

  def check_for_spawn() do
    post_spawn_check(self())
  end

  def check_for_death() do
    post_death_check(self())
  end

  defp random_chance_passed?(threshold) do
    :rand.uniform(100) <= threshold
  end

  def kill_terminator(terminator_list) do
    terminator_to_be_killed = self()
    List.delete(terminator_list, %Skynet.Terminator{task_pid: terminator_to_be_killed})
    Process.exit(terminator_to_be_killed, :normal)
  end

  def handle_info(:check_for_death, state) do
    Logger.info("Checking for termination")

    if random_chance_passed?(@chance_of_death) do
      Logger.info("Sarah Connor got this terminator")
      kill_terminator(state.terminator_list)
    else
      check_for_death()
      # No need to do anything
      {:noreply, state}
    end
  end

  def handle_info(:possibly_spawn_terminator, state) do
    Logger.info("Checking for spawning new terminator")

    if random_chance_passed?(@chance_spawn_new) do
      Logger.info("state before spawning new terminator: #{inspect(state)}")
      Logger.info("Spawning new terminator")
      terminator = spawn_terminator()
      terminator_list = state.terminator_list
      terminator_list = [terminator] ++ terminator_list
      List.flatten(terminator_list)

      state = Map.replace(state, :terminator_list, terminator_list)

      Logger.info("terminator_list post task #{inspect(state.terminator_list)}")
      Logger.info("state after spawning new terminator #{inspect(state)}")
      check_for_spawn()
      {:noreply, state}
    else
      # No need to do anything
      check_for_spawn()
      {:noreply, state}
    end
  end
end
