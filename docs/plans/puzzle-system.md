# Plan: the puzzle system

This plan has all the decisions for the first part of the game. Read all of it before you start.

## 1. Context

I build a Go (cờ vây) learning game for my son. He is 7. I do not know the rules of Go well myself.

- Repository: `sntran/Go`. It is empty now (only `README.md`).
- Stack: Phoenix LiveView. I will deploy it later to Cloudflare Workers with BEAM.com (`sntran/BEAM.com`). See `examples/phoenix_demo` in that repository for a Phoenix app that runs there.
- I will add a leaderboard later. Thus the server must own the puzzle answers and check all results.
- This plan: build the **puzzle system** first, on `main`.

## 2. Versions

Use the latest versions. On 2026-10-30 they were:

- Erlang/OTP 29.1
- Elixir 1.20.5
- Phoenix 1.8.16
- Phoenix LiveView 1.2.13

Check Hex for newer versions before you start. Use the tools of BEAM.com (`mix.com`, `iex.com`) as its README shows, or a local OTP and Elixir of these versions.

Keep the app able to run on BEAM.com on Workers:

- Do not add NIFs that beam.com does not have.
- Do not make the puzzle system need a database. A data file in `priv/` is sufficient for the puzzle bank.
- Generate the app with `mix phx.new`. Follow the choices of `examples/phoenix_demo` where they apply.

## 3. Design decisions (already made)

### The look

- The player is Blue. The computer is Red.
- The default look is "castles". A toggle changes it to a real Go board (Blue = black stones, Red = white stones).
- Every picture must show a real Go rule. Nothing moves after it is placed. The mapping:
  - tower = stone
  - wall between towers = connected stones
  - open road (a dashed ring on an empty point) = liberty
  - fields = territory
- A tower with 1 road left shakes (atari). A captured tower crumbles.
- Each puzzle shows the real Go word too ("Open roads are called liberties").
- The file [`tower-go-prototype.html`](tower-go-prototype.html) in this directory is my earlier prototype. Use it as the reference for the look, the castle drawings and the rules engine. It is one HTML page with JavaScript. Port the ideas to Elixir and HEEx. Do not copy the client-side game logic: in the new app, the server owns the game.

### How a puzzle works

- Each puzzle has a goal that the server can check. Start with two goal types:
  - **Capture**: "Catch the red stone in N moves." Blue attacks.
  - **Escape**: "Save your fort for N moves." Blue defends, and Red attacks.
- The whole board is open. Do not grey out points. If a move is far from the fight, it is a wrong move, and Red gets a free move.
- The computer plays Red with a solver. Red always plays its best defense (or best attack in an escape puzzle). Thus any wrong move gets the correct punishment, also moves that nobody thought of.
- The browser never gets the answer. The server sends only the board state and the results. The solver runs only on the server.
- When the goal is reached, the puzzle is solved. When the goal cannot be reached in the moves that are left, the puzzle is failed.
- No timers. The game must be fun, not stressful.

### Wrong moves must teach

After a wrong move, play out Red's punishment, then show three parts:

1. **What happened.** For example: "Red ran down and joined its friend."
2. **Why.** For example: "Your move touched Red, but it left Red a road toward its friend."
3. **Better move.** A text, and a "Show the better move" button that marks the point.

Also give these buttons: "Watch again" (replay the last moves), "Go back one move", "Try again".

Explanations come from two sources:

- Hand-written texts for each template and for the typical wrong moves.
- Generated texts from the solver's line for all other wrong moves (road counts before and after, "joined its friend", "escaped with N roads").

### Stars and hints

- 3 stars: solved on the first try, with no hint.
- 2 stars: solved with one hint or after one "Go back".
- 1 star: solved after more help.
- "Show the answer" marks the puzzle as "learned", not "solved". The same puzzle comes back some days later.

### Worlds

Worlds, in this order: capture, escape, connect and cut, eyes (two eyes live), ko, fields (territory).
**Build capture and escape now.** Make the data model ready for the other goal types.

Make the difficulty go up slowly. The levers:

- more moves to read (catch in 1, then 2, then 3)
- tempting wrong moves (traps)
- answers that do not touch the target (a net)
- the road counts are hidden on harder levels
- bigger boards (5x5, 7x7, then 9x9)

## 4. The solver and the puzzle generator

### Solver

- Search for the attacker and the defender to a depth of N attacker moves.
- Use this sound cut: a target group with L liberties needs at least L attacker moves. If L is more than the attacker moves that are left, the target survives.
- Look only at moves near the fight:
  - the liberties of the target
  - the liberties of those liberties (second-order liberties)
  - the liberties of attacker groups next to the target that are in atari (to capture them or to save them)
- Keep a cache of positions that you already checked (a transposition table).
- Rules: simple ko, no suicide (a move with no liberty is illegal unless it captures).

