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

## Make the puzzle bank

```sh
mix go.gen.puzzles
```

The task checks the hand-made starter set, makes puzzles from templates,
checks each puzzle with the solver, makes the book of each puzzle, runs
the final check, and writes `priv/puzzles/bank.json`. It takes about 20
minutes on 4 cores. The same seed (`--seed`, 1 by default) gives the same
puzzles. Commit the file after you make it again.

Each puzzle in the bank passes these checks:

- It has exactly one correct first move, on the whole board.
- It cannot be solved in fewer moves. In an escape puzzle, the move limit
  is the danger: if Blue does nothing, Red needs exactly that many moves to
  capture the fort.
- Each tempting wrong move of a capture puzzle (a move that touches the
  target, or that takes stones) really fails: Blue cannot capture Red in
  the move limit plus 6 moves.
- In an escape puzzle, a move is correct only if the fort lives also
  after the move limit: Red cannot capture it in the move limit plus 6
  moves. The game also uses this check during play.
- It is not a copy of another puzzle, also after rotation or mirroring.

In these deep checks, a group with 5 roads or more has escaped: the
search stops there. Without this cut, the deep checks of open positions
are too slow.

On a small board, a group with few roads often dies some moves later.
Thus the templates for the edge chase and the ladder also have red helper
stones ("friends") in the escape path, so that a wrong move really fails.

### The final check

A fixed depth cannot prove that a group escaped. After the generator
keeps a puzzle, the final check looks to the move limit plus 12 moves,
with no 5-road rule (`Go.Puzzles.Proof`). Each claim has a time limit of
20 s (`--proof-ms`). The claims:

- Escape: the fort lives after the answer line. When the check proves
  that the fort dies, the bank drops the puzzle (a hand-made puzzle must
  be fixed).
- Capture: each tempting wrong move fails. When the check proves that the
  wrong move still catches Red later, the puzzle stays, as "mate in N" in
  chess: the texts say only that Blue cannot catch Red in the moves that
  are left. The task shows these "late catches".

A claim that does not finish in time is "unproven", and the puzzle stays.
With seed 1: 89 claims, 1 proven (escape-01), 0 proven false (no late
catch, no dropped puzzle), and 88 unproven. A stronger proving search
comes later, with the world "Two eyes".

### What the texts say

The texts say only what the server proves:

- "Red got away" and "Your fort is safe!" need a proof that the group is
  alive for good: Benson's algorithm (`Go.Life`). For example, escape-01:
  the tower joins a big fort with two courtyards.
- Else, after a wrong capture move, the title is "Red is still free", and
  the text tells that Blue cannot catch Red in the moves that are left.
  When an escape puzzle is solved, the title is "Your fort escaped the
  attack!", and the text tells that Red cannot catch the fort in the moves
  that it has.

### The yield

The yield is the number of good, different puzzles from each template
(seed 1). "Variations" are the positions that the generator made,
"Different" are the positions that are not copies, "Good" are the
positions that pass all checks, and "Kept" are the puzzles in the bank.
A "swapped" template has Blue and Red in the other places, so a capture
becomes an escape.

| Template           | Variations | Different | Good | Kept |
|--------------------|-----------:|----------:|-----:|-----:|
| capture_in_1       |       1644 |       159 |   58 |    6 |
| edge_chase         |        160 |        37 |    7 |    7 |
| edge_chase_swapped |        160 |        47 |    4 |    4 |
| ladder             |        634 |       234 |   16 |    8 |
| ladder_swapped     |        634 |       234 |   37 |    8 |
| net                |       1005 |       503 |   88 |   10 |
| escape_extend      |       1162 |       419 |  277 |    8 |
| escape_capture     |        595 |       508 |   50 |    8 |
| escape_connect     |        603 |       531 |   18 |    8 |

With the 23 hand-made puzzles (12 capture, 11 escape), the bank has 90
puzzles: 43 in the capture world and 47 in the escape world.

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

### Speed

A tap must be fast: a child does not wait. The bank has a book for each
puzzle: the result of each legal first move, and the answer line. So a
first tap, a hint at the start and "Show the answer" need no search. A
later tap shows the blue stone and "Red is thinking…" at once, and the
search runs in a task with a time limit of 700 ms (`:think_ms`). When the
time is over, a fast search in the move limit decides.

`test/go/speed_test.exs` checks that each server action takes less than
1 s, for each puzzle of the bank.

I measured the taps on the WebAssembly runtime of BEAM.com 0.1.0-rc.6:
`app.com` of a release (`RELEASE_ERTS=false mix release`), in `workerd`
on my computer (`wrangler dev`), with a browser at phone width. 231 taps
in 136 tap sequences (the answer lines, a wrong first move and a wrong
second move of each puzzle with 2 moves or more):

- From the tap to the blue stone: 98 ms at most.
- From the tap to the first move of Red, less the planned pause of 700 ms
  before Red moves: 769 ms at most. The slowest are the later taps where
  the time limit of 700 ms ran out. For the 136 first taps (from the
  book), it is 85 ms at most.

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
