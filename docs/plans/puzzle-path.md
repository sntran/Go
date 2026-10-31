# Plan: the puzzle path and the story games

This plan follows [`puzzle-system.md`](puzzle-system.md). The look, the three-part explanations, the tests and the rules of the repository stay as that plan says. Read both plans before you start.

## 1. Goal

The path through the puzzles must be shorter at the start, and it must lead to a full game:

- A player who knows an idea does not play the same puzzle again.
- The earlier ideas come back between the new ones.
- Story games show that the small fights are parts of one real 9x9 game.

## 2. Ideas, and the skip

An **idea** is the template of a puzzle: `capture_in_1`, `edge_chase`, `ladder`, `net`, `escape_extend`, `escape_capture`, `escape_connect`, `edge_chase_swapped`, `ladder_swapped`. The hand-made puzzles have a template too.

- The ideas of a world come in the order of their first puzzle in the world (from easy to hard). The puzzles of an idea come in the order of the world.
- The first puzzle of an idea is a test. A puzzle is **solved clean** when the player solves it on the first try with no help (3 stars).
- When the player solves a puzzle of an idea clean, the idea is **known**. The path skips the other puzzles of the idea, and goes to the next idea.
- When the player needs help or fails, the path gives the next puzzle of the same idea, until the player solves one clean.
- When no puzzle of an idea is left, the idea is **practised**. The path goes to the next idea.
- An idea that is known or practised is **finished**.
- The skipped puzzles stay available. The world page lists all puzzles by idea, and shows a skipped puzzle as "Skipped. You know this one."
- A learned puzzle ("Show the answer") comes back when it is due, as now.

The code: `Go.Path` (no processes). It takes the results of the player and gives the next puzzle. The results come from `Go.Progress`.

## 3. Mix the earlier ideas into the later puzzles

When 2 ideas or more are finished, about 1 puzzle in 4 is a **review**: a puzzle of an earlier, finished idea. Practice that mixes problem types gives better results on a later test than practice of one type at a time (Rohrer and Taylor, 2007).

- `Go.Progress` counts the puzzles since the last review. After 3 new puzzles, the next puzzle is a review.
- A review puzzle is a skipped puzzle of a finished idea (the first one of the earliest idea). When no skipped puzzle is left, there is no review.
- The player must not know the idea before he reads the board. Thus a review puzzle shows only the goal as its title ("Catch the red tower in 2 moves") and a neutral text ("A puzzle from before. Read the board first."), not the title and the text of its idea.

## 4. Story games

A story game is one 9x9 game. Each puzzle of the story is a **moment** of that game: the position before a key move of Blue.

### The flow

1. The story starts: the first moves of the game play on the board, one by one.
2. A moment: the player plays the puzzle, as a normal puzzle (the same goal, the same help, the same three-part explanation after a wrong move).
3. When the moment is over (solved, failed or learned), the button "Continue the story" plays the main line of the game from the moment, with its correct move, to the next moment. Thus the next moment is always there.
4. The last part: the game plays to its end. The players close the borders, and both pass. Then the page shows the score: towers plus fields for each side.

### The view

- The board is always the full 9x9 board. The solver always uses the full board.
- The view shows only a corner of it: 5x5, then 7x7, then 9x9. The view is the smallest corner window (of these 3 sizes) that holds all the stones. It grows when the game spreads, and it never becomes smaller in a story.
- The sides of the view that are not the edge of the board show that the board goes on.
- The answer of a moment is always in the view.

### Where the games come from

The mix task `mix go.gen.stories` makes the story games, and writes `priv/puzzles/stories.json`.

1. **Self-play.** The computer plays 9x9 games against itself (`Go.SelfPlay`). Its moves, in order of priority: capture a group in atari, save an own group in atari, a tactic that the solver finds (a capture or an escape with one correct move), else a move near the last moves, with some chance. It does not fill its own eyes and fields. The first 16 moves stay in the top-left 5x5 corner, the moves until move 30 in the 7x7 corner, and then the game spreads. When no useful move is left, the player passes. Two passes end the game.
2. **The scan.** For each position where Blue is to play, the task makes puzzles of the open worlds (capture and escape) from the full board, and runs the normal puzzle checks (`Go.Puzzles.Check`). It keeps a moment only when the move of the game is the one correct move. Moments must be at least 4 moves apart.
3. **The choice.** A game is kept only if it gives at least 5 good moments. The task makes games until it has 3 stories. Also, both sides must still have 10 stones or more at the end, and Blue must win: a story where one side loses all its stones is not a real game, and a story must not end with a loss after the player found each key move. The first moment must fit in the 5x5 view, and the last moment must need the full 9x9 board, so that the view grows from the corner.
4. **The book.** Each moment gets its book (the result of each legal first move, and the answer line), as the puzzles of the bank.
5. **The score.** Area scoring: the stones of a side, plus the empty regions that only its stones touch. Red gets 7 points (komi), because Blue plays first.

### The home page

The story is the main path: the home page starts with the button "Continue the story". The world pages stay.

The progress in a story (the story and the moment) stays in `Go.Progress`, in memory, as the other progress.

## 5. Tests

- The skip: solve the first puzzle of an idea on the first try, and the next puzzle is of a new idea. Use a hint, and the next puzzle is of the same idea.
- The mix: after 2 finished ideas, an earlier idea comes back, with the neutral title.
- The world page shows a skipped puzzle as "Skipped. You know this one."
- Story games: play each story from start to end with the correct moves, and with a wrong move at each moment. The story always goes on, and the view grows.
- Each moment of each story passes the puzzle checks, and its answer is the move of the game.
- Each server action stays under 1 s, as in `test/go/speed_test.exs`, also for the moments.

## 6. Not in this plan

- New worlds, and a change of the look. Ask me first.
- A full game against the computer, outside the stories.
- The leaderboard.
