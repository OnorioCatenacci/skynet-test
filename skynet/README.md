# Skynet

Notes:

1.) To start the app:https://stackoverflow.com/users/2820/onorio-catenacci?tab=profile

{:ok, original_pid} = GenServer.start(Skynet.Terminator, [max_retries: 5])

2.) To totally kill all processes:

System.stop(0) (or, of course, one can hit Ctrl+C and a to abort everything.)

This bears with a little commentary.  Since each new terminator process is spun up as a separate process, killing the initial process (e. g. Process.exit(original_pid, :normal) ) won't work here.  It will close down the initial process but it won't do anything to the other terminators that may have been created. Hence System.stop(0) is the right way to close all of it down.

3.) It's quite possible (in fact I've seen it several times) to have the initial "terminator" get destroyed without ever spawning any additional terminators.  I'm not sure if this is intentional or not--I can't quite tell from the specs I was given.

As you'll see I haven't even gotten to the API implmentation.  I could have gone with either a REST API or a GraphQL but I feel like either one of them would only make sense if I were persisting state somewhere--maybe even a SQLite DB.  I hadn't got round to that yet.

I will say that while I agree with asking someone to write Task/GenServer code is surely a good test of Elixir know-how in the jobs I've had professionally coding Elixir it hasn't come up.  I mean--at all.  In all the jobs I've had we wrote code to fetch code from either a GraphQL endpoint or a REST endpoint and we never spawned/tasked/genserver'd up background processes to do so.  I suspect you won't even need to read this paragraph to see how much I struggled to recall this portion of Elixir's library.  It's not an excuse but it is an explanation.  Everything we did we deployed to Docker containers then we deployed the docker containers with Kubernetes on AWS.  But at no point did I need to actually code up GenServers or other mechamisms of that sort--so for this exercise I had to fire up some rarely used neurons. 

So if you've gotten this far and you've looked at my code I suspect you'll decide I'm not a fit for GetThru.  I'm far from finishing the exercise which I'm sure you consider trivial (as I said above, I'd dispute "trivial" given the lack of people using things like GenServer in practice but YMMV). 

If so, then thanks for your time and thanks for helping me to refresh my memory on GenServers etc.  I am honestly more senior and more capable with Elixir than this code probably demonstrates.  Look here: https://stackoverflow.com/users/2820/onorio-catenacci?tab=profile and look at some of the Elixir answers I've provided to people. I'm not bragging or trying to toot my own horn--just trying to insure you're aware of my honest weaknesses and strengths. But if I were in your shoes the fact that I failed to finish this after more than a week would be a red flag and I wouldn't blame you if you just pass. 


