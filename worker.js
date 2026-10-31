// The entry of Tower Go on Cloudflare Workers: app.com (npm run build) with
// the engine of the npm package beam.com.
import app from './app.com' with { type: 'bytes' };
import { serve } from 'beam.com';

// Stateful: the Durable Object Beam (the binding BEAM of wrangler.jsonc)
// runs one VM for all the requests. LiveView needs it, and the progress of
// the players stays in the memory of this VM.
export { Beam } from 'beam.com';

const beam = serve(app);

export default {
  fetch(request, env, ctx) {
    return beam.fetch(request, env, ctx);
  },
};
