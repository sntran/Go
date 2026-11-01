// The board in the browser: the rules (captures, groups, roads) and the
// SVG of a board, the same SVG as GoWeb.BoardComponents.board/1 on the
// server. The hook Anim (anim.mjs) plays the moves of a game with it, so
// the server sends the moves one time and renders nothing for each move.
// test/go_web/board_js_test.exs compares this SVG with the SVG of the
// server for real positions.

const VIEW = 400;
const other = (c) => (c === 'blue' ? 'red' : 'blue');
const key = (r, c) => `${r}-${c}`;

// A board: its size and its stones, as "r-c" => color.
export function newBoard(size, stones) {
  const map = new Map();
  for (const [r, c, color] of stones) map.set(key(r, c), color);
  return { size, stones: map };
}

function neighbors(size, r, c) {
  const out = [];
  if (r > 0) out.push([r - 1, c]);
  if (r < size - 1) out.push([r + 1, c]);
  if (c > 0) out.push([r, c - 1]);
  if (c < size - 1) out.push([r, c + 1]);
  return out;
}

// The group of the stone on (r, c): its stones and its liberties, in the
// order of Go.Board (sorted).
function group(board, r, c) {
  const color = board.stones.get(key(r, c));
  const seen = new Set([key(r, c)]);
  const stones = [];
  const libs = new Set();
  const todo = [[r, c]];
  while (todo.length) {
    const [a, b] = todo.pop();
    stones.push([a, b]);
    for (const [x, y] of neighbors(board.size, a, b)) {
      const k = key(x, y);
      const here = board.stones.get(k);
      if (here === undefined) libs.add(k);
      else if (here === color && !seen.has(k)) {
        seen.add(k);
        todo.push([x, y]);
      }
    }
  }
  const sortPts = (list) => list.sort((p, q) => p[0] - q[0] || p[1] - q[1]);
  return {
    color,
    stones: sortPts(stones),
    liberties: sortPts([...libs].map((k) => k.split('-').map(Number))),
  };
}

// The groups of a color, in the order of Go.Board.groups/2: by the first
// stone of each group, row by row.
export function groups(board, color) {
  const seen = new Set();
  const out = [];
  for (let r = 0; r < board.size; r++) {
    for (let c = 0; c < board.size; c++) {
      const k = key(r, c);
      if (board.stones.get(k) === color && !seen.has(k)) {
        const g = group(board, r, c);
        g.stones.forEach(([a, b]) => seen.add(key(a, b)));
        out.push(g);
      }
    }
  }
  return out;
}

// Plays a move of a game (a legal move: the game was played on the
// server). Gives the new board and the captured stones.
export function play(board, color, move) {
  const stones = new Map(board.stones);
  const next = { size: board.size, stones };
  if (move === 'pass') return { board: next, captured: [] };
  const [r, c] = move;
  stones.set(key(r, c), color);
  const captured = [];
  for (const [x, y] of neighbors(board.size, r, c)) {
    if (stones.get(key(x, y)) === other(color)) {
      const g = group(next, x, y);
      if (g.liberties.length === 0) {
        for (const [a, b] of g.stones) {
          stones.delete(key(a, b));
          captured.push([a, b]);
        }
      }
    }
  }
  return { board: next, captured };
}

// The numbers as the server writes them. Elixir keeps integers and floats
// apart: a float has 1 decimal (:erlang.float_to_binary(v, decimals: 1)),
// and an integer has none. Here f() is for a float, and fi() for an
// integer.
const f = (v) => v.toFixed(1);
const fi = (v) => String(v);
// Elixir max(int, float) and min(float, int) give the integer when it wins.
const maxIF = (i, v) => (i >= v ? fi(i) : f(v));

function piece(castle, x, y, r, color, cls, attrs) {
  if (castle) {
    const s = r * 0.82;
    const body = [-0.72, -0.18, 0.36]
      .map((o) => `<rect x="${f(x + o * s)}" y="${f(y - s * 0.8)}" width="${f(s * 0.36)}" height="${f(s * 0.38)}" class="body"/>`)
      .join('');
    return (
      // phx-r: LiveView puts it on the root tag of each component.
      `<g class="tower tower-${color}${cls ? ' ' + cls : ''}"${attrs} phx-r="">` +
      `<rect x="${f(x - s * 0.72)}" y="${f(y - s * 0.45)}" width="${f(s * 1.44)}" height="${f(s * 1.2)}" rx="2" class="body"/>` +
      body +
      `<path d="M${f(x - s * 0.22)} ${f(y + s * 0.75)}v-${f(s * 0.32)}a${f(s * 0.22)} ${f(s * 0.22)} 0 0 1 ${f(s * 0.44)} 0v${f(s * 0.32)}z" class="door"/>` +
      `<rect x="${f(x - s * 0.09)}" y="${f(y - s * 0.22)}" width="${f(s * 0.18)}" height="${f(s * 0.22)}" class="door"/>` +
      `</g>`
    );
  }
  return `<circle class="stone stone-${color}${cls ? ' ' + cls : ''}" cx="${f(x)}" cy="${f(y)}" r="${f(r * 0.98)}"${attrs} phx-r=""/>`;
}

