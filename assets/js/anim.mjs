// The hook Anim: plays the moves of a stage on the board, in the browser.
// The server renders the first board one time, with the moves in
// data-steps; then it renders nothing until the end. At the end (or
// after Skip on the server), the hook sends "anim_done", and the server
// shows the next step of the run. See GoWeb.PuzzleLive.
import { newBoard, play, render } from './board.mjs';

const other = (c) => (c === 'blue' ? 'red' : 'blue');

export const Anim = {
  mounted() {
    const data = this.el.dataset;
    const steps = JSON.parse(data.steps);
    const delay = Number(data.delay);
    let board = newBoard(Number(data.size), JSON.parse(data.stones));
    let i = 0;

    const tick = () => {
      const [color, move] = steps[i];
      const { board: next, captured } = play(board, color, move);
      board = next;
      i += 1;
      const svg = this.el.querySelector('svg');
      if (svg) {
        svg.innerHTML = render(board, {
          look: data.look,
          marks: move === 'pass' ? [] : [[move[0], move[1], color]],
          falls: captured.map(([a, b]) => [a, b, other(color)]),
          step: i,
        });
      }
      if (i < steps.length) this.timer = setTimeout(tick, delay);
      else this.done();
    };

    this.timer = steps.length ? setTimeout(tick, delay) : null;
    if (!steps.length) this.done();
  },

  done() {
    if (this.sent) return;
    this.sent = true;
    this.pushEvent('anim_done', { id: this.el.id });
  },

  destroyed() {
    clearTimeout(this.timer);
  },
};
