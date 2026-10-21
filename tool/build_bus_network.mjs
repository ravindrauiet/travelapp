// Builds assets/data/bus_network.json from the raw Delhi OTD bus GTFS feed.
//
// The raw feed (assets/gtfs_data_bus, ~120 MB stop_times.txt) is far too large to
// ship in the app, so this script reduces it to what the app needs:
//   - every stop (id, code, name, lat, lon)
//   - every route with its ordered stop list, minutes-from-start per stop,
//     first/last departure and trip count (for frequency)
//
// Usage:  node tool/build_bus_network.mjs [inputDir] [outputFile]

import fs from 'fs';
import readline from 'readline';
import path from 'path';

const inDir = process.argv[2] ?? 'assets/gtfs_data_bus';
const outFile = process.argv[3] ?? 'assets/data/bus_network.json';

const readCsv = (file) => {
  const lines = fs.readFileSync(path.join(inDir, file), 'utf8').split(/\r?\n/).filter(Boolean);
  const header = lines.shift().split(',');
  return lines.map((l) => {
    const cols = l.split(',');
    return Object.fromEntries(header.map((h, i) => [h.trim(), (cols[i] ?? '').trim()]));
  });
};

const toMin = (t) => {
  const [h, m, s] = t.split(':').map(Number);
  return h * 60 + m + (s || 0) / 60;
};

// "764MSTLDOWN" -> { number: "764MSTL", dir: "DOWN" }; "CBD3(+)UP" -> { "CBD3(+)", "UP" }
const splitName = (longName) => {
  const m = longName.match(/^(.*?)(UP|DOWN)(\d*)$/i);
  if (!m) return { number: longName, dir: '' };
  return { number: m[1], dir: m[2].toUpperCase() + (m[3] || '') };
};

// "STL" suffix in the feed means a standard (non-AC) DIMTS cluster bus; keep the
// passenger-facing number readable while preserving the full name separately.
const displayNumber = (n) => n.replace(/STL$/i, '').replace(/EXT$/i, ' Ext') || n;

const stops = readCsv('stops.txt').map((s) => [
  Number(s.stop_id),
  s.stop_code,
  s.stop_name,
  Math.round(Number(s.stop_lat) * 1e6) / 1e6,
  Math.round(Number(s.stop_lon) * 1e6) / 1e6,
]);

const routesCsv = readCsv('routes.txt');
const routeMeta = new Map(routesCsv.map((r) => [r.route_id, r]));

// Trip start times per route (trip_id = "<route>_<HH>_<MM>")
const tripsByRoute = new Map();
for (const t of readCsv('trips.txt')) {
  const list = tripsByRoute.get(t.route_id) ?? [];
  const parts = t.trip_id.split('_');
  list.push(Number(parts[1]) * 60 + Number(parts[2]));
  tripsByRoute.set(t.route_id, list);
}

// Stream stop_times: keep, per route, the trip with the most stops (the full pattern).
const best = new Map(); // routeId -> { stops: [], times: [] }
let curTrip = null;
let cur = null;

const flush = () => {
  if (!curTrip) return;
  const routeId = curTrip.split('_')[0];
  const prev = best.get(routeId);
  if (!prev || cur.stops.length > prev.stops.length) best.set(routeId, cur);
};

const rl = readline.createInterface({
  input: fs.createReadStream(path.join(inDir, 'stop_times.txt')),
  crlfDelay: Infinity,
});
let header = true;
for await (const line of rl) {
  if (header) { header = false; continue; }
  if (!line) continue;
  const [tripId, arrival, , stopId, seq] = line.split(',');
  if (tripId !== curTrip) {
    flush();
    curTrip = tripId;
    cur = { stops: [], times: [], seq: [] };
  }
  cur.stops.push(Number(stopId));
  cur.times.push(toMin(arrival));
  cur.seq.push(Number(seq));
}
flush();

const routes = [];
for (const [routeId, pattern] of best) {
  const meta = routeMeta.get(routeId);
  if (!meta) continue;
  // Order by stop_sequence and drop consecutive duplicates
  const order = pattern.seq.map((s, i) => [s, i]).sort((a, b) => a[0] - b[0]).map(([, i]) => i);
  const seqStops = [];
  const offsets = [];
  const t0 = pattern.times[order[0]];
  for (const i of order) {
    if (seqStops[seqStops.length - 1] === pattern.stops[i]) continue;
    seqStops.push(pattern.stops[i]);
    offsets.push(Math.max(0, Math.round(pattern.times[i] - t0)));
  }
  if (seqStops.length < 2) continue;

  const starts = (tripsByRoute.get(routeId) ?? []).sort((a, b) => a - b);
  const { number, dir } = splitName(meta.route_long_name);
  routes.push({
    id: Number(routeId),
    n: displayNumber(number),
    ln: meta.route_long_name,
    d: dir,
    a: meta.agency_id,
    s: seqStops,
    t: offsets,
    f: starts[0] ?? null,
    l: starts[starts.length - 1] ?? null,
    k: starts.length,
  });
}
routes.sort((x, y) => x.id - y.id);

const out = {
  v: 1,
  source: 'Delhi Open Transit Data (otd.delhi.gov.in) static GTFS',
  generated: new Date().toISOString().slice(0, 10),
  stopFields: ['id', 'code', 'name', 'lat', 'lon'],
  stops,
  routes,
};
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, JSON.stringify(out));
const kb = Math.round(fs.statSync(outFile).size / 1024);
console.log(`stops=${stops.length} routes=${routes.length} -> ${outFile} (${kb} KB)`);
