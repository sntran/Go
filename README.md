# Tower Go

Tower Go is a game that teaches Go (cờ vây) to children. I make it for my
son. The player is Blue, and the computer is Red. The default look is
"castles": a tower is a stone, a wall between towers shows connected
stones, and an open road (a dashed ring) is a liberty. A toggle changes
the look to a real Go board.

This first part is the puzzle system, with two worlds:

- **Capture**: "Catch the red tower in N moves." Blue attacks.
- **Escape**: "Save your fort for N moves." Red attacks, and Blue defends.

The server owns the game. The browser gets only the board and the
results, never the answer. A solver plays Red, so each wrong move gets the
correct punishment. After a wrong move, the game shows what happened, why,
and a better move.

The plan is in [`docs/plans/puzzle-system.md`](docs/plans/puzzle-system.md).

## What you need

- Erlang/OTP 29 and Elixir 1.20. Use a local installation, or the tools of
  [BEAM.com](https://github.com/sntran/BEAM.com) (`mix.com` and `iex.com`
  in place of `mix` and `iex`).
- No database. The puzzle bank is a data file in `priv/`.

### Use BEAM.com

`beam.com` is one file that has Erlang/OTP and Elixir. You install
nothing else. BEAM.com has only pre-releases now, so the link
`releases/latest/download` does not work. Download a release by its tag:

```sh
TAG=v0.1.0-rc.6
curl -fLO https://github.com/sntran/BEAM.com/releases/download/$TAG/beam.com
curl -fLO https://github.com/sntran/BEAM.com/releases/download/$TAG/SHA256SUMS
grep " beam.com$" SHA256SUMS | sha256sum -c
chmod +x beam.com
ln -s beam.com mix.com && ln -s beam.com iex.com
```

Put the directory of `mix.com` on your `PATH`, then use `mix.com` in place
of `mix` in all the commands below (for example `mix.com setup` and
`mix.com test`).

## Run the app

```sh
mix setup
mix phx.server
```

Then open <http://localhost:4000>. Choose the capture world or the escape
world, and play.

## Run the tests

```sh
mix test
```

The tests include:

- the rules (capture, suicide, ko), the solver, and the two verified
  puzzles of the plan (the edge chase and the net),
- a comparison of the solver with a slow reference solver
  (`test/support/reference_solver.ex`) that tries all legal moves: on
  1000 random 5x5 positions, and on the puzzles of the bank,
- the checks of the generator, and a check of each puzzle in the bank,
- LiveView tests with real taps and clicks for each puzzle flow: the
  correct line, the typical wrong moves and their explanations, "Show the
  better move", "Watch again", "Go back one move", "Try again", the hints
  and the stars, "Show the answer", "Next puzzle", and taps on occupied
  points, on illegal points and during the turn of Red.

The comparison with the reference solver on the bank puzzles that are
bigger than 5x5 is slow (some minutes). `mix test` does not run it. Run it
with:

```sh
mix test --include reference
```

## Make the puzzle bank

```sh
mix go.gen.puzzles
```

The task checks the hand-made starter set, makes puzzles from templates,
checks each puzzle with the solver, and writes `priv/puzzles/bank.json`.
It takes about 45 seconds. The same seed (`--seed`, 1 by default) gives
the same file. Commit the file after you make it again.

Each puzzle in the bank passes these checks:

- It has exactly one correct first move, on the whole board.
- It cannot be solved in fewer moves. In an escape puzzle, the move limit
  is the danger: if Blue does nothing, Red needs exactly that many moves to
  capture the fort.
- Each tempting wrong move of a capture puzzle (a move that touches the
  target, or that takes stones) really fails: Blue cannot capture Red in
  the move limit plus 6 moves.
- In an escape puzzle, a move is correct only if the fort really lives:
  Red cannot capture it in the move limit plus 6 moves. The game also uses
  this check during play, so it shows "Your fort is safe!" only when the
  fort is safe.
- It is not a copy of another puzzle, also after rotation or mirroring.

The checks are true in real Go, not only in the move limit. On a small
board, a group with few roads often dies some moves later. Thus the
templates for the edge chase and the ladder also have red helper stones
("friends") in the escape path, so that a wrong move really fails.

### The yield

The yield is the number of good, different puzzles from each template
(seed 1). "Variations" are the positions that the generator made,
"Different" are the positions that are not copies, "Good" are the
positions that pass all checks, and "Kept" are the puzzles in the bank.
A "swapped" template has Blue and Red in the other places, so a capture
becomes an escape.

| Template           | Variations | Different | Good | Kept |
|--------------------|-----------:|----------:|-----:|-----:|
| capture_in_1       |       1644 |       157 |   58 |    6 |
| edge_chase         |        484 |       198 |   54 |   10 |
| edge_chase_swapped |        484 |       210 |    3 |    3 |
| ladder             |       1468 |       651 |   84 |    8 |
| ladder_swapped     |       1468 |       656 |   82 |    8 |
| net                |      10224 |      4316 |  770 |   10 |
| escape_extend      |       1162 |       373 |  301 |    8 |
| escape_capture     |        595 |       508 |   44 |    8 |
| escape_connect     |        603 |       531 |   16 |    8 |

With the 23 hand-made puzzles (12 capture, 11 escape), the bank has 92
puzzles: 46 in each world.

## How it works

| Part | Where |
|---|---|
| The rules: capture, no suicide, simple ko | `lib/go/board.ex` |
| The solver: reads a capture fight to the end | `lib/go/solver.ex` |
| The goals (capture, escape) and the moves of Red | `lib/go/goal.ex` |
| One player on one puzzle: moves, help, stars | `lib/go/play.ex` |
| The texts after a wrong move | `lib/go/explain.ex` |
| The puzzle data, the bank, the starter set | `lib/go/puzzle.ex`, `lib/go/puzzles.ex`, `lib/go/puzzles/` |
| The generator, its templates and checks | `lib/go/puzzles/generator.ex`, `templates.ex`, `check.ex` |
| The attempts and the results of each player | `lib/go/progress.ex` |
| The pages | `lib/go_web/live/`, `lib/go_web/components/board_components.ex` |

The solver searches the attacker and the defender to a depth of N
attacker moves. It looks only at moves near the fight:

- the liberties of the target, and the liberties of these liberties,
- the liberties of enemy groups next to the target that have 3 liberties
  or fewer (counter-attacks for the defender, rescues for the attacker),
- the liberties of friend groups that touch a liberty of the target and
  have 3 liberties or fewer.

It uses a sound cut: a target with L liberties needs at least L attacker
moves. It keeps a cache of the positions that it already checked. The
tests compare it with the reference solver, which tries all legal moves.

### Stars

- 3 stars: solved on the first try, with no help.
- 2 stars: solved with one help (a hint, a "Go back", a "Show the better
  move" or a new try).
- 1 star: solved with more help.
- "Show the answer" marks the puzzle as "learned", not "solved". The
  puzzle comes back after 3 days.

### For the leaderboard (later)

Each attempt is stored with the puzzle id, the list of moves, the result
and the stars. Before the server counts a result, it plays the moves again
with the rules engine. The attempts stay in memory for now.

## Deploy

The app does not use a database or NIFs that beam.com does not have, so it
can run on Cloudflare Workers with
[BEAM.com](https://github.com/sntran/BEAM.com). See
`examples/phoenix_demo` in that repository. The deploy is not part of this
step.
