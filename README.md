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
- the checks of the generator, and a check of each puzzle in the bank,
- LiveView tests with real taps and clicks for each puzzle flow: the
  correct line, the typical wrong moves and their explanations, "Show the
  better move", "Watch again", "Go back one move", "Try again", the hints
  and the stars, "Show the answer", "Next puzzle", and taps on occupied
  points, on illegal points and during the turn of Red.

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
- It cannot be solved in fewer moves.
- Each tempting wrong move (a move that touches the target, or that takes
  stones) really fails, also 2 moves deeper than the limit.
- In an escape puzzle, the fort lives also 2 moves deeper than the limit
  after the correct move.
- It is not a copy of another puzzle, also after rotation or mirroring.

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
attacker moves. It looks only at moves near the fight: the liberties of
the target, the liberties of these liberties, and the liberties of groups
next to the target that are in atari. It uses a sound cut: a target with
L liberties needs at least L attacker moves. It keeps a cache of the
positions that it already checked.

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
