-module(sb).
-export([start/0]).
-define(MAX_BARBERS, 3).
-define(MAX_SEATS, 10).

start() ->
  BarberShopPID = spawn(fun() -> barber_shop([], 0, yes) end),
  spawn(fun() -> client_generator(BarberShopPID, 50) end).

client_generator(BarberShopPID, ClientsToGenerate) ->
  case ClientsToGenerate of
    0 ->
      BarberShopPID ! client_generator_is_done;
    _ ->
      timer:sleep(random(100, 500)),
      Hair = random(1000, 3000),
      BarberShopPID ! {client, Hair},
      client_generator(BarberShopPID, ClientsToGenerate-1)
  end.

barber_shop(Clients, Barbers, IsCGRunning) ->
  receive
    {client, Hair} ->
      case length(Clients) of
        ?MAX_SEATS ->
          write("A client entered, but there are no available seats."),
          barber_shop(Clients, Barbers, IsCGRunning);
        _ ->
          write("A client entered and found a available seat."),
          {NClient, NBarber} = try_attend([Hair | Clients], Barbers, self()),
          barber_shop(NClient, NBarber, IsCGRunning)
      end;
    barber_is_done ->
      {NClient, NBarber} = try_attend(Clients, Barbers-1, self()),
      case should_continue(NClient, NBarber, IsCGRunning) of
        yes ->
          barber_shop(NClient, NBarber, IsCGRunning);
        no ->
          write("Bye from the glorious barber shop.")
      end;
    client_generator_is_done ->
      case should_continue(Clients, Barbers, no) of
        yes ->
          {NClient, NBarber} = try_attend(Clients, Barbers, self()),
            barber_shop(NClient, NBarber, no);
        no ->
          write("Bye from the glorious barber shop.")
      end
  end.

barber(Hair, BarberShopPID) ->
  write("Barber started his job."),
  timer:sleep(Hair),
  write("Barber has done his job."),
  BarberShopPID ! barber_is_done.

try_attend(Clients, ?MAX_BARBERS, _) ->
  {Clients, ?MAX_BARBERS};
try_attend([], Barbers, _) ->
  {[], Barbers};
try_attend([First | T], Barbers, BarberShopPID) ->
  spawn(fun() -> barber(First, BarberShopPID) end),
  {T, Barbers+1}.

should_continue([], 0, no) ->
  no;
should_continue(_, _, _) ->
  yes.

random(Min, Max) ->
  random:uniform(Max-Min+1)+Min.

write(Message) ->
  io:format(Message ++ "~n", []).