# Plan: strong stories, and runs from a seed

This plan follows [`puzzle-system.md`](puzzle-system.md) and [`puzzle-path.md`](puzzle-path.md). The look, the three-part explanations, the tests and the rules of the repository stay as those plans say.

## 1. Why the stories are weak now

I tested the 3 stories of `Go.SelfPlay`. From each moment, I played the game to its end 10 times after the correct move and 10 times after a wrong move.

- From the same position, the final margin goes from about -88 to +74, because the computer makes big mistakes later. The end of a story is mostly luck.
- Only about 4 of the 20 moments change who wins.
- At many moments, a wrong move is as good as the correct move.
- The first 16 moves stay in the 5x5 corner, so the openings are not real Go.

## 2. A library of strong stories (made offline)

The mix task `mix go.gen.library` makes the library. It runs only on a computer or in CI, never on the server. `Go.SelfPlay` stays only for the tests.

### KataGo

- KataGo plays the games, through its analysis engine (JSON over stdin and stdout, `Go.Katago`).
- The code of KataGo is under an MIT-style license. The network is the official "KataGo Finetuned 9x9 Net (October 2023)", `kata9x9-b18c384nbt-20231025.bin.gz`, under the KataGo Neural Network License (MIT-style). The README tells both licenses, with the copyright notices, and where to download the files. The repository does not hold KataGo or the network.
- The rules are Tromp-Taylor with komi 7: area scoring, as `Go.Score`, and the players capture the dead stones before they pass. Thus the area score at the end is the real score.
- Speed on my computer (4 CPU cores, no GPU, the Eigen AVX2 build of KataGo 1.18.1): about 12 network evaluations each second with the 9x9 network, with all 4 cores. This is slow, thus:
  - The 9x9 network plays all moves (1 evaluation for each move), and makes all final checks.
  - During a game, a small official network (`kata1-b10c128`, about 30 times faster) makes the fast estimates that find the moments (1 evaluation, the same limit of 5 points). After the game, the 9x9 network checks each moment again with a search (16 visits).

### The games

- Both sides play at the same strength: each move comes from the policy of the network (1 evaluation for each move), with some temperature in the opening for variety.
- Real openings: the game uses the whole board from the first move.
- Red makes a realistic mistake only at the moments that become puzzles: on some turns, Red plays one of its top policy moves that leaves a chance for Blue (for example a group with 1 road left, or two groups that it does not join). The solver finds the chance.
- When the solver finds a capture or an escape puzzle for Blue, Blue plays its answer.

### The checks of a moment

1. The normal puzzle checks (`Go.Puzzles.Check`): exactly one correct move, and the tempting wrong moves fail. The moment needs at least one tempting wrong move.
2. The moment matters: by the score estimate of KataGo, the correct move is better than each tempting wrong move by at least 5 points.
3. The correct move is also nearly the best move on the whole board: not more than 2 points worse than the top move of the policy. Else the game goes on without the moment.
4. Two moments are at least 4 moves apart, or 2 moves apart on other groups. A moment with the answer of an earlier moment (in a ko fight, for example) does not count: the computer plays it.

### The checks of a story

0. The game ends with two passes, not at the move limit (160 moves). A cycle of captures can stop a game at the limit.
1. At least 4 moments pass the checks.
2. Not more than half of the moments are "capture in 1".
3. A close game: on the main line, Blue wins by 1 to 10 points, by the KataGo estimate before the end and by the area score at the end.

### The window

The whole board shows. At a moment, the part outside the fight is dimmed. The window is a square of 5x5, 7x7 or 9x9 points, in any part of the board. It holds all the points of the fight: the target group, its roads, the answer, the tempting wrong moves, and the groups next to the target. Nothing that matters is dimmed. A tap in the dimmed part still plays: the board stays open.

### Grade and rank

- The grade of a story comes from the grades of its moments (`Go.Puzzles.Grade`).
- The rank score gives more points when a later moment uses stones of an earlier moment, when the moments teach different ideas, and when the moments become harder.

### The library file

- 300 stories to start with. The README tells how to make more.
- A compact format: the moves are bytes (one byte for each move), in Base64. The board of a moment comes from the moves. Each moment keeps its book.
- The Worker must stay under 64 MiB with `app.com`. I measure the size of the file and of `app.com`, and write it in the README. If it is too big, the library goes outside the Worker bundle (for example in R2).
- The task writes a report: for each story, the main-line score, the score difference of each moment (the correct move against each tempting wrong move), the grade and the rank score. The README has the counts.

## 3. Runs from a seed

- A run has 5 stages. Each stage is one story of the library. The stages become harder: the first stages are short parts of stories with easy moments, and the last stage is a full game to the score.
- A seed chooses the run. The same seed always gives the same run, on each device and after a restart. The server makes the choice with its own random generator from the seed. No neural network runs on the server.
- For each stage, the seed chooses the story (by grade) and one of the 8 rotations or mirrors. The puzzles stay correct after a rotation. The texts with directions come from the rotated board.
- The level of the player chooses which moments are puzzles. The computer plays the other moments by itself. A stronger player gets more moments as puzzles, and harder ones. The level is fixed at the start of a run.
- Continue: the run (the seed, the level, the stage, the moment) stays with the player. The home page shows "Continue the run" and "Start a new run".
- Share: each run has a link with its seed, for example `/run/8F3K`. The run page shows the seed.
- A daily run: one seed for each day, the same for all players.
- The result of each stage (the stars and the help of each moment) stays in `Go.Progress`, for a later leaderboard. No leaderboard now. The leaderboard must never take a move list from the browser.
- Help in a run is only real-Go help: a hint, the road counts, or a take-back ("Go back one move").
- The runs replace the 3 stories of `Go.SelfPlay` on the home page. The world pages and the puzzle bank stay.

## 4. Tests

- Each story of the library passes the checks of part 2.
- A test story whose moments do not change the score is dropped by the checks.
- The same seed gives the same run, the same rotations and the same moments, also after a restart.
- A rotated moment has the same answer (rotated), and passes the puzzle checks.
- Continue a run after a reload, and open a run from its shared link.
- Each server action stays under 1 s, also in a run.

## 5. Changes after the audit of the first library

- **Versions.** Each library file is a version (`priv/library/stories-N.json`), and the old files stay. A run code has the version and the seed (`/run/2-8F3K`). An old link with no version opens version 1. A new run uses the newest version.
- **Progress after a deploy.** The progress (results, runs, stage results, attempts) is in SQLite (`Go.Repo`): on Workers, the SQLite storage of the Durable Object.
- **The window** also holds each stone next to a road of the target, next to the answer and next to each trap.
- **Red answers as the shown answer.** While the player follows the stored answer line, Red prefers the red move of the line.
- **Openings.** For the first 8 moves, the maker takes one of the 6 best different moves (not more than 1.5 points worse than the best). A game whose first 10 moves are the same as in 2 stories stops at move 10. The 14 stories that were the same game as another story are not in version 2.
- **Near moments.** Each difference under 8 points is checked again with 200 visits. A moment under 5 points is dropped.
- **The daily run** uses the date of the player (from the browser), when that date is today somewhere on Earth. Else, the UTC date. A new version is used for the daily runs from 2 days after it is made. The results of a daily run keep its date.

## 6. Not in this plan

- New worlds, and a change of the look. Ask me first.
- The leaderboard.
