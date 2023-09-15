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

  def init(args) do
    Map.put(args, :terminator_list, [])
    check_for_spawn()
    check_for_death()
    {:ok, args}
  end

  def spawn_terminator(terminator_list) do
    id = generate_random_id()
    {:ok, pid} = GenServer.start(Skynet.Terminator, %{})
    t = %Skynet.Terminator{id: id, task_pid: pid}
    terminator_list = [t] ++ [terminator_list]
    List.flatten(terminator_list)
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

  def handle_info(:check_for_death, args) do
    Logger.info("Checking for termination")

    if random_chance_passed?(@chance_of_death) do
      Logger.info("Sarah Connor got this terminator")
      kill_terminator(args.terminator_list)
    else
      check_for_death()
      # No need to do anything
      {:noreply, args}
    end
  end

  def handle_info(:possibly_spawn_terminator, args) do
    Logger.info("Checking for spawning new terminator")

    if random_chance_passed?(@chance_spawn_new) do
      Logger.info("args before spawning new terminator: #{inspect(args)}")
      Logger.info("Spawning new terminator")
      terminator_list = spawn_terminator(args.terminator_list)
      Logger.info("terminator_list post task #{inspect(terminator_list)}")
      Logger.info("args after spawning new terminator #{inspect(args)}")
      %{args | terminator_list: terminator_list}
      Logger.info("args after replacing key #{inspect(args)}")
      # Logger.info("New process #{inspect(pid)} started")
      #      post_spawn_check(self())
      check_for_spawn()
      {:noreply, args}
    else
      # No need to do anything
      check_for_spawn()
      {:noreply, args}
    end
  end
end
