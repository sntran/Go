# The library report

Made by `mix go.gen.library`. Do not change this file by hand.

- Stories: 300, from 3225 games.
- Moments: 1721. capture in 1: 552, capture in 2: 245, capture in 3: 399, escape in 1: 434, escape in 2: 68, escape in 3: 23.
- Size of `priv/library/stories-2.json`: 470905 bytes.

Why the maker dropped the other new games:

- not a close game by the area score: 48
- fewer than 4 moments that matter: 41
- fewer than 2 moments at move 44: 24
- not a close game by the estimate: 5
- an opening that 2 stories have: 4

For each story: the score of the main line (the area score at the end,
and the score estimate of KataGo before the end), the grade and the rank
score. For each moment: the move, the goal, the answer, the grade, and
how many points the answer is better than each tempting wrong move (by
the score estimate of KataGo). The points use the KataGo coordinates:
the columns A to J (no I) from the left, and the rows 1 to 9 from the
bottom.

```
story-920: 47 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.2. Grade 22. Rank score 45.
  1. Move 29: capture in 1, answer F3, grade 22. Better than: B6 12.6.
  2. Move 31: escape in 1, answer E9, grade 22. Better than: B6 7.6.
  3. Move 33: escape in 1, answer E3, grade 22. Better than: B6 7.0.
  4. Move 37: capture in 1, answer F1, grade 22. Better than: B6 10.4.

story-1551: 73 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 22. Rank score 45.
  1. Move 39: escape in 1, answer G4, grade 22. Better than: A5 33.9.
  2. Move 57: capture in 1, answer F6, grade 22. Better than: C7 18.3.
  3. Move 59: capture in 1, answer E1, grade 22. Better than: C7 17.4.
  4. Move 61: escape in 1, answer G6, grade 22. Better than: C7 18.9.

story-1350: 63 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 22. Rank score 35.
  1. Move 25: escape in 1, answer D3, grade 22. Better than: F6 9.8.
  2. Move 41: capture in 1, answer H9, grade 22. Better than: F6 12.4.
  3. Move 43: capture in 1, answer D9, grade 22. Better than: F6 6.5.
  4. Move 49: escape in 1, answer G9, grade 22. Better than: F6 10.1.

story-978: 73 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 5.7. Grade 24. Rank score 85.
  1. Move 31: capture in 1, answer A5, grade 22. Better than: A7 10.7.
  2. Move 35: capture in 1, answer E9, grade 22. Better than: A7 20.1.
  3. Move 43: escape in 1, answer F9, grade 22. Better than: A7 18.4.
  4. Move 45: capture in 1, answer C9, grade 22. Better than: A7 25.3.
  5. Move 47: escape in 1, answer D9, grade 22. Better than: A7 26.9.
  6. Move 49: capture in 2, answer J8, grade 36. Better than: J9 7.5, A7 7.5.
  7. Move 51: capture in 1, answer A7, grade 26. Better than: J9 9.3, J6 7.8.
  8. Move 55: escape in 1, answer D1, grade 26. Better than: J9 10.1, J6 9.0.
  9. Move 69: escape in 1, answer H9, grade 22. Better than: B3 8.1.

story-2964: 77 moves. Main line: area score Blue 47, Red 38 (Blue wins by 9). Estimate before the end: Blue by 2.0. Grade 24. Rank score 75.
  1. Move 39: escape in 1, answer D7, grade 22. Better than: J4 7.9.
  2. Move 51: escape in 1, answer F2, grade 22. Better than: J4 14.7.
  3. Move 53: capture in 1, answer G3, grade 22. Better than: J4 17.7.
  4. Move 55: capture in 2, answer H1, grade 36. Better than: J4 8.1, F1 12.7.
  5. Move 65: capture in 1, answer E9, grade 22. Better than: J4 13.3.
  6. Move 67: escape in 1, answer F9, grade 22. Better than: J4 13.5.

story-1956: 74 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 8.0. Grade 24. Rank score 65.
  1. Move 21: capture in 2, answer E2, grade 32. Better than: E4 6.5.
  2. Move 23: capture in 1, answer D1, grade 22. Better than: E4 11.4.
  3. Move 29: escape in 1, answer D6, grade 22. Better than: E4 15.4.
  4. Move 39: capture in 1, answer D9, grade 22. Better than: E4 11.0.
  5. Move 53: escape in 1, answer J6, grade 22. Better than: E4 5.2.
  6. Move 65: capture in 1, answer F1, grade 22. Better than: E4 11.4.

story-2859: 67 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 24. Rank score 65.
  1. Move 35: capture in 1, answer A3, grade 22. Better than: F9 14.6.
  2. Move 45: capture in 1, answer J8, grade 22. Better than: F9 6.5.
  3. Move 49: escape in 1, answer F6, grade 22. Better than: F9 6.4.
  4. Move 51: capture in 2, answer C7, grade 36. Better than: F9 24.7, B5 27.3.
  5. Move 53: escape in 1, answer B5, grade 22. Better than: F9 25.6.
  6. Move 55: capture in 1, answer B6, grade 22. Better than: F9 25.5.

story-2579: 63 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 24. Rank score 55.
  1. Move 21: capture in 2, answer B5, grade 32. Better than: D5 6.4.
  2. Move 23: capture in 1, answer A6, grade 22. Better than: D5 11.4.
  3. Move 31: escape in 1, answer F6, grade 22. Better than: D5 15.8.
  4. Move 35: escape in 1, answer H4, grade 22. Better than: D5 15.2.
  5. Move 41: capture in 1, answer H5, grade 22. Better than: D5 12.5.
  6. Move 45: capture in 1, answer C3, grade 22. Better than: D5 7.4.

story-1481: 65 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 25. Rank score 75.
  1. Move 21: escape in 1, answer F4, grade 22. Better than: E7 22.0.
  2. Move 31: capture in 3, answer G2, grade 42. Better than: F1 18.2.
  3. Move 33: escape in 1, answer C8, grade 22. Better than: F1 7.2.
  4. Move 37: capture in 1, answer A7, grade 22. Better than: F1 12.4.
  5. Move 51: capture in 1, answer A9, grade 22. Better than: H6 29.9.
  6. Move 59: capture in 1, answer C9, grade 22. Better than: H6 28.5.

story-1164: 67 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 7.9. Grade 25. Rank score 65.
  1. Move 15: capture in 3, answer C2, grade 42. Better than: D1 11.4.
  2. Move 21: capture in 1, answer B3, grade 22. Better than: D1 20.3.
  3. Move 27: capture in 1, answer A4, grade 22. Better than: D1 13.6.
  4. Move 29: capture in 1, answer F6, grade 22. Better than: D1 17.4.
  5. Move 31: escape in 1, answer E6, grade 22. Better than: D1 13.2.
  6. Move 35: escape in 1, answer H7, grade 22. Better than: D1 18.0.

story-670: 71 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 25. Rank score 55.
  1. Move 29: escape in 1, answer C6, grade 22. Better than: G6 6.3.
  2. Move 35: capture in 1, answer D5, grade 22. Better than: G6 24.7.
  3. Move 49: capture in 2, answer B8, grade 32. Better than: A8 6.5.
  4. Move 61: capture in 1, answer H3, grade 22. Better than: J7 23.6.

story-1421: 76 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 25. Rank score 55.
  1. Move 17: capture in 1, answer J5, grade 22. Better than: C6 14.1.
  2. Move 43: capture in 2, answer J8, grade 32. Better than: J6 12.1.
  3. Move 49: capture in 1, answer J6, grade 22. Better than: G3 10.0.
  4. Move 51: escape in 1, answer H7, grade 22. Better than: G3 9.1.

story-2811: 81 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 25. Rank score 55.
  1. Move 19: capture in 3, answer B2, grade 42. Better than: A3 5.6.
  2. Move 25: escape in 1, answer E5, grade 22. Better than: A3 12.6.
  3. Move 27: capture in 1, answer C5, grade 22. Better than: A3 15.1.
  4. Move 39: capture in 1, answer J8, grade 22. Better than: A3 8.4.
  5. Move 41: capture in 1, answer B6, grade 22. Better than: A3 9.4.
  6. Move 61: escape in 1, answer J7, grade 22. Better than: A5 13.4.

story-1212: 84 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.8. Grade 25. Rank score 50.
  1. Move 21: escape in 1, answer D4, grade 22. Better than: J3 9.5.
  2. Move 57: capture in 1, answer E5, grade 22. Better than: E9 54.7.
  3. Move 61: capture in 1, answer H6, grade 22. Better than: E9 15.8.
  4. Move 71: capture in 2, answer C2, grade 32. Better than: D1 10.7.

story-1302: 75 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 25. Rank score 45.
  1. Move 29: escape in 1, answer F3, grade 22. Better than: F7 6.3.
  2. Move 35: capture in 1, answer E4, grade 22. Better than: F7 24.5.
  3. Move 51: escape in 2, answer E1, grade 32. Better than: G1 15.2.
  4. Move 65: capture in 1, answer C8, grade 22. Better than: J7 19.8.

story-3006: 57 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 25. Rank score 45.
  1. Move 31: capture in 2, answer B8, grade 32. Better than: A9 5.3.
  2. Move 41: capture in 1, answer G1, grade 22. Better than: A9 21.1.
  3. Move 45: escape in 1, answer F1, grade 22. Better than: A9 13.8.
  4. Move 47: capture in 1, answer E3, grade 22. Better than: A9 21.1.

story-373: 76 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 25. Rank score 40.
  1. Move 23: escape in 1, answer G3, grade 22. Better than: A5 10.8.
  2. Move 27: capture in 1, answer A5, grade 22. Better than: E4 13.8.
  3. Move 47: capture in 1, answer B2, grade 22. Better than: C9 12.5.
  4. Move 61: capture in 2, answer C9, grade 32. Better than: E9 15.5.

story-604: 59 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.2. Grade 25. Rank score 35.
  1. Move 21: escape in 1, answer F6, grade 22. Better than: E3 22.2.
  2. Move 29: escape in 1, answer F2, grade 32. Better than: F7 21.4.
  3. Move 35: capture in 1, answer A5, grade 22. Better than: F4 8.6.
  4. Move 39: escape in 1, answer B7, grade 22. Better than: F4 5.8.

story-1061: 54 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.2. Grade 25. Rank score 35.
  1. Move 21: escape in 1, answer F6, grade 22. Better than: C5 22.4.
  2. Move 29: escape in 1, answer B6, grade 32. Better than: G6 21.7.
  3. Move 35: capture in 1, answer E1, grade 22. Better than: D6 8.3.
  4. Move 39: escape in 1, answer G2, grade 22. Better than: D6 5.8.

story-2250: 88 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 26. Rank score 105.
  1. Move 17: capture in 3, answer F2, grade 42. Better than: G1 14.9.
  2. Move 35: escape in 1, answer C6, grade 22. Better than: G1 9.2.
  3. Move 39: escape in 1, answer B6, grade 22. Better than: G1 10.9.
  4. Move 51: capture in 1, answer D9, grade 26. Better than: D2 13.7, G1 17.4.
  5. Move 53: capture in 1, answer C8, grade 22. Better than: G1 15.4.
  6. Move 55: escape in 1, answer F3, grade 26. Better than: B9 23.7, G1 23.6.
  7. Move 57: capture in 1, answer G1, grade 22. Better than: B9 25.3.
  8. Move 67: capture in 1, answer E1, grade 26. Better than: B9 23.9, J8 22.2.
  9. Move 69: escape in 1, answer F1, grade 26. Better than: B9 23.3, J8 20.7.
  10. Move 71: capture in 1, answer J1, grade 26. Better than: B9 26.2, J8 24.6.

story-2685: 64 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 26. Rank score 105.
  1. Move 19: capture in 3, answer B4, grade 42. Better than: A3 8.3.
  2. Move 21: capture in 2, answer C5, grade 36. Better than: D5 10.9, A3 11.0.
  3. Move 23: escape in 1, answer D5, grade 22. Better than: A3 14.7.
  4. Move 31: escape in 1, answer F7, grade 22. Better than: A3 14.3.
  5. Move 35: capture in 1, answer E9, grade 22. Better than: A3 8.5.
  6. Move 41: capture in 1, answer G9, grade 22. Better than: A3 13.0.
  7. Move 49: capture in 1, answer H7, grade 22. Better than: A3 16.9.
  8. Move 57: capture in 1, answer C4, grade 22. Better than: A3 8.4.

story-309: 65 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 26. Rank score 60.
  1. Move 21: escape in 1, answer D6, grade 22. Better than: G5 21.9.
  2. Move 33: capture in 3, answer B8, grade 42. Better than: A7 19.1.
  3. Move 35: escape in 1, answer H3, grade 22. Better than: A7 8.1.
  4. Move 41: capture in 1, answer A7, grade 22. Better than: G1 39.5.
  5. Move 43: escape in 1, answer B7, grade 22. Better than: G1 39.6.

story-3171: 63 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 26. Rank score 55.
  1. Move 31: capture in 1, answer A4, grade 22. Better than: J7 9.4.
  2. Move 35: escape in 1, answer A5, grade 22. Better than: J7 6.0.
  3. Move 37: capture in 2, answer B2, grade 36. Better than: J7 6.2, A1 6.4.
  4. Move 41: capture in 1, answer A1, grade 22. Better than: J7 6.2.

story-2995: 77 moves. Main line: area score Blue 43, Red 42 (Blue wins by 1). Estimate before the end: Blue by 6.0. Grade 26. Rank score 50.
  1. Move 21: capture in 1, answer B3, grade 22. Better than: D5 5.9.
  2. Move 35: capture in 1, answer G6, grade 22. Better than: D5 13.1.
  3. Move 61: escape in 1, answer A5, grade 26. Better than: J8 6.0, D5 6.0.
  4. Move 63: capture in 2, answer B8, grade 40. Better than: A9 20.1, J8 20.1, D5 19.9.
  5. Move 65: capture in 1, answer D5, grade 26. Better than: A9 18.7, J8 20.5.
  6. Move 71: escape in 1, answer A8, grade 22. Better than: J8 5.9.

story-7: 83 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 26. Rank score 35.
  1. Move 33: capture in 2, answer E4, grade 32. Better than: F5 6.9.
  2. Move 47: capture in 1, answer H1, grade 22. Better than: F5 12.1.
  3. Move 71: escape in 1, answer A5, grade 22. Better than: F5 6.5.
  4. Move 77: capture in 1, answer A2, grade 26. Better than: F5 14.4, D1 13.9.

story-2608: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 26. Rank score 35.
  1. Move 39: escape in 1, answer C4, grade 22. Better than: J5 33.6.
  2. Move 45: escape in 1, answer C6, grade 22. Better than: J5 25.1.
  3. Move 49: escape in 2, answer E9, grade 36. Better than: C9 42.9, J5 41.4.
  4. Move 59: capture in 1, answer A9, grade 22. Better than: J5 42.1.

story-3051: 83 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 27. Rank score 120.
  1. Move 15: capture in 3, answer C2, grade 42. Better than: D1 11.0.
  2. Move 21: capture in 1, answer B3, grade 22. Better than: D1 21.0.
  3. Move 23: capture in 3, answer B5, grade 46. Better than: A4 11.5, D1 11.5.
  4. Move 27: capture in 1, answer A4, grade 22. Better than: D1 13.2.
  5. Move 31: capture in 1, answer F6, grade 22. Better than: D1 12.1.
  6. Move 33: escape in 1, answer E6, grade 22. Better than: D1 10.0.
  7. Move 37: capture in 1, answer A6, grade 22. Better than: D1 10.5.
  8. Move 45: capture in 2, answer A7, grade 32. Better than: A9 10.0.
  9. Move 67: escape in 1, answer D4, grade 22. Better than: H1 23.7.
  10. Move 77: capture in 1, answer A2, grade 22. Better than: H1 9.8.

story-305: 85 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 5.8. Grade 27. Rank score 105.
  1. Move 15: capture in 3, answer C2, grade 42. Better than: D1 10.9.
  2. Move 21: capture in 1, answer B3, grade 22. Better than: D1 20.2.
  3. Move 29: capture in 1, answer F6, grade 22. Better than: D1 17.3.
  4. Move 31: escape in 1, answer E6, grade 22. Better than: D1 13.1.
  5. Move 39: escape in 2, answer A7, grade 36. Better than: B8 8.1, D1 12.1.
  6. Move 45: capture in 1, answer A2, grade 22. Better than: D1 20.8.
  7. Move 65: capture in 1, answer J6, grade 22. Better than: D1 6.3.
  8. Move 67: capture in 2, answer D1, grade 32. Better than: F1 11.3.
  9. Move 79: capture in 2, answer G9, grade 32. Better than: J9 23.5.
  10. Move 83: capture in 1, answer B1, grade 22. Better than: J9 5.9.

story-1663: 85 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.5. Grade 27. Rank score 90.
  1. Move 19: capture in 3, answer F8, grade 42. Better than: G9 8.2.
  2. Move 21: capture in 2, answer E7, grade 36. Better than: G9 10.8, E6 11.1.
  3. Move 23: escape in 1, answer E6, grade 22. Better than: G9 14.1.
  4. Move 31: escape in 1, answer A4, grade 22. Better than: G9 26.3.
  5. Move 35: capture in 1, answer B3, grade 22. Better than: G9 32.7.
  6. Move 69: capture in 1, answer C2, grade 22. Better than: G9 8.2.
  7. Move 71: capture in 1, answer D1, grade 22. Better than: G9 7.9.

story-1277: 73 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 27. Rank score 80.
  1. Move 17: capture in 2, answer G9, grade 32. Better than: J9 16.6.
  2. Move 21: escape in 1, answer G4, grade 22. Better than: J9 10.3.
  3. Move 35: escape in 1, answer C5, grade 22. Better than: J9 16.5.
  4. Move 37: capture in 1, answer J9, grade 22. Better than: B4 29.6.
  5. Move 41: capture in 3, answer B5, grade 46. Better than: A6 30.0, B4 12.9.
  6. Move 53: capture in 1, answer H9, grade 22. Better than: B4 37.3.
  7. Move 55: capture in 1, answer J6, grade 22. Better than: B4 38.2.

story-311: 58 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 27. Rank score 75.
  1. Move 23: escape in 1, answer E5, grade 22. Better than: J4 11.3.
  2. Move 27: escape in 1, answer F5, grade 22. Better than: J4 22.4.
  3. Move 29: escape in 1, answer C6, grade 26. Better than: J4 18.0, F3 11.9.
  4. Move 35: capture in 2, answer C9, grade 40. Better than: A9 10.7, J4 19.5, F3 11.7.
  5. Move 41: capture in 1, answer E9, grade 26. Better than: J4 35.1, F3 31.0.
  6. Move 45: capture in 1, answer G7, grade 26. Better than: J4 13.4, F3 15.5.

story-2960: 73 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 27. Rank score 70.
  1. Move 19: capture in 3, answer H2, grade 46. Better than: F8 16.4, G1 10.5.
  2. Move 23: capture in 1, answer G1, grade 22. Better than: F8 7.5.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F8 8.1.
  4. Move 37: escape in 1, answer E6, grade 32. Better than: E5 28.3.
  5. Move 45: capture in 1, answer C9, grade 22. Better than: E3 18.9.
  6. Move 47: escape in 1, answer G6, grade 22. Better than: E3 40.3.
  7. Move 69: capture in 1, answer J1, grade 22. Better than: H5 17.8.

story-498: 72 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 27. Rank score 65.
  1. Move 25: capture in 3, answer H3, grade 42. Better than: J4 6.0.
  2. Move 27: capture in 1, answer G2, grade 22. Better than: J4 8.7.
  3. Move 37: capture in 2, answer E5, grade 32. Better than: J4 6.6.
  4. Move 41: capture in 1, answer D6, grade 22. Better than: J4 24.9.
  5. Move 45: escape in 1, answer E6, grade 22. Better than: J4 28.5.
  6. Move 53: capture in 1, answer E9, grade 22. Better than: J4 14.1.

story-507: 74 moves. Main line: area score Blue 48, Red 39 (Blue wins by 9). Estimate before the end: Blue by 6.0. Grade 27. Rank score 60.
  1. Move 35: capture in 1, answer H6, grade 22. Better than: E3 19.6.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: A4 50.7.
  3. Move 51: capture in 2, answer F8, grade 32. Better than: G9 17.8.
  4. Move 55: capture in 2, answer D8, grade 36. Better than: G9 17.9, E8 16.8.
  5. Move 57: escape in 1, answer E8, grade 22. Better than: G9 20.3.

story-2234: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 27. Rank score 60.
  1. Move 19: capture in 3, answer H8, grade 46. Better than: J7 10.5, B6 16.4.
  2. Move 23: capture in 1, answer J7, grade 22. Better than: B6 6.5.
  3. Move 29: capture in 1, answer H4, grade 22. Better than: B6 23.3.
  4. Move 31: capture in 1, answer G7, grade 22. Better than: B6 13.4.
  5. Move 35: escape in 1, answer H5, grade 22. Better than: B6 16.6.
  6. Move 49: capture in 2, answer D5, grade 32. Better than: C4 5.5.
  7. Move 53: escape in 1, answer B7, grade 22. Better than: C4 7.4.

story-3053: 93 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.7. Grade 27. Rank score 60.
  1. Move 25: capture in 1, answer F7, grade 22. Better than: H7 12.3.
  2. Move 39: capture in 1, answer E1, grade 22. Better than: G8 16.0.
  3. Move 41: capture in 2, answer B2, grade 32. Better than: A1 9.6.
  4. Move 47: escape in 1, answer A1, grade 32. Better than: A2 8.5.

story-3161: 65 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 27. Rank score 45.
  1. Move 21: capture in 3, answer B6, grade 42. Better than: A5 5.6.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: J7 8.5.
  3. Move 51: capture in 1, answer A3, grade 22. Better than: C4 9.8.
  4. Move 59: capture in 1, answer F7, grade 22. Better than: C4 10.1.

story-622: 76 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.7. Grade 27. Rank score 35.
  1. Move 11: capture in 3, answer F8, grade 42. Better than: E9 6.9.
  2. Move 45: escape in 1, answer E7, grade 22. Better than: C1 22.7.
  3. Move 51: capture in 1, answer A4, grade 22. Better than: C1 5.2.
  4. Move 63: capture in 1, answer A2, grade 22. Better than: C1 9.9.

story-1853: 67 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 27. Rank score 35.
  1. Move 19: capture in 3, answer C8, grade 42. Better than: D9 13.2.
  2. Move 33: escape in 1, answer D2, grade 22. Better than: H9 5.3.
  3. Move 37: capture in 1, answer D3, grade 22. Better than: H9 8.0.
  4. Move 45: capture in 1, answer A2, grade 22. Better than: H9 12.8.

story-2891: 78 moves. Main line: area score Blue 47, Red 38 (Blue wins by 9). Estimate before the end: Blue by 3.9. Grade 27. Rank score 35.
  1. Move 33: capture in 3, answer H8, grade 42. Better than: G9 7.9.
  2. Move 35: capture in 1, answer A9, grade 22. Better than: G9 40.3.
  3. Move 39: escape in 1, answer D6, grade 22. Better than: G9 42.4.
  4. Move 43: capture in 1, answer F5, grade 22. Better than: G9 46.0.

story-466: 85 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 28. Rank score 110.
  1. Move 21: escape in 1, answer B6, grade 22. Better than: J7 11.5.
  2. Move 27: capture in 1, answer D5, grade 22. Better than: J7 12.1.
  3. Move 31: escape in 1, answer C5, grade 22. Better than: J7 8.8.
  4. Move 43: capture in 1, answer D1, grade 22. Better than: J7 6.6.
  5. Move 47: escape in 2, answer D3, grade 36. Better than: J7 44.8, C1 48.8.
  6. Move 51: capture in 2, answer A2, grade 32. Better than: J7 42.9.
  7. Move 53: escape in 1, answer A4, grade 36. Better than: J7 33.8, A1 45.6.
  8. Move 69: escape in 1, answer J7, grade 32. Better than: H5 16.7.

story-2705: 91 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 28. Rank score 105.
  1. Move 17: capture in 1, answer E1, grade 22. Better than: F7 14.1.
  2. Move 29: capture in 3, answer H1, grade 46. Better than: F7 9.2, J2 12.3.
  3. Move 35: capture in 2, answer J3, grade 32. Better than: J1 18.4.
  4. Move 37: escape in 1, answer J1, grade 32. Better than: J4 19.1.
  5. Move 41: capture in 1, answer G1, grade 22. Better than: G6 17.7.
  6. Move 49: capture in 3, answer G8, grade 42. Better than: F9 8.4.
  7. Move 55: capture in 1, answer H7, grade 22. Better than: F9 12.1.
  8. Move 59: capture in 1, answer A1, grade 22. Better than: F9 15.2.
  9. Move 67: capture in 1, answer C1, grade 22. Better than: F9 25.8.
  10. Move 77: escape in 1, answer C5, grade 22. Better than: F9 5.8.

story-1248: 68 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 28. Rank score 100.
  1. Move 17: capture in 2, answer J3, grade 32. Better than: J1 16.7.
  2. Move 21: escape in 1, answer D3, grade 22. Better than: J1 10.0.
  3. Move 31: capture in 3, answer B8, grade 46. Better than: A7 7.5, J1 9.9.
  4. Move 35: escape in 1, answer F2, grade 22. Better than: A7 19.7.
  5. Move 39: capture in 1, answer J2, grade 22. Better than: A7 9.2.
  6. Move 47: capture in 1, answer G2, grade 22. Better than: A7 10.6.
  7. Move 49: capture in 1, answer J6, grade 22. Better than: A7 10.7.
  8. Move 53: escape in 1, answer A7, grade 32. Better than: A6 17.7.

story-450: 80 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 28. Rank score 80.
  1. Move 23: capture in 3, answer B8, grade 42. Better than: C9 10.1.
  2. Move 25: escape in 1, answer E8, grade 22. Better than: C9 23.8.
  3. Move 47: capture in 1, answer E9, grade 22. Better than: C9 38.5.
  4. Move 53: escape in 1, answer J4, grade 22. Better than: C9 25.8.
  5. Move 57: capture in 1, answer D9, grade 22. Better than: H1 36.5.
  6. Move 59: escape in 1, answer J1, grade 32. Better than: J3 92.3.
  7. Move 63: escape in 2, answer J7, grade 32. Better than: J9 67.8.

story-1728: 85 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.6. Grade 28. Rank score 75.
  1. Move 27: capture in 3, answer E8, grade 46. Better than: D9 10.0, F5 15.6.
  2. Move 33: escape in 1, answer J4, grade 22. Better than: F5 8.7.
  3. Move 37: capture in 2, answer H2, grade 36. Better than: F5 8.7, J1 8.9.
  4. Move 41: capture in 1, answer J1, grade 22. Better than: F5 6.8.
  5. Move 45: capture in 1, answer G1, grade 22. Better than: F5 7.3.
  6. Move 65: capture in 1, answer F5, grade 22. Better than: E9 30.0.

story-1827: 82 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 28. Rank score 75.
  1. Move 25: capture in 3, answer B7, grade 42. Better than: A6 8.5.
  2. Move 27: capture in 1, answer C8, grade 22. Better than: A6 10.5.
  3. Move 31: escape in 1, answer G8, grade 22. Better than: A6 8.8.
  4. Move 33: escape in 1, answer D3, grade 22. Better than: A6 11.0.
  5. Move 37: capture in 3, answer D2, grade 46. Better than: A6 21.4, E1 15.9.
  6. Move 41: capture in 1, answer E1, grade 22. Better than: A6 6.0.
  7. Move 47: capture in 1, answer C1, grade 22. Better than: A6 21.3.

story-2393: 72 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 28. Rank score 75.
  1. Move 35: capture in 3, answer H3, grade 42. Better than: J4 11.5.
  2. Move 37: escape in 1, answer H6, grade 22. Better than: J4 12.6.
  3. Move 39: escape in 1, answer J4, grade 32. Better than: F4 15.7.
  4. Move 43: capture in 2, answer G8, grade 32. Better than: F8 29.2.
  5. Move 45: escape in 1, answer B6, grade 22. Better than: F8 26.3.
  6. Move 47: capture in 2, answer F8, grade 32. Better than: G9 43.5.
  7. Move 49: capture in 1, answer A4, grade 22. Better than: G9 27.1.
  8. Move 53: capture in 1, answer A8, grade 22. Better than: G9 27.6.

story-3263: 69 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 28. Rank score 75.
  1. Move 23: capture in 3, answer H2, grade 42. Better than: J3 8.2.
  2. Move 25: escape in 1, answer F3, grade 22. Better than: J3 8.5.
  3. Move 33: escape in 1, answer J3, grade 32. Better than: J4 32.2.
  4. Move 51: capture in 1, answer J1, grade 22. Better than: F2 11.8.
  5. Move 53: capture in 1, answer A3, grade 22. Better than: F2 11.0.
  6. Move 57: capture in 1, answer A7, grade 22. Better than: F2 15.7.
  7. Move 61: escape in 2, answer C7, grade 36. Better than: D9 24.4, F2 24.9.

story-1053: 57 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 28. Rank score 70.
  1. Move 19: capture in 3, answer H8, grade 42. Better than: G9 6.7.
  2. Move 25: escape in 1, answer E5, grade 22. Better than: G9 13.0.
  3. Move 27: capture in 1, answer E7, grade 22. Better than: G9 14.9.
  4. Move 39: capture in 1, answer B1, grade 22. Better than: G9 8.5.
  5. Move 43: capture in 1, answer D8, grade 22. Better than: G9 9.6.
  6. Move 49: capture in 2, answer G9, grade 36. Better than: E9 15.8, J9 17.8.

story-1507: 54 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 28. Rank score 70.
  1. Move 33: capture in 3, answer H8, grade 42. Better than: J7 19.5.
  2. Move 35: escape in 1, answer D3, grade 22. Better than: J7 9.1.
  3. Move 37: capture in 1, answer H9, grade 22. Better than: J7 6.2.
  4. Move 39: capture in 2, answer E7, grade 32. Better than: J7 7.7.
  5. Move 43: capture in 1, answer F6, grade 26. Better than: J7 7.8, B1 7.8.
  6. Move 47: capture in 1, answer F2, grade 22. Better than: J7 23.2.

story-1817: 59 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 28. Rank score 70.
  1. Move 33: capture in 3, answer B2, grade 42. Better than: C1 19.4.
  2. Move 35: escape in 1, answer G6, grade 22. Better than: C1 9.2.
  3. Move 37: capture in 1, answer A2, grade 22. Better than: C1 6.2.
  4. Move 39: capture in 2, answer C5, grade 32. Better than: C1 7.8.
  5. Move 43: capture in 1, answer D4, grade 26. Better than: J8 7.8, C1 7.8.
  6. Move 47: capture in 1, answer H4, grade 22. Better than: C1 23.1.

story-3222: 73 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 28. Rank score 70.
  1. Move 23: capture in 3, answer H6, grade 46. Better than: J5 35.6, G3 10.0.
  2. Move 27: capture in 1, answer G2, grade 22. Better than: J5 12.1.
  3. Move 37: capture in 1, answer A4, grade 22. Better than: J5 26.2.
  4. Move 49: capture in 1, answer B3, grade 22. Better than: J5 7.1.
  5. Move 61: escape in 1, answer A3, grade 22. Better than: J5 8.3.
  6. Move 69: capture in 2, answer J4, grade 32. Better than: J6 22.1.

story-982: 49 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 28. Rank score 65.
  1. Move 11: capture in 3, answer C2, grade 42. Better than: D1 14.1.
  2. Move 21: capture in 1, answer C7, grade 22. Better than: D1 11.0.
  3. Move 33: capture in 1, answer H9, grade 22. Better than: C5 10.9.
  4. Move 35: escape in 2, answer G9, grade 36. Better than: J9 8.5, C5 6.8.
  5. Move 37: capture in 1, answer D9, grade 22. Better than: C5 11.0.
  6. Move 41: escape in 1, answer E9, grade 22. Better than: C5 9.3.

story-2360: 91 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.2. Grade 28. Rank score 65.
  1. Move 31: capture in 3, answer B4, grade 42. Better than: A5 9.1.
  2. Move 33: escape in 1, answer D7, grade 22. Better than: A5 9.7.
  3. Move 39: capture in 1, answer G4, grade 22. Better than: A5 12.1.
  4. Move 69: capture in 1, answer D9, grade 26. Better than: J6 25.5, A3 26.5.
  5. Move 71: capture in 2, answer G9, grade 36. Better than: J6 10.2, A3 11.9.
  6. Move 73: escape in 1, answer J9, grade 22. Better than: A3 14.4.

story-2605: 66 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 28. Rank score 65.
  1. Move 19: capture in 3, answer F8, grade 42. Better than: G9 8.5.
  2. Move 21: capture in 2, answer E7, grade 36. Better than: G9 11.0, E6 11.1.
  3. Move 23: escape in 1, answer E6, grade 22. Better than: G9 14.4.
  4. Move 31: escape in 1, answer A4, grade 22. Better than: G9 26.6.
  5. Move 35: capture in 1, answer B3, grade 22. Better than: G9 32.7.
  6. Move 49: capture in 1, answer B8, grade 22. Better than: G9 7.5.

story-2737: 61 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 28. Rank score 65.
  1. Move 19: capture in 2, answer F2, grade 32. Better than: F4 8.2.
  2. Move 33: escape in 1, answer D9, grade 22. Better than: F4 10.2.
  3. Move 37: capture in 3, answer B8, grade 46. Better than: A7 19.3, F4 28.7.
  4. Move 41: capture in 1, answer A7, grade 22. Better than: F4 32.7.
  5. Move 43: capture in 1, answer A5, grade 22. Better than: F4 16.6.
  6. Move 51: capture in 1, answer H4, grade 22. Better than: F4 9.4.

story-367: 80 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 28. Rank score 60.
  1. Move 41: capture in 2, answer B4, grade 32. Better than: A3 6.8.
  2. Move 43: escape in 1, answer E6, grade 22. Better than: A3 26.6.
  3. Move 47: escape in 1, answer B7, grade 22. Better than: A3 27.9.
  4. Move 49: capture in 2, answer E5, grade 36. Better than: B6 36.7, A3 37.3.
  5. Move 57: capture in 2, answer B8, grade 36. Better than: B6 8.3, A3 11.5.
  6. Move 71: capture in 1, answer C8, grade 22. Better than: A3 5.7.

story-687: 54 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 28. Rank score 60.
  1. Move 33: capture in 3, answer H2, grade 42. Better than: G1 19.7.
  2. Move 35: escape in 1, answer C6, grade 22. Better than: G1 9.1.
  3. Move 37: capture in 1, answer J2, grade 22. Better than: G1 6.3.
  4. Move 39: capture in 2, answer G5, grade 32. Better than: G1 7.8.
  5. Move 47: capture in 1, answer B4, grade 22. Better than: G1 23.2.

story-1087: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 28. Rank score 60.
  1. Move 33: capture in 3, answer H2, grade 42. Better than: G1 19.7.
  2. Move 35: escape in 1, answer C6, grade 22. Better than: G1 9.1.
  3. Move 37: capture in 1, answer J2, grade 22. Better than: G1 6.3.
  4. Move 39: capture in 2, answer G5, grade 32. Better than: G1 7.8.
  5. Move 47: capture in 1, answer B4, grade 22. Better than: G1 23.2.

story-372: 71 moves. Main line: area score Blue 44, Red 43 (Blue wins by 1). Estimate before the end: Blue by 1.1. Grade 28. Rank score 55.
  1. Move 23: capture in 3, answer H4, grade 42. Better than: G5 10.3.
  2. Move 31: capture in 1, answer A1, grade 22. Better than: G5 27.4.
  3. Move 33: escape in 1, answer B4, grade 22. Better than: G5 32.6.
  4. Move 45: capture in 1, answer D2, grade 22. Better than: G5 26.9.
  5. Move 53: escape in 1, answer G5, grade 32. Better than: J5 89.4.
  6. Move 59: capture in 1, answer J6, grade 26. Better than: A6 55.9, A2 56.0.

story-763: 85 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.8. Grade 28. Rank score 55.
  1. Move 23: escape in 1, answer F5, grade 22. Better than: D6 8.5.
  2. Move 25: capture in 1, answer G4, grade 22. Better than: D6 8.7.
  3. Move 39: capture in 3, answer F2, grade 46. Better than: H5 16.1, E1 26.0.
  4. Move 55: capture in 1, answer E1, grade 22. Better than: H5 10.5.

story-969: 61 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 28. Rank score 55.
  1. Move 35: escape in 1, answer B7, grade 32. Better than: C9 30.6.
  2. Move 37: capture in 3, answer B9, grade 42. Better than: A8 19.8.
  3. Move 41: capture in 1, answer F1, grade 22. Better than: A8 30.8.
  4. Move 43: escape in 1, answer E3, grade 22. Better than: A8 46.5.
  5. Move 51: capture in 1, answer A2, grade 22. Better than: A8 54.1.

story-1394: 74 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 28. Rank score 55.
  1. Move 41: capture in 2, answer D8, grade 32. Better than: C9 6.6.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: C9 27.8.
  3. Move 47: escape in 1, answer C9, grade 32. Better than: F8 10.6.
  4. Move 49: capture in 2, answer G8, grade 32. Better than: H9 16.9.
  5. Move 51: escape in 1, answer E5, grade 22. Better than: H9 33.3.

story-2985: 79 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 28. Rank score 55.
  1. Move 43: capture in 1, answer C2, grade 22. Better than: E3 19.3.
  2. Move 67: capture in 1, answer E3, grade 22. Better than: D4 22.0.
  3. Move 69: capture in 2, answer E1, grade 36. Better than: D4 20.4, D2 19.0.
  4. Move 77: escape in 1, answer D2, grade 32. Better than: F1 14.6.

story-959: 65 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 28. Rank score 50.
  1. Move 25: escape in 1, answer C6, grade 22. Better than: F4 9.9.
  2. Move 37: capture in 3, answer H2, grade 42. Better than: G1 19.3.
  3. Move 41: capture in 1, answer J2, grade 22. Better than: G1 6.7.
  4. Move 43: capture in 2, answer G1, grade 32. Better than: J1 24.6.
  5. Move 51: escape in 1, answer J3, grade 22. Better than: J1 6.3.

story-1233: 83 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 28. Rank score 50.
  1. Move 37: capture in 3, answer H8, grade 42. Better than: G9 9.6.
  2. Move 39: escape in 1, answer E4, grade 22. Better than: G9 35.6.
  3. Move 41: capture in 2, answer G9, grade 32. Better than: J9 15.9.
  4. Move 49: capture in 1, answer A5, grade 22. Better than: J9 6.5.
  5. Move 67: capture in 1, answer A9, grade 22. Better than: J9 10.6.

story-1296: 80 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 28. Rank score 50.
  1. Move 31: capture in 3, answer H2, grade 42. Better than: J3 13.2.
  2. Move 33: capture in 1, answer H1, grade 22. Better than: J3 10.0.
  3. Move 37: escape in 1, answer D7, grade 22. Better than: J3 9.2.
  4. Move 39: capture in 2, answer E3, grade 32. Better than: J3 7.5.
  5. Move 57: capture in 1, answer A8, grade 22. Better than: J3 22.4.

story-2649: 87 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 1.9. Grade 28. Rank score 45.
  1. Move 55: capture in 2, answer A3, grade 32. Better than: A1 9.7.
  2. Move 67: capture in 1, answer A2, grade 26. Better than: A8 10.7, C8 10.6.
  3. Move 71: escape in 1, answer G9, grade 26. Better than: A8 7.8, C8 7.8.
  4. Move 73: capture in 1, answer F9, grade 26. Better than: A8 19.6, C8 13.4.

story-3167: 67 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 28. Rank score 45.
  1. Move 27: capture in 3, answer B6, grade 46. Better than: A5 16.9, H3 8.4.
  2. Move 29: capture in 1, answer H3, grade 22. Better than: A5 19.2.
  3. Move 45: escape in 1, answer D6, grade 22. Better than: F9 8.0.
  4. Move 47: capture in 1, answer D4, grade 22. Better than: F9 17.5.

story-191: 65 moves. Main line: area score Blue 47, Red 39 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 28. Rank score 40.
  1. Move 37: capture in 1, answer G2, grade 22. Better than: B4 16.2.
  2. Move 45: capture in 2, answer E6, grade 32. Better than: E4 11.3.
  3. Move 53: capture in 1, answer E3, grade 26. Better than: F7 15.8, E4 17.0.
  4. Move 61: capture in 2, answer C1, grade 32. Better than: A1 17.6.

story-49: 66 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 28. Rank score 35.
  1. Move 21: escape in 1, answer G4, grade 22. Better than: E9 18.9.
  2. Move 31: capture in 3, answer B8, grade 46. Better than: E9 13.3, A7 10.8.
  3. Move 35: capture in 1, answer A7, grade 22. Better than: E9 8.9.
  4. Move 41: capture in 1, answer J4, grade 22. Better than: E9 13.1.

story-402: 79 moves. Main line: area score Blue 43, Red 40 (Blue wins by 3). Estimate before the end: Blue by 10.0. Grade 28. Rank score 35.
  1. Move 39: capture in 2, answer C9, grade 32. Better than: A9 18.9.
  2. Move 41: capture in 2, answer A9, grade 32. Better than: A7 20.2.
  3. Move 47: capture in 1, answer B1, grade 22. Better than: B7 7.1.
  4. Move 51: escape in 1, answer F1, grade 22. Better than: B7 5.8.
  5. Move 67: escape in 1, answer B7, grade 32. Better than: D9 51.6.

story-690: 53 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.3. Grade 28. Rank score 35.
  1. Move 25: capture in 2, answer J3, grade 36. Better than: J5 12.5, B4 9.0.
  2. Move 29: escape in 2, answer J5, grade 32. Better than: J7 8.0.
  3. Move 37: escape in 1, answer E4, grade 22. Better than: C5 15.4.
  4. Move 39: capture in 1, answer C5, grade 22. Better than: F3 11.7.

story-1292: 77 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 28. Rank score 35.
  1. Move 35: capture in 3, answer J3, grade 46. Better than: H2 5.0, J1 5.1.
  2. Move 41: escape in 1, answer C2, grade 22. Better than: F1 18.8.
  3. Move 43: capture in 1, answer D4, grade 22. Better than: F1 25.4.
  4. Move 45: capture in 1, answer F1, grade 22. Better than: E3 21.8.

story-1839: 71 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 28. Rank score 35.
  1. Move 17: capture in 3, answer B7, grade 42. Better than: A6 15.2.
  2. Move 31: capture in 1, answer F7, grade 22. Better than: H4 8.8.
  3. Move 33: escape in 1, answer E7, grade 22. Better than: H4 11.2.
  4. Move 37: capture in 1, answer H4, grade 22. Better than: D9 8.6.
  5. Move 55: escape in 1, answer B1, grade 32. Better than: C3 9.9.

story-2222: 50 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.4. Grade 28. Rank score 35.
  1. Move 25: capture in 2, answer A7, grade 36. Better than: H6 9.1, A5 12.5.
  2. Move 29: escape in 2, answer A5, grade 32. Better than: A3 8.3.
  3. Move 37: escape in 1, answer E6, grade 22. Better than: G5 15.3.
  4. Move 39: capture in 1, answer G5, grade 22. Better than: D7 11.7.

story-866: 75 moves. Main line: area score Blue 45, Red 40 (Blue wins by 5). Estimate before the end: Blue by 9.8. Grade 28. Rank score 30.
  1. Move 19: capture in 3, answer G2, grade 42. Better than: F1 13.1.
  2. Move 37: escape in 1, answer H6, grade 22. Better than: B1 6.0.
  3. Move 41: capture in 1, answer B1, grade 22. Better than: J8 6.5.
  4. Move 57: capture in 2, answer J5, grade 32. Better than: J3 19.1.
  5. Move 65: capture in 1, answer B6, grade 22. Better than: A2 7.6.

story-1378: 82 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 28. Rank score 30.
  1. Move 33: escape in 1, answer F1, grade 32. Better than: E3 16.0.
  2. Move 49: capture in 1, answer A6, grade 22. Better than: H1 11.2.
  3. Move 61: capture in 1, answer J5, grade 26. Better than: A2 7.2, H1 6.9.
  4. Move 75: escape in 1, answer H1, grade 32. Better than: J1 24.6.

story-1039: 87 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 29. Rank score 125.
  1. Move 15: capture in 3, answer C8, grade 42. Better than: D9 10.9.
  2. Move 35: capture in 2, answer J7, grade 36. Better than: J9 5.4, B7 10.2.
  3. Move 39: capture in 1, answer G9, grade 22. Better than: B7 8.1.
  4. Move 47: capture in 1, answer J5, grade 22. Better than: B7 26.8.
  5. Move 49: capture in 1, answer H4, grade 22. Better than: B7 24.1.
  6. Move 51: capture in 1, answer J3, grade 22. Better than: B7 25.6.
  7. Move 53: escape in 2, answer D6, grade 36. Better than: B7 8.5, D5 11.3.
  8. Move 55: escape in 1, answer J4, grade 22. Better than: B7 22.2.
  9. Move 57: capture in 2, answer H2, grade 36. Better than: B7 20.4, J1 20.7.
  10. Move 71: capture in 1, answer B9, grade 26. Better than: J9 8.4, J1 8.4.
  11. Move 81: capture in 2, answer J1, grade 32. Better than: G1 22.1.

story-758: 62 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 29. Rank score 105.
  1. Move 31: capture in 1, answer F9, grade 22. Better than: E4 7.6.
  2. Move 35: capture in 1, answer E8, grade 22. Better than: E4 8.7.
  3. Move 37: escape in 1, answer E9, grade 22. Better than: E4 8.5.
  4. Move 41: capture in 3, answer C8, grade 46. Better than: B9 8.9, E4 8.4.
  5. Move 43: capture in 1, answer E4, grade 22. Better than: B9 16.2.
  6. Move 45: capture in 2, answer C6, grade 36. Better than: B9 42.8, C7 9.3.
  7. Move 47: escape in 1, answer C7, grade 32. Better than: B9 42.6.

story-15: 67 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 7.8. Grade 29. Rank score 100.
  1. Move 17: capture in 2, answer J3, grade 32. Better than: J1 16.7.
  2. Move 23: escape in 1, answer J1, grade 32. Better than: J4 28.8.
  3. Move 27: capture in 3, answer B8, grade 42. Better than: A7 9.2.
  4. Move 33: capture in 1, answer C5, grade 22. Better than: A7 7.8.
  5. Move 41: escape in 1, answer E1, grade 22. Better than: A7 21.0.
  6. Move 47: capture in 1, answer A5, grade 22. Better than: A7 5.7.
  7. Move 53: capture in 2, answer F2, grade 36. Better than: A7 29.9, G1 29.9.
  8. Move 59: capture in 1, answer H2, grade 26. Better than: A7 29.4, G1 29.4.

story-1127: 70 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 7.9. Grade 29. Rank score 70.
  1. Move 31: capture in 2, answer F7, grade 36. Better than: E8 12.5, D4 26.6.
  2. Move 37: capture in 1, answer D4, grade 26. Better than: E8 29.4, A6 25.5.
  3. Move 41: capture in 1, answer A6, grade 22. Better than: E8 20.6.
  4. Move 53: capture in 2, answer H2, grade 36. Better than: E8 48.1, J3 8.3.
  5. Move 55: escape in 1, answer J3, grade 22. Better than: E8 47.8.
  6. Move 57: capture in 1, answer J1, grade 22. Better than: E8 47.7.
  7. Move 63: capture in 2, answer E8, grade 36. Better than: D9 11.8, E1 14.5.

story-1767: 64 moves. Main line: area score Blue 47, Red 39 (Blue wins by 8). Estimate before the end: Blue by 4.1. Grade 29. Rank score 70.
  1. Move 13: capture in 3, answer G8, grade 42. Better than: F9 13.0.
  2. Move 21: escape in 1, answer D4, grade 22. Better than: F9 9.3.
  3. Move 23: escape in 1, answer F9, grade 32. Better than: E9 20.0.
  4. Move 29: capture in 2, answer E4, grade 32. Better than: F5 7.2.
  5. Move 45: capture in 1, answer B1, grade 22. Better than: F5 9.9.
  6. Move 55: capture in 1, answer H9, grade 22. Better than: F5 11.9.

story-2327: 79 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 29. Rank score 70.
  1. Move 15: capture in 3, answer H6, grade 42. Better than: J7 5.9.
  2. Move 21: escape in 1, answer G4, grade 22. Better than: J7 10.8.
  3. Move 23: capture in 3, answer H3, grade 46. Better than: J7 10.4, J4 6.4.
  4. Move 27: capture in 1, answer J4, grade 22. Better than: J7 10.7.
  5. Move 33: capture in 1, answer J2, grade 22. Better than: J7 8.6.
  6. Move 67: capture in 1, answer J6, grade 22. Better than: J7 26.3.

story-268: 65 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.7. Grade 29. Rank score 65.
  1. Move 19: capture in 2, answer C6, grade 32. Better than: D5 13.9.
  2. Move 27: capture in 2, answer F3, grade 36. Better than: D5 20.6, E4 19.6.
  3. Move 31: capture in 1, answer E4, grade 22. Better than: D5 23.9.
  4. Move 33: escape in 1, answer E3, grade 22. Better than: D5 11.2.
  5. Move 41: escape in 1, answer D5, grade 32. Better than: B6 31.6.

story-2251: 75 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 29. Rank score 65.
  1. Move 19: capture in 3, answer B8, grade 42. Better than: A7 10.5.
  2. Move 39: escape in 1, answer D7, grade 22. Better than: A1 23.6.
  3. Move 41: capture in 3, answer E8, grade 50. Better than: C9 16.8, D9 21.3, A1 24.6.
  4. Move 43: escape in 1, answer E2, grade 22. Better than: A1 16.7.
  5. Move 51: capture in 1, answer A3, grade 22. Better than: C9 6.9.
  6. Move 61: capture in 1, answer F6, grade 22. Better than: C9 15.4.
  7. Move 63: escape in 1, answer G6, grade 22. Better than: C9 13.7.

story-347: 53 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 29. Rank score 60.
  1. Move 33: capture in 3, answer B2, grade 42. Better than: A3 19.3.
  2. Move 35: escape in 1, answer F7, grade 22. Better than: A3 9.2.
  3. Move 37: capture in 1, answer B1, grade 22. Better than: A3 6.2.
  4. Move 39: capture in 2, answer E3, grade 32. Better than: A3 7.7.
  5. Move 43: capture in 1, answer D4, grade 26. Better than: H9 7.8, A3 7.8.

story-481: 76 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 29. Rank score 60.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: A3 14.1.
  2. Move 33: capture in 1, answer B1, grade 22. Better than: A3 9.5.
  3. Move 37: capture in 2, answer E3, grade 32. Better than: A3 6.5.
  4. Move 47: escape in 1, answer D2, grade 22. Better than: A3 9.0.
  5. Move 51: capture in 1, answer E8, grade 26. Better than: D4 19.0, A3 20.2.

story-1453: 69 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 29. Rank score 60.
  1. Move 19: capture in 3, answer F8, grade 42. Better than: G9 8.2.
  2. Move 21: capture in 2, answer E7, grade 36. Better than: G9 10.8, E6 11.1.
  3. Move 23: escape in 1, answer E6, grade 22. Better than: G9 14.1.
  4. Move 31: escape in 1, answer A4, grade 22. Better than: G9 26.2.
  5. Move 35: capture in 1, answer B3, grade 22. Better than: G9 32.7.

story-1672: 81 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 29. Rank score 60.
  1. Move 17: capture in 3, answer F2, grade 42. Better than: E1 8.3.
  2. Move 37: capture in 2, answer F1, grade 36. Better than: F4 11.3, D1 13.6.
  3. Move 47: capture in 1, answer F4, grade 22. Better than: D1 32.4.
  4. Move 69: capture in 1, answer E7, grade 22. Better than: D4 26.3.
  5. Move 73: escape in 1, answer E2, grade 22. Better than: D4 8.1.

story-787: 66 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 29. Rank score 55.
  1. Move 25: capture in 3, answer B7, grade 42. Better than: A6 6.9.
  2. Move 37: capture in 2, answer E5, grade 32. Better than: A6 6.6.
  3. Move 41: capture in 1, answer F4, grade 22. Better than: A6 24.5.
  4. Move 47: capture in 2, answer D1, grade 36. Better than: A6 13.2, F1 13.6.
  5. Move 57: capture in 1, answer C3, grade 22. Better than: A6 21.0.
  6. Move 59: capture in 1, answer E1, grade 22. Better than: A6 15.6.

story-1675: 81 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 29. Rank score 55.
  1. Move 25: capture in 3, answer H3, grade 42. Better than: J4 6.0.
  2. Move 27: capture in 1, answer G2, grade 22. Better than: J4 8.6.
  3. Move 31: escape in 1, answer C3, grade 22. Better than: J4 15.0.
  4. Move 45: capture in 2, answer C9, grade 36. Better than: A9 10.2, J4 10.2.
  5. Move 55: capture in 1, answer A7, grade 26. Better than: J4 10.2, F1 10.1.
  6. Move 67: capture in 1, answer J2, grade 26. Better than: G7 9.6, J4 10.1.

story-774: 69 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 29. Rank score 50.
  1. Move 17: capture in 3, answer B4, grade 42. Better than: A5 8.4.
  2. Move 35: capture in 1, answer C8, grade 22. Better than: A5 46.5.
  3. Move 45: capture in 1, answer F6, grade 26. Better than: D6 13.5, A5 16.1.
  4. Move 59: escape in 1, answer F5, grade 22. Better than: A5 13.5.
  5. Move 61: capture in 2, answer A5, grade 32. Better than: A7 19.9.

story-2497: 71 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 29. Rank score 50.
  1. Move 33: capture in 3, answer C2, grade 42. Better than: D1 9.1.
  2. Move 35: escape in 1, answer J6, grade 22. Better than: D1 9.4.
  3. Move 39: escape in 1, answer J9, grade 36. Better than: G8 8.6, D1 9.4.
  4. Move 41: capture in 1, answer G9, grade 22. Better than: D1 11.5.
  5. Move 45: capture in 1, answer D1, grade 22. Better than: G3 13.0.

story-3104: 73 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 2.0. Grade 29. Rank score 45.
  1. Move 23: capture in 1, answer C2, grade 22. Better than: E6 12.6.
  2. Move 29: capture in 2, answer G1, grade 36. Better than: E6 12.7, J1 13.7.
  3. Move 31: escape in 1, answer J1, grade 36. Better than: E6 16.4, F1 22.4.
  4. Move 51: capture in 1, answer E1, grade 22. Better than: E6 18.6.

story-238: 74 moves. Main line: area score Blue 45, Red 41 (Blue wins by 4). Estimate before the end: Blue by 7.9. Grade 29. Rank score 40.
  1. Move 37: capture in 3, answer F8, grade 42. Better than: E9 16.1.
  2. Move 43: capture in 1, answer F6, grade 22. Better than: E9 16.8.
  3. Move 51: escape in 1, answer C1, grade 22. Better than: J1 18.4.
  4. Move 55: capture in 2, answer D1, grade 36. Better than: E2 18.4, J1 20.3.
  5. Move 65: capture in 1, answer G4, grade 22. Better than: J1 5.7.

story-525: 68 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 90.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: A3 15.6.
  2. Move 33: capture in 1, answer B1, grade 22. Better than: A3 9.6.
  3. Move 37: capture in 2, answer E3, grade 32. Better than: A3 6.4.
  4. Move 45: escape in 2, answer F8, grade 36. Better than: E9 12.9, A3 9.4.
  5. Move 47: capture in 2, answer D8, grade 36. Better than: E9 30.3, A3 28.1.
  6. Move 51: capture in 1, answer D9, grade 22. Better than: A3 20.4.
  7. Move 53: capture in 1, answer D4, grade 22. Better than: A3 5.1.

story-2558: 81 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 9.8. Grade 30. Rank score 85.
  1. Move 25: capture in 1, answer D7, grade 22. Better than: B7 12.8.
  2. Move 45: capture in 2, answer G5, grade 32. Better than: E5 8.1.
  3. Move 53: capture in 1, answer J2, grade 22. Better than: E5 10.2.
  4. Move 55: capture in 2, answer J5, grade 40. Better than: H6 12.0, E5 12.7, H1 13.1.
  5. Move 57: capture in 2, answer H6, grade 40. Better than: J9 9.4, E5 9.1, H1 9.7.
  6. Move 61: capture in 1, answer J9, grade 26. Better than: E5 12.3, H1 12.9.

story-2881: 69 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 7.9. Grade 30. Rank score 85.
  1. Move 19: capture in 3, answer H2, grade 46. Better than: F8 16.5, G1 10.5.
  2. Move 23: capture in 1, answer G1, grade 22. Better than: F8 7.6.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F8 8.1.
  4. Move 37: escape in 1, answer E6, grade 32. Better than: E5 28.3.
  5. Move 43: escape in 2, answer E8, grade 32. Better than: F9 15.6.
  6. Move 47: escape in 1, answer G6, grade 22. Better than: E3 39.1.
  7. Move 49: capture in 2, answer H8, grade 36. Better than: G9 14.1, E3 11.8.
  8. Move 51: capture in 1, answer E3, grade 22. Better than: G9 8.3.
  9. Move 53: capture in 2, answer G9, grade 32. Better than: J9 15.5.

story-310: 58 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 30. Rank score 75.
  1. Move 21: escape in 1, answer F6, grade 22. Better than: E3 22.2.
  2. Move 29: escape in 1, answer F2, grade 32. Better than: F7 21.4.
  3. Move 35: capture in 1, answer A5, grade 22. Better than: F4 8.3.
  4. Move 47: capture in 3, answer H2, grade 42. Better than: G1 11.1.
  5. Move 49: capture in 2, answer G1, grade 32. Better than: J1 16.7.

story-3169: 89 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.8. Grade 30. Rank score 75.
  1. Move 25: escape in 1, answer C3, grade 22. Better than: H6 21.0.
  2. Move 33: capture in 3, answer B6, grade 46. Better than: G8 20.9, A5 9.2.
  3. Move 47: capture in 1, answer B1, grade 22. Better than: G8 22.4.
  4. Move 57: capture in 1, answer G1, grade 30. Better than: G8 8.2, B6 12.1, A2 16.7.
  5. Move 69: capture in 2, answer F1, grade 32. Better than: J3 39.0.

story-762: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 65.
  1. Move 25: capture in 3, answer B5, grade 46. Better than: D6 33.4, A4 13.5.
  2. Move 27: escape in 1, answer A4, grade 36. Better than: D6 35.5, D3 37.8.
  3. Move 29: escape in 1, answer F7, grade 22. Better than: D6 20.8.
  4. Move 31: escape in 1, answer B4, grade 22. Better than: D6 23.9.
  5. Move 45: capture in 2, answer G9, grade 32. Better than: J9 13.9.
  6. Move 47: capture in 1, answer F8, grade 22. Better than: J9 12.6.

story-2144: 73 moves. Main line: area score Blue 44, Red 41 (Blue wins by 3). Estimate before the end: Blue by 7.9. Grade 30. Rank score 65.
  1. Move 15: capture in 3, answer B6, grade 42. Better than: A7 5.9.
  2. Move 21: escape in 1, answer C4, grade 22. Better than: A7 10.5.
  3. Move 23: capture in 3, answer B3, grade 46. Better than: A7 10.5, A4 6.8.
  4. Move 27: capture in 1, answer A4, grade 22. Better than: A7 10.9.
  5. Move 67: capture in 1, answer A6, grade 26. Better than: B9 23.3, A7 21.8.
  6. Move 71: capture in 1, answer C6, grade 22. Better than: A7 34.3.

story-2046: 74 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 30. Rank score 60.
  1. Move 11: capture in 3, answer G8, grade 42. Better than: F9 14.0.
  2. Move 21: capture in 1, answer F9, grade 22. Better than: G3 21.7.
  3. Move 31: capture in 2, answer J3, grade 32. Better than: J1 25.0.
  4. Move 33: escape in 1, answer J1, grade 32. Better than: J4 54.6.
  5. Move 45: escape in 1, answer H7, grade 32. Better than: J9 49.0.
  6. Move 61: escape in 1, answer F8, grade 22. Better than: C9 32.5.

story-2904: 55 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 30. Rank score 60.
  1. Move 17: capture in 3, answer B7, grade 42. Better than: A6 11.1.
  2. Move 33: capture in 3, answer G8, grade 46. Better than: F9 28.0, A2 26.8.
  3. Move 37: capture in 1, answer F9, grade 26. Better than: H7 10.4, A2 12.3.
  4. Move 41: escape in 1, answer A3, grade 22. Better than: H7 9.7.
  5. Move 43: capture in 1, answer D9, grade 22. Better than: H7 9.9.
  6. Move 45: capture in 1, answer C8, grade 22. Better than: H7 15.7.

story-689: 74 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 55.
  1. Move 41: capture in 2, answer D8, grade 32. Better than: C9 6.5.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: C9 27.7.
  3. Move 47: escape in 1, answer H7, grade 22. Better than: C9 27.0.
  4. Move 51: capture in 2, answer E5, grade 36. Better than: C9 32.5, F8 17.7.
  5. Move 53: capture in 2, answer F8, grade 36. Better than: C9 29.8, G9 36.0.

story-1028: 75 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 30. Rank score 55.
  1. Move 25: capture in 3, answer H2, grade 42. Better than: J3 15.8.
  2. Move 39: capture in 1, answer E9, grade 22. Better than: J3 18.4.
  3. Move 43: capture in 2, answer J3, grade 32. Better than: J1 14.4.
  4. Move 65: capture in 2, answer J6, grade 32. Better than: J4 32.1.
  5. Move 67: capture in 1, answer H7, grade 22. Better than: J4 42.5.

story-1080: 74 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 55.
  1. Move 41: capture in 2, answer D8, grade 32. Better than: C9 6.4.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: C9 27.8.
  3. Move 47: escape in 1, answer H7, grade 22. Better than: C9 27.2.
  4. Move 51: capture in 2, answer E5, grade 36. Better than: C9 29.9, F8 15.0.
  5. Move 53: capture in 2, answer F8, grade 36. Better than: C9 29.7, G9 35.9.

story-1186: 74 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 55.
  1. Move 41: capture in 2, answer D8, grade 32. Better than: C9 6.5.
  2. Move 43: escape in 1, answer F5, grade 22. Better than: C9 27.8.
  3. Move 47: escape in 1, answer H7, grade 22. Better than: C9 27.2.
  4. Move 51: capture in 2, answer E5, grade 36. Better than: C9 31.8, F8 17.0.
  5. Move 53: capture in 2, answer F8, grade 36. Better than: C9 29.7, G9 35.9.

story-1696: 67 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 1.9. Grade 30. Rank score 55.
  1. Move 25: capture in 3, answer B4, grade 42. Better than: A5 13.6.
  2. Move 31: capture in 3, answer D2, grade 46. Better than: A5 16.6, E1 18.3.
  3. Move 33: capture in 1, answer A5, grade 22. Better than: E1 14.3.
  4. Move 35: capture in 1, answer E1, grade 22. Better than: A7 7.1.
  5. Move 43: escape in 1, answer E4, grade 22. Better than: A7 8.2.
  6. Move 47: capture in 1, answer A9, grade 26. Better than: A7 10.2, E6 9.5.

story-1889: 73 moves. Main line: area score Blue 44, Red 41 (Blue wins by 3). Estimate before the end: Blue by 7.8. Grade 30. Rank score 55.
  1. Move 15: capture in 3, answer B6, grade 42. Better than: A7 5.9.
  2. Move 21: escape in 1, answer C4, grade 22. Better than: A7 10.5.
  3. Move 23: capture in 3, answer B3, grade 46. Better than: A7 10.5, A4 6.8.
  4. Move 45: capture in 1, answer F9, grade 22. Better than: A7 11.0.
  5. Move 67: capture in 1, answer A6, grade 26. Better than: B9 23.2, A7 21.7.
  6. Move 71: capture in 1, answer C6, grade 22. Better than: A7 34.3.

story-2826: 65 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 30. Rank score 55.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: A3 15.5.
  2. Move 33: capture in 1, answer B1, grade 22. Better than: A3 9.6.
  3. Move 37: capture in 2, answer E3, grade 32. Better than: A3 6.4.
  4. Move 47: escape in 1, answer D2, grade 22. Better than: A3 8.8.

story-682: 72 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer D3, grade 22. Better than: E9 33.8.
  2. Move 45: escape in 1, answer F3, grade 22. Better than: E9 26.4.
  3. Move 47: escape in 3, answer J6, grade 64. Better than: E9 44.0, J5 41.1, H4 37.8, J3 40.4.
  4. Move 57: capture in 1, answer J8, grade 22. Better than: E9 52.7.
  5. Move 61: capture in 1, answer J1, grade 22. Better than: E9 42.0.

story-1024: 63 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 30. Rank score 50.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: C1 13.9.
  2. Move 33: capture in 1, answer A2, grade 22. Better than: C1 9.6.
  3. Move 37: capture in 2, answer C5, grade 32. Better than: C1 6.5.
  4. Move 45: capture in 1, answer D4, grade 22. Better than: C1 5.9.

story-1218: 92 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 30. Rank score 50.
  1. Move 25: capture in 3, answer C2, grade 42. Better than: D1 6.7.
  2. Move 27: capture in 1, answer B3, grade 22. Better than: D1 8.6.
  3. Move 31: escape in 1, answer C7, grade 22. Better than: D1 15.2.
  4. Move 45: capture in 2, answer J7, grade 36. Better than: J9 10.7, D1 10.8.
  5. Move 71: capture in 1, answer B1, grade 26. Better than: G3 6.2, D1 9.1.

story-1513: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer G4, grade 22. Better than: A5 34.1.
  2. Move 45: escape in 1, answer G6, grade 22. Better than: A5 28.5.
  3. Move 47: escape in 3, answer D9, grade 64. Better than: E9 37.9, G9 37.9, F8 32.9, A5 40.7.
  4. Move 57: capture in 1, answer B9, grade 22. Better than: A5 54.8.
  5. Move 61: capture in 1, answer J9, grade 22. Better than: A5 42.0.

story-2262: 61 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 30. Rank score 50.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: C1 14.0.
  2. Move 33: capture in 1, answer A2, grade 22. Better than: C1 9.6.
  3. Move 37: capture in 2, answer C5, grade 32. Better than: C1 6.5.
  4. Move 45: capture in 1, answer D4, grade 22. Better than: C1 5.9.

story-2844: 72 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer G4, grade 22. Better than: A5 34.2.
  2. Move 45: escape in 1, answer G6, grade 22. Better than: A5 28.5.
  3. Move 47: escape in 3, answer D9, grade 64. Better than: E9 39.9, G9 41.9, F8 32.7, A5 40.2.
  4. Move 57: capture in 1, answer B9, grade 22. Better than: A5 54.8.
  5. Move 61: capture in 1, answer J9, grade 22. Better than: A5 42.0.

story-2912: 72 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer D3, grade 22. Better than: E9 33.8.
  2. Move 45: escape in 1, answer F3, grade 22. Better than: E9 22.6.
  3. Move 47: escape in 3, answer J6, grade 64. Better than: E9 41.3, J5 36.9, H4 35.1, J3 36.6.
  4. Move 57: capture in 1, answer J8, grade 22. Better than: E9 55.0.
  5. Move 61: capture in 1, answer J1, grade 22. Better than: E9 42.0.

story-2927: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer D3, grade 22. Better than: E9 33.9.
  2. Move 45: escape in 1, answer F3, grade 22. Better than: E9 23.1.
  3. Move 47: escape in 3, answer J6, grade 64. Better than: E9 41.6, J5 36.7, H4 34.9, J3 36.4.
  4. Move 57: capture in 1, answer J8, grade 22. Better than: E9 54.8.
  5. Move 61: capture in 1, answer J1, grade 22. Better than: E9 42.0.

story-2988: 52 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.2. Grade 30. Rank score 50.
  1. Move 33: capture in 3, answer H8, grade 42. Better than: G9 19.4.
  2. Move 35: escape in 1, answer C4, grade 22. Better than: G9 9.2.
  3. Move 37: capture in 1, answer J8, grade 22. Better than: G9 6.2.
  4. Move 39: capture in 2, answer G5, grade 32. Better than: G9 7.7.

story-2991: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 50.
  1. Move 39: escape in 1, answer D3, grade 22. Better than: E9 33.9.
  2. Move 45: escape in 1, answer F3, grade 22. Better than: E9 23.1.
  3. Move 47: escape in 3, answer J6, grade 64. Better than: E9 41.6, J5 36.7, H4 36.3, J3 36.4.
  4. Move 57: capture in 1, answer J8, grade 22. Better than: E9 54.8.
  5. Move 61: capture in 1, answer J1, grade 22. Better than: E9 42.0.

story-961: 94 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 30. Rank score 45.
  1. Move 21: capture in 3, answer H5, grade 42. Better than: J6 19.6.
  2. Move 25: capture in 1, answer J6, grade 22. Better than: A4 16.1.
  3. Move 71: capture in 2, answer J9, grade 32. Better than: A4 30.1.
  4. Move 75: escape in 1, answer G2, grade 22. Better than: A4 15.0.

story-2688: 75 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 30. Rank score 45.
  1. Move 21: capture in 3, answer C8, grade 42. Better than: D9 10.9.
  2. Move 41: escape in 1, answer A5, grade 22. Better than: H9 6.0.
  3. Move 53: escape in 1, answer D5, grade 26. Better than: H9 5.7, G7 5.8.
  4. Move 57: capture in 1, answer A6, grade 30. Better than: B9 13.2, H9 13.2, G7 13.3.
  5. Move 65: escape in 2, answer J9, grade 32. Better than: G7 41.9.

story-227: 79 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 30. Rank score 40.
  1. Move 25: capture in 1, answer B9, grade 22. Better than: C3 10.5.
  2. Move 31: escape in 2, answer E4, grade 32. Better than: C4 17.6.
  3. Move 57: escape in 2, answer D8, grade 32. Better than: F6 26.5.
  4. Move 71: escape in 1, answer H9, grade 32. Better than: J9 17.6.

story-3007: 77 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 30. Rank score 40.
  1. Move 27: capture in 3, answer F2, grade 42. Better than: E1 7.4.
  2. Move 37: capture in 2, answer B9, grade 32. Better than: E1 24.4.
  3. Move 39: capture in 1, answer E1, grade 22. Better than: A8 39.5.
  4. Move 41: capture in 1, answer G1, grade 22. Better than: A8 35.4.

story-135: 82 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.7. Grade 30. Rank score 35.
  1. Move 25: capture in 3, answer H3, grade 42. Better than: J2 7.8.
  2. Move 31: capture in 1, answer D8, grade 22. Better than: J2 22.6.
  3. Move 45: capture in 1, answer F8, grade 22. Better than: J2 15.7.
  4. Move 61: capture in 2, answer J8, grade 32. Better than: J6 42.5.

story-2602: 65 moves. Main line: area score Blue 43, Red 42 (Blue wins by 1). Estimate before the end: Blue by 5.9. Grade 30. Rank score 35.
  1. Move 35: capture in 1, answer D2, grade 22. Better than: G5 19.1.
  2. Move 41: capture in 3, answer H4, grade 42. Better than: J5 25.2.
  3. Move 43: capture in 1, answer F4, grade 22. Better than: J5 10.5.
  4. Move 55: capture in 2, answer G1, grade 32. Better than: J1 25.0.

story-1741: 60 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 30. Rank score 30.
  1. Move 23: capture in 3, answer D2, grade 42. Better than: E1 5.6.
  2. Move 35: escape in 1, answer F9, grade 32. Better than: C9 6.7.
  3. Move 41: capture in 1, answer D9, grade 22. Better than: D2 16.8.
  4. Move 49: capture in 1, answer J8, grade 22. Better than: D2 17.6.

story-1754: 78 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 4.8. Grade 30. Rank score 30.
  1. Move 15: capture in 3, answer F2, grade 42. Better than: G1 5.7.
  2. Move 21: escape in 1, answer D3, grade 22. Better than: G1 8.7.
  3. Move 37: escape in 2, answer B8, grade 36. Better than: A7 12.7, G1 12.7.
  4. Move 53: capture in 1, answer H9, grade 26. Better than: C9 24.0, G1 25.8.
  5. Move 57: escape in 1, answer F3, grade 26. Better than: C9 45.7, G1 37.1.

story-2011: 87 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 30. Rank score 30.
  1. Move 37: capture in 3, answer D8, grade 42. Better than: E9 29.7.
  2. Move 45: capture in 1, answer E9, grade 22. Better than: J2 22.0.
  3. Move 55: escape in 1, answer A4, grade 32. Better than: J1 16.4.
  4. Move 65: capture in 1, answer J4, grade 22. Better than: H1 17.2.

story-2461: 70 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 8.0. Grade 31. Rank score 140.
  1. Move 29: capture in 3, answer B6, grade 42. Better than: A5 20.5.
  2. Move 33: capture in 1, answer A5, grade 22. Better than: G3 31.3.
  3. Move 35: capture in 1, answer A3, grade 22. Better than: G3 34.3.
  4. Move 37: escape in 1, answer A4, grade 22. Better than: G3 9.1.
  5. Move 39: capture in 3, answer C1, grade 52. Better than: G3 27.0.
  6. Move 47: escape in 1, answer C9, grade 22. Better than: G3 13.3.
  7. Move 53: capture in 3, answer B8, grade 46. Better than: A7 37.1, G3 34.8.
  8. Move 55: capture in 1, answer G3, grade 22. Better than: A7 54.1.
  9. Move 57: capture in 2, answer A8, grade 32. Better than: A6 39.1.
  10. Move 59: escape in 1, answer A6, grade 32. Better than: A9 43.5.
  11. Move 63: capture in 1, answer G1, grade 22. Better than: A9 8.3.

story-327: 78 moves. Main line: area score Blue 45, Red 41 (Blue wins by 4). Estimate before the end: Blue by 7.9. Grade 31. Rank score 125.
  1. Move 19: capture in 3, answer B4, grade 42. Better than: A3 13.6.
  2. Move 23: capture in 2, answer A3, grade 32. Better than: A1 32.9.
  3. Move 33: escape in 1, answer F5, grade 22. Better than: A1 9.9.
  4. Move 35: capture in 1, answer D6, grade 22. Better than: A1 9.3.
  5. Move 47: capture in 1, answer D1, grade 22. Better than: A1 9.6.
  6. Move 51: capture in 3, answer B8, grade 50. Better than: A7 35.7, A6 34.7, A1 36.3.
  7. Move 53: capture in 2, answer C9, grade 36. Better than: A9 36.0, A1 36.2.
  8. Move 55: capture in 2, answer A9, grade 36. Better than: A7 38.5, A1 38.0.
  9. Move 57: escape in 1, answer A7, grade 36. Better than: B9 41.7, A1 35.3.
  10. Move 61: capture in 1, answer D9, grade 30. Better than: A6 8.0, A5 8.3, A1 8.0.
  11. Move 63: capture in 1, answer A6, grade 22. Better than: A1 11.9.
  12. Move 69: escape in 1, answer E8, grade 22. Better than: A1 5.8.

story-315: 66 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 31. Rank score 105.
  1. Move 11: capture in 3, answer G8, grade 42. Better than: F9 14.1.
  2. Move 21: capture in 1, answer F9, grade 22. Better than: G3 21.8.
  3. Move 33: capture in 3, answer C2, grade 42. Better than: B1 11.3.
  4. Move 37: escape in 2, answer G9, grade 50. Better than: J7 32.0, H6 36.9, B1 25.7.
  5. Move 39: capture in 1, answer J9, grade 22. Better than: B1 34.3.
  6. Move 49: escape in 1, answer F8, grade 22. Better than: B1 43.9.
  7. Move 51: capture in 1, answer H9, grade 22. Better than: B1 43.6.
  8. Move 55: capture in 1, answer B1, grade 22. Better than: H4 8.1.
  9. Move 57: escape in 1, answer H4, grade 32. Better than: H8 61.9.

story-1473: 66 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 105.
  1. Move 11: capture in 3, answer G8, grade 42. Better than: F9 14.0.
  2. Move 21: capture in 1, answer F9, grade 22. Better than: G3 21.7.
  3. Move 33: capture in 3, answer C2, grade 42. Better than: B1 12.2.
  4. Move 37: escape in 2, answer G9, grade 50. Better than: J7 31.9, H6 36.7, B1 26.6.
  5. Move 39: capture in 1, answer J9, grade 22. Better than: B1 34.4.
  6. Move 49: escape in 1, answer F8, grade 22. Better than: B1 43.9.
  7. Move 51: capture in 1, answer H9, grade 22. Better than: B1 43.6.
  8. Move 55: capture in 1, answer B1, grade 22. Better than: H4 8.0.
  9. Move 57: escape in 1, answer H4, grade 32. Better than: H8 61.8.

story-1759: 76 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 1.9. Grade 31. Rank score 100.
  1. Move 19: capture in 3, answer B4, grade 42. Better than: A3 8.3.
  2. Move 21: capture in 2, answer C5, grade 36. Better than: D5 10.9, A3 10.9.
  3. Move 23: escape in 1, answer D5, grade 22. Better than: A3 14.7.
  4. Move 29: escape in 1, answer H6, grade 22. Better than: A3 23.7.
  5. Move 35: capture in 3, answer H9, grade 46. Better than: J8 18.1, A3 23.5.
  6. Move 39: capture in 1, answer J9, grade 22. Better than: A3 23.5.
  7. Move 41: escape in 1, answer J8, grade 36. Better than: G9 25.0, A3 25.1.
  8. Move 51: capture in 1, answer B6, grade 22. Better than: A3 14.8.

story-306: 70 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 90.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.0, D1 13.5.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 37.9, F4 35.3.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.2.
  5. Move 35: capture in 3, answer B3, grade 46. Better than: F4 11.0, A2 13.1.
  6. Move 39: capture in 1, answer A2, grade 22. Better than: F4 8.5.
  7. Move 51: capture in 1, answer J4, grade 22. Better than: F4 9.3.
  8. Move 59: escape in 1, answer H1, grade 32. Better than: G4 40.6.

story-360: 70 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 90.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.0, D1 13.5.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 37.9, F4 35.3.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.2.
  5. Move 35: capture in 3, answer B3, grade 46. Better than: F4 10.9, A2 13.1.
  6. Move 39: capture in 1, answer A2, grade 22. Better than: F4 8.6.
  7. Move 51: capture in 1, answer J4, grade 22. Better than: F4 9.2.
  8. Move 59: escape in 1, answer H1, grade 32. Better than: G4 40.6.

story-1116: 59 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 90.
  1. Move 17: capture in 3, answer C2, grade 42. Better than: D1 11.2.
  2. Move 27: capture in 3, answer G2, grade 42. Better than: H1 5.4.
  3. Move 33: capture in 3, answer B7, grade 46. Better than: A6 28.1, H1 27.0.
  4. Move 37: capture in 1, answer A6, grade 26. Better than: C8 10.4, H1 12.1.
  5. Move 39: capture in 1, answer H1, grade 22. Better than: C8 7.7.
  6. Move 41: escape in 1, answer G1, grade 22. Better than: C8 8.2.
  7. Move 43: capture in 1, answer A4, grade 22. Better than: C8 10.0.
  8. Move 45: capture in 1, answer B3, grade 22. Better than: C8 20.6.

story-2720: 70 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 90.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.1, D1 13.5.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 38.0, F4 35.2.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.2.
  5. Move 35: capture in 3, answer B3, grade 46. Better than: F4 10.9, A2 13.1.
  6. Move 39: capture in 1, answer A2, grade 22. Better than: F4 8.5.
  7. Move 51: capture in 1, answer J4, grade 22. Better than: F4 9.2.
  8. Move 59: escape in 1, answer H1, grade 32. Better than: G4 40.6.

story-558: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 31. Rank score 85.
  1. Move 17: capture in 3, answer B2, grade 42. Better than: C1 6.1.
  2. Move 21: capture in 2, answer B1, grade 32. Better than: D1 15.2.
  3. Move 25: escape in 2, answer F5, grade 36. Better than: E4 13.0, D1 14.9.
  4. Move 27: capture in 3, answer H2, grade 46. Better than: J3 21.0, D1 13.9.
  5. Move 29: capture in 1, answer D1, grade 22. Better than: J3 12.1.
  6. Move 41: capture in 1, answer J5, grade 22. Better than: A3 5.7.
  7. Move 45: capture in 1, answer J1, grade 22. Better than: A3 25.7.
  8. Move 47: capture in 1, answer G1, grade 22. Better than: A3 18.8.

story-2552: 79 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 31. Rank score 75.
  1. Move 27: capture in 3, answer G3, grade 46. Better than: J4 27.1, J3 27.4.
  2. Move 37: capture in 3, answer H7, grade 46. Better than: J8 9.0, J3 8.1.
  3. Move 39: escape in 1, answer D6, grade 26. Better than: J8 38.6, J3 40.0.
  4. Move 41: capture in 1, answer J8, grade 22. Better than: J3 10.7.
  5. Move 45: capture in 2, answer A7, grade 36. Better than: A9 35.9, J3 36.1.
  6. Move 47: escape in 1, answer B7, grade 26. Better than: A9 42.9, J3 42.8.
  7. Move 49: capture in 1, answer A9, grade 22. Better than: J3 42.1.
  8. Move 51: capture in 1, answer C9, grade 22. Better than: J3 41.3.

story-2882: 77 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 31. Rank score 75.
  1. Move 37: capture in 3, answer G5, grade 42. Better than: J5 5.6.
  2. Move 39: escape in 1, answer A3, grade 22. Better than: J5 16.2.
  3. Move 41: escape in 1, answer D2, grade 22. Better than: J5 28.3.
  4. Move 43: capture in 3, answer A5, grade 60. Better than: J5 21.5, A1 23.9, B1 21.6.
  5. Move 49: capture in 1, answer A6, grade 26. Better than: J7 15.9, J3 17.0.
  6. Move 59: capture in 1, answer F8, grade 26. Better than: J3 23.1, D1 23.2.
  7. Move 61: capture in 1, answer G9, grade 22. Better than: J3 21.8.

story-1520: 75 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 31. Rank score 70.
  1. Move 29: escape in 1, answer G4, grade 22. Better than: E4 17.9.
  2. Move 35: capture in 1, answer J5, grade 22. Better than: E4 22.8.
  3. Move 41: capture in 3, answer C8, grade 50. Better than: D9 11.3, E9 9.5, E4 11.9.
  4. Move 49: capture in 1, answer E4, grade 22. Better than: H6 9.8.
  5. Move 53: capture in 3, answer B8, grade 46. Better than: A7 20.7, H6 19.1.
  6. Move 61: capture in 1, answer A9, grade 22. Better than: H6 10.9.

story-1180: 80 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 31. Rank score 65.
  1. Move 19: capture in 3, answer G2, grade 42. Better than: F1 6.2.
  2. Move 31: capture in 1, answer J4, grade 22. Better than: F1 10.8.
  3. Move 35: capture in 3, answer D8, grade 46. Better than: E9 10.5, F1 9.8.
  4. Move 41: capture in 1, answer D6, grade 22. Better than: F1 24.7.
  5. Move 43: escape in 1, answer D7, grade 22. Better than: F1 22.1.
  6. Move 45: capture in 3, answer B8, grade 46. Better than: C9 23.2, F1 23.7.
  7. Move 49: capture in 1, answer D9, grade 22. Better than: F1 25.5.
  8. Move 63: capture in 1, answer F1, grade 26. Better than: A7 9.3, F5 6.7.

story-1237: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 65.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: D4 33.8, F1 13.8.
  2. Move 27: escape in 1, answer F1, grade 36. Better than: D4 35.3, G4 37.7.
  3. Move 29: escape in 1, answer C6, grade 22. Better than: D4 20.9.
  4. Move 31: escape in 1, answer F2, grade 22. Better than: D4 23.7.
  5. Move 43: capture in 2, answer A7, grade 36. Better than: A9 14.3, D4 11.6.
  6. Move 47: capture in 1, answer B6, grade 22. Better than: A9 12.6.

story-1509: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 65.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: D4 33.9, F1 13.9.
  2. Move 27: escape in 1, answer F1, grade 36. Better than: D4 35.3, G4 37.7.
  3. Move 29: escape in 1, answer C6, grade 22. Better than: D4 20.9.
  4. Move 31: escape in 1, answer F2, grade 22. Better than: D4 23.8.
  5. Move 43: capture in 2, answer A7, grade 36. Better than: A9 14.7, D4 10.0.
  6. Move 45: capture in 1, answer B6, grade 26. Better than: A9 14.5, D4 14.0.

story-1542: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 65.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.1, D1 13.5.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 37.9, F4 35.3.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.2.
  5. Move 43: capture in 2, answer J7, grade 36. Better than: J9 16.2, F4 11.9.
  6. Move 45: capture in 1, answer H6, grade 26. Better than: J9 16.3, F4 16.0.

story-2668: 74 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 31. Rank score 65.
  1. Move 33: capture in 3, answer H9, grade 46. Better than: J8 14.0, F5 10.7.
  2. Move 39: escape in 2, answer J9, grade 36. Better than: G9 24.4, F5 20.8.
  3. Move 41: capture in 1, answer J8, grade 22. Better than: F5 17.7.
  4. Move 45: capture in 1, answer A6, grade 22. Better than: F5 27.1.
  5. Move 49: capture in 1, answer E9, grade 22. Better than: F5 21.3.
  6. Move 59: capture in 2, answer D8, grade 36. Better than: C9 21.5, G4 24.1.

story-2729: 65 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 65.
  1. Move 19: capture in 2, answer B4, grade 32. Better than: D4 8.2.
  2. Move 33: escape in 1, answer J6, grade 22. Better than: D4 10.1.
  3. Move 39: capture in 3, answer H8, grade 46. Better than: G9 17.3, D4 26.5.
  4. Move 47: capture in 1, answer D4, grade 22. Better than: G9 11.1.
  5. Move 49: escape in 1, answer G9, grade 32. Better than: D9 42.0.

story-2833: 57 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 65.
  1. Move 25: capture in 3, answer H5, grade 46. Better than: F6 33.7, J4 13.1.
  2. Move 27: escape in 1, answer J4, grade 36. Better than: F6 35.6, F3 38.1.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F6 20.8.
  4. Move 31: escape in 1, answer H4, grade 22. Better than: F6 24.0.
  5. Move 43: capture in 2, answer C9, grade 36. Better than: A9 16.2, F6 11.9.
  6. Move 45: capture in 1, answer D8, grade 26. Better than: A9 16.4, F6 16.0.

story-1252: 63 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 60.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.0, D1 13.5.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 37.9, F4 35.3.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.1.
  5. Move 43: capture in 2, answer J7, grade 36. Better than: J9 14.4, F4 11.6.
  6. Move 55: escape in 1, answer H7, grade 22. Better than: H2 16.3.

story-1297: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 31. Rank score 60.
  1. Move 11: capture in 3, answer H3, grade 42. Better than: J4 13.8.
  2. Move 21: capture in 1, answer J4, grade 22. Better than: C3 21.9.
  3. Move 33: capture in 3, answer B7, grade 42. Better than: A8 11.3.
  4. Move 39: capture in 1, answer J1, grade 22. Better than: A8 34.5.
  5. Move 41: escape in 1, answer J2, grade 36. Better than: A8 25.6, G1 40.6.
  6. Move 51: escape in 1, answer H4, grade 22. Better than: A8 44.3.

story-1862: 57 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 60.
  1. Move 15: capture in 3, answer B3, grade 42. Better than: A4 10.8.
  2. Move 21: capture in 1, answer C2, grade 22. Better than: A4 21.4.
  3. Move 27: capture in 1, answer D1, grade 22. Better than: A4 12.5.
  4. Move 39: escape in 2, answer G4, grade 36. Better than: A4 13.2, J4 14.8.
  5. Move 41: escape in 1, answer A4, grade 32. Better than: A5 11.7.

story-2085: 63 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 60.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 34.1, D1 13.6.
  2. Move 27: escape in 1, answer D1, grade 36. Better than: C4 38.0, F4 35.3.
  3. Move 29: escape in 1, answer G6, grade 22. Better than: F4 21.0.
  4. Move 31: escape in 1, answer D2, grade 22. Better than: F4 24.2.
  5. Move 43: capture in 2, answer J7, grade 36. Better than: J9 14.3, F4 11.5.
  6. Move 55: escape in 1, answer H7, grade 22. Better than: H2 16.3.

story-2796: 63 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 31. Rank score 60.
  1. Move 25: capture in 3, answer H5, grade 46. Better than: F6 33.7, J4 13.1.
  2. Move 27: escape in 1, answer J4, grade 36. Better than: F6 35.7, F3 38.2.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F6 20.8.
  4. Move 31: escape in 1, answer H4, grade 22. Better than: F6 23.9.
  5. Move 43: capture in 2, answer C9, grade 36. Better than: A9 14.4, F6 11.6.
  6. Move 55: escape in 1, answer C8, grade 22. Better than: H8 16.3.

story-502: 72 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 31. Rank score 55.
  1. Move 17: capture in 3, answer B7, grade 42. Better than: A6 13.5.
  2. Move 33: capture in 1, answer A8, grade 22. Better than: H3 8.6.
  3. Move 37: escape in 1, answer J4, grade 32. Better than: H7 14.6.
  4. Move 41: capture in 1, answer J2, grade 22. Better than: J6 10.3.
  5. Move 43: capture in 3, answer B3, grade 46. Better than: J6 9.5, A2 12.6.
  6. Move 53: capture in 1, answer J6, grade 22. Better than: B1 12.5.

story-1792: 66 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 55.
  1. Move 39: escape in 1, answer F3, grade 22. Better than: E9 34.6.
  2. Move 43: escape in 3, answer A6, grade 64. Better than: E9 41.2, A5 29.0, B4 21.5, A3 45.7.
  3. Move 45: escape in 1, answer D3, grade 22. Better than: E9 30.8.
  4. Move 49: capture in 1, answer A8, grade 22. Better than: E9 49.1.
  5. Move 51: escape in 1, answer D1, grade 36. Better than: E9 40.1, A1 46.7.
  6. Move 57: capture in 1, answer A3, grade 22. Better than: E9 41.0.

story-2625: 68 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 55.
  1. Move 39: escape in 1, answer C4, grade 22. Better than: J5 33.6.
  2. Move 43: escape in 3, answer F9, grade 64. Better than: C9 45.8, E9 29.4, D8 21.2, J5 41.1.
  3. Move 45: escape in 1, answer C6, grade 22. Better than: J5 31.0.
  4. Move 49: capture in 1, answer H9, grade 22. Better than: J5 49.3.
  5. Move 51: escape in 1, answer A6, grade 36. Better than: A9 45.7, J5 40.3.
  6. Move 57: capture in 1, answer E9, grade 22. Better than: J5 43.1.

story-349: 79 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 31. Rank score 50.
  1. Move 27: capture in 3, answer B6, grade 42. Better than: A5 8.9.
  2. Move 31: capture in 3, answer G7, grade 46. Better than: G9 21.4, A5 15.2.
  3. Move 33: capture in 1, answer A5, grade 22. Better than: G9 21.3.
  4. Move 35: capture in 2, answer G9, grade 32. Better than: J9 18.9.
  5. Move 43: capture in 1, answer D2, grade 22. Better than: J9 20.0.
  6. Move 53: capture in 1, answer E1, grade 22. Better than: J9 13.3.

story-437: 75 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 31. Rank score 50.
  1. Move 27: capture in 3, answer B6, grade 42. Better than: A5 8.9.
  2. Move 31: capture in 3, answer G7, grade 46. Better than: G9 21.6, A5 15.1.
  3. Move 33: capture in 1, answer A5, grade 22. Better than: G9 21.3.
  4. Move 35: capture in 2, answer G9, grade 32. Better than: J9 18.8.
  5. Move 39: capture in 1, answer D2, grade 22. Better than: J9 11.1.
  6. Move 43: capture in 1, answer J9, grade 22. Better than: E1 24.9.

story-1167: 61 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 50.
  1. Move 23: capture in 2, answer F4, grade 32. Better than: G5 20.6.
  2. Move 27: capture in 1, answer G5, grade 22. Better than: B3 17.2.
  3. Move 37: capture in 3, answer E2, grade 46. Better than: E7 19.1, D1 20.2.
  4. Move 41: capture in 1, answer D1, grade 22. Better than: F3 13.3.

story-2289: 72 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 31. Rank score 50.
  1. Move 35: capture in 2, answer E6, grade 36. Better than: G9 8.4, F7 5.7.
  2. Move 43: capture in 1, answer A9, grade 26. Better than: G9 6.5, F7 6.1.
  3. Move 45: capture in 1, answer D8, grade 30. Better than: G9 10.6, A7 8.4, F7 10.4.
  4. Move 47: capture in 1, answer A7, grade 26. Better than: G9 8.9, F7 7.3.
  5. Move 53: escape in 2, answer D9, grade 36. Better than: B9 10.1, G9 10.2.
  6. Move 57: escape in 1, answer G9, grade 32. Better than: B9 15.9.

story-3122: 76 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 45.
  1. Move 29: capture in 1, answer J1, grade 22. Better than: C4 9.9.
  2. Move 35: capture in 3, answer H8, grade 46. Better than: J7 5.9, C4 8.3.
  3. Move 53: capture in 1, answer B5, grade 22. Better than: J7 17.1.
  4. Move 61: capture in 2, answer J8, grade 32. Better than: J6 16.2.

story-573: 71 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 40.
  1. Move 25: capture in 3, answer H3, grade 42. Better than: J4 6.2.
  2. Move 27: capture in 1, answer G2, grade 22. Better than: J4 8.6.
  3. Move 31: escape in 1, answer C3, grade 22. Better than: J4 15.0.
  4. Move 45: capture in 2, answer C9, grade 36. Better than: A9 10.2, J4 10.2.

story-594: 77 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.8. Grade 31. Rank score 40.
  1. Move 33: capture in 3, answer A7, grade 50. Better than: A9 15.8, B8 9.8, D4 14.2.
  2. Move 49: capture in 1, answer D4, grade 26. Better than: J9 41.2, G7 29.3.
  3. Move 59: capture in 1, answer G7, grade 22. Better than: J9 43.5.
  4. Move 61: capture in 1, answer A2, grade 22. Better than: J9 49.9.
  5. Move 65: escape in 2, answer F4, grade 36. Better than: J9 12.8, H4 14.2.
  6. Move 73: escape in 1, answer J9, grade 32. Better than: H7 15.7.

story-1609: 63 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 31. Rank score 40.
  1. Move 17: capture in 3, answer H3, grade 46. Better than: J5 11.7, J4 18.9.
  2. Move 25: capture in 2, answer D5, grade 32. Better than: E4 14.8.
  3. Move 29: capture in 1, answer J5, grade 22. Better than: E4 11.9.
  4. Move 43: capture in 1, answer C1, grade 22. Better than: E4 17.8.

story-1925: 63 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 31. Rank score 40.
  1. Move 17: capture in 3, answer H3, grade 46. Better than: J5 12.0, J4 19.2.
  2. Move 25: capture in 2, answer D5, grade 32. Better than: E4 14.8.
  3. Move 29: capture in 1, answer J5, grade 22. Better than: E4 11.9.
  4. Move 43: capture in 1, answer C1, grade 22. Better than: E4 17.8.

story-2087: 84 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 31. Rank score 40.
  1. Move 35: capture in 3, answer F6, grade 46. Better than: E5 6.6, A4 9.4.
  2. Move 37: capture in 2, answer E5, grade 32. Better than: A4 14.0.
  3. Move 57: capture in 1, answer A4, grade 22. Better than: G8 20.3.
  4. Move 59: capture in 2, answer G8, grade 32. Better than: A6 9.6.
  5. Move 61: capture in 1, answer F9, grade 22. Better than: A6 9.4.

story-2354: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 31. Rank score 40.
  1. Move 17: capture in 3, answer H3, grade 46. Better than: J5 12.0, J4 19.2.
  2. Move 25: capture in 2, answer D5, grade 32. Better than: E4 14.8.
  3. Move 29: capture in 1, answer J5, grade 22. Better than: E4 12.5.
  4. Move 43: capture in 1, answer C1, grade 22. Better than: E4 17.9.

story-2474: 79 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 31. Rank score 40.
  1. Move 15: capture in 3, answer D2, grade 42. Better than: C1 5.8.
  2. Move 21: escape in 1, answer F3, grade 22. Better than: C1 8.5.
  3. Move 37: capture in 2, answer D4, grade 36. Better than: D3 15.1, C1 32.2.
  4. Move 39: capture in 1, answer F9, grade 26. Better than: D3 8.0, C1 9.0.
  5. Move 43: capture in 2, answer C9, grade 36. Better than: A9 16.2, D3 15.2.
  6. Move 47: capture in 1, answer B4, grade 26. Better than: A9 8.2, D3 11.9.

story-1171: 77 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.8. Grade 31. Rank score 35.
  1. Move 25: capture in 3, answer E8, grade 46. Better than: F9 7.2, J5 9.5.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.6.
  3. Move 57: escape in 1, answer J4, grade 22. Better than: E1 39.2.
  4. Move 67: capture in 1, answer A1, grade 22. Better than: J1 10.8.
  5. Move 69: capture in 1, answer C3, grade 22. Better than: J1 14.1.

story-3212: 70 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 31. Rank score 30.
  1. Move 25: capture in 3, answer H8, grade 42. Better than: G9 8.7.
  2. Move 27: capture in 2, answer F2, grade 36. Better than: G9 15.6, G2 27.3.
  3. Move 31: capture in 1, answer E9, grade 22. Better than: G2 8.0.
  4. Move 35: capture in 1, answer G1, grade 22. Better than: D6 13.7.

story-2795: 87 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.7. Grade 32. Rank score 120.
  1. Move 29: capture in 3, answer B6, grade 42. Better than: A5 20.5.
  2. Move 33: capture in 1, answer A5, grade 22. Better than: G3 31.0.
  3. Move 35: capture in 1, answer A3, grade 22. Better than: G3 34.0.
  4. Move 37: escape in 1, answer A4, grade 22. Better than: G3 9.2.
  5. Move 39: capture in 3, answer C1, grade 52. Better than: G3 18.2.
  6. Move 47: capture in 3, answer G3, grade 42. Better than: G1 30.3.
  7. Move 49: capture in 2, answer G1, grade 32. Better than: E1 50.5.
  8. Move 51: capture in 1, answer A7, grade 26. Better than: E1 39.8, J1 41.2.
  9. Move 67: capture in 3, answer H2, grade 42. Better than: J3 45.7.
  10. Move 73: capture in 1, answer A8, grade 22. Better than: J1 6.4.
  11. Move 81: capture in 2, answer J1, grade 32. Better than: J4 58.3.

story-839: 79 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 32. Rank score 115.
  1. Move 17: capture in 3, answer H4, grade 42. Better than: J5 14.2.
  2. Move 21: capture in 2, answer E5, grade 36. Better than: J5 8.2, F4 10.2.
  3. Move 31: capture in 1, answer D2, grade 26. Better than: J5 10.6, F4 13.2.
  4. Move 33: capture in 1, answer C1, grade 26. Better than: J5 13.5, F4 16.3.
  5. Move 45: capture in 2, answer J4, grade 36. Better than: J6 10.6, F4 8.2.
  6. Move 47: capture in 1, answer J6, grade 22. Better than: F4 10.5.
  7. Move 53: capture in 1, answer G1, grade 22. Better than: F4 13.1.
  8. Move 59: capture in 3, answer C3, grade 52. Better than: F4 5.6.
  9. Move 73: escape in 1, answer J5, grade 22. Better than: F4 10.1.

story-560: 84 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 2.0. Grade 32. Rank score 105.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: C1 14.1.
  2. Move 33: capture in 1, answer A2, grade 22. Better than: C1 9.6.
  3. Move 37: capture in 2, answer C5, grade 32. Better than: C1 6.5.
  4. Move 49: escape in 1, answer A5, grade 22. Better than: C1 5.8.
  5. Move 53: capture in 2, answer D1, grade 32. Better than: B1 29.1.
  6. Move 55: escape in 1, answer B1, grade 32. Better than: E1 49.5.
  7. Move 57: capture in 3, answer G2, grade 42. Better than: F1 31.1.

story-1671: 84 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 1.9. Grade 32. Rank score 105.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: C1 14.0.
  2. Move 33: capture in 1, answer A2, grade 22. Better than: C1 9.6.
  3. Move 37: capture in 2, answer C5, grade 32. Better than: C1 6.5.
  4. Move 49: escape in 1, answer A5, grade 22. Better than: C1 5.7.
  5. Move 53: capture in 2, answer D1, grade 32. Better than: B1 29.1.
  6. Move 55: escape in 1, answer B1, grade 32. Better than: E1 49.5.
  7. Move 57: capture in 3, answer G2, grade 42. Better than: F1 31.1.

story-1400: 83 moves. Main line: area score Blue 42, Red 41 (Blue wins by 1). Estimate before the end: Blue by 7.9. Grade 32. Rank score 95.
  1. Move 29: capture in 3, answer F2, grade 42. Better than: E1 8.1.
  2. Move 37: capture in 2, answer E1, grade 32. Better than: G1 14.0.
  3. Move 43: escape in 1, answer A4, grade 40. Better than: A5 12.7, C1 10.4, G1 10.3.
  4. Move 49: capture in 3, answer G7, grade 42. Better than: H6 14.8.
  5. Move 53: capture in 3, answer H6, grade 42. Better than: J7 32.1.
  6. Move 59: escape in 1, answer G9, grade 22. Better than: J7 8.4.
  7. Move 65: escape in 1, answer D1, grade 22. Better than: J7 10.6.
  8. Move 67: capture in 1, answer C3, grade 22. Better than: J7 15.4.
  9. Move 69: capture in 1, answer B2, grade 22. Better than: J7 10.5.

story-3234: 71 moves. Main line: area score Blue 44, Red 43 (Blue wins by 1). Estimate before the end: Blue by 1.1. Grade 32. Rank score 75.
  1. Move 23: capture in 3, answer H2, grade 42. Better than: J3 8.1.
  2. Move 25: escape in 1, answer F3, grade 22. Better than: J3 8.1.
  3. Move 31: capture in 1, answer A5, grade 22. Better than: J3 8.5.
  4. Move 33: escape in 1, answer D6, grade 22. Better than: J3 10.1.
  5. Move 37: escape in 1, answer J3, grade 32. Better than: J4 40.2.
  6. Move 57: escape in 3, answer A4, grade 50. Better than: A6 22.3, B5 23.6, J4 21.4.

story-424: 66 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 32. Rank score 70.
  1. Move 25: capture in 3, answer B5, grade 42. Better than: A6 44.6.
  2. Move 33: capture in 2, answer F2, grade 32. Better than: G1 16.8.
  3. Move 45: capture in 1, answer A4, grade 22. Better than: G1 42.2.
  4. Move 49: capture in 2, answer A9, grade 36. Better than: C9 17.8, G1 17.7.
  5. Move 51: escape in 1, answer C9, grade 36. Better than: D9 19.6, G1 19.3.
  6. Move 55: capture in 1, answer A1, grade 22. Better than: G1 6.0.

story-2229: 112 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 32. Rank score 70.
  1. Move 41: escape in 1, answer A6, grade 32. Better than: A9 7.5.
  2. Move 43: capture in 2, answer B5, grade 32. Better than: C5 5.9.
  3. Move 75: capture in 2, answer G1, grade 32. Better than: C5 15.1.
  4. Move 105: capture in 2, answer C9, grade 40. Better than: E9 9.5, A4 8.5, J4 8.6.
  5. Move 107: capture in 1, answer E9, grade 26. Better than: A4 8.4, J4 8.4.

story-855: 62 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 32. Rank score 65.
  1. Move 33: capture in 3, answer H8, grade 42. Better than: J7 19.5.
  2. Move 35: capture in 1, answer H9, grade 22. Better than: J7 7.0.
  3. Move 43: capture in 2, answer J6, grade 32. Better than: J8 25.6.
  4. Move 47: escape in 1, answer J8, grade 32. Better than: J5 35.5.
  5. Move 49: escape in 1, answer D1, grade 32. Better than: A1 8.5.

story-1803: 71 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 32. Rank score 65.
  1. Move 13: capture in 2, answer D4, grade 32. Better than: E3 9.6.
  2. Move 25: capture in 1, answer C7, grade 22. Better than: E3 18.1.
  3. Move 27: capture in 3, answer B4, grade 46. Better than: A5 10.8, E3 11.7.
  4. Move 29: escape in 1, answer A5, grade 36. Better than: B3 14.4, E3 10.5.
  5. Move 31: capture in 1, answer E3, grade 26. Better than: A7 24.5, A3 22.9.

story-1098: 55 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 32. Rank score 60.
  1. Move 17: capture in 3, answer B3, grade 42. Better than: A4 10.8.
  2. Move 33: capture in 3, answer G2, grade 46. Better than: A8 26.7, F1 28.2.
  3. Move 37: capture in 1, answer F1, grade 26. Better than: A8 12.6, H3 10.6.
  4. Move 41: escape in 2, answer A7, grade 36. Better than: A9 8.2, H3 11.0.
  5. Move 43: capture in 1, answer D1, grade 22. Better than: H3 10.1.
  6. Move 45: capture in 1, answer C2, grade 22. Better than: H3 19.5.

story-1581: 69 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 9.9. Grade 32. Rank score 60.
  1. Move 27: capture in 3, answer C8, grade 42. Better than: B9 10.6.
  2. Move 29: capture in 1, answer D7, grade 22. Better than: B9 9.2.
  3. Move 35: capture in 2, answer C9, grade 32. Better than: A9 31.2.
  4. Move 45: escape in 1, answer A9, grade 32. Better than: C7 43.7.

story-1653: 81 moves. Main line: area score Blue 45, Red 41 (Blue wins by 4). Estimate before the end: Blue by 9.9. Grade 32. Rank score 60.
  1. Move 27: capture in 3, answer C8, grade 42. Better than: B9 10.9.
  2. Move 29: capture in 1, answer D7, grade 22. Better than: B9 8.0.
  3. Move 35: capture in 2, answer C9, grade 32. Better than: A9 31.4.
  4. Move 45: escape in 1, answer A9, grade 32. Better than: C7 37.2.
  5. Move 65: capture in 1, answer H4, grade 30. Better than: E9 7.4, E6 7.7, J1 9.1.

story-1730: 70 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 10.0. Grade 32. Rank score 60.
  1. Move 27: capture in 3, answer C8, grade 42. Better than: B9 10.6.
  2. Move 29: capture in 1, answer D7, grade 22. Better than: B9 8.0.
  3. Move 35: capture in 2, answer C9, grade 32. Better than: A9 31.6.
  4. Move 45: escape in 1, answer A9, grade 32. Better than: C7 43.7.

story-286: 69 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 32. Rank score 55.
  1. Move 39: escape in 1, answer D9, grade 32. Better than: C6 48.9.
  2. Move 45: escape in 1, answer D8, grade 22. Better than: A4 14.0.
  3. Move 47: escape in 1, answer A4, grade 32. Better than: B6 9.7.
  4. Move 49: capture in 3, answer H8, grade 46. Better than: G9 6.0, A6 10.7.
  5. Move 51: escape in 1, answer G9, grade 36. Better than: A6 10.7, G6 10.8.
  6. Move 53: escape in 1, answer C2, grade 22. Better than: A6 7.9.

story-2209: 59 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 32. Rank score 55.
  1. Move 17: capture in 3, answer G8, grade 42. Better than: F9 11.2.
  2. Move 33: capture in 3, answer H3, grade 46. Better than: B9 27.1, J4 28.1.
  3. Move 37: capture in 1, answer J4, grade 26. Better than: B9 12.3, G2 10.6.
  4. Move 39: capture in 1, answer B9, grade 22. Better than: G2 7.9.
  5. Move 41: escape in 2, answer C9, grade 36. Better than: A9 8.3, G2 10.2.
  6. Move 43: capture in 1, answer H7, grade 22. Better than: G2 26.1.

story-2353: 59 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 32. Rank score 55.
  1. Move 25: capture in 3, answer H5, grade 46. Better than: F6 33.6, J4 13.0.
  2. Move 27: escape in 1, answer J4, grade 36. Better than: F6 35.3, F3 37.6.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F6 20.8.
  4. Move 31: escape in 1, answer H4, grade 22. Better than: F6 24.0.
  5. Move 45: escape in 1, answer F6, grade 32. Better than: D8 25.3.

story-3189: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 32. Rank score 55.
  1. Move 35: capture in 3, answer B3, grade 42. Better than: A2 11.7.
  2. Move 37: escape in 1, answer A2, grade 32. Better than: C3 9.5.
  3. Move 39: escape in 2, answer A3, grade 32. Better than: A1 5.5.
  4. Move 53: capture in 1, answer B1, grade 22. Better than: G9 5.8.

story-775: 57 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 6.0. Grade 32. Rank score 50.
  1. Move 31: capture in 3, answer H6, grade 42. Better than: J7 9.1.
  2. Move 33: escape in 1, answer J7, grade 32. Better than: F6 27.4.
  3. Move 37: capture in 3, answer E2, grade 42. Better than: D1 13.8.
  4. Move 39: capture in 1, answer F5, grade 22. Better than: D1 16.5.
  5. Move 47: escape in 1, answer H9, grade 22. Better than: E4 6.1.

story-810: 55 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 32. Rank score 50.
  1. Move 25: capture in 3, answer B5, grade 46. Better than: D6 33.4, A4 13.5.
  2. Move 27: escape in 1, answer A4, grade 36. Better than: D6 35.5, D3 37.8.
  3. Move 29: escape in 1, answer F7, grade 22. Better than: D6 20.9.
  4. Move 31: escape in 1, answer B4, grade 22. Better than: D6 24.0.
  5. Move 51: capture in 2, answer G9, grade 32. Better than: J9 13.9.

story-3050: 60 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 32. Rank score 50.
  1. Move 13: capture in 3, answer C2, grade 42. Better than: D1 10.4.
  2. Move 21: capture in 1, answer D1, grade 22. Better than: C7 21.7.
  3. Move 31: capture in 2, answer A7, grade 32. Better than: A9 24.6.
  4. Move 33: escape in 1, answer A9, grade 32. Better than: A6 55.4.

story-50: 75 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 32. Rank score 45.
  1. Move 31: capture in 3, answer B2, grade 42. Better than: A3 10.6.
  2. Move 39: escape in 1, answer A3, grade 32. Better than: D2 47.5.
  3. Move 53: escape in 2, answer G9, grade 32. Better than: J9 32.2.
  4. Move 71: capture in 1, answer D1, grade 22. Better than: G1 58.0.

story-817: 69 moves. Main line: area score Blue 48, Red 39 (Blue wins by 9). Estimate before the end: Blue by 6.0. Grade 32. Rank score 45.
  1. Move 41: escape in 1, answer D1, grade 36. Better than: H5 13.1, A1 16.1.
  2. Move 43: capture in 3, answer B3, grade 46. Better than: H5 8.4, A2 7.5.
  3. Move 47: capture in 1, answer A2, grade 22. Better than: H5 10.7.
  4. Move 51: capture in 1, answer H5, grade 22. Better than: D4 27.9.

story-2846: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 32. Rank score 45.
  1. Move 19: capture in 3, answer B8, grade 42. Better than: A7 10.5.
  2. Move 39: escape in 1, answer D7, grade 22. Better than: A1 23.7.
  3. Move 41: capture in 3, answer E8, grade 50. Better than: C9 16.8, D9 21.3, A1 24.6.
  4. Move 43: escape in 1, answer E2, grade 22. Better than: A1 16.7.
  5. Move 57: capture in 1, answer A3, grade 22. Better than: C9 9.2.

story-20: 80 moves. Main line: area score Blue 47, Red 40 (Blue wins by 7). Estimate before the end: Blue by 6.7. Grade 32. Rank score 40.
  1. Move 31: capture in 3, answer B7, grade 46. Better than: E9 8.4, A6 9.6.
  2. Move 45: escape in 2, answer A3, grade 36. Better than: E7 17.3, A1 24.6.
  3. Move 55: capture in 1, answer A5, grade 22. Better than: E7 32.4.
  4. Move 71: capture in 1, answer E7, grade 22. Better than: G1 26.1.

story-786: 63 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 32. Rank score 40.
  1. Move 31: capture in 2, answer B6, grade 32. Better than: D6 16.3.
  2. Move 35: escape in 1, answer D6, grade 32. Better than: F3 33.8.
  3. Move 43: capture in 2, answer D2, grade 32. Better than: C1 11.8.
  4. Move 53: escape in 2, answer C8, grade 32. Better than: B9 10.0.

story-832: 83 moves. Main line: area score Blue 43, Red 41 (Blue wins by 2). Estimate before the end: Blue by 8.0. Grade 32. Rank score 40.
  1. Move 17: capture in 3, answer D2, grade 42. Better than: E3 10.7.
  2. Move 33: escape in 1, answer E9, grade 22. Better than: E3 7.3.
  3. Move 45: escape in 2, answer G9, grade 32. Better than: J9 21.7.
  4. Move 57: capture in 2, answer J9, grade 32. Better than: J7 93.7.

story-1195: 72 moves. Main line: area score Blue 47, Red 39 (Blue wins by 8). Estimate before the end: Blue by 2.1. Grade 32. Rank score 40.
  1. Move 17: capture in 3, answer H2, grade 42. Better than: J3 5.7.
  2. Move 21: escape in 1, answer J3, grade 32. Better than: J4 21.2.
  3. Move 29: escape in 1, answer F8, grade 32. Better than: F5 8.2.
  4. Move 57: capture in 1, answer H1, grade 22. Better than: F6 33.7.

story-16: 77 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 32. Rank score 30.
  1. Move 21: capture in 3, answer H6, grade 42. Better than: J5 11.3.
  2. Move 27: capture in 1, answer A3, grade 22. Better than: J5 24.1.
  3. Move 61: capture in 1, answer G1, grade 22. Better than: J5 7.3.
  4. Move 67: capture in 3, answer H2, grade 42. Better than: J3 34.6.

story-14: 55 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 32. Rank score 25.
  1. Move 25: capture in 3, answer E2, grade 46. Better than: F4 33.5, D1 14.8.
  2. Move 29: escape in 1, answer D2, grade 22. Better than: F4 23.7.
  3. Move 33: escape in 1, answer G6, grade 22. Better than: F4 25.2.
  4. Move 43: capture in 2, answer J7, grade 36. Better than: J9 14.4, F4 11.5.

story-994: 83 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 33. Rank score 140.
  1. Move 15: capture in 3, answer F8, grade 42. Better than: G9 5.9.
  2. Move 21: escape in 1, answer D7, grade 22. Better than: G9 11.2.
  3. Move 23: capture in 3, answer C8, grade 46. Better than: D9 6.7, G9 10.3.
  4. Move 27: capture in 1, answer D9, grade 22. Better than: G9 11.8.
  5. Move 33: capture in 3, answer H2, grade 54. Better than: G9 16.3, C1 14.8, G1 11.9, J1 15.9.
  6. Move 37: capture in 1, answer J1, grade 26. Better than: G9 21.6, C1 18.4.
  7. Move 39: capture in 1, answer B9, grade 30. Better than: G9 19.6, J3 14.8, C1 15.5.
  8. Move 49: capture in 1, answer C1, grade 22. Better than: G9 17.7.
  9. Move 53: capture in 2, answer F6, grade 36. Better than: G9 44.6, F7 43.6.
  10. Move 55: capture in 2, answer B6, grade 40. Better than: G9 10.0, A7 8.1, F7 8.7.
  11. Move 63: capture in 1, answer J7, grade 26. Better than: G9 6.2, F7 6.2.
  12. Move 73: capture in 1, answer J9, grade 26. Better than: G9 11.7, F7 12.1.
  13. Move 79: escape in 1, answer G9, grade 32. Better than: J8 21.4.

story-2000: 83 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 33. Rank score 140.
  1. Move 15: capture in 3, answer F8, grade 42. Better than: G9 5.9.
  2. Move 21: escape in 1, answer D7, grade 22. Better than: G9 11.0.
  3. Move 23: capture in 3, answer C8, grade 46. Better than: D9 6.8, G9 10.2.
  4. Move 27: capture in 1, answer D9, grade 22. Better than: G9 11.8.
  5. Move 33: capture in 3, answer H2, grade 54. Better than: G9 16.3, C1 14.6, G1 11.9, J1 16.1.
  6. Move 37: capture in 1, answer J1, grade 26. Better than: G9 20.8, C1 17.6.
  7. Move 39: capture in 1, answer B9, grade 30. Better than: G9 19.6, J3 14.8, C1 15.5.
  8. Move 49: capture in 1, answer C1, grade 22. Better than: G9 17.7.
  9. Move 53: capture in 2, answer F6, grade 36. Better than: G9 45.6, F7 44.2.
  10. Move 55: capture in 2, answer B6, grade 40. Better than: G9 10.0, A7 8.2, F7 8.8.
  11. Move 63: capture in 1, answer J7, grade 26. Better than: G9 6.2, F7 6.2.
  12. Move 73: capture in 1, answer J9, grade 26. Better than: G9 11.7, F7 12.1.
  13. Move 79: escape in 1, answer G9, grade 32. Better than: J8 21.3.

story-403: 85 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 7.9. Grade 33. Rank score 125.
  1. Move 29: capture in 3, answer H8, grade 42. Better than: G9 51.5.
  2. Move 31: escape in 1, answer F5, grade 22. Better than: G9 37.5.
  3. Move 33: capture in 3, answer H4, grade 50. Better than: G9 27.8, J6 12.8, J5 13.0.
  4. Move 35: capture in 3, answer H2, grade 46. Better than: G9 12.2, J3 7.8.
  5. Move 37: capture in 2, answer J3, grade 36. Better than: G9 13.7, J1 13.6.
  6. Move 41: escape in 1, answer J2, grade 22. Better than: G9 6.5.
  7. Move 43: capture in 1, answer J5, grade 22. Better than: G9 18.3.
  8. Move 45: capture in 2, answer F2, grade 40. Better than: G9 9.8, J6 9.4, F1 8.8.
  9. Move 47: escape in 1, answer F1, grade 26. Better than: G9 9.5, J6 8.0.
  10. Move 53: escape in 1, answer D1, grade 26. Better than: G9 5.8, J6 5.8.
  11. Move 55: capture in 2, answer B2, grade 40. Better than: G9 5.5, J6 5.6, A1 5.6.
  12. Move 67: capture in 1, answer A3, grade 26. Better than: G9 8.4, J6 8.5.

story-1283: 77 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 33. Rank score 125.
  1. Move 19: capture in 3, answer H2, grade 46. Better than: F8 16.5, G1 10.5.
  2. Move 23: capture in 1, answer G1, grade 22. Better than: F8 7.5.
  3. Move 29: escape in 1, answer D7, grade 22. Better than: F8 8.1.
  4. Move 37: escape in 1, answer E6, grade 32. Better than: E5 28.3.
  5. Move 45: capture in 1, answer C9, grade 22. Better than: E3 18.8.
  6. Move 47: escape in 1, answer G6, grade 22. Better than: E3 41.9.
  7. Move 51: escape in 1, answer D6, grade 22. Better than: E3 9.6.
  8. Move 57: escape in 3, answer J6, grade 50. Better than: J9 29.4, H8 26.2, E3 26.2.
  9. Move 61: escape in 3, answer J4, grade 50. Better than: J9 93.9, H8 33.9, E3 32.0.
  10. Move 65: capture in 3, answer H3, grade 52. Better than: E8 94.9.
  11. Move 71: capture in 1, answer J1, grade 26. Better than: J9 15.8, J2 15.7.

story-923: 79 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 5.8. Grade 33. Rank score 85.
  1. Move 17: capture in 3, answer D2, grade 42. Better than: E3 10.7.
  2. Move 33: escape in 1, answer E9, grade 22. Better than: E3 7.3.
  3. Move 45: escape in 2, answer G9, grade 32. Better than: J9 21.7.
  4. Move 67: capture in 2, answer D8, grade 32. Better than: C7 20.4.
  5. Move 69: escape in 1, answer C7, grade 32. Better than: D9 37.8.
  6. Move 71: capture in 3, answer C9, grade 42. Better than: B8 23.9.
  7. Move 73: escape in 1, answer B8, grade 32. Better than: D9 23.6.

story-898: 57 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 33. Rank score 80.
  1. Move 27: capture in 3, answer H6, grade 42. Better than: J5 17.6.
  2. Move 31: capture in 1, answer J5, grade 22. Better than: C3 29.5.
  3. Move 39: capture in 3, answer G1, grade 42. Better than: H2 10.9.
  4. Move 41: escape in 2, answer C4, grade 36. Better than: D7 13.6, H2 18.4.
  5. Move 43: capture in 1, answer B3, grade 22. Better than: H2 20.0.
  6. Move 49: escape in 2, answer H2, grade 46. Better than: J6 30.0, H5 30.0.
  7. Move 51: capture in 1, answer A4, grade 22. Better than: J1 14.0.

story-1278: 61 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 33. Rank score 80.
  1. Move 27: capture in 3, answer H6, grade 42. Better than: J5 17.4.
  2. Move 31: capture in 1, answer J5, grade 22. Better than: C3 29.5.
  3. Move 39: capture in 3, answer G1, grade 42. Better than: H2 10.9.
  4. Move 41: escape in 2, answer C4, grade 36. Better than: D7 13.5, H2 18.3.
  5. Move 43: capture in 1, answer B3, grade 22. Better than: H2 20.0.
  6. Move 49: escape in 2, answer H2, grade 46. Better than: J6 30.0, H5 30.0.
  7. Move 51: capture in 1, answer A4, grade 22. Better than: J1 14.0.

story-2018: 70 moves. Main line: area score Blue 46, Red 40 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 33. Rank score 75.
  1. Move 25: capture in 3, answer B3, grade 42. Better than: A4 5.5.
  2. Move 41: capture in 2, answer C1, grade 32. Better than: E1 8.6.
  3. Move 43: capture in 3, answer H8, grade 46. Better than: G9 15.2, E1 15.0.
  4. Move 51: capture in 1, answer G9, grade 22. Better than: E1 20.6.
  5. Move 53: capture in 1, answer J9, grade 22. Better than: E1 21.0.
  6. Move 59: escape in 2, answer E1, grade 32. Better than: G3 25.9.

story-528: 77 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 33. Rank score 70.
  1. Move 25: escape in 1, answer A4, grade 32. Better than: A1 6.8.
  2. Move 31: escape in 3, answer G7, grade 46. Better than: J8 16.6, J6 20.5.
  3. Move 33: capture in 3, answer C2, grade 42. Better than: B1 9.1.
  4. Move 37: escape in 1, answer C6, grade 22. Better than: B1 24.3.
  5. Move 39: capture in 2, answer E5, grade 36. Better than: F7 16.2, B1 29.4.
  6. Move 51: capture in 1, answer B1, grade 22. Better than: F7 5.4.

story-968: 57 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 33. Rank score 70.
  1. Move 27: capture in 3, answer D8, grade 42. Better than: E9 20.1.
  2. Move 31: capture in 1, answer E9, grade 22. Better than: G3 29.8.
  3. Move 39: capture in 3, answer J7, grade 42. Better than: H8 10.5.
  4. Move 41: escape in 2, answer F3, grade 36. Better than: H8 18.4, C4 13.7.
  5. Move 43: capture in 1, answer G2, grade 22. Better than: H8 19.8.
  6. Move 49: escape in 2, answer H8, grade 46. Better than: D9 29.9, E8 29.9.
  7. Move 51: capture in 1, answer F1, grade 22. Better than: J9 14.0.

story-1222: 70 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 33. Rank score 70.
  1. Move 11: capture in 3, answer H3, grade 42. Better than: J4 13.8.
  2. Move 21: capture in 1, answer J4, grade 22. Better than: C3 21.7.
  3. Move 33: capture in 3, answer B7, grade 42. Better than: A8 11.3.
  4. Move 39: capture in 1, answer J1, grade 22. Better than: A8 34.4.
  5. Move 41: escape in 1, answer J2, grade 36. Better than: A8 25.0, G1 40.6.
  6. Move 53: capture in 2, answer E3, grade 32. Better than: A8 37.3.

story-1881: 63 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 33. Rank score 65.
  1. Move 25: capture in 2, answer D2, grade 32. Better than: E2 9.1.
  2. Move 29: capture in 3, answer H9, grade 46. Better than: J8 9.1, E2 18.7.
  3. Move 31: capture in 1, answer E2, grade 22. Better than: J8 11.2.
  4. Move 33: capture in 2, answer J7, grade 32. Better than: J9 15.0.
  5. Move 37: escape in 1, answer J8, grade 32. Better than: G9 13.7.

story-2507: 78 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.8. Grade 33. Rank score 65.
  1. Move 25: capture in 2, answer B5, grade 32. Better than: A6 23.5.
  2. Move 31: escape in 2, answer C9, grade 32. Better than: A9 31.2.
  3. Move 33: capture in 2, answer D7, grade 32. Better than: A9 29.3.
  4. Move 43: capture in 1, answer A9, grade 22. Better than: J5 30.2.
  5. Move 53: escape in 2, answer D1, grade 46. Better than: A3 7.8, A1 7.6.

story-3176: 75 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 33. Rank score 65.
  1. Move 39: escape in 1, answer H2, grade 32. Better than: G4 7.0.
  2. Move 45: escape in 1, answer J3, grade 32. Better than: G4 8.6.
  3. Move 51: capture in 2, answer E5, grade 32. Better than: E7 28.9.
  4. Move 57: capture in 1, answer E7, grade 22. Better than: A4 7.8.
  5. Move 69: escape in 2, answer A6, grade 46. Better than: B6 6.0, A5 6.0.

story-696: 77 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 33. Rank score 60.
  1. Move 23: capture in 3, answer H8, grade 42. Better than: J7 8.8.
  2. Move 25: capture in 1, answer J6, grade 22. Better than: J7 9.9.
  3. Move 39: capture in 3, answer B7, grade 42. Better than: A8 24.8.
  4. Move 41: escape in 2, answer B8, grade 32. Better than: C7 29.2.
  5. Move 53: capture in 2, answer G9, grade 36. Better than: A9 11.7, J9 17.7.
  6. Move 55: capture in 1, answer F8, grade 26. Better than: A9 15.7, J9 21.5.

story-2792: 71 moves. Main line: area score Blue 48, Red 38 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 33. Rank score 60.
  1. Move 37: capture in 1, answer H9, grade 22. Better than: D4 10.5.
  2. Move 43: capture in 1, answer D9, grade 22. Better than: D4 18.7.
  3. Move 47: escape in 1, answer C6, grade 22. Better than: D4 19.3.
  4. Move 53: capture in 1, answer A3, grade 22. Better than: A1 5.6.
  5. Move 59: escape in 3, answer A1, grade 60. Better than: E2 11.6, E1 11.7, G1 11.9.
  6. Move 61: escape in 3, answer C8, grade 60. Better than: E9 25.7, G9 27.0, C1 14.4.
  7. Move 65: escape in 1, answer B1, grade 26. Better than: B9 5.7, A5 5.8.

story-3206: 66 moves. Main line: area score Blue 47, Red 40 (Blue wins by 7). Estimate before the end: Blue by 6.8. Grade 33. Rank score 60.
  1. Move 15: capture in 3, answer H6, grade 42. Better than: J5 12.9.
  2. Move 25: capture in 3, answer C2, grade 46. Better than: J5 42.3, D1 43.8.
  3. Move 29: capture in 1, answer D1, grade 22. Better than: J5 19.7.
  4. Move 49: escape in 2, answer C9, grade 36. Better than: A9 10.1, E9 9.3.
  5. Move 55: escape in 1, answer E1, grade 22. Better than: E9 26.9.
  6. Move 57: escape in 1, answer E9, grade 32. Better than: A9 34.8.

story-1992: 69 moves. Main line: area score Blue 41, Red 40 (Blue wins by 1). Estimate before the end: Blue by 9.8. Grade 33. Rank score 55.
  1. Move 25: capture in 2, answer H6, grade 32. Better than: H5 9.6.
  2. Move 27: capture in 3, answer H8, grade 46. Better than: J7 9.4, H5 12.0.
  3. Move 29: capture in 1, answer H5, grade 22. Better than: J7 10.8.
  4. Move 31: capture in 2, answer J7, grade 32. Better than: J9 16.7.

story-2940: 48 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.2. Grade 33. Rank score 50.
  1. Move 19: capture in 3, answer D3, grade 42. Better than: E4 9.2.
  2. Move 31: capture in 3, answer H7, grade 46. Better than: J8 10.7, E4 8.0.
  3. Move 33: capture in 1, answer E4, grade 22. Better than: J8 12.2.
  4. Move 37: escape in 1, answer A4, grade 32. Better than: A5 13.2.
  5. Move 41: escape in 1, answer D4, grade 22. Better than: A7 21.9.

story-3235: 79 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 2.0. Grade 33. Rank score 50.
  1. Move 27: escape in 1, answer J4, grade 32. Better than: F3 50.1.
  2. Move 37: capture in 3, answer E8, grade 46. Better than: D9 29.3, E1 25.6.
  3. Move 59: escape in 1, answer J8, grade 32. Better than: G7 8.1.
  4. Move 61: escape in 2, answer J7, grade 32. Better than: J9 7.2.
  5. Move 69: capture in 1, answer A9, grade 22. Better than: C1 28.6.

story-283: 49 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 33. Rank score 45.
  1. Move 17: capture in 3, answer G8, grade 46. Better than: E9 11.4, F9 18.8.
  2. Move 33: capture in 1, answer E9, grade 22. Better than: H1 7.5.
  3. Move 35: capture in 1, answer H1, grade 22. Better than: C9 8.7.
  4. Move 41: capture in 2, answer E7, grade 40. Better than: F8 8.0, F5 8.1, H3 8.1.

story-1745: 73 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 33. Rank score 45.
  1. Move 29: capture in 3, answer F5, grade 46. Better than: E7 10.8, D6 18.7.
  2. Move 35: escape in 1, answer H6, grade 22. Better than: D4 40.2.
  3. Move 39: capture in 1, answer H7, grade 22. Better than: D4 31.9.
  4. Move 47: capture in 3, answer A3, grade 42. Better than: A1 17.0.

story-867: 85 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 33. Rank score 40.
  1. Move 25: capture in 3, answer E8, grade 46. Better than: F9 7.1, J5 8.1.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.0.
  3. Move 59: capture in 2, answer A3, grade 32. Better than: A1 39.0.
  4. Move 61: capture in 1, answer B4, grade 22. Better than: A1 9.5.
  5. Move 73: capture in 1, answer A4, grade 22. Better than: A1 12.1.

story-3178: 73 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.7. Grade 33. Rank score 40.
  1. Move 37: capture in 3, answer H4, grade 42. Better than: F3 11.6.
  2. Move 39: capture in 2, answer J3, grade 36. Better than: F3 44.9, J1 44.5.
  3. Move 49: capture in 1, answer J1, grade 22. Better than: F3 7.2.
  4. Move 57: capture in 2, answer F2, grade 32. Better than: G1 51.7.

story-3195: 73 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 33. Rank score 40.
  1. Move 33: capture in 3, answer C2, grade 42. Better than: B1 10.0.
  2. Move 37: escape in 2, answer C1, grade 32. Better than: A1 6.7.
  3. Move 39: capture in 3, answer B3, grade 42. Better than: A2 5.4.
  4. Move 47: escape in 1, answer A3, grade 22. Better than: F7 5.9.
  5. Move 55: capture in 1, answer J5, grade 26. Better than: B9 6.7, F7 8.0.

story-2523: 47 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 33. Rank score 35.
  1. Move 21: capture in 3, answer G2, grade 42. Better than: F1 10.9.
  2. Move 25: capture in 3, answer H7, grade 42. Better than: J6 16.7.
  3. Move 27: escape in 1, answer D8, grade 22. Better than: J6 8.1.
  4. Move 35: capture in 1, answer H1, grade 26. Better than: G8 14.2, J6 14.4.

story-2559: 53 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 33. Rank score 35.
  1. Move 21: capture in 3, answer C2, grade 42. Better than: D1 9.2.
  2. Move 25: capture in 1, answer C4, grade 22. Better than: D1 9.9.
  3. Move 27: capture in 3, answer B7, grade 46. Better than: A6 9.2, D1 9.6.
  4. Move 29: capture in 1, answer D1, grade 22. Better than: A6 8.4.

story-2896: 53 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 33. Rank score 35.
  1. Move 21: capture in 3, answer H3, grade 42. Better than: J4 8.5.
  2. Move 25: capture in 1, answer F3, grade 22. Better than: J4 9.8.
  3. Move 27: capture in 3, answer C2, grade 46. Better than: J4 9.2, D1 8.8.
  4. Move 29: capture in 1, answer J4, grade 22. Better than: D1 8.3.

story-1879: 73 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 33. Rank score 25.
  1. Move 11: capture in 3, answer H3, grade 42. Better than: J4 13.7.
  2. Move 21: capture in 1, answer J4, grade 22. Better than: C3 21.8.
  3. Move 33: capture in 3, answer B7, grade 42. Better than: A8 11.3.
  4. Move 45: capture in 1, answer E5, grade 26. Better than: A8 11.7, C7 11.8.

story-2270: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 33. Rank score 20.
  1. Move 17: capture in 3, answer B3, grade 46. Better than: A5 11.8, A4 18.8.
  2. Move 29: capture in 2, answer F5, grade 32. Better than: E4 9.1.
  3. Move 57: escape in 1, answer C9, grade 22. Better than: E4 5.6.
  4. Move 61: capture in 2, answer A8, grade 32. Better than: B9 11.8.

story-348: 72 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 34. Rank score 140.
  1. Move 17: capture in 3, answer H2, grade 42. Better than: J3 5.6.
  2. Move 21: escape in 1, answer F4, grade 22. Better than: J3 6.3.
  3. Move 23: capture in 3, answer F5, grade 46. Better than: J6 6.5, J3 8.6.
  4. Move 25: escape in 1, answer E6, grade 26. Better than: J6 5.7, J3 5.5.
  5. Move 35: capture in 1, answer G2, grade 26. Better than: J6 10.1, J3 9.9.
  6. Move 39: capture in 1, answer D1, grade 26. Better than: J6 6.0, J3 6.2.
  7. Move 41: escape in 1, answer E1, grade 26. Better than: J6 7.3, J3 7.6.
  8. Move 43: capture in 3, answer C2, grade 50. Better than: J6 7.6, J3 7.6, B1 7.6.
  9. Move 45: escape in 1, answer B1, grade 40. Better than: J6 7.6, C3 7.5, J3 7.5.
  10. Move 51: capture in 2, answer J7, grade 40. Better than: J5 19.4, J3 13.2, A2 15.2.
  11. Move 53: escape in 1, answer J5, grade 40. Better than: J8 18.0, J3 16.0, A2 18.1.
  12. Move 61: capture in 1, answer A1, grade 22. Better than: J3 13.9.

story-1395: 72 moves. Main line: area score Blue 46, Red 41 (Blue wins by 5). Estimate before the end: Blue by 7.9. Grade 34. Rank score 95.
  1. Move 25: capture in 3, answer D6, grade 42. Better than: E7 12.0.
  2. Move 31: capture in 3, answer B8, grade 46. Better than: C9 8.7, E7 8.1.
  3. Move 35: capture in 1, answer C9, grade 22. Better than: E7 7.0.
  4. Move 39: capture in 1, answer A7, grade 26. Better than: E9 10.0, E7 10.9.
  5. Move 41: escape in 2, answer H5, grade 40. Better than: E9 11.8, E7 12.1, J4 12.4.
  6. Move 43: capture in 1, answer G6, grade 26. Better than: E9 15.5, E7 15.7.
  7. Move 49: capture in 2, answer B5, grade 40. Better than: E9 8.2, E7 8.6, A6 7.5.
  8. Move 51: escape in 1, answer A2, grade 30. Better than: E9 11.3, E7 11.2, A6 9.5.

story-3200: 75 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 34. Rank score 95.
  1. Move 21: capture in 3, answer B8, grade 42. Better than: A7 7.2.
  2. Move 29: capture in 3, answer B3, grade 46. Better than: A5 30.9, A4 31.5.
  3. Move 47: capture in 3, answer A4, grade 52. Better than: A3 36.3.
  4. Move 51: capture in 2, answer H8, grade 32. Better than: G9 24.0.
  5. Move 53: escape in 1, answer G6, grade 22. Better than: G9 7.1.
  6. Move 55: capture in 1, answer G9, grade 22. Better than: H7 13.1.
  7. Move 57: capture in 1, answer J9, grade 22. Better than: H7 14.0.
  8. Move 71: escape in 1, answer J7, grade 32. Better than: G8 36.0.

story-361: 73 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 34. Rank score 90.
  1. Move 15: capture in 3, answer D8, grade 42. Better than: C9 5.9.
  2. Move 21: escape in 1, answer F7, grade 22. Better than: C9 11.0.
  3. Move 23: capture in 3, answer G8, grade 46. Better than: C9 10.2, F9 6.5.
  4. Move 27: capture in 1, answer F9, grade 22. Better than: C9 12.1.
  5. Move 45: capture in 3, answer F8, grade 60. Better than: C9 11.1, D7 10.3, D6 10.2.
  6. Move 51: capture in 1, answer J1, grade 22. Better than: C9 5.2.
  7. Move 57: capture in 2, answer C9, grade 32. Better than: E9 33.8.
  8. Move 61: capture in 1, answer J3, grade 22. Better than: E9 6.2.

story-2212: 98 moves. Main line: area score Blue 44, Red 43 (Blue wins by 1). Estimate before the end: Blue by 4.1. Grade 34. Rank score 90.
  1. Move 31: escape in 2, answer F5, grade 32. Better than: E3 10.1.
  2. Move 41: capture in 2, answer A7, grade 32. Better than: A9 17.9.
  3. Move 43: capture in 3, answer D9, grade 50. Better than: A9 8.0, B9 18.9, C8 19.7.
  4. Move 47: capture in 2, answer C8, grade 32. Better than: B9 20.5.
  5. Move 49: escape in 1, answer H6, grade 22. Better than: B9 21.5.
  6. Move 57: capture in 1, answer H5, grade 22. Better than: B9 36.7.
  7. Move 73: capture in 3, answer J6, grade 52. Better than: B9 8.2.
  8. Move 81: capture in 2, answer J8, grade 36. Better than: B9 39.5, A5 36.9.
  9. Move 83: capture in 1, answer H9, grade 30. Better than: B9 38.3, A5 35.2, A1 36.8.

story-2961: 73 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 34. Rank score 75.
  1. Move 29: capture in 3, answer H4, grade 42. Better than: J5 24.5.
  2. Move 33: capture in 3, answer J5, grade 56. Better than: G8 32.7, J7 46.3.
  3. Move 43: capture in 1, answer J7, grade 22. Better than: D1 21.3.
  4. Move 51: escape in 1, answer D1, grade 32. Better than: A4 41.8.
  5. Move 53: capture in 3, answer A3, grade 42. Better than: B2 28.9.
  6. Move 57: capture in 1, answer J1, grade 22. Better than: B2 35.0.
  7. Move 61: capture in 1, answer E1, grade 22. Better than: B2 11.6.
  8. Move 63: escape in 1, answer B2, grade 32. Better than: A4 89.6.

story-301: 77 moves. Main line: area score Blue 45, Red 41 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 34. Rank score 60.
  1. Move 39: capture in 1, answer J6, grade 22. Better than: D3 12.5.
  2. Move 43: capture in 1, answer B4, grade 22. Better than: D3 10.6.
  3. Move 53: escape in 2, answer D6, grade 46. Better than: A9 11.8, D8 11.8.
  4. Move 57: escape in 2, answer B6, grade 46. Better than: A9 12.7, D8 12.6.
  5. Move 69: escape in 1, answer G1, grade 32. Better than: G3 9.2.

story-1570: 79 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 34. Rank score 60.
  1. Move 19: capture in 3, answer G2, grade 42. Better than: F1 6.2.
  2. Move 29: capture in 3, answer F8, grade 46. Better than: E9 24.9, F1 23.7.
  3. Move 33: capture in 1, answer E9, grade 22. Better than: F1 25.6.
  4. Move 43: capture in 1, answer G9, grade 22. Better than: F1 22.5.
  5. Move 45: capture in 2, answer H8, grade 36. Better than: J9 15.9, F1 11.3.

story-1476: 75 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 34. Rank score 55.
  1. Move 17: capture in 3, answer F8, grade 42. Better than: E7 10.6.
  2. Move 41: capture in 2, answer D8, grade 44. Better than: C9 23.5, E7 17.9, C3 36.6, A1 41.0.
  3. Move 43: escape in 1, answer D9, grade 40. Better than: E7 9.0, C3 8.7, A1 9.7.
  4. Move 51: capture in 1, answer E7, grade 22. Better than: C3 9.5.
  5. Move 53: capture in 2, answer G3, grade 36. Better than: C3 14.9, F2 10.7.
  6. Move 69: escape in 1, answer G9, grade 22. Better than: F2 5.7.

story-1771: 72 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 34. Rank score 45.
  1. Move 43: capture in 1, answer D1, grade 22. Better than: H9 22.1.
  2. Move 57: capture in 3, answer J5, grade 60. Better than: B5 28.5, G2 29.0, H1 29.3.
  3. Move 61: capture in 1, answer A6, grade 22. Better than: G2 8.1.
  4. Move 63: capture in 2, answer G2, grade 32. Better than: J1 17.4.

story-1505: 73 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 34. Rank score 35.
  1. Move 17: capture in 3, answer B3, grade 46. Better than: A5 11.8, A4 18.8.
  2. Move 29: capture in 2, answer F5, grade 32. Better than: E4 9.4.
  3. Move 39: capture in 2, answer F1, grade 32. Better than: E4 9.1.
  4. Move 47: capture in 2, answer B8, grade 36. Better than: A9 6.2, E4 6.3.
  5. Move 51: capture in 1, answer E3, grade 22. Better than: C9 16.4.

story-570: 71 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 34. Rank score 25.
  1. Move 29: capture in 3, answer H6, grade 42. Better than: J5 20.4.
  2. Move 33: capture in 3, answer J5, grade 42. Better than: J3 45.7.
  3. Move 55: capture in 3, answer A7, grade 42. Better than: B8 29.6.
  4. Move 59: capture in 1, answer E9, grade 22. Better than: B8 31.5.
  5. Move 61: capture in 1, answer J9, grade 22. Better than: B8 29.5.

story-3193: 85 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 35. Rank score 105.
  1. Move 29: capture in 3, answer H6, grade 46. Better than: A7 7.4, J5 5.9.
  2. Move 37: capture in 3, answer D8, grade 42. Better than: C9 36.3.
  3. Move 39: capture in 2, answer C9, grade 32. Better than: A9 35.2.
  4. Move 45: capture in 3, answer H2, grade 46. Better than: A6 29.3, G1 12.3.
  5. Move 51: capture in 1, answer A6, grade 22. Better than: G1 24.4.
  6. Move 61: capture in 2, answer A3, grade 32. Better than: A1 13.5.
  7. Move 63: escape in 1, answer A1, grade 32. Better than: C2 6.7.
  8. Move 65: escape in 1, answer C1, grade 32. Better than: A2 8.1.
  9. Move 71: escape in 2, answer D1, grade 32. Better than: B1 11.5.
  10. Move 81: escape in 1, answer A7, grade 32. Better than: B9 19.4.

story-1079: 61 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 35. Rank score 85.
  1. Move 29: capture in 3, answer H2, grade 42. Better than: J3 51.1.
  2. Move 31: escape in 1, answer E4, grade 22. Better than: J3 37.4.
  3. Move 33: capture in 3, answer D2, grade 50. Better than: J3 27.5, E1 9.9, F1 10.2.
  4. Move 35: capture in 3, answer B2, grade 46. Better than: J3 12.2, C1 7.8.
  5. Move 37: capture in 2, answer C1, grade 36. Better than: J3 13.6, A1 13.7.
  6. Move 41: capture in 1, answer A3, grade 22. Better than: J3 8.7.
  7. Move 45: capture in 1, answer J8, grade 22. Better than: J3 9.4.
  8. Move 53: capture in 2, answer E1, grade 36. Better than: J3 44.2, F1 42.2.

story-2942: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.7. Grade 35. Rank score 80.
  1. Move 21: capture in 3, answer D8, grade 42. Better than: E7 9.4.
  2. Move 23: escape in 1, answer B4, grade 22. Better than: E7 19.9.
  3. Move 35: capture in 3, answer D1, grade 42. Better than: E7 24.2.
  4. Move 37: escape in 1, answer C2, grade 36. Better than: E7 24.4, A3 25.1.
  5. Move 39: capture in 1, answer E7, grade 22. Better than: B1 20.7.
  6. Move 49: capture in 3, answer J2, grade 50. Better than: E9 10.8, B1 12.4, H1 8.3.
  7. Move 51: escape in 1, answer H1, grade 40. Better than: E9 10.1, J3 11.5, B1 12.1.
  8. Move 55: capture in 1, answer E9, grade 22. Better than: B1 13.1.

story-1864: 67 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 35. Rank score 75.
  1. Move 27: capture in 3, answer H7, grade 42. Better than: J6 7.7.
  2. Move 37: escape in 1, answer F9, grade 32. Better than: J9 19.9.
  3. Move 41: capture in 2, answer J8, grade 32. Better than: J6 12.8.
  4. Move 43: escape in 2, answer J6, grade 46. Better than: G9 17.3, J9 13.2.
  5. Move 51: capture in 1, answer F4, grade 22. Better than: E1 8.4.

story-2549: 77 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 35. Rank score 70.
  1. Move 17: capture in 3, answer H4, grade 42. Better than: G5 10.5.
  2. Move 41: capture in 1, answer G5, grade 22. Better than: A7 15.9.
  3. Move 43: capture in 2, answer B3, grade 36. Better than: A7 8.2, C4 9.4.
  4. Move 45: capture in 1, answer A7, grade 22. Better than: C4 7.3.
  5. Move 47: escape in 1, answer C4, grade 32. Better than: B1 11.5.
  6. Move 49: capture in 3, answer C3, grade 56. Better than: A2 6.6, A1 8.9.
  7. Move 63: escape in 1, answer H1, grade 32. Better than: J3 26.0.

story-319: 70 moves. Main line: area score Blue 45, Red 41 (Blue wins by 4). Estimate before the end: Blue by 9.8. Grade 35. Rank score 65.
  1. Move 29: capture in 3, answer B7, grade 46. Better than: A6 10.0, D5 18.6.
  2. Move 33: capture in 3, answer B2, grade 50. Better than: A6 16.3, D5 18.8, A3 15.5.
  3. Move 37: capture in 1, answer A3, grade 26. Better than: D5 26.8, A4 24.3.
  4. Move 41: capture in 1, answer J5, grade 26. Better than: D5 24.8, A4 22.9.
  5. Move 53: capture in 1, answer D2, grade 26. Better than: D5 27.9, A4 27.1.
  6. Move 57: capture in 2, answer E3, grade 36. Better than: D5 30.4, A4 30.7.

story-3215: 58 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 35. Rank score 65.
  1. Move 19: capture in 3, answer G2, grade 42. Better than: F1 17.4.
  2. Move 27: escape in 1, answer J5, grade 22. Better than: G3 5.7.
  3. Move 29: capture in 3, answer H7, grade 46. Better than: J8 7.8, G3 8.9.
  4. Move 31: capture in 1, answer H3, grade 22. Better than: J8 20.9.
  5. Move 37: escape in 2, answer C4, grade 36. Better than: J8 9.4, D5 8.1.
  6. Move 49: capture in 3, answer B2, grade 42. Better than: C1 28.4.

story-953: 93 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 35. Rank score 60.
  1. Move 25: capture in 3, answer B5, grade 46. Better than: E9 8.3, A6 6.9.
  2. Move 37: capture in 3, answer C2, grade 42. Better than: D1 23.9.
  3. Move 63: capture in 1, answer F2, grade 22. Better than: E9 7.8.
  4. Move 77: escape in 1, answer B7, grade 32. Better than: A5 11.6.
  5. Move 89: capture in 2, answer J2, grade 32. Better than: G3 31.8.

story-1601: 95 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 35. Rank score 60.
  1. Move 25: capture in 3, answer B5, grade 46. Better than: E9 8.3, A6 6.8.
  2. Move 37: capture in 3, answer C2, grade 42. Better than: D1 25.0.
  3. Move 63: capture in 1, answer F2, grade 22. Better than: E9 7.8.
  4. Move 77: escape in 1, answer B7, grade 32. Better than: A5 11.6.
  5. Move 91: capture in 2, answer J2, grade 32. Better than: G3 31.8.

story-2378: 68 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 35. Rank score 60.
  1. Move 39: escape in 1, answer G4, grade 22. Better than: A5 34.1.
  2. Move 45: escape in 1, answer G6, grade 22. Better than: A5 28.5.
  3. Move 47: escape in 3, answer D9, grade 64. Better than: E9 37.9, G9 37.9, F8 32.9, A5 40.3.
  4. Move 57: capture in 2, answer J7, grade 36. Better than: J9 57.7, A5 40.1.
  5. Move 59: escape in 1, answer J9, grade 32. Better than: A5 42.0.

story-108: 82 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 35. Rank score 50.
  1. Move 15: capture in 3, answer B3, grade 42. Better than: A4 8.0.
  2. Move 27: capture in 3, answer F2, grade 46. Better than: A4 13.5, G1 11.3.
  3. Move 37: capture in 2, answer J1, grade 36. Better than: A4 5.4, J3 7.4.
  4. Move 47: capture in 2, answer A3, grade 36. Better than: A5 18.6, J3 15.7.
  5. Move 53: capture in 1, answer J4, grade 22. Better than: A5 12.9.
  6. Move 59: capture in 1, answer A5, grade 26. Better than: C9 11.0, F6 12.6.

story-2026: 72 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.0. Grade 35. Rank score 45.
  1. Move 11: capture in 3, answer F8, grade 42. Better than: E9 6.9.
  2. Move 43: escape in 1, answer A6, grade 32. Better than: A9 11.0.
  3. Move 45: capture in 3, answer C8, grade 42. Better than: B9 9.2.
  4. Move 61: capture in 2, answer C3, grade 36. Better than: A6 39.4, E2 40.8.
  5. Move 63: escape in 1, answer E1, grade 22. Better than: A6 40.0.

story-3012: 69 moves. Main line: area score Blue 47, Red 39 (Blue wins by 8). Estimate before the end: Blue by 4.0. Grade 35. Rank score 35.
  1. Move 25: capture in 3, answer E8, grade 46. Better than: F9 7.1, J5 8.0.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.7.
  3. Move 47: capture in 3, answer A8, grade 42. Better than: B9 10.2.
  4. Move 51: capture in 1, answer C1, grade 22. Better than: B9 6.8.
  5. Move 55: escape in 1, answer F8, grade 22. Better than: B9 9.7.

story-285: 80 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 36. Rank score 150.
  1. Move 11: escape in 1, answer E4, grade 32. Better than: C5 5.3.
  2. Move 29: escape in 3, answer H7, grade 46. Better than: J9 60.0, J7 62.7.
  3. Move 39: capture in 3, answer D1, grade 46. Better than: C2 23.6, B1 9.0.
  4. Move 43: capture in 3, answer F7, grade 42. Better than: G9 58.0.
  5. Move 47: escape in 3, answer H2, grade 50. Better than: G9 24.6, G1 24.3, J1 26.7.
  6. Move 49: capture in 2, answer A3, grade 32. Better than: G9 10.0.
  7. Move 51: capture in 2, answer A1, grade 32. Better than: G9 11.3.
  8. Move 53: escape in 2, answer C2, grade 32. Better than: A2 43.3.
  9. Move 55: capture in 3, answer G3, grade 46. Better than: F3 47.5, G1 41.9.
  10. Move 57: capture in 1, answer J6, grade 22. Better than: J3 11.0.
  11. Move 67: capture in 1, answer C1, grade 22. Better than: J3 26.9.
  12. Move 73: capture in 1, answer H5, grade 30. Better than: D5 10.8, F3 8.0, J3 8.0.

story-2505: 81 moves. Main line: area score Blue 42, Red 41 (Blue wins by 1). Estimate before the end: Blue by 8.0. Grade 36. Rank score 120.
  1. Move 17: capture in 3, answer D8, grade 42. Better than: E7 10.6.
  2. Move 33: escape in 1, answer E1, grade 22. Better than: E7 7.3.
  3. Move 35: capture in 3, answer G2, grade 46. Better than: E7 5.1, H1 6.8.
  4. Move 45: escape in 2, answer G1, grade 32. Better than: J1 20.0.
  5. Move 47: capture in 3, answer E6, grade 42. Better than: E8 8.5.
  6. Move 55: capture in 1, answer E8, grade 22. Better than: J9 39.2.
  7. Move 59: capture in 2, answer C2, grade 32. Better than: D3 15.2.
  8. Move 61: escape in 1, answer D3, grade 32. Better than: A2 12.1.
  9. Move 63: capture in 3, answer C3, grade 56. Better than: A1 10.0, B1 8.1.

story-2527: 81 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 36. Rank score 100.
  1. Move 21: capture in 3, answer H6, grade 42. Better than: J5 11.0.
  2. Move 23: capture in 3, answer B5, grade 50. Better than: J5 21.9, A4 24.5, A3 21.0.
  3. Move 33: capture in 1, answer F4, grade 26. Better than: J5 6.0, A4 6.3.
  4. Move 35: capture in 1, answer A4, grade 22. Better than: J5 26.9.
  5. Move 45: escape in 1, answer F1, grade 22. Better than: J5 9.6.
  6. Move 47: capture in 1, answer C1, grade 22. Better than: J5 13.4.
  7. Move 55: escape in 2, answer F6, grade 36. Better than: E5 7.5, J5 7.4.
  8. Move 57: capture in 3, answer D1, grade 64. Better than: E5 9.6, J5 12.0, H2 9.2, H1 9.7.

story-1876: 81 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 36. Rank score 95.
  1. Move 35: capture in 1, answer A5, grade 22. Better than: F9 10.5.
  2. Move 41: capture in 3, answer F2, grade 42. Better than: E1 16.7.
  3. Move 53: capture in 2, answer E5, grade 32. Better than: B2 32.5.
  4. Move 57: capture in 1, answer B2, grade 22. Better than: C7 62.9.
  5. Move 67: capture in 3, answer H2, grade 46. Better than: F1 14.6, H1 14.6.
  6. Move 69: capture in 2, answer J3, grade 32. Better than: J1 17.0.
  7. Move 71: capture in 3, answer J1, grade 56. Better than: F1 19.4, H1 20.0.
  8. Move 75: capture in 2, answer F1, grade 32. Better than: H1 19.7.

story-1568: 72 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 36. Rank score 65.
  1. Move 15: capture in 3, answer C2, grade 42. Better than: D1 13.2.
  2. Move 29: capture in 1, answer D1, grade 22. Better than: C7 9.3.
  3. Move 35: capture in 1, answer D9, grade 22. Better than: C7 12.0.
  4. Move 51: escape in 3, answer H8, grade 46. Better than: J6 52.6, H5 44.6.
  5. Move 59: capture in 3, answer A6, grade 42. Better than: A8 9.1.
  6. Move 61: capture in 3, answer B7, grade 42. Better than: A8 40.1.
  7. Move 63: escape in 1, answer A8, grade 36. Better than: A9 36.4, G1 30.0.

story-3231: 55 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.3. Grade 36. Rank score 60.
  1. Move 35: escape in 3, answer B8, grade 46. Better than: A9 37.2, C9 19.1.
  2. Move 37: capture in 2, answer A6, grade 32. Better than: A8 17.5.
  3. Move 41: capture in 3, answer B2, grade 46. Better than: A8 19.5, C1 17.1.
  4. Move 43: escape in 1, answer C1, grade 36. Better than: A8 10.2, D1 12.4.
  5. Move 47: capture in 1, answer A9, grade 22. Better than: J6 6.3.

story-1699: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 36. Rank score 55.
  1. Move 17: capture in 3, answer B4, grade 42. Better than: A3 7.5.
  2. Move 19: escape in 1, answer A3, grade 32. Better than: D2 26.9.
  3. Move 21: capture in 3, answer D2, grade 42. Better than: C1 11.4.
  4. Move 23: capture in 3, answer C1, grade 42. Better than: E1 29.0.
  5. Move 25: escape in 1, answer F5, grade 22. Better than: E1 18.7.

story-1483: 71 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.9. Grade 36. Rank score 50.
  1. Move 17: capture in 3, answer F8, grade 42. Better than: E7 10.6.
  2. Move 41: capture in 2, answer D8, grade 44. Better than: C9 23.4, E7 17.7, C3 36.4, A1 40.8.
  3. Move 43: escape in 1, answer D9, grade 40. Better than: E7 9.0, C3 8.7, A1 9.7.
  4. Move 53: capture in 1, answer E7, grade 22. Better than: C3 9.5.
  5. Move 65: escape in 1, answer F9, grade 32. Better than: J8 5.5.

story-2198: 64 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 6.1. Grade 36. Rank score 50.
  1. Move 41: escape in 1, answer J4, grade 32. Better than: J1 8.0.
  2. Move 45: capture in 3, answer A7, grade 46. Better than: A9 29.0, B8 27.0.
  3. Move 49: capture in 2, answer B9, grade 32. Better than: A9 32.7.
  4. Move 51: escape in 2, answer A9, grade 32. Better than: C9 38.5.

story-1545: 61 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 36. Rank score 35.
  1. Move 21: capture in 3, answer B7, grade 42. Better than: A6 11.0.
  2. Move 23: capture in 3, answer C2, grade 46. Better than: A6 15.4, D1 12.7.
  3. Move 25: capture in 1, answer A6, grade 22. Better than: D1 10.9.
  4. Move 35: escape in 1, answer F9, grade 32. Better than: J9 13.3.

story-2807: 73 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 1.9. Grade 36. Rank score 35.
  1. Move 25: capture in 3, answer C8, grade 46. Better than: B9 16.4, G3 18.0.
  2. Move 43: escape in 2, answer G2, grade 32. Better than: H1 7.8.
  3. Move 61: capture in 2, answer A7, grade 32. Better than: A5 36.1.
  4. Move 63: escape in 2, answer B5, grade 32. Better than: B8 36.1.

story-3256: 69 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.7. Grade 36. Rank score 30.
  1. Move 11: capture in 3, answer F8, grade 42. Better than: E9 12.8.
  2. Move 17: escape in 1, answer E4, grade 22. Better than: E9 14.9.
  3. Move 35: capture in 3, answer B5, grade 46. Better than: A4 9.0, F2 9.3.
  4. Move 53: escape in 1, answer J1, grade 32. Better than: J4 6.1.

story-788: 71 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.8. Grade 36. Rank score 20.
  1. Move 29: capture in 3, answer B6, grade 42. Better than: A5 21.2.
  2. Move 33: capture in 3, answer A5, grade 42. Better than: A3 42.0.
  3. Move 37: capture in 2, answer A3, grade 32. Better than: C2 30.5.
  4. Move 51: capture in 1, answer J4, grade 26. Better than: G9 46.9, C2 46.0.

story-1511: 67 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 36. Rank score 20.
  1. Move 29: capture in 3, answer B6, grade 42. Better than: A5 20.5.
  2. Move 33: capture in 3, answer A5, grade 42. Better than: A3 42.0.
  3. Move 37: capture in 2, answer A3, grade 32. Better than: C2 30.5.
  4. Move 51: capture in 1, answer J4, grade 26. Better than: G9 46.8, C2 45.9.

story-2670: 67 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 36. Rank score 20.
  1. Move 29: capture in 3, answer B6, grade 42. Better than: A5 20.4.
  2. Move 33: capture in 3, answer A5, grade 42. Better than: A3 42.0.
  3. Move 37: capture in 2, answer A3, grade 32. Better than: C2 30.6.
  4. Move 51: capture in 1, answer J4, grade 26. Better than: G9 46.9, C2 46.1.

story-3095: 77 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 37. Rank score 135.
  1. Move 17: capture in 3, answer B4, grade 42. Better than: C5 10.4.
  2. Move 31: escape in 1, answer J5, grade 22. Better than: C5 7.2.
  3. Move 33: capture in 3, answer H7, grade 46. Better than: J8 9.1, C5 7.4.
  4. Move 35: escape in 1, answer J8, grade 36. Better than: G7 9.4, C5 7.6.
  5. Move 39: escape in 2, answer J7, grade 32. Better than: J9 21.6.
  6. Move 41: capture in 3, answer D5, grade 42. Better than: B5 12.1.
  7. Move 51: capture in 2, answer H3, grade 36. Better than: B5 15.4, G4 15.5.
  8. Move 53: capture in 1, answer B5, grade 22. Better than: G4 50.7.
  9. Move 55: escape in 1, answer G4, grade 32. Better than: H1 12.6.
  10. Move 57: capture in 3, answer G3, grade 56. Better than: J2 7.7, J1 10.1.

story-1957: 80 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 37. Rank score 85.
  1. Move 33: capture in 3, answer H9, grade 46. Better than: J8 32.6, F5 13.2.
  2. Move 39: capture in 1, answer F5, grade 22. Better than: J8 13.8.
  3. Move 41: capture in 2, answer J7, grade 32. Better than: J9 18.0.
  4. Move 45: escape in 2, answer J9, grade 32. Better than: G9 40.5.
  5. Move 47: escape in 1, answer J8, grade 32. Better than: G9 85.8.
  6. Move 57: escape in 2, answer J4, grade 46. Better than: E1 8.7, F1 48.3.
  7. Move 61: escape in 2, answer A7, grade 46. Better than: A9 89.8, C9 88.0.

story-2022: 71 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 37. Rank score 75.
  1. Move 15: capture in 3, answer H6, grade 42. Better than: J7 5.9.
  2. Move 21: escape in 1, answer G4, grade 22. Better than: J7 11.0.
  3. Move 23: capture in 3, answer H3, grade 46. Better than: J7 10.3, J4 6.5.
  4. Move 27: capture in 1, answer J4, grade 22. Better than: J7 10.6.
  5. Move 45: capture in 3, answer H4, grade 60. Better than: J7 11.1, F6 10.2, G6 10.3.
  6. Move 57: capture in 2, answer J7, grade 32. Better than: J5 34.6.

story-2471: 56 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 4.1. Grade 37. Rank score 75.
  1. Move 13: capture in 3, answer D8, grade 42. Better than: C9 8.0.
  2. Move 25: escape in 1, answer G7, grade 22. Better than: C9 20.0.
  3. Move 27: capture in 3, answer H8, grade 46. Better than: C9 19.7, J7 13.9.
  4. Move 35: capture in 3, answer B2, grade 46. Better than: C9 16.6, C1 10.1.
  5. Move 39: capture in 1, answer C1, grade 22. Better than: C9 6.8.
  6. Move 45: escape in 3, answer J9, grade 46. Better than: G9 20.2, H7 22.1.

story-1850: 71 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 37. Rank score 50.
  1. Move 25: capture in 3, answer H2, grade 42. Better than: J3 15.8.
  2. Move 43: escape in 1, answer D9, grade 22. Better than: J3 10.5.
  3. Move 55: capture in 2, answer J3, grade 32. Better than: J1 64.4.
  4. Move 65: escape in 3, answer G6, grade 50. Better than: A3 32.5, C3 32.4, J1 31.5.

story-2698: 89 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 37. Rank score 45.
  1. Move 39: escape in 1, answer A9, grade 32. Better than: B9 16.7.
  2. Move 53: escape in 1, answer F8, grade 32. Better than: H9 71.0.
  3. Move 67: escape in 1, answer A4, grade 32. Better than: A1 83.5.
  4. Move 71: capture in 3, answer B1, grade 50. Better than: E4 18.3, H4 17.2, C1 18.0.

story-814: 72 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 37. Rank score 35.
  1. Move 23: capture in 3, answer B2, grade 42. Better than: C1 9.1.
  2. Move 35: capture in 1, answer F3, grade 22. Better than: C5 7.0.
  3. Move 47: capture in 3, answer B5, grade 56. Better than: B7 29.0, B6 30.4.
  4. Move 49: escape in 1, answer J2, grade 32. Better than: J1 11.1.
  5. Move 53: capture in 2, answer F8, grade 32. Better than: E9 13.0.

story-3158: 77 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 7.8. Grade 37. Rank score 35.
  1. Move 21: capture in 3, answer B5, grade 42. Better than: A6 6.1.
  2. Move 23: escape in 1, answer E5, grade 22. Better than: A6 6.3.
  3. Move 45: capture in 2, answer H8, grade 32. Better than: J9 35.9.
  4. Move 65: capture in 3, answer C9, grade 46. Better than: A9 12.1, B8 9.3.
  5. Move 69: capture in 3, answer H2, grade 42. Better than: J5 66.9.

story-421: 46 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 37. Rank score 30.
  1. Move 23: capture in 3, answer B8, grade 42. Better than: A7 34.6.
  2. Move 27: capture in 3, answer E2, grade 46. Better than: A7 43.8, F1 28.7.
  3. Move 29: escape in 1, answer F1, grade 36. Better than: A7 45.7, G4 46.9.
  4. Move 33: escape in 1, answer D3, grade 22. Better than: A7 36.1.

story-2472: 57 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 37. Rank score 20.
  1. Move 19: capture in 3, answer H7, grade 42. Better than: J6 8.3.
  2. Move 27: capture in 3, answer D2, grade 42. Better than: C1 15.1.
  3. Move 29: capture in 2, answer C1, grade 32. Better than: A1 13.7.
  4. Move 37: capture in 2, answer A1, grade 32. Better than: A3 13.5.

story-330: 73 moves. Main line: area score Blue 47, Red 41 (Blue wins by 6). Estimate before the end: Blue by 5.9. Grade 38. Rank score 120.
  1. Move 17: capture in 3, answer F8, grade 42. Better than: E7 10.6.
  2. Move 31: escape in 1, answer E1, grade 22. Better than: E7 7.1.
  3. Move 33: capture in 3, answer C2, grade 46. Better than: E7 7.1, B1 8.8.
  4. Move 35: escape in 1, answer B1, grade 36. Better than: E7 7.3, C3 8.1.
  5. Move 39: escape in 2, answer C1, grade 32. Better than: A1 18.4.
  6. Move 41: capture in 3, answer E6, grade 42. Better than: E8 10.1.
  7. Move 55: capture in 2, answer G2, grade 32. Better than: F3 14.3.
  8. Move 57: escape in 1, answer F3, grade 32. Better than: J2 11.2.
  9. Move 59: capture in 3, answer G3, grade 56. Better than: H1 7.8, J1 9.6.

story-1216: 63 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 38. Rank score 70.
  1. Move 15: capture in 3, answer B6, grade 42. Better than: A7 5.9.
  2. Move 21: escape in 1, answer C4, grade 22. Better than: A7 10.6.
  3. Move 23: capture in 3, answer B3, grade 46. Better than: A7 10.5, A4 7.0.
  4. Move 27: capture in 1, answer A4, grade 22. Better than: A7 10.5.
  5. Move 45: capture in 3, answer B4, grade 60. Better than: A7 11.1, C6 10.2, D6 10.2.

story-1402: 63 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 38. Rank score 70.
  1. Move 15: capture in 3, answer B6, grade 42. Better than: A7 5.9.
  2. Move 21: escape in 1, answer C4, grade 22. Better than: A7 10.6.
  3. Move 23: capture in 3, answer B3, grade 46. Better than: A7 10.5, A4 7.0.
  4. Move 27: capture in 1, answer A4, grade 22. Better than: A7 10.6.
  5. Move 45: capture in 3, answer B4, grade 60. Better than: A7 11.1, C6 10.2, D6 10.2.

story-1612: 63 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.1. Grade 38. Rank score 70.
  1. Move 15: capture in 3, answer F8, grade 42. Better than: G9 5.9.
  2. Move 21: escape in 1, answer D7, grade 22. Better than: G9 11.1.
  3. Move 23: capture in 3, answer C8, grade 46. Better than: D9 6.7, G9 10.2.
  4. Move 27: capture in 1, answer D9, grade 22. Better than: G9 11.8.
  5. Move 47: capture in 3, answer D8, grade 60. Better than: G9 14.9, F7 13.9, F6 14.1.

story-1088: 64 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.0. Grade 38. Rank score 45.
  1. Move 31: capture in 3, answer G3, grade 42. Better than: J3 11.4.
  2. Move 37: capture in 3, answer F9, grade 50. Better than: A9 15.5, E8 7.8, J3 22.9.
  3. Move 41: capture in 1, answer E8, grade 26. Better than: A9 27.8, J3 26.4.
  4. Move 55: capture in 2, answer J4, grade 32. Better than: J1 21.7.

story-1777: 75 moves. Main line: area score Blue 45, Red 43 (Blue wins by 2). Estimate before the end: Blue by 2.0. Grade 38. Rank score 45.
  1. Move 39: capture in 3, answer H7, grade 42. Better than: J6 19.5.
  2. Move 43: capture in 1, answer J1, grade 22. Better than: J6 7.7.
  3. Move 47: escape in 3, answer C1, grade 56. Better than: J2 26.0, H1 25.8.
  4. Move 49: capture in 2, answer J7, grade 32. Better than: J5 16.8.

story-1758: 101 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 7.8. Grade 38. Rank score 25.
  1. Move 11: capture in 3, answer F8, grade 42. Better than: E9 7.1.
  2. Move 27: capture in 3, answer C2, grade 42. Better than: D1 14.0.
  3. Move 63: capture in 2, answer A6, grade 32. Better than: B5 8.7.
  4. Move 69: escape in 1, answer B7, grade 36. Better than: A9 19.4, G6 8.4.

story-854: 81 moves. Main line: area score Blue 46, Red 40 (Blue wins by 6). Estimate before the end: Blue by 6.0. Grade 39. Rank score 50.
  1. Move 29: capture in 3, answer H5, grade 42. Better than: J4 21.6.
  2. Move 41: capture in 3, answer G2, grade 42. Better than: H1 20.0.
  3. Move 45: capture in 3, answer B7, grade 46. Better than: A6 31.6, H1 33.9.
  4. Move 51: capture in 2, answer G1, grade 32. Better than: J1 26.8.
  5. Move 59: escape in 1, answer J1, grade 32. Better than: F2 46.2.

story-2820: 76 moves. Main line: area score Blue 45, Red 42 (Blue wins by 3). Estimate before the end: Blue by 3.1. Grade 39. Rank score 45.
  1. Move 25: capture in 3, answer B5, grade 46. Better than: E9 8.3, A6 6.9.
  2. Move 37: capture in 3, answer C2, grade 42. Better than: D1 11.1.
  3. Move 43: capture in 3, answer H9, grade 42. Better than: J8 71.0.
  4. Move 47: capture in 2, answer J7, grade 32. Better than: J9 40.7.
  5. Move 71: escape in 2, answer H8, grade 32. Better than: H6 47.3.

story-722: 77 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 39. Rank score 40.
  1. Move 25: capture in 3, answer E8, grade 46. Better than: F9 7.2, J5 8.1.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.7.
  3. Move 57: escape in 1, answer J4, grade 22. Better than: E1 39.3.
  4. Move 71: capture in 3, answer C2, grade 42. Better than: B3 7.9.
  5. Move 73: capture in 3, answer B3, grade 42. Better than: A4 41.8.

story-2115: 77 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 39. Rank score 40.
  1. Move 25: capture in 3, answer E8, grade 46. Better than: F9 7.2, J5 8.0.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.7.
  3. Move 57: escape in 1, answer J4, grade 22. Better than: E1 39.2.
  4. Move 71: capture in 3, answer C2, grade 42. Better than: B3 7.8.
  5. Move 73: capture in 3, answer B3, grade 42. Better than: A4 41.7.

story-2350: 55 moves. Main line: area score Blue 48, Red 40 (Blue wins by 8). Estimate before the end: Blue by 8.1. Grade 39. Rank score 35.
  1. Move 19: capture in 3, answer H2, grade 46. Better than: F8 16.5, G1 10.5.
  2. Move 23: capture in 1, answer G1, grade 22. Better than: F8 7.8.
  3. Move 33: capture in 3, answer D3, grade 56. Better than: D1 12.9, F1 13.0.
  4. Move 43: escape in 2, answer D7, grade 32. Better than: D6 5.7.

story-869: 65 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 10.0. Grade 41. Rank score 80.
  1. Move 15: capture in 3, answer D2, grade 42. Better than: C1 5.8.
  2. Move 21: escape in 1, answer F3, grade 22. Better than: C1 8.4.
  3. Move 37: escape in 2, answer H8, grade 36. Better than: J7 13.0, C1 13.2.
  4. Move 41: capture in 3, answer F7, grade 46. Better than: G9 36.7, C1 36.8.
  5. Move 43: escape in 1, answer G9, grade 36. Better than: F9 36.7, C1 36.6.
  6. Move 51: capture in 3, answer F2, grade 64. Better than: A5 9.8, D4 10.1, D3 9.3, C1 10.1.

story-350: 79 moves. Main line: area score Blue 45, Red 40 (Blue wins by 5). Estimate before the end: Blue by 9.9. Grade 42. Rank score 75.
  1. Move 37: capture in 1, answer D6, grade 22. Better than: B4 50.9.
  2. Move 41: capture in 3, answer C7, grade 46. Better than: A6 8.0, A5 9.6.
  3. Move 55: capture in 3, answer C1, grade 52. Better than: A3 32.5.
  4. Move 57: capture in 3, answer A1, grade 56. Better than: A6 22.2, A5 35.2.
  5. Move 59: escape in 1, answer A5, grade 32. Better than: B1 40.7.

story-2519: 79 moves. Main line: area score Blue 44, Red 42 (Blue wins by 2). Estimate before the end: Blue by 9.9. Grade 45. Rank score 70.
  1. Move 31: capture in 3, answer C6, grade 42. Better than: A6 8.1.
  2. Move 47: capture in 2, answer B2, grade 36. Better than: A1 10.1, E1 20.0.
  3. Move 61: capture in 3, answer C8, grade 46. Better than: D7 41.7, J1 42.0.
  4. Move 63: escape in 1, answer D7, grade 36. Better than: A8 45.9, J1 46.2.
  5. Move 67: capture in 3, answer C7, grade 64. Better than: A9 16.7, B9 19.9, C1 17.0, J1 15.7.

story-2159: 67 moves. Main line: area score Blue 49, Red 39 (Blue wins by 10). Estimate before the end: Blue by 9.9. Grade 45. Rank score 45.
  1. Move 31: capture in 3, answer H3, grade 56. Better than: H5 23.0, H4 20.3.
  2. Move 39: escape in 3, answer D1, grade 64. Better than: H5 15.3, F2 20.1, E1 21.1, G1 20.6.
  3. Move 43: escape in 2, answer E1, grade 36. Better than: H5 20.6, G1 19.5.
  4. Move 47: escape in 1, answer C1, grade 22. Better than: H5 28.7.

story-2849: 79 moves. Main line: area score Blue 46, Red 42 (Blue wins by 4). Estimate before the end: Blue by 3.9. Grade 48. Rank score 20.
  1. Move 25: capture in 3, answer G8, grade 46. Better than: F9 22.6, J5 9.1.
  2. Move 37: capture in 3, answer B7, grade 42. Better than: A6 12.7.
  3. Move 69: capture in 3, answer G4, grade 56. Better than: J2 48.1, J1 48.0.
  4. Move 71: escape in 2, answer J1, grade 46. Better than: H5 48.2, J4 48.1.
```
