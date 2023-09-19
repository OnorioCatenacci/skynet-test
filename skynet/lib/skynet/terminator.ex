defmodule Skynet.Terminator do
  use GenServer
  require Logger

  @time_for_death_check 10_000
  @chance_of_death 25
  @time_to_spawn_new 5_000
  @chance_spawn_new 20

  defstruct [:id, :task_pid]

  defp generate_random_id() do
    :crypto.strong_rand_bytes(6) |> Base.encode64(padding: false)
  end

  # send_dc_message to pid (send death check message to specified process id)
  # Post :check_for_death atom (message) to message queue of specified process after specified timeout
  defp send_dc_message(pid) do
    Process.send_after(pid, :destroy_terminator, @time_for_death_check)
  end

  # send_sc_message to pid (send spawn check message to specified process id)
  # Post :spawn_terminator atom (message) to message queue of specified process after specified timeout
  defp send_sc_message(pid) do
    Process.send_after(pid, :spawn_terminator, @time_to_spawn_new)
  end

  defp should_act_on_message?(threshold) do
    :rand.uniform(100) <= threshold
  end

  defp terminator_exists?(id, terminator_list) when is_binary(id) do
    Enum.member?(terminator_list, %Skynet.Terminator{id: id})
  end

  defp terminator_exists?(pid, terminator_list) when is_pid(pid) do
    Enum.member?(terminator_list, %Skynet.Terminator{task_pid: pid})
  end

  def init(init_args) do
    max_retries = Keyword.get(init_args, :max_retries, 5)
    send_sc_message(self())
    send_dc_message(self())
    state = %{terminator_list: [], max_retries: max_retries}
    {:ok, state}
  end

  def spawn_terminator() do
    id = generate_random_id()
    {:ok, pid} = GenServer.start(Skynet.Terminator, max_retries: 5)
    %Skynet.Terminator{id: id, task_pid: pid}
  end

  def destroy_terminator(id, terminator_list) when is_binary(id) do
    if terminator_exists?(id, terminator_list) do
      terminator_to_be_destroyed = %Skynet.Terminator{id: id}
      List.delete(terminator_list, terminator_to_be_destroyed)
      Process.exit(terminator_to_be_destroyed.task_pid, :normal)
    end
  end

  def destroy_terminator(pid, terminator_list) when is_pid(pid) do
    if terminator_exists?(pid, terminator_list) do
      terminator_to_be_destroyed = %Skynet.Terminator{task_pid: pid}
      List.delete(terminator_list, terminator_to_be_destroyed)
      Process.exit(terminator_to_be_destroyed.task_pid, :normal)
    end
  end

  def handle_info(:destroy_terminator, state) do
    Logger.info("Checking for terminator destruction")

    if should_act_on_message?(@chance_of_death) do
      Logger.info("Sarah Connor got this terminator")
      destroy_terminator(self(), state.terminator_list)
      {:noreply, state}
    else
      send_dc_message(self())
      # No need to do anything
      {:noreply, state}
    end
  end

  def handle_info(:spawn_terminator, state) do
    Logger.info("Checking for spawning new terminator")

    if should_act_on_message?(@chance_spawn_new) do
      Logger.info("Spawning new terminator")
      terminator = spawn_terminator()
      terminator_list = state.terminator_list
      terminator_list = [terminator] ++ terminator_list
      List.flatten(terminator_list)

      #      state = Map.replace(state, :terminator_list, terminator_list)
      Map.replace(state, :terminator_list, terminator_list)
    end

    send_sc_message(self())
    {:noreply, state}
  end

  def handle_info(:list_all_terminators, state) do
    for t <- state.terminator_list do
      Logger.info("Terminator id: #{t.id}")
      Logger.info("Terminator task process id: #{t.task_pid}")
    end
  end
end
