defmodule Go.Puzzles.Starter do
  @moduledoc """
  The hand-made starter set: the first puzzles of the capture world and of
  the escape world, with hand-written texts.

  The solver checks these puzzles too (see the tests). In the diagrams,
  `B` is blue, `R` is red, and `b` or `r` is the target (see
  `Go.Puzzles.Diagram`).

  In `wrong`, `reply` is the red reply to show. It must be a move that
  makes the puzzle fail.
  """

  alias Go.Puzzle
  alias Go.Puzzles.Diagram

  @doc "All starter puzzles, in the order of the game."
  @spec all() :: [Puzzle.t()]
  def all, do: Enum.map(capture() ++ escape(), &build/1)

  defp build(spec) do
    d = Diagram.parse(spec.rows)

    %Puzzle{
      id: spec.id,
      world: spec.type,
      goal: %{type: spec.type, target: d.target, moves: spec.moves},
      size: d.size,
      blue: d.blue,
      red: d.red,
      answer: spec.answer,
      template: spec.template,
      source: :hand,
      title: spec.title,
      say: spec.say,
      hint: spec.hint,
      better: spec.better,
      win: spec[:win],
      wrong: Map.get(spec, :wrong, %{})
    }
  end

  defp capture do
    [
      %{
        id: "capture-01",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          ". . . . .",
          ". . B . .",
          ". B r . .",
          ". . B . .",
          ". . . . ."
        ],
        answer: {2, 3},
        title: "Close the last road",
        say: "The red tower has only 1 open road left, so it shakes. Build your tower on that road to catch it.",
        hint: "Find the dashed ring next to the red tower.",
        better: "Build on the last open road, to the right of the red tower.",
        win: "You closed its last road, and the red tower fell!"
      },
      %{
        id: "capture-02",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          ". . . . .",
          ". . . . .",
          ". . . . .",
          ". . . B .",
          ". . B r ."
        ],
        answer: {4, 4},
        title: "Towers on the edge",
        say: "This red tower stands on the edge of the board. The edge has no roads. Count the open roads of the red tower, then catch it.",
        hint: "The edge closes roads for free. How many roads are left?",
        better: "Build on the last open road, between the red tower and the corner.",
        win: "The edge and your towers closed all its roads. The red tower fell!"
      },
      %{
        id: "capture-03",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          "r B . . .",
          ". . . . .",
          ". . . . .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {1, 0},
        title: "Towers in the corner",
        say: "A tower in the corner has only 2 roads. Blue already closed one of them. Catch the red tower!",
        hint: "Count the roads of the red tower in the corner.",
        better: "Build below the red tower. That closes its last road.",
        win: "A tower in the corner falls fast. You caught it!"
      },
      %{
        id: "capture-04",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          ". . . . .",
          ". B B . .",
          "B r R . .",
          ". B B . .",
          ". . . . ."
        ],
        answer: {2, 3},
        title: "A wall of two towers",
        say: "Two red towers touch, so a wall joins them into one fort. They share their roads. How many roads does the fort have?",
        hint: "Count the roads of the whole fort, not of one tower.",
        better: "Build on the last open road, at the end of the red wall.",
        win: "The whole red fort fell, both towers!"
      },
      %{
        id: "capture-05",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          ". . . . .",
          ". B . B .",
          "B r . R B",
          ". B . . .",
          ". . . . ."
        ],
        answer: {2, 2},
        title: "Which fort shakes?",
        say: "There are two red towers. One of them has only 1 road left, and it shakes. Catch it.",
        hint: "Count the roads of each red tower.",
        better: "Build between the two red towers. That closes the last road of the left one.",
        win: "You found the shaking tower and caught it!"
      },
      %{
        id: "capture-06",
        type: :capture,
        moves: 1,
        template: "capture_in_1",
        rows: [
          ". . . . .",
          ". . . . .",
          ". . . . .",
          ". B B B .",
          "B r R R ."
        ],
        answer: {4, 4},
        title: "A big fort can fall too",
        say: "Three red towers stand in a row on the edge. They share their roads. Find the last one.",
        hint: "Follow the red wall to its end.",
        better: "Build in the corner, at the end of the red wall.",
        win: "All three red towers fell at once!"
      },
      %{
        id: "capture-07",
        type: :capture,
        moves: 2,
        template: "edge_chase",
        rows: [
          ". r R . .",
          ". B B . .",
          ". . . . .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {0, 3},
        title: "Chase into the corner",
        say: "Catch the red wall in 2 moves. Chase it toward the corner, where it has no roads.",
        hint: "Close the road that leads away from the corner.",
        better:
          "Build at the right end of the red wall. Then Red can only run into the corner, and there it has only 1 road.",
        wrong: %{
          {0, 0} => %{
            what: "Red built below your corner tower, and your tower fell.",
            why: "Your tower in the corner had only 1 road. Red closed it, and then the red wall had 2 roads again.",
            reply: {1, 0}
          }
        }
      },
      %{
        id: "capture-08",
        type: :capture,
        moves: 2,
        template: "edge_chase",
        rows: [
          ". . . r .",
          ". . . B .",
          ". . . . .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {0, 2},
        title: "Chase along the edge",
        say: "Catch the red tower in 2 moves. The edge closes roads for free. Chase Red toward the corner.",
        hint: "Which road leads away from the corner?",
        better: "Build to the left of the red tower. Then Red must run into the corner, and you can close its last road.",
        wrong: %{
          {0, 4} => %{
            what: "Red ran to the left, away from the corner. Now it has 2 roads.",
            why: "Your move closed the road toward the corner. Red ran the other way, into open space. You have only 1 move left, and Red has 2 roads.",
            reply: {0, 2}
          }
        }
      },
      %{
        id: "capture-09",
        type: :capture,
        moves: 2,
        template: "edge_chase",
        rows: [
          ". . . . . . .",
          ". . B . . . .",
          ". B r . R . .",
          ". B . B . . .",
          ". . . . . . .",
          ". . . . . . .",
          ". . . . . . ."
        ],
        answer: {2, 3},
        title: "Keep Red from its friend",
        say: "Catch the red tower in 2 moves. Its friend waits on the right. If the two meet, they share their roads.",
        hint: "Stand between Red and its friend.",
        better: "Build between Red and its friend. Then Red can only run down, into your towers.",
        wrong: %{
          {3, 2} => %{
            what: "Red ran right and joined its friend.",
            why: "Your move touched Red, but it left Red a road toward its friend. Now they share many roads.",
            reply: {2, 3}
          }
        }
      },
      %{
        id: "capture-10",
        type: :capture,
        moves: 3,
        template: "ladder",
        rows: [
          "R . . . . . .",
          ". . . . . . .",
          ". B . . . . .",
          "B r . . . . .",
          ". . B . . . .",
          ". . . . . . .",
          ". . . . . . ."
        ],
        answer: {3, 2},
        title: "The ladder",
        say: "Catch the red tower in 3 moves. Each time, leave Red only 1 road. Red runs in steps, like on a ladder, until it hits the edge.",
        hint: "Close the road on the right. Then Red can only run down.",
        better: "Build to the right of Red. Then Red runs down, and you chase it to the edge, one step at a time.",
        wrong: %{
          {4, 1} => %{
            what: "Red ran right, into open space.",
            why: "Your move closed the road below Red, but it left the road on the right open. There Red gets many roads.",
            reply: {3, 2}
          }
        }
      },
      %{
        id: "capture-11",
        type: :capture,
        moves: 3,
        template: "net",
        rows: [
          ". . . . . . .",
          ". . B B . . .",
          ". B r . . R .",
          ". B . . . . .",
          ". . . . . . .",
          ". . R . . . .",
          ". . . . . . ."
        ],
        answer: {3, 3},
        title: "A small net",
        say: "Catch the red tower in 3 moves. Red has two friends. Do not touch Red: throw a net!",
        hint: "Build corner to corner from Red.",
        better: "Build corner to corner from Red, below and to the right. That closes both ways to its friends, like a net.",
        wrong: %{
          {2, 3} => %{
            what: "Red ran down, toward its friend below.",
            why: "Your move touched Red, but it left Red a road toward its friend below.",
            reply: {3, 2}
          },
          {3, 2} => %{
            what: "Red ran right, toward its friend on the right.",
            why: "Your move touched Red, but it left Red a road toward its friend on the right.",
            reply: {2, 3}
          }
        }
      },
      %{
        id: "capture-12",
        type: :capture,
        moves: 3,
        template: "net",
        rows: [
          ". . . . . . . . .",
          ". . . . . . . . .",
          ". . . . . . . . .",
          ". . . . B B . . .",
          ". . . B r . . R .",
          ". . . B . . . . .",
          ". . . . . . . . .",
          ". . . . R . . . .",
          ". . . . . . . . ."
        ],
        answer: {5, 5},
        title: "The big net",
        say: "Catch the red tower in 3 moves. The board is big, and Red has two friends. Throw a net that does not touch Red.",
        hint: "Two roads lead to the friends. One tower can close both ways.",
        better: "Build corner to corner from Red, below and to the right. Then each way to a friend is closed, like a net.",
        wrong: %{
          {4, 5} => %{
            what: "Red ran down, toward its friend below.",
            why: "Your move touched Red, but it left Red a road toward its friend below.",
            reply: {5, 4}
          },
          {5, 4} => %{
            what: "Red ran right, toward its friend on the right.",
            why: "Your move touched Red, but it left Red a road toward its friend on the right.",
            reply: {4, 5}
          }
        }
      }
    ]
  end

  defp escape do
    [
      %{
        id: "escape-01",
        type: :escape,
        moves: 1,
        template: "escape_extend",
        rows: [
          ". . . . .",
          ". . R . .",
          ". R b . .",
          ". . R . .",
          ". . . . ."
        ],
        answer: {2, 3},
        title: "Run out!",
        say: "Your tower has only 1 open road, so it shakes. Red wants to close it. Build on the open road, and your fort gets new roads.",
        hint: "Find the dashed ring next to your tower.",
        better: "Build on your last open road, to the right. There your fort gets 3 new roads."
      },
      %{
        id: "escape-02",
        type: :escape,
        moves: 1,
        template: "escape_extend",
        rows: [
          ". . . . .",
          ". R . . .",
          "R b R . .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {3, 1},
        title: "Run down",
        say: "Red closed three roads of your tower. Run out on the last one!",
        hint: "Which road is still open?",
        better: "Build below your tower. There your fort gets 3 new roads."
      },
      %{
        id: "escape-03",
        type: :escape,
        moves: 1,
        template: "escape_connect",
        rows: [
          ". . . . .",
          ". R . . .",
          "R b . B .",
          ". R . . .",
          ". . . . ."
        ],
        answer: {2, 2},
        title: "Join your friend",
        say: "Your tower shakes. A friend stands near. Towers that touch join into one fort and share their roads.",
        hint: "Which spot touches your tower and its friend?",
        better: "Build between your tower and its friend. Then they join, and the fort has 5 roads."
      },
      %{
        id: "escape-04",
        type: :escape,
        moves: 1,
        template: "escape_connect",
        rows: [
          ". . . . . . .",
          ". . . . . . .",
          ". . R . . . .",
          ". R b . . . .",
          ". . R B . . .",
          ". . . . . . .",
          ". . . . . . ."
        ],
        answer: {3, 3},
        title: "A friend at the corner",
        say: "Your tower shakes. Its friend touches it only corner to corner, so they are not joined yet.",
        hint: "Towers join only up, down, left and right.",
        better: "Build to the right of your tower. Then it touches its friend, and they share their roads."
      },
      %{
        id: "escape-05",
        type: :escape,
        moves: 1,
        template: "escape_capture",
        rows: [
          ". B R b .",
          ". . . R .",
          ". R R . .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {1, 2},
        title: "Who is faster?",
        say: "Your tower on the edge shakes. But look: a red tower next to it shakes too! Take it first.",
        hint: "Find the red tower with only 1 open road.",
        better: "Build below the shaking red tower. That takes it, and your tower gets its road.",
        wrong: %{
          {0, 4} => %{
            what: "Red closed the last road, and your towers fell.",
            why: "Your tower ran into the corner. There it had only 1 road again.",
            reply: {1, 4}
          }
        }
      },
      %{
        id: "escape-06",
        type: :escape,
        moves: 1,
        template: "escape_capture",
        rows: [
          ". . . . .",
          "b R R . .",
          "B R . . .",
          "R B . . .",
          ". . . . ."
        ],
        answer: {4, 0},
        title: "Take in the corner",
        say: "Your fort on the edge has only 1 road left. Find a red tower that is in more danger than your fort.",
        hint: "Look below your fort.",
        better: "Build in the corner below. That takes the red tower, and your fort gets a new road.",
        wrong: %{
          {0, 0} => %{
            what: "Red closed the last road, and 3 of your towers fell.",
            why: "Your fort ran into the corner. There it still had only 1 road.",
            reply: {0, 1}
          }
        }
      },
      %{
        id: "escape-07",
        type: :escape,
        moves: 1,
        template: "escape_extend",
        rows: [
          ". . . . . . .",
          ". . . . . . .",
          ". . R R . . .",
          ". R b . . B .",
          ". . R . . . .",
          ". . . . . . .",
          ". . . . . . ."
        ],
        answer: {3, 3},
        title: "Run toward your friend",
        say: "Your tower shakes again. Run out, toward your friend.",
        hint: "Only one road is still open.",
        better: "Build to the right of your tower. There your fort gets 2 new roads, and it is closer to its friend."
      },
      %{
        id: "escape-08",
        type: :escape,
        moves: 2,
        template: "escape_extend",
        rows: [
          ". R . . B . .",
          "b B R . . . .",
          "R . . . . . .",
          ". . . . . . .",
          ". . . . . . .",
          ". . . . . . .",
          ". . . . . . ."
        ],
        answer: {2, 1},
        title: "Run to open space",
        say: "Your fort has 2 open roads. One leads into the corner, one leads out to open space. Red attacks. Save your fort for 2 moves.",
        hint: "Where does your fort get more roads?",
        better: "Run down, out to open space. There your fort gets 3 new roads.",
        wrong: %{
          {0, 0} => %{
            what: "Red closed the last road, and 3 of your towers fell.",
            why: "Your fort ran into the corner. The corner has no new roads, so your fort had only 1 road left.",
            reply: {2, 1}
          }
        }
      },
      %{
        id: "escape-09",
        type: :escape,
        moves: 3,
        template: "escape_connect",
        rows: [
          ". . . . .",
          ". . . . .",
          ". R R . .",
          ". b . B .",
          ". B R . ."
        ],
        answer: {3, 2},
        title: "Join, do not run to the edge",
        say: "Your fort has 3 roads. A friend stands near. Red has 3 moves to attack. Save your fort!",
        hint: "A fort with a friend has more roads.",
        better: "Build between your fort and its friend. Joined, they share many roads.",
        wrong: %{
          {3, 0} => %{
            what: nil,
            why: "Your fort ran to the edge. The edge has no roads, and Red got between your fort and its friend."
          },
          {4, 0} => %{
            what: nil,
            why: "Your move went into the corner. The corner has no new roads, and Red got between your fort and its friend."
          }
        }
      },
      %{
        id: "escape-10",
        type: :escape,
        moves: 3,
        template: "escape_extend",
        rows: [
          ". R . b .",
          ". . . B R",
          ". . . R .",
          ". . . . .",
          ". . . . ."
        ],
        answer: {1, 2},
        title: "Run to the middle",
        say: "Your fort stands on the edge. Red has 3 moves to attack. Run where your fort gets the most roads.",
        hint: "Count the roads for each spot. The edge gives few roads.",
        better: "Build to the left of your lower tower. There your fort gets the most roads.",
        wrong: %{
          {0, 2} => %{
            what: nil,
            why: "Your move went along the edge. The edge gives few roads, and Red closed the way to the middle."
          },
          {0, 4} => %{
            what: nil,
            why: "Your move went into the corner. The corner gives no new roads."
          }
        }
      },
      %{
        id: "escape-11",
        type: :escape,
        moves: 3,
        template: "escape_extend",
        rows: [
          ". . . . .",
          ". . B R .",
          ". . . R .",
          ". . . b .",
          ". R R . B"
        ],
        answer: {3, 2},
        title: "Which way?",
        say: "Your tower has 3 open roads, but Red is all around. Red has 3 moves. Find the way out.",
        hint: "Run toward open space and your friend, away from the edge.",
        better: "Build to the left of your tower. That way leads to open space and to your friend.",
        wrong: %{
          {3, 4} => %{
            what: nil,
            why: "Your move went to the edge. There your fort had only a few roads."
          },
          {4, 3} => %{
            what: nil,
            why: "Your move went down, toward the edge and the red towers."
          }
        }
      }
    ]
  end
end
