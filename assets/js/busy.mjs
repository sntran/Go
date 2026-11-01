// The hook Busy: the safety net of a busy screen ("Red is thinking…").
// The element has data-busy ("true" while the server works on a step),
// data-step (a number that changes on each change of the play) and
// data-wait (the time to wait, in ms). If the screen stays busy on the
// same step for data-wait ms, the hook asks the server for the current
// state (the event "sync"), and asks again after each data-wait ms. The
// server then does the step that it waits on (see GoWeb.PuzzleLive).
export const Busy = {
  mounted() {
    this.check();
  },

  updated() {
    this.check();
  },

  destroyed() {
    clearTimeout(this.timer);
  },

  check() {
    clearTimeout(this.timer);
    const { busy, step, wait } = this.el.dataset;
    if (busy !== 'true') return;
    const ask = () => {
      this.pushEvent('sync', { step });
      this.timer = setTimeout(ask, Number(wait));
    };
    this.timer = setTimeout(ask, Number(wait));
  },
};
