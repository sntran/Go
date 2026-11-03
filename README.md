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

The main path is a **run**: 5 stages, and each stage is a real 9x9 game
that KataGo played. At each key moment of the game, the player finds the
best move. A seed chooses the run, so a friend can play the same run. See
[Runs](#runs) and [`docs/plans/story-runs.md`](docs/plans/story-runs.md).

## What you need

- Erlang/OTP 29 and Elixir 1.20. Use a local installation, or the tools of
  [BEAM.com](https://github.com/sntran/BEAM.com) (`mix.com` and `iex.com`
  in place of `mix` and `iex`).
- The puzzle bank and the library of stories are data files in `priv/`.
  The progress of the players is in SQLite (`ecto_sqlite3`; the NIF of
  `exqlite` 0.41.0 is in beam.com). In dev and test, the files are in
  `tmp/`.
- Only to make the library again: KataGo and two of its networks (see
  [The library of strong stories](#the-library-of-strong-stories)).

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
- the path (the skip and the reviews),
- the library: each story passes the checks of the maker (from the data
  in the file), a sample of the moments runs the full puzzle checks again,
  a rotated moment keeps its answer (rotated) and passes the checks, and a
  test story whose moments do not change the score is dropped,
- the books: each tap and the hint in each position of each book (the
  bank, and each moment of each library version, unturned and turned)
  run with no search (`test/go/book_test.exs`),
- the stored answer lines: for each moment of each version of the
  library, in all 8 rotations, the answer line solves the puzzle with real
  taps (Red answers as the shown line),
- the progress: the session cookie lives one year; a transfer code moves
  the progress, and a used, an old or a wrong code does not; at most 5
  wrong codes in one hour; a run page keeps little memory, and pages
  hibernate,
- the windows: in each version, no stone next to a road of the target,
  next to the answer or next to a trap is dimmed,
- the maker: a difference under 8 points is checked again with 200
  visits; the opening takes different moves; a game stops at move 10 when
  2 stories have its opening,
- the runs: the same code gives the same run, the same rotations and the
  same moments, also after a restart; the run of an old link stays the
  same in later versions of the library; a run plays from stage 1 to the
  score, with the correct moves and with wrong moves; a run goes on after
  a reload and after a restart of the app (the progress is in SQLite),
  and opens from a shared link; the daily run uses the date of the
  player only when it is today somewhere,
- LiveView tests with real taps and clicks for each puzzle flow: the
  correct line, the typical wrong moves and their explanations, "Show the
  better move", "Watch again", "Go back one move", "Try again", the hints
  and the stars, "Show the answer", "Next puzzle", and taps on occupied
  points, on illegal points and during the turn of Red.

## The path through the puzzles

The plan is in [`docs/plans/puzzle-path.md`](docs/plans/puzzle-path.md).

- **The skip.** The puzzles of a world are grouped by their idea (the
  template: capture in 1, edge chase, ladder, net, and so on). The first
  puzzle of an idea is a test. When the player solves it on the first try
  with no help, the path skips the other puzzles of the idea. After help
  or a failure, the next puzzle is of the same idea. The world page
  (`/worlds/capture`, `/worlds/escape`) shows all puzzles, and a skipped
  puzzle as "Skipped. You know this one."
- **The mix.** When 2 ideas or more are finished, each 4th puzzle is a
  review of an earlier idea. A review shows only its goal as its title,
  so that the player reads the board before he knows the idea.

## Runs

The plan is in [`docs/plans/story-runs.md`](docs/plans/story-runs.md).

- A run has 5 stages. Each stage is one story of the library (see below).
  Stages 1 and 2 are short parts of a story with its 2 easiest moments,
  stages 3 and 4 are longer parts with 3 and 4 moments, and stage 5 is the
  full game, to the score. The stories come from 5 tiers of the library,
  from the easiest grade to the hardest.
- A run code has the version of the library and a seed of 4 letters and
  digits, for example `2-8F3K`. The seed chooses the run: the story of
  each stage, and one of the 8 rotations or mirrors. The server makes the
  choices with its own random generator from the seed, so the same code
  always gives the same run, also when the library has a new version (each
  version stays in `priv/library`). A new run uses the newest version. An
  old link with no version (`/run/8F3K`) opens the run of version 1. No
  neural network runs on the server. The texts come from the rotated
  board.
- The level of the player (1 to 3, from the ideas that the player knows in
  the worlds and the runs that the player finished well) chooses which
  moments are puzzles. The computer plays the other moments. A stronger
  player gets more puzzles, and harder ones. The level is fixed at the
  start of a run.
- The whole board shows. During a puzzle, the part outside the fight is
  dimmed. A tap there still plays.
- The home page has "Continue the run", "Start a new run" and "Play the
  daily run". The link `/run/2-8F3K` opens a run, and the run page shows
  its code.
- The daily run: one run for each date, the same for all players of that
  date. The date is the date of the player: the browser sends it. The
  server takes it only when it is today somewhere on Earth (not more than
  14 hours before or 12 hours after the UTC date), so a changed time zone
  cannot open the run of tomorrow early. With no date, the server uses the
  UTC date. The results of a daily run keep its date, so players can
  compare.
- A new version of the library starts daily runs only when it is live.
  When the server first sees a version, it stores the time in SQLite
  (`Go.Library.Seen`, the table `library_versions`). The version starts
  daily runs on the later of two dates: its `daily_from` date (2 days
  after the task made it), and the first date that had not started
  anywhere on Earth at that time (the date in UTC+14, plus one day). So a
  version that is deployed late never changes a daily run that a player
  started already, and all players of one date play the same run.
- The place in a run and the result of each stage (the stars and the help
  of each puzzle) stay in `Go.Progress`, in SQLite, for a later
  leaderboard. They stay after a new deploy.

## The progress of a player

- There are no accounts. The progress (stars, puzzles, runs) belongs to
  the player id in the session cookie. The cookie lives one year, and each
  visit sends it again, so the year starts again.
- **Move my progress to another device** (`/move`, a link at the bottom
  of the home page): the page shows a code of 10 characters from the
  alphabet of the run codes (32 ** 10 = 2 ** 50 codes, so nobody can guess
  one). It works one time, for 24 hours. On the other device, the player
  types it, and that browser gets the same player id. A browser can type
  at most 5 wrong codes in one hour. The codes and the tries are in SQLite
  (`Go.Transfer`).

## How many players one Durable Object serves

The details are in [`docs/load-test.md`](docs/load-test.md) and
[`docs/beam-memory.md`](docs/beam-memory.md). The real limit is the
memory: the memory of the VM never shrinks, and when the isolate goes
over its limit, the Durable Object resets. `scripts/load/series.mjs`
starts N players at the same time on a new VM for each N, on `wrangler
dev` or on Cloudflare, and reads the memory of the VM
(`wasm_host:memory/0`) each 5 s. With beam.com built from `main` of
BEAM.com (with the fix of #145) and `-Mea min`:

| Players | VM peak, `wrangler dev` | VM peak, Cloudflare | Cloudflare | Tap → blue stone, p95 (Cloudflare) |
|---:|---:|---:|---|---:|
| 1 | 54 MB | 48 MB | pass | 144 ms |
| 5 | 86 MB | 80 MB | pass | 148 ms |
| 10 | 134 MB | 123 to 127 MB | pass, pass, pass | 141 to 145 ms |
| 15 | 190 MB | reset after 167 MB | reset, reset | |
| 20 | 220 MB | reset after 160 MB | reset, reset | |

- On Cloudflare, one Durable Object serves 10 players who start at the
  same time with no reset (with the default flags of the VM: 7). The tap
  times include about 100 ms of network. Players who come one after the
  other need less.
- Above 100 MB of VM memory (`MEMORY_LIMIT_MB`), a new player gets the
  page "Too many players are here now. Try again in one minute." A player
  who is already here continues to play (`Go.Capacity`).
- The production Worker still runs beam.com 0.1.0-rc.6, because no
  release has the fix yet. There, the guard is off.
- By the time of a tap, it serves about 150 players (an earlier test).
- The memory of the VM never shrinks, and in WebAssembly it grows far
  above the memory that Erlang uses. `docs/beam-memory.md` is a report
  for BEAM.com about this.
- A page that waits 5 s on "Red is thinking…" asks the server for the
  current state (the hook `Busy`), so a player never waits forever.

```sh
mix go.gen.library --count 100   # 100 more stories
```

The task makes the stories offline, on a computer or in CI. It never
runs on the server. It writes a new version of the library: the stories
of the newest version and the new stories, in a new file
`priv/library/stories-N.etf`. A change of the library (one story more
or less) changes almost all runs, so each change is a new version, and
the old files stay for the old links. The task also writes the report
`docs/library-report.md`. The library file keeps the next seed, so the
task never plays a seed again. When a run of the task stops early, the
next run goes on from the parts file `library-parts.jsonl`.

How the maker works (`Go.Library.Maker`):

1. **The games.** KataGo plays both sides at the same strength: each move
   comes from the policy of the strong 9x9 network. For the first 8
   moves, the game takes one of the 6 best different moves of the policy
   by chance (the copies of a move under a symmetry of the board count one
   time), when it is not more than 1.5 points worse than the best of them.
   A game whose first 10 moves (with the rotations) are the same as in 2
   stories of the library stops at move 10, and a game that is the same as
   a story is dropped.
2. **Red's mistakes.** Red makes a realistic mistake only at a moment that
   becomes a puzzle: one of its top policy moves that gives Blue a puzzle
   that passes all checks. Blue then plays the answer.
3. **A moment matters.** It passes the normal puzzle checks, it has at
   least one tempting wrong move, and by the score estimate of KataGo the
   answer is better than each tempting wrong move by at least 5 points
   (after the game: a search of 16 visits, and each difference under 8
   points again with 200 visits). The answer is also nearly the best move on the whole board (not more
   than 2 points worse than the top move of the policy). Two moments are
   at least 4 moves apart, or 2 moves apart on other groups. A moment with
   the answer of an earlier one (in a ko fight, for example) does not
   count.
4. **A story.** The game ends with two passes (not at the move limit of
   160 moves). At least 4 moments matter, not more than half of them are
   "capture in 1", and the game is close: Blue wins by 1 to 10 points, by
   the score estimate before the end and by the area score at the end.
5. **The window** of a moment is the smallest square of 5x5, 7x7 or 9x9
   points, anywhere on the board, that holds the fight: the target group
   and its roads, the answer, the tempting wrong moves, the groups next to
   the target, the answer line, and each stone next to a road of the
   target, next to the answer or next to a tempting wrong move. So no
   stone that touches the fight is dimmed.
6. **Grade and rank.** The grade of a story is the mean grade of its
   moments. The rank score gives points when a later moment uses stones
   of an earlier moment, for each different idea, and when the moments
   become harder.
7. **The book** of each moment has each tap in each position that a player
   can reach (see [Speed](#speed)). While the player follows the answer
   line, Red plays the red moves of the line. So a player who repeats the
   shown answer wins, also on a turned board.

### KataGo

Download KataGo and the networks from their official pages. The
repository does not hold them.

- KataGo 1.18.1, the CPU build ("eigenavx2", Linux):
  <https://github.com/lightvector/KataGo/releases/tag/v1.18.1>.
- The strong network: "KataGo Finetuned 9x9 Net (October 2023)",
  `kata9x9-b18c384nbt-20231025.bin.gz`, from
  <https://katagotraining.org/extra_networks/>.
- The fast network (optional): `kata1-b10c128-s1141046784-d204142634.txt.gz`,
  a small network of the "kata1" run, from
  <https://katagotraining.org/networks/>.

```sh
export KATAGO=~/katago/katago
export KATAGO_MODEL=~/katago/kata9x9-b18c384nbt-20231025.bin.gz
export KATAGO_FAST_MODEL=~/katago/kata1-b10c128-s1141046784-d204142634.txt.gz
mix go.gen.library --count 100
```

The rules of KataGo are the rules of this game: area scoring, simple ko,
no suicide, komi 7, and no pass before the dead stones are captured. Thus
the area score at the end is the real score.

The strong network plays all moves, and makes all final checks. During a
game, a fast estimate (1 visit) finds the moments that matter. With a fast
network, the fast network makes these estimates. After the game, a search
of the strong network (16 visits) checks each moment again, with the same
limit of 5 points, and the game must be close by its estimate too.

The speed on my computer (4 CPU cores, no GPU, the Eigen AVX2 build of
KataGo 1.18.1): the 9x9 network makes about 12 evaluations each second.
With both networks and 8 games in parallel, the maker played about 12
games each minute, and about 1 game in 10 made a story: about 1.2 stories
each minute. The 300 stories took about 4 hours. A computer with a GPU is
much faster.

### Licenses of KataGo and its networks

KataGo is under an MIT license:

> Copyright 2025 David J Wu ("lightvector") and/or other authors of the
> content in this repository.
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the
> "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish,
> distribute, sublicense, and/or sell copies of the Software, and to permit
> persons to whom the Software is furnished to do so, subject to the
> following conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
> NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
> DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
> OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
> USE OR OTHER DEALINGS IN THE SOFTWARE.

The KataGo binary also has third-party parts with their own licenses (see
the `cpp/external` directory of the KataGo repository).

Both networks are official KataGo networks of katagotraining.org (the 9x9
network on the "extra networks" page, labeled as a KataGo network, and
the small network of the "kata1" run). They are under the KataGo Neural
Network License
(<https://katagotraining.org/network_license/>):

> Copyright 2026 David J Wu ("lightvector").
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of the neural net files or training weight files (the "Software"),
> to deal in the Software without restriction, including without
> limitation the rights to use, copy, modify, merge, publish, distribute,
> sublicense, and/or sell copies of the Software, and to permit persons to
> whom the Software is furnished to do so, subject to the following
> conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
> NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
> DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
> OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
> USE OR OTHER DEALINGS IN THE SOFTWARE.

The repository holds only the games (the moves) and the checks that came
from these programs, not the programs or the networks.

### The library now

Two versions:

- **Version 1** (`stories-1.etf`): the first 300 stories. It stays for
  the old links and the runs in progress. Only its windows changed (they
  hold the stones that touch the fight); its stories and moments are the
  same, so its runs are the same.
- **Version 2** (`stories-2.etf`), the newest: version 1 without the 14
  stories that were the same game as another story, with each difference
  under 8 points checked again with 200 visits (29 moments fell under 5
  points, and 7 stories then had fewer than 4 moments), and 21 new stories
  with the new openings. Its `daily_from` date is November 3, 2026: the
  daily runs use it from then, or later when it is deployed late.

Version 2:

- 300 stories, from 3225 games. 1721 moments: capture in 1: 552,
  capture in 2: 245, capture in 3: 399, escape in 1: 434, escape in 2: 68,
  escape in 3: 23.
- 4 to 13 moments in a story. Games of 46 to 112 moves. Blue wins each
  game by 1 to 10 points. The grades of the stories go from 22 to 48, and
  the rank scores from 20 to 150. No two stories are the same game.
- The openings: 11 different first two moves (5 in version 1), and 120
  different first 10 moves. Each of the new stories has its own first 10
  moves.
- The windows: 550 moments of 5x5, 589 of 7x7, and 582 of 9x9 (the whole
  board, nothing dimmed).
- The report for each story: [`docs/library-report.md`](docs/library-report.md).

The second check with 200 visits took about 3.5 hours on my computer (771
positions), and the 21 new stories about 2 hours, with the second check
too.

The size: each library file is about 470 KB (about 1.6 KB for each story,
with the books). `app.com` of a release with both versions is 37,121,157
bytes (35.4 MiB, 20.6 MB with gzip). This is under the limit of 64 MiB of
the Worker, so the library stays in the Worker bundle. No R2 is needed.
Each new version adds about 0.5 MB.

## Make the puzzle bank

```sh
mix go.gen.puzzles
```

The task checks the hand-made starter set, makes puzzles from templates,
checks each puzzle with the solver, makes the book of each puzzle, runs
the final check, and writes `priv/puzzles/bank.etf`. It takes about 20
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
| The attempts and the results of each player (SQLite) | `lib/go/progress.ex`, `lib/go/repo.ex` |
| The library of stories, and its maker (offline, with KataGo) | `lib/go/library.ex`, `lib/go/library/`, `lib/go/katago.ex` |
| The runs: a seed, 5 stages, the level | `lib/go/runs.ex` |
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

A tap must be fast: a child does not wait, and one Durable Object serves
all players. So during play the server never searches: a tap is only a
lookup in the book of the puzzle (`Go.Book`).

- The book has every position that a player can reach: the correct line,
  and each legal tap at each turn. A wrong tap ends the puzzle after Red's
  punishment, so the tree is small: it grows only along the good taps.
- For each tap: the result (solved, good or wrong); for a good tap, Red's
  reply (the same reply as the shown answer line) and if the goal is
  reached after it; for a wrong tap, Red's punishment and the better move.
  The three-part explanation comes from these data and the board (it
  needs no search). Each position also has its good taps, for the hint.
- The book is for the unturned board. A turned puzzle of a run keeps its
  symmetry: a lookup turns the tap back, and turns the result again.
- A library file keeps each book as Base64 text in memory, and a puzzle
  decodes its book when it starts. So the books of all versions do not
  fill the memory of the Durable Object.
- If a position is ever not in the book, the old search runs, with its
  time limit of 700 ms (`:think_ms`), and the server logs the position
  (and sends the telemetry event `[:go, :play, :search]`), so that we can
  find the gap. `test/go/book_test.exs` plays each tap in each position of
  each book (the bank, and each moment of each library version, unturned
  and turned), and the hint in each position, and checks that no search
  runs.

The books now (made by `mix go.gen.books`, on my computer with 4 cores):

| | Books | Positions | Taps | Book bytes | File | Time |
|---|---:|---:|---:|---:|---:|---:|
| The bank (`bank.etf`) | 90 | 149 | 5,607 | 31 KB | 104 KB | 9.5 min |
| Library version 1 | 1,745 | 3,136 | 141,868 | 738 KB | 1.27 MB | 27.6 min |
| Library version 2 | 1,721 | 3,101 | 139,370 | 725 KB | 1.25 MB | 21.9 min |

No tap needed more than the time limit of the build (60 s for one tap).
The files hold the books in Base64, so they are about 1.7 times the book
bytes.

- `mix go.gen.puzzles` (the whole bank, with the books): 16 min 44 s. It
  gives the same puzzles and the same books as the bank.
- `mix go.gen.library`: the books add about 1 s for each moment (on 4
  cores), so about 30 minutes for 300 stories, after the KataGo part
  (about 4 hours for the first 300 stories, see above).
- `app.com` with the bank and both library versions: 37,640,528 bytes
  (35.9 MiB, 21.0 MB with gzip). This is under the limit of 64 MiB. Now
  `app.com` has only the part for WebAssembly: 12,284,027 bytes.

`test/go/speed_test.exs` checks that each server action takes less than
1 s, for each puzzle of the bank and for the puzzles of a run.

Before the full books, I measured the taps on the WebAssembly runtime of BEAM.com 0.1.0-rc.6:
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
with the rules engine. The result of each stage of a run (the stars and
the help of each puzzle) is stored too. All results come from the plays on
the server: the leaderboard must never take a move list from the browser.
The data is in SQLite.

## Deploy to Cloudflare Workers

The app runs on Cloudflare Workers with
[BEAM.com](https://github.com/sntran/BEAM.com), as
`examples/phoenix_demo` of that repository. Its database is the SQLite
storage of the Durable Object: beam.com sends each statement of Ecto
SQLite there, and gives `DATABASE_PATH`. These files do the deploy:

| File | What |
|---|---|
| `package.json` | The dev dependencies `beam.com` and `wrangler`, and the scripts `build` and `deploy`. |
| `scripts/app-com.sh` | The build: a release with no ERTS (`RELEASE_ERTS=false`), in one file `app.com`, for WebAssembly only (`--target wasm32`, about 12 MB). |
| `worker.js` | The entry of the Worker: `serve(app)` of the npm package `beam.com`. |
| `wrangler.jsonc` | The Worker `go`, with one Durable Object that runs the VM, and `BEAM_ERL_FLAGS` = `-Mea min` (less memory, see `docs/load-test.md`). |

The Worker is stateful: one Durable Object runs one VM for all the
requests, as LiveView needs. The Worker needs no secret: the VM makes
`SECRET_KEY_BASE` one time and keeps it, and `PHX_HOST` is the host of the
first request. The progress of the players is in the SQLite storage of
the Durable Object, so it stays after a new deploy. The migrations run at
each start. The SQLite of Workers takes only text and numbers, so
`Go.Progress` keeps each value as text (an Erlang term in Base64).

I checked this with `wrangler dev`: a run in progress went on at the same
puzzle after a restart of the Worker.

Two variables of the Worker change the memory guard (`config/runtime.exs`):
`MEMORY_LIMIT_MB` (100 by default, or `off`) and `MEMORY_STATS=1` (the
route `/stats/memory` for the load test; off by default). The guard needs
`wasm_host:memory/0`, which only beam.com after BEAM.com #145 has. When a
release of beam.com has it, set its version in `package.json`.

### Deploy at each push (Workers Builds)

1. In the Cloudflare dashboard, open Workers & Pages, select Create, and
   import the GitHub repository `sntran/Go`.
2. Set the build command to `npm run build`, and the deploy command to
   `npm run deploy`.
3. Save. Cloudflare builds and deploys the Worker at each push to
   `main`. The address is `https://go.<your subdomain>.workers.dev`.

### Deploy from your computer

```sh
npm install
npm run build            # makes app.com for the Worker (about 1 minute)
npx wrangler login       # one time
npm run deploy
```

To try the Worker on your computer first: `npx wrangler dev`, then open
<http://localhost:8787>.