### Generator

- Do not use random boards. I tested it: 265 random "catch in 2" boards gave 0 good puzzles.
- Use **templates** made from real Go ideas: capture in 1, edge chase, ladder, net, escape, connect, cut, snapback, two eyes, ko.
- Make variations of each template: the 8 symmetries (rotate and mirror), shift on the board, add or move helper stones, swap the sides.
- The solver must check each variation:
  - It has exactly one correct first move.
  - It cannot be solved in fewer moves.
  - Each tempting wrong move really fails. Check this **deeper than the move limit**. I found this problem: on a 7x7 board, the "wrong" moves also captured Red some moves later, because Red ran into the edge. Helper stones of Red (a "friend" in the escape path) correct this.
  - It is not a copy of a puzzle in the bank, also after rotation or mirroring.
- Give each puzzle a difficulty grade: the number of moves, the number of traps, and if the answer touches the target.
- Run the generator as a mix task (for example `mix go.gen.puzzles`), not in the request path. Commit the bank as a data file in `priv/`.
- Measure the yield: the number of good, different puzzles from each template. I could not measure it, because my test solver was too slow.
- Also make a hand-made starter set: 10 to 15 puzzles for each of the two worlds, with hand-written explanations. The solver must check these too.

### Two verified puzzles (use them as test fixtures)

Coordinates are (row, column), from 0, row 0 at the top.

**Edge chase, 5x5, capture in 2 moves**

- Red target: (0,3). Red helper ("friend"): (1,1). Blue: (1,3). Blue plays first.
- Only answer: Blue (0,2). Red runs to (0,4). Blue (1,4) captures both red stones.
- Wrong: Blue (0,4). Red runs to (0,2) and has 2 liberties. Not solved.
- Correction: my first version of this fixture had no red helper. On an empty 5x5 board, the wrong move (0,4) does not really fail: Red runs along the edge to the other corner, and Blue catches it there some moves later. The helper at (1,1) gives Red a real escape after the wrong move. The answer does not change.

**Net, 9x9, capture in 3 moves**

- Blue: (3,4), (3,5), (4,3), (5,3). Red target: (4,4). Red helpers ("friends"): (4,7), (7,4). Blue plays first.
- There are 74 legal first moves. Only (5,5) works. It does not touch the target.
- Line: Blue (5,5), Red (5,4), Blue (6,4), Red (4,5), Blue (4,6) captures 3 stones. If Red goes to (4,5) first, Blue (4,6), then Red (5,4), Blue (6,4) captures.
- The two tempting moves, (4,5) and (5,4), touch the target. After each of them, Red escapes to a helper. The solver shows that Red survives also at a depth of 8 moves.

## 5. The leaderboard (later), and what to prepare now

- Store each attempt: the puzzle id, the list of moves, the result, the stars.
- The server replays a move list with the rules engine before it counts a result.
- Later, each player can get different generated puzzles from a seed on the server. Then nobody can share a list of answers.
- Do not store hashed answers in the browser. A board has at most 81 points, so a script finds a hashed answer at once.

## 6. Testing

Test as a 7-year-old child plays. I must not find bugs myself.

- Unit tests: the rules (capture, suicide, ko), the solver, the generator checks, and the two fixtures above.
- LiveView tests with real clicks for each puzzle flow:
  - the correct line
  - each typical wrong move, and the three parts of the explanation
  - "Show the better move", "Watch again", "Go back one move", "Try again"
  - hints and the star count
  - "Show the answer" gives "learned", not "solved"
  - "Next puzzle"
  - taps on occupied points, on illegal points and during Red's turn
- Nothing can freeze. Each screen must always give the player a next step.
- If you can, also look at the pages in a real browser at phone width, in the light theme and the dark theme.

## 7. Repository rules

- Write all text in the repository in ASD-STE100 Simplified Technical English: documents, code comments, names, log text and commit messages.
- Write documents in the first person, as me. Never write "the owner".
- Add no notes about the tools that helped to write the code or the text.
- Commit with my identity:
  `git -c user.name="Sơn Trần-Nguyễn" -c user.email=github@sntran.com -c commit.gpgsign=false commit ...`
- Add no `Co-Authored-By` line or other note to a commit.
- For this task, push to `main`. Do not open a pull request.

## 8. Not in this plan

- The 10 lessons of the prototype
- A full game against the computer
- The leaderboard pages
- The deploy to Workers (but keep the app able to deploy, see section 2)

## 9. Done means

- `mix test` passes.
- I can open the app, choose the capture world or the escape world, and play the puzzles with castles or with the real board.
- Each wrong move shows Red's punishment and the three-part explanation.
- The puzzle bank is in `priv/`, and a mix task makes it again.
- `README.md` tells how to run the app, run the tests and make the puzzle bank.
