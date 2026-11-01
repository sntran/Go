defmodule GoWeb.BusyJsTest do
  @moduledoc """
  The hook Busy (`assets/js/busy.mjs`), with a fake element in `node`: it
  sends "sync" after the wait of a busy screen, again after each wait, and
  stops when the screen is not busy, or when the step changes.
  """

  use ExUnit.Case, async: true

  @node System.find_executable("node")
  @moduletag skip: if(@node, do: false, else: "no node")

  test "the hook asks the server only while the screen stays busy on one step" do
    dir = Path.join(System.tmp_dir!(), "busy-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    script = Path.join(dir, "run.mjs")

    File.write!(script, """
    import { Busy } from '#{Path.expand("assets/js/busy.mjs")}';
    const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));
    const pushes = [];
    const hook = Object.create(Busy);
    hook.el = { dataset: { busy: 'false', step: '1', wait: '50' } };
    hook.pushEvent = (event, payload) => pushes.push([Date.now(), event, payload.step]);
    const out = {};

    // Not busy: no push.
    hook.mounted();
    await sleep(120);
    out.idle = pushes.length;

    // Busy on step 2: a push after 50 ms, then one after each 50 ms.
    const t0 = Date.now();
    hook.el.dataset = { busy: 'true', step: '2', wait: '50' };
    hook.updated();
    await sleep(30);
    out.early = pushes.length;
    await sleep(150);
    out.busy = pushes.map(([t, e, s]) => [e, s]);
    out.first = pushes[0][0] - t0;

    // A new step while busy: the wait starts again, with the new step.
    pushes.length = 0;
    hook.el.dataset = { busy: 'true', step: '3', wait: '50' };
    hook.updated();
    await sleep(30);
    out.restart = pushes.length;
    await sleep(40);
    out.next = pushes.map(([, , s]) => s);

    // Not busy any more: no more pushes.
    pushes.length = 0;
    hook.el.dataset = { busy: 'false', step: '4', wait: '50' };
    hook.updated();
    await sleep(150);
    out.done = pushes.length;

    // Busy, then the page goes away: no push.
    hook.el.dataset = { busy: 'true', step: '5', wait: '50' };
    hook.updated();
    hook.destroyed();
    await sleep(120);
    out.destroyed = pushes.length;
    console.log(JSON.stringify(out));
    """)

    {json, 0} = System.cmd(@node, [script])
    File.rm_rf!(dir)
    out = JSON.decode!(json)

    assert out["idle"] == 0
    assert out["early"] == 0
    assert out["first"] >= 45
    assert length(out["busy"]) in 2..4
    assert Enum.all?(out["busy"], &(&1 == ["sync", "2"]))
    assert out["restart"] == 0
    assert out["next"] == ["3"]
    assert out["done"] == 0
    assert out["destroyed"] == 0
  end
end
