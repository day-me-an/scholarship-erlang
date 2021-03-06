-module (scholarship).
-define (CACHE_FILE, "cache.dat").
-define (DEFAULT_COINS, 36).
-export ([arrange/1, init/0, piles/1, move/1, repeated/2, play/1, game/1, game/0]).

init() ->
  dets:open_file(?CACHE_FILE, []).


piles(Coins) when Coins > 1 ->
  [{Coins - X, X} || X <- lists:seq(1, Coins div 2)].


arrange(1) -> [[1]];
arrange(Coins) when Coins > 1 ->
  case dets:lookup(?CACHE_FILE, Coins) of
    [] ->
      Orderings = lists:foldl(fun arrange/2, [[Coins]], piles(Coins)),
      dets:insert(?CACHE_FILE, {Coins, Orderings}),
      Orderings;
    [{Coins, Orderings}] ->
      Orderings
  end.

arrange({Left, Right}, Positions) ->
  Positions 
  ++
  [LeftAlternate ++ [Right] || LeftAlternate <- arrange(Left), Right =< lists:last(LeftAlternate)].


move(Ordering) when length(Ordering) > 0 ->  
  NewPile = length(Ordering),
  NewOrdering = [Pile - 1 || Pile <- Ordering, Pile > 1] ++ [NewPile],
  lists:reverse(lists:sort(NewOrdering)).


repeated([], _, _) -> not_found;
repeated([H|_], Position, Ordering) when H == Ordering -> {found, Position};
repeated([_|T], Position, Ordering) -> repeated(T, Position - 1, Ordering).
repeated(Ordering, MoveHistory) ->
  repeated(MoveHistory, length(MoveHistory) - 1, Ordering).


play(Ordering, MoveHistory, Score) ->
  NewOrdering = move(Ordering),
  case repeated(NewOrdering, MoveHistory) of
    {found, MoveNumber} ->
      {Score, Score - MoveNumber};
    _ ->
      play(NewOrdering, [NewOrdering|MoveHistory], Score + 1)
  end.
play(Ordering) -> play(Ordering, [], 0).


game(MaxCoins, Coins) when Coins > MaxCoins -> done;
game(MaxCoins, Coins) ->
  Orderings = arrange(Coins),
  Results = lists:map(fun play/1, Orderings),
  Scores = lists:map(fun({Score, _}) -> Score end, Results),
  Loops = lists:map(fun({_, Loop}) -> Loop end, Results),
  io:fwrite("Coins: ~p Max loop=~p Max score=~p \n", [Coins, lists:max(Loops), lists:max(Scores)]),
  game(MaxCoins, Coins + 1).

game(MaxCoins) -> game(MaxCoins, 1).
game() -> game(?DEFAULT_COINS).
