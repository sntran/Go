defmodule Go.Library.Evaluator do
  @moduledoc """
  The program that plays and scores the games of the library maker
  (`Go.Library.Maker`). The real one is KataGo (`Go.Library.KatagoEvaluator`).
  The tests use simple ones.

  An evaluator is `{module, state}`. All scores are from the side of Blue.
  """

  alias Go.Board

  @type t :: {module(), term()}
  @type moves :: [{Board.color(), Board.point() | :pass}]

  @doc "The chance of each legal move (and `:pass`) for the side to move."
  @callback policy(state :: term(), moves()) :: %{(Board.point() | :pass) => float()}

  @doc "The score estimate after the moves, with a search of `visits`."
  @callback score(state :: term(), moves(), visits :: pos_integer()) :: float()

  @doc "Calls `policy/2` of an evaluator."
  def policy({module, state}, moves), do: module.policy(state, moves)

  @doc "Calls `score/3` of an evaluator."
  def score({module, state}, moves, visits), do: module.score(state, moves, visits)
end

defmodule Go.Library.KatagoEvaluator do
  @moduledoc "The evaluator that asks KataGo (`Go.Katago`)."
  @behaviour Go.Library.Evaluator

  @impl true
  def policy(server, moves), do: Go.Katago.policy(server, moves)

  @impl true
  def score(server, moves, visits), do: Go.Katago.score(server, moves, visits)
end