// The inner SVG of a full board (no view, no window, no fields, no glow,
// no target): what GoWeb.BoardComponents.board/1 draws during a game.
// opts: look ('castle' | 'board'), marks ([[r, c, color]]), falls
// ([[r, c, color]]), step (a number for the ids of the falls).
export function render(board, opts = {}) {
  const n = board.size;
  const pad = n > 5 ? 32 : 44;
  const cs = (VIEW - 2 * pad) / (n - 1);
  // r is the integer 32 on a small board (Elixir min/2 gives it).
  const rInt = cs * 0.42 > 32;
  const r = rInt ? 32 : cs * 0.42;
  const castle = (opts.look || 'castle') === 'castle';
  const X = (k) => pad + k * cs;
  const all = [...groups(board, 'blue'), ...groups(board, 'red')];
  const show = (g) => !opts.hideRoads && (n <= 5 || g.liberties.length <= 3);
  const danger = new Set();
  for (const g of all) if (g.liberties.length === 1) g.stones.forEach(([a, b]) => danger.add(key(a, b)));

  // The roads: each liberty of a group with 3 roads or fewer, with an
  // offset when both colors use the same point.
  const byPoint = new Map();
  for (const g of all.filter(show)) {
    for (const [a, b] of g.liberties) {
      const k = key(a, b);
      if (!byPoint.has(k)) byPoint.set(k, { p: [a, b], colors: [] });
      const e = byPoint.get(k);
      if (!e.colors.includes(g.color)) e.colors.push(g.color);
    }
  }
  const roads = [];
  for (const { p, colors } of byPoint.values()) {
    colors.forEach((c, i) => roads.push([p, c, colors.length > 1 ? (i === 0 ? -6 : 6) : 0]));
  }
  roads.sort((u, v) => u[0][0] - v[0][0] || u[0][1] - v[0][1] || (u[1] < v[1] ? -1 : u[1] > v[1] ? 1 : 0) || u[2] - v[2]);

  const stones = [...board.stones.entries()]
    .map(([k, color]) => [...k.split('-').map(Number), color])
    .sort((p, q) => p[0] - q[0] || p[1] - q[1]);

  const out = [];
  out.push(`<rect x="4" y="4" width="392" height="392" rx="20" class="${castle ? 'ground-grass' : 'ground-wood'}"/>`);
  const lineClass = castle ? 'path' : 'gridline';
  for (let k = 0; k < n; k++)
    out.push(`<line x1="${fi(pad)}" y1="${f(X(k))}" x2="${fi(VIEW - pad)}" y2="${f(X(k))}" class="${lineClass}"/>`);
  for (let k = 0; k < n; k++)
    out.push(`<line x1="${f(X(k))}" y1="${fi(pad)}" x2="${f(X(k))}" y2="${fi(VIEW - pad)}" class="${lineClass}"/>`);

  for (const [[a, b], color, dx] of roads) {
    out.push(
      castle
        ? `<circle class="road road-${color}" data-road="${a}-${b}" cx="${f(X(b) + dx)}" cy="${f(X(a))}" r="${maxIF(6, r * 0.28)}"/>`
        : `<circle class="dot dot-${color}" data-road="${a}-${b}" cx="${f(X(b) + dx)}" cy="${f(X(a))}" r="${maxIF(4, r * 0.18)}"/>`
    );
  }

  if (castle) {
    for (const [a, b, color] of stones) {
      for (const [x, y] of [[a, b + 1], [a + 1, b]]) {
        if (board.stones.get(key(x, y)) === color) {
          out.push(
            `<g class="wall wall-${color}">` +
              `<line x1="${f(X(b))}" y1="${f(X(a))}" x2="${f(X(y))}" y2="${f(X(x))}" style="stroke-width:${f(r * 0.62)}" class="wall-base"/>` +
              `<line x1="${f(X(b))}" y1="${f(X(a))}" x2="${f(X(y))}" y2="${f(X(x))}" style="stroke-width:${f(r * 0.4)}" class="wall-top"/>` +
              `</g>`
          );
        }
      }
    }
  }

  for (const [a, b, color] of stones) {
    const d = danger.has(key(a, b));
    if (d) out.push(`<circle class="alarm" cx="${f(X(b))}" cy="${f(X(a))}" r="${f(r * 1.02)}"/>`);
    out.push(piece(castle, X(b), X(a), r, color, d ? 'danger' : '', ` data-stone="${a}-${b}" data-color="${color}"`));
  }

  for (const [a, b, color] of (opts.marks || []).slice().sort((p, q) => p[0] - q[0] || p[1] - q[1])) {
    if (board.stones.has(key(a, b))) out.push(`<circle class="mark mark-${color}" cx="${f(X(b))}" cy="${f(X(a))}" r="${rInt ? fi(r + 5) : f(r + 5)}"/>`);
  }

  for (const g of all) {
    if (!show(g)) continue;
    const [a, b] = g.stones.reduce((best, p) => (p[0] < best[0] || (p[0] === best[0] && p[1] > best[1]) ? p : best));
    const x = X(b) + r * 0.85;
    const y = X(a) - r * 0.85;
    out.push(
      `<g class="count"><circle cx="${f(x)}" cy="${f(y)}" r="11" class="count-ring count-${g.color}"/>` +
        `<text x="${f(x)}" y="${f(y + 4.5)}" text-anchor="middle">${g.liberties.length}</text></g>`
    );
  }

  for (const [a, b, color] of opts.falls || []) {
    out.push(piece(castle, X(b), X(a), r, color, 'fall', ` id="fall-${opts.step || 0}-${a}-${b}"`));
  }

  return out.join('');
}
