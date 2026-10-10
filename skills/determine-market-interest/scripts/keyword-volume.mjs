#!/usr/bin/env node
/**
 * keyword-volume.mjs — fetch real keyword search-volume data from a configured paid
 * provider (or from a local CSV export) and emit one normalized record per query.
 *
 * Zero dependencies. Node 18+ builtins only (global fetch, node:fs, node:os, node:path).
 *
 * ---------------------------------------------------------------------------
 * NORMALIZED OUTPUT CONTRACT
 * ---------------------------------------------------------------------------
 * Exactly one record is emitted per de-duplicated input query, in input order,
 * with the same keys in the same order no matter which provider answered:
 *
 *   {
 *     "query":         string,                 // the query as it appeared in --queries
 *     "volume":        int | null,             // 12-month average monthly searches
 *     "trend":         "rising"|"flat"|"declining"|null,
 *     "trend_series":  [{year,month,volume}] | null,   // absolute monthly volumes, oldest first
 *     "cpc":           number | null,
 *     "competition":   number | null,          // 0..1
 *     "source":        "dataforseo"|"semrush"|"ahrefs"|"csv"|"dataforseo-sandbox",
 *     "confidence":    "Data" | "NoData" | "Sandbox",   // only these three, ever
 *     "country":       string,                 // as passed to --country
 *     "fetched":       "YYYY-MM-DD"
 *   }
 *
 * `confidence` is "Data" for any row a live API or a CSV actually returned, and
 * "NoData" for a query the provider did not return a row for. A NoData row is never
 * dropped: the caller must be able to tell "zero demand" (volume 0, confidence Data)
 * apart from "provider returned nothing" (volume null, confidence NoData).
 *
 * "Sandbox" is the third and only other value, produced solely by --sandbox. It marks
 * a row that came from the DataForSEO sandbox host, whose response is canned fixture
 * data with no relation to the keywords that were requested. Data means measured
 * truth; a fixture is not a measurement, so a sandbox row is never emitted as Data,
 * carries source "dataforseo-sandbox", and is never written to the cache.
 *
 * ROW MATCHING. Every adapter maps returned rows back to requested queries by
 * comparing the provider's own keyword field (DataForSEO result[].keyword, Semrush
 * column Ph, Ahrefs keywords[].keyword) against the request, normalized to lowercase
 * with collapsed whitespace. Nothing is ever matched by array position. Providers are
 * free to reorder rows, omit zero-volume keywords, or return extra rows; output is
 * built by iterating the requested queries, so a returned row that matches no request
 * is discarded rather than emitted, and a request with no returned row becomes NoData.
 *
 * `trend_series` carries ABSOLUTE monthly volumes only. Semrush's trend column (Td)
 * is a relative 0.00-1.00 index, not a volume, so Semrush rows always carry
 * trend_series: null while still carrying a derived `trend` direction. Ahrefs rows
 * carry a series only when its (undocumented) history object shape can be mapped
 * confidently at runtime; otherwise trend and trend_series are both null. Detecting
 * whether Ahrefs even accepts that column can cost one extra paid call on the first
 * chunk, which the spend confirmation discloses and the cache then remembers.
 *
 * Provider CPC/competition values are passed through with minimal normalization:
 *   - competition: DataForSEO competition_index/100, Semrush Co (already 0..1),
 *     Ahrefs difficulty/100 (keyword difficulty, NOT ad competition — closest analogue).
 *   - cpc: reported exactly as the provider returns it. Ahrefs CPC units are not
 *     documented in the verified spec and are NOT converted here.
 *
 * ---------------------------------------------------------------------------
 * OFFICIAL PROVIDER DOCS
 * ---------------------------------------------------------------------------
 *   DataForSEO: https://docs.dataforseo.com/v3/keywords_data/google_ads/search_volume/live/
 *   Semrush:    https://developer.semrush.com/api/v3/analytics/keyword-reports/
 *   Ahrefs:     https://docs.ahrefs.com/en/api/reference/keywords-explorer/get-overview
 *
 * ---------------------------------------------------------------------------
 * EXIT CODES
 * ---------------------------------------------------------------------------
 *   0  success
 *   1  usage or local I/O error (bad flag, unreadable file, unparseable CSV)
 *   2  the operator declined the spend confirmation prompt
 *   3  no provider configured (documented, actionable, non-fatal for the caller)
 *   4  estimated spend exceeds --max-spend and --yes was not passed
 *   5  the run completed but at least one chunk failed; those rows are NoData
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const SCRIPT = 'keyword-volume.mjs';

/* =========================================================================
 * Help
 * ========================================================================= */

const HELP = `
${SCRIPT} — fetch real keyword search-volume data, emit normalized JSON.

USAGE
  node ${SCRIPT} --queries <file|-> [options]
  node ${SCRIPT} --check-keys
  node ${SCRIPT} --help

OPTIONS
  --queries <file|->     Newline-delimited queries. "-" reads stdin. Blank lines and
                         lines beginning with # are ignored. Duplicate queries are
                         collapsed to one API lookup and one output record.
                         Required unless --check-keys or --help.
  --provider <name>      dataforseo | semrush | ahrefs
                         Default: the first provider whose env vars are all present,
                         preferring dataforseo > semrush > ahrefs.
  --country <cc>         Market to query. Default: us
                         Semrush uses it verbatim as its "database" param.
                         Ahrefs requires ISO 3166-1 alpha-2 lowercase (e.g. us, gb).
                         DataForSEO needs a numeric location_code; only us=2840 is
                         verified here. Use DATAFORSEO_LOCATION_CODE for other markets.
  --keywords <file>      Parse a Google Keyword Planner / Ahrefs / Semrush CSV or TSV
                         export instead of calling any API. Free, offline, source "csv".
                         Takes precedence over auto-detected providers but not over an
                         explicit --provider.
  --check-keys           Run only the free, zero-cost balance/quota probes, print what
                         is configured, and exit. Never consumes paid units.
  --max-spend <usd>      Refuse to run if estimated USD spend exceeds this.
                         Default: 1.00. Only DataForSEO publishes a USD price, so the
                         numeric gate can only bind for DataForSEO; see COST NOTES.
                         --max-spend 0 additionally refuses any semrush or ahrefs call,
                         because an unpublished price cannot be shown to be zero.
  --yes                  Skip the interactive spend confirmation.
  --no-cache             Bypass cache reads. Fresh results are still written to cache.
  --json                 Emit a single JSON array instead of JSON Lines (the default).
  --sandbox              Call https://sandbox.dataforseo.com instead of the live
                         DataForSEO host. For adapter testing only.

                         THE NUMBERS IT RETURNS ARE NOT REAL SEARCH VOLUMES. The
                         sandbox returns canned fixture rows that bear no relation to
                         the keywords sent; a single-keyword request has been observed
                         returning four unrelated rows such as "seo", "phone" and
                         "watch". Do not use the output for analysis, for scoring, or
                         for any decision.

                         The flag is free, needs no verified account, and uses the same
                         DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD. It implies
                         --provider dataforseo and is rejected with any other provider.
                         Every row it produces is labeled confidence "Sandbox" (never
                         "Data") and source "dataforseo-sandbox", nothing is read from
                         or written to the cache, no spend gate or confirmation applies,
                         and a prominent warning is printed to stderr before and after
                         the rows.
  --help                 Print this help and exit 0.

ENVIRONMENT VARIABLES
  DATAFORSEO_LOGIN           API login from https://app.dataforseo.com/api-access
  DATAFORSEO_PASSWORD        API password from that same page. This is the
                             auto-generated API password, NOT the account password.
  DATAFORSEO_LOCATION_CODE   Optional. Numeric DataForSEO location_code override,
                             required for any --country other than us.
  DATAFORSEO_LANGUAGE_CODE   Optional. DataForSEO language_code. Default: en
  SEMRUSH_API_KEY            Semrush API key. Sent as the "key" query param.
  AHREFS_API_KEY             Ahrefs API key. Sent as "Authorization: Bearer <key>".

COST NOTES
  dataforseo  $0.09 per live task, any number of keywords up to 1000 per task.
              The actual charge is read back from the response "cost" field and
              reported on stderr. Rate limit: 12 requests/minute.
  semrush     10 API units per returned line. Semrush does not publish a USD price
              per unit, so spend is reported in units and the USD conversion is
              reported as unknown rather than guessed. Rate limit: 10 requests/second.
  ahrefs      The units-cost formula is not available in the verified spec, so no
              spend is predicted. The actual cost is read back from the response
              headers x-api-units-cost-total-actual, x-api-units-cost-total and
              x-api-rows after EVERY call, including a rejected one, and reported on
              stderr. Rate limit: 60 requests/minute.
              One extra paid probe call may be issued on the first chunk: the request
              is first sent with the unverified volume_monthly_history column and, if
              Ahrefs rejects it, re-sent without it. The spend confirmation discloses
              this as "up to N+1 calls". The verdict is cached (see CACHE), so later
              runs do not pay for the probe again.
  csv         Free.

OUTPUT
  One record per de-duplicated query, in input order, same keys for every provider.
  confidence is "Data" (a live API or CSV returned the row), "NoData" (the provider
  returned no row for that query), or "Sandbox" (--sandbox fixture, never real).
  Rows are matched to queries by the provider's own keyword field, normalized to
  lowercase with collapsed whitespace, never by array position. A provider may
  reorder rows or omit zero-volume keywords without a volume landing on the wrong
  query: returned rows matching no request are discarded, and a request with no
  returned row becomes NoData rather than being dropped.

CACHE
  ~/.cache/market-interest/volumes.json, keyed "provider|country|query".
  --sandbox is never cached, in either direction; see that flag above.
  TTL 30 days for semrush (hard limit, licensing — see the comment in the source),
  90 days for every other provider. CSV results are not cached. Only rows with
  confidence "Data" are cached, so a NoData answer is always retried next run.
  The same file holds one reserved non-row key, "#meta", which cannot collide with a
  cached row. It stores whether Ahrefs accepts the volume_monthly_history column, so
  the extra probe call above is paid for once rather than on every run. That verdict
  is re-probed after 30 days, so a stored "unsupported" recovers if Ahrefs later fixes
  the column. --no-cache bypasses row reads but not this verdict, which is a
  capability fact about the API rather than keyword data.

EXIT CODES
  0 success   1 usage/IO error   2 spend declined   3 no provider configured
  4 over --max-spend             5 completed with at least one failed chunk
`.trimStart();

/* =========================================================================
 * Small utilities
 * ========================================================================= */

const warnings = [];
function warn(msg) {
  warnings.push(msg);
  process.stderr.write(`${SCRIPT}: warning: ${msg}\n`);
}
function info(msg) {
  process.stderr.write(`${SCRIPT}: ${msg}\n`);
}
function fail(msg, code = 1) {
  process.stderr.write(`${SCRIPT}: error: ${msg}\n`);
  process.exit(code);
}
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
function todayISO(d = new Date()) {
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}-${p(d.getUTCMonth() + 1)}-${p(d.getUTCDate())}`;
}
const TODAY = todayISO();

/** Canonical form used for matching provider rows back to input queries. */
function norm(s) {
  return String(s == null ? '' : s).trim().toLowerCase().replace(/\s+/g, ' ');
}
function toNum(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = typeof v === 'number' ? v : Number(String(v).replace(/[$,\s ]/g, ''));
  return Number.isFinite(n) ? n : null;
}
function toInt(v) {
  const n = toNum(v);
  return n === null ? null : Math.round(n);
}
function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

/* =========================================================================
 * Trend derivation
 * ========================================================================= */

/**
 * Trend derivation rule — identical for every provider, so the output is comparable:
 *
 *   1. Order the series chronologically, oldest first, and drop non-numeric points.
 *   2. Fewer than 4 usable points -> trend is null. Four points is the smallest
 *      window where a half-vs-half comparison is not just noise.
 *   3. Split into halves; on an odd length the single middle point is discarded so
 *      neither half is weighted by it.
 *   4. ratio = mean(second half) / mean(first half)
 *        ratio >= 1.15  -> "rising"
 *        ratio <= 0.85  -> "declining"
 *        otherwise      -> "flat"
 *      The +/-15% dead band keeps normal month-to-month wobble from reading as a trend.
 *   5. first-half mean 0 and second-half mean > 0 -> "rising" (ratio is undefined).
 *      Both halves 0 -> "flat".
 *
 * This works unchanged on Semrush's relative 0..1 index because it only ever reads
 * the ratio between two means of the same series, never an absolute magnitude.
 */
function deriveTrend(values) {
  const v = (values || []).map(toNum).filter((n) => n !== null);
  if (v.length < 4) return null;
  const half = Math.floor(v.length / 2);
  const first = v.slice(0, half);
  const second = v.slice(v.length - half);
  const mean = (a) => a.reduce((x, y) => x + y, 0) / a.length;
  const m1 = mean(first);
  const m2 = mean(second);
  if (m1 === 0) return m2 > 0 ? 'rising' : 'flat';
  const ratio = m2 / m1;
  if (ratio >= 1.15) return 'rising';
  if (ratio <= 0.85) return 'declining';
  return 'flat';
}

/** Sort a [{year,month,volume}] series oldest-first and drop unusable points. */
function cleanSeries(points) {
  const out = [];
  for (const p of points || []) {
    const year = toInt(p.year);
    const month = toInt(p.month);
    const volume = toInt(p.volume);
    if (year === null || month === null || volume === null) continue;
    if (month < 1 || month > 12) continue;
    out.push({ year, month, volume });
  }
  out.sort((a, b) => a.year - b.year || a.month - b.month);
  return out.length ? out : null;
}

/* =========================================================================
 * Normalized record
 * ========================================================================= */

function makeRow({
  query,
  volume = null,
  trend = null,
  trend_series = null,
  cpc = null,
  competition = null,
  source,
  confidence,
  country,
}) {
  return {
    query,
    volume: volume === null ? null : toInt(volume),
    trend,
    trend_series,
    cpc: cpc === null ? null : toNum(cpc),
    competition: competition === null ? null : toNum(competition),
    source,
    confidence,
    country,
    fetched: TODAY,
  };
}

function noDataRow(query, source, country) {
  return makeRow({ query, source, confidence: 'NoData', country });
}

/* =========================================================================
 * Argument parsing
 * ========================================================================= */

const KNOWN_FLAGS = new Set([
  '--queries', '--provider', '--country', '--keywords', '--check-keys',
  '--max-spend', '--yes', '--no-cache', '--json', '--sandbox', '--help', '-h',
]);

function parseArgs(argv) {
  const opts = {
    queries: null,
    provider: null,
    country: 'us',
    keywords: null,
    checkKeys: false,
    maxSpend: 1.0,
    yes: false,
    noCache: false,
    json: false,
    sandbox: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const need = () => {
      const v = argv[++i];
      if (v === undefined || v.startsWith('--')) fail(`${a} requires a value`);
      return v;
    };
    switch (a) {
      case '--queries': opts.queries = need(); break;
      case '--provider': opts.provider = need().toLowerCase(); break;
      case '--country': opts.country = need().toLowerCase(); break;
      case '--keywords': opts.keywords = need(); break;
      case '--check-keys': opts.checkKeys = true; break;
      case '--max-spend': {
        const v = toNum(need());
        if (v === null || v < 0) fail('--max-spend must be a non-negative number');
        opts.maxSpend = v;
        break;
      }
      case '--yes': opts.yes = true; break;
      case '--no-cache': opts.noCache = true; break;
      case '--json': opts.json = true; break;
      case '--sandbox': opts.sandbox = true; break;
      case '--help':
      case '-h': opts.help = true; break;
      default:
        if (!KNOWN_FLAGS.has(a)) fail(`unknown argument "${a}". Run --help for usage.`);
    }
  }
  return opts;
}

/* =========================================================================
 * Input reading
 * ========================================================================= */

function readStdinSync() {
  const chunks = [];
  const buf = Buffer.alloc(65536);
  let eagain = 0;
  for (;;) {
    let n;
    try {
      n = fs.readSync(0, buf, 0, buf.length, null);
    } catch (e) {
      if (e.code === 'EAGAIN') {
        if (++eagain > 2_000_000) throw e;
        continue;
      }
      if (e.code === 'EOF') break;
      throw e;
    }
    if (n === 0) break;
    chunks.push(Buffer.from(buf.subarray(0, n)));
  }
  return Buffer.concat(chunks).toString('utf8');
}

/** Decode a buffer that may be UTF-8, UTF-8 with BOM, UTF-16LE or UTF-16BE.
 *  Google Keyword Planner exports are UTF-16LE TSV with a BOM. */
function decodeTextBuffer(buf) {
  if (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xfe) {
    return buf.subarray(2).toString('utf16le');
  }
  if (buf.length >= 2 && buf[0] === 0xfe && buf[1] === 0xff) {
    const swapped = Buffer.from(buf.subarray(2));
    swapped.swap16();
    return swapped.toString('utf16le');
  }
  let s = buf.toString('utf8');
  if (s.charCodeAt(0) === 0xfeff) s = s.slice(1);
  return s;
}

function readQueries(src) {
  let text;
  if (src === '-') {
    text = readStdinSync();
  } else {
    try {
      text = decodeTextBuffer(fs.readFileSync(src));
    } catch (e) {
      fail(`cannot read --queries file "${src}": ${e.message}`);
    }
  }
  const seen = new Map();
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const k = norm(line);
    if (!k || seen.has(k)) continue;
    seen.set(k, line);
  }
  return [...seen.values()];
}

/* =========================================================================
 * Cache — ~/.cache/market-interest/volumes.json
 * ========================================================================= */

const CACHE_DIR = path.join(os.homedir(), '.cache', 'market-interest');
const CACHE_FILE = path.join(CACHE_DIR, 'volumes.json');

/**
 * TTL by provider.
 *
 * SEMRUSH IS A HARD 30 DAYS AND MUST NOT BE RAISED.
 * The Semrush API usage restrictions prohibit storing or caching data obtained
 * from their API for longer than one month without their prior written consent.
 * Every other provider here allows ordinary caching, so they get 90 days; Semrush
 * rows are expired at 30 days to stay inside that licensing constraint, not for
 * any data-freshness reason.
 */
const TTL_DAYS = { semrush: 30, dataforseo: 90, ahrefs: 90 };

function cacheKey(provider, country, query) {
  return `${provider}|${country}|${norm(query)}`;
}

function loadCache() {
  try {
    const parsed = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
  } catch {
    return {};
  }
}

function cacheIsFresh(entry, provider) {
  if (!entry || typeof entry !== 'object' || !entry.fetched || !entry.payload) return false;
  const then = Date.parse(`${entry.fetched}T00:00:00Z`);
  if (!Number.isFinite(then)) return false;
  const ageDays = (Date.now() - then) / 86_400_000;
  if (ageDays < 0) return false;
  return ageDays <= (TTL_DAYS[provider] ?? 90);
}

function saveCache(store) {
  try {
    fs.mkdirSync(CACHE_DIR, { recursive: true });
    const tmp = `${CACHE_FILE}.${process.pid}.tmp`;
    fs.writeFileSync(tmp, `${JSON.stringify(store, null, 0)}\n`, 'utf8');
    fs.renameSync(tmp, CACHE_FILE);
  } catch (e) {
    warn(`could not write cache ${CACHE_FILE}: ${e.message}`);
  }
}

/* -------------------------------------------------------------------------
 * Reserved non-row metadata inside volumes.json
 * -------------------------------------------------------------------------
 * "#meta" can never collide with a cached query row: cacheKey() always produces
 * "provider|country|query" and so always contains at least two "|" characters,
 * while this key contains none. Row reads are also always exact-key lookups of a
 * cacheKey() string, never a scan, so the sentinel is never visited as a row.
 * Belt and braces, the sentinel carries no `payload` field, and cacheIsFresh()
 * rejects any entry without one.
 */
const CACHE_META_KEY = '#meta';

/** Days before a stored Ahrefs history-support verdict is re-probed. */
const AHREFS_HISTORY_PROBE_TTL_DAYS = 30;

function readCacheMeta(store) {
  const m = store[CACHE_META_KEY];
  return m && typeof m === 'object' && !Array.isArray(m) ? m : {};
}

/**
 * Returns true, false, or undefined ("unknown, probe it").
 * A stored verdict older than AHREFS_HISTORY_PROBE_TTL_DAYS reads as undefined so a
 * stale `false` can recover if Ahrefs later documents and fixes the column.
 */
function loadAhrefsHistorySupport() {
  const rec = readCacheMeta(loadCache()).ahrefs_history_supported;
  if (!rec || typeof rec !== 'object' || typeof rec.value !== 'boolean') return undefined;
  const then = Date.parse(`${rec.checked}T00:00:00Z`);
  if (!Number.isFinite(then)) return undefined;
  const ageDays = (Date.now() - then) / 86_400_000;
  if (ageDays < 0 || ageDays > AHREFS_HISTORY_PROBE_TTL_DAYS) return undefined;
  return rec.value;
}

/** Re-reads the cache first so this never clobbers rows written by another run. */
function saveAhrefsHistorySupport(value) {
  const store = loadCache();
  const meta = readCacheMeta(store);
  meta.ahrefs_history_supported = { value, checked: TODAY };
  store[CACHE_META_KEY] = meta;
  saveCache(store);
}

/**
 * Persists the verdict at most once per run.
 *
 * A `false` that is already stored as `false` is deliberately NOT re-stamped.
 * Refreshing its timestamp on every run would keep pushing the 30-day re-probe
 * window forward, so the verdict could never expire and the column could never be
 * picked up again after Ahrefs fixed it.
 */
function persistAhrefsHistorySupport(state, value) {
  if (state.ahrefsHistoryPersisted) return;
  state.ahrefsHistoryPersisted = true;
  if (value === false && state.ahrefsHistoryLoaded === false) return;
  saveAhrefsHistorySupport(value);
  info(`cache: recorded ahrefs ${AHREFS_HISTORY_COLUMN} support = ${value} (re-probed after ${AHREFS_HISTORY_PROBE_TTL_DAYS} days)`);
}

/* =========================================================================
 * Provider configuration / detection
 * ========================================================================= */

const PROVIDERS = {
  dataforseo: {
    env: ['DATAFORSEO_LOGIN', 'DATAFORSEO_PASSWORD'],
    chunkSize: 1000,
    delayMs: 5000, // 12 live requests/minute
  },
  semrush: {
    env: ['SEMRUSH_API_KEY'],
    chunkSize: 100, // phrase_these hard max
    delayMs: 150, // 10 requests/second
  },
  ahrefs: {
    env: ['AHREFS_API_KEY'],
    chunkSize: 100,
    delayMs: 1100, // 60 requests/minute
  },
};
const PREFERENCE = ['dataforseo', 'semrush', 'ahrefs'];

function isConfigured(name) {
  return PROVIDERS[name].env.every((e) => !!process.env[e]);
}
function missingEnv(name) {
  return PROVIDERS[name].env.filter((e) => !process.env[e]);
}

function noProviderMessage() {
  const lines = [
    'No keyword-volume provider is configured, so no volume data can be fetched.',
    '',
    'Set the environment variables for whichever provider you have an account with:',
    '',
    '  dataforseo (preferred — cheapest, $0.09 per task of up to 1000 keywords)',
    '      DATAFORSEO_LOGIN      API login  from https://app.dataforseo.com/api-access',
    '      DATAFORSEO_PASSWORD   API password from that page (NOT the account password)',
    '',
    '  semrush',
    '      SEMRUSH_API_KEY       from https://www.semrush.com/api-analytics/',
    '',
    '  ahrefs',
    '      AHREFS_API_KEY        from https://ahrefs.com/api',
    '',
    'Already-missing variables for each provider right now:',
    `  dataforseo: ${missingEnv('dataforseo').join(', ') || 'none'}`,
    `  semrush:    ${missingEnv('semrush').join(', ') || 'none'}`,
    `  ahrefs:     ${missingEnv('ahrefs').join(', ') || 'none'}`,
    '',
    'Alternatively, run with --keywords <file> to read volumes from a Keyword Planner,',
    'Ahrefs or Semrush CSV export instead of calling any API. That path is free and',
    'needs no credentials.',
  ];
  return `${lines.join('\n')}\n`;
}

/**
 * Provider resolution, in this exact precedence:
 *   1. explicit --provider
 *   2. --keywords <file> CSV ingestion
 *   3. first configured provider, preferring dataforseo > semrush > ahrefs
 *   4. none -> exit 3 with an actionable message
 */
function resolveProvider(opts) {
  // --sandbox only exists for DataForSEO; no other provider has a free fixture host.
  if (opts.sandbox) {
    if (opts.provider && opts.provider !== 'dataforseo') {
      fail(`--sandbox only applies to the dataforseo provider, but --provider ${opts.provider} was requested.`);
    }
    if (!isConfigured('dataforseo')) {
      fail(
        '--sandbox needs DataForSEO credentials; the sandbox host authenticates with the same ' +
          `login and password as the live host. Missing: ${missingEnv('dataforseo').join(', ')}.`,
      );
    }
    return 'dataforseo';
  }
  if (opts.provider) {
    if (!PROVIDERS[opts.provider]) {
      fail(`unknown --provider "${opts.provider}". Choose dataforseo, semrush or ahrefs.`);
    }
    if (!isConfigured(opts.provider)) {
      fail(
        `--provider ${opts.provider} was requested but ${missingEnv(opts.provider).join(' and ')} ` +
          'is not set in the environment.',
      );
    }
    return opts.provider;
  }
  if (opts.keywords) return 'csv';
  for (const name of PREFERENCE) if (isConfigured(name)) return name;
  process.stderr.write(noProviderMessage());
  process.exit(3);
}

/* =========================================================================
 * HTTP helper
 * ========================================================================= */

async function httpRequest(provider, url, init = {}) {
  let res;
  try {
    res = await fetch(url, { ...init, signal: AbortSignal.timeout(90_000) });
  } catch (e) {
    throw new Error(`${provider}: network failure calling ${hideSecrets(url)}: ${e.message}`);
  }
  const text = await res.text().catch(() => '');
  return { res, text };
}

function hideSecrets(url) {
  return String(url).replace(/([?&]key=)[^&]+/gi, '$1***');
}

/* =========================================================================
 * Zero-cost key / quota probes  (--check-keys)
 * ========================================================================= */

async function checkKeys() {
  const out = [];
  let anyConfigured = false;

  // --- dataforseo -----------------------------------------------------------
  if (isConfigured('dataforseo')) {
    anyConfigured = true;
    out.push('dataforseo: configured (DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD are set)');
    // The verified spec documents no zero-cost balance endpoint for DataForSEO, and
    // every documented keywords_data call is billable. Credentials are therefore
    // reported as present but deliberately NOT validated against the API, because
    // doing so would cost money and --check-keys promises to spend nothing.
    out.push('  balance: not probed — the verified spec lists no zero-cost DataForSEO');
    out.push('           endpoint, and every documented call is billable, so these');
    out.push('           credentials are reported as present but unverified.');
  } else {
    out.push(`dataforseo: not configured (missing ${missingEnv('dataforseo').join(', ')})`);
  }

  // --- semrush --------------------------------------------------------------
  if (isConfigured('semrush')) {
    anyConfigured = true;
    out.push('semrush: configured (SEMRUSH_API_KEY is set)');
    const url = `http://www.semrush.com/users/countapiunits.html?key=${encodeURIComponent(process.env.SEMRUSH_API_KEY)}`;
    try {
      const { res, text } = await httpRequest('semrush', url);
      const body = text.trim();
      if (!res.ok) {
        out.push(`  units: probe failed, HTTP ${res.status} — ${body.slice(0, 200) || '(empty body)'}`);
      } else if (/^\d+$/.test(body)) {
        out.push(`  units: ${body} API units remaining (this probe costs 0 units)`);
      } else {
        out.push(`  units: unexpected probe response — ${body.slice(0, 200) || '(empty body)'}`);
      }
    } catch (e) {
      out.push(`  units: probe failed — ${e.message}`);
    }
  } else {
    out.push(`semrush: not configured (missing ${missingEnv('semrush').join(', ')})`);
  }

  // --- ahrefs ---------------------------------------------------------------
  if (isConfigured('ahrefs')) {
    anyConfigured = true;
    out.push('ahrefs: configured (AHREFS_API_KEY is set)');
    const headers = { Authorization: `Bearer ${process.env.AHREFS_API_KEY}`, Accept: 'application/json' };
    try {
      const { res, text } = await httpRequest(
        'ahrefs',
        'https://api.ahrefs.com/v3/subscription-info/limits-and-usage',
        { headers },
      );
      if (!res.ok) {
        out.push(`  quota: probe failed, HTTP ${res.status} — ${text.slice(0, 300) || '(empty body)'}`);
      } else {
        out.push(`  quota: ${text.trim().slice(0, 600) || '(empty body)'}`);
      }
    } catch (e) {
      out.push(`  quota: probe failed — ${e.message}`);
    }
    // A keywords-explorer request whose only keyword is literally "ahrefs" consumes
    // no units, so it is a safe way to prove the key works on the endpoint we use.
    try {
      const smoke = new URL('https://api.ahrefs.com/v3/keywords-explorer/overview');
      smoke.searchParams.set('select', 'keyword,volume');
      smoke.searchParams.set('country', 'us');
      smoke.searchParams.set('keywords', 'ahrefs');
      smoke.searchParams.set('output', 'json');
      const { res, text } = await httpRequest('ahrefs', smoke, { headers });
      out.push(
        res.ok
          ? '  smoke test: keywords-explorer/overview reachable and authorized (0 units)'
          : `  smoke test: HTTP ${res.status} — ${text.slice(0, 300) || '(empty body)'}`,
      );
    } catch (e) {
      out.push(`  smoke test: failed — ${e.message}`);
    }
  } else {
    out.push(`ahrefs: not configured (missing ${missingEnv('ahrefs').join(', ')})`);
  }

  out.push('');
  out.push(
    anyConfigured
      ? `default provider: ${PREFERENCE.find(isConfigured)} (preference order dataforseo > semrush > ahrefs)`
      : 'default provider: none',
  );
  out.push('csv ingestion via --keywords <file> is always available and costs nothing.');

  process.stdout.write(`${out.join('\n')}\n`);
  return anyConfigured ? 0 : 3;
}

/* =========================================================================
 * Cost preflight
 * ========================================================================= */

function promptYesNo(question) {
  let fd;
  try {
    fd = fs.openSync('/dev/tty', 'r');
  } catch {
    return null; // no controlling terminal -> non-interactive
  }
  try {
    process.stderr.write(question);
    const buf = Buffer.alloc(1);
    let line = '';
    let eagain = 0;
    for (;;) {
      let n;
      try {
        n = fs.readSync(fd, buf, 0, 1, null);
      } catch (e) {
        if (e.code === 'EAGAIN' && ++eagain < 1_000_000) continue;
        return null;
      }
      if (n === 0) break;
      const ch = buf.toString('utf8');
      if (ch === '\n' || ch === '\r') break;
      line += ch;
    }
    process.stderr.write('\n');
    return /^(y|yes)$/i.test(line.trim());
  } finally {
    try {
      fs.closeSync(fd);
    } catch { /* ignore */ }
  }
}

/**
 * Returns {calls, usd|null, units|null, text}. usd === null means "USD unknown".
 * `extraProbePossible` is true only for ahrefs when the history-support verdict is
 * still unknown, in which case one additional paid call may be issued.
 */
function estimateSpend(provider, count, extraProbePossible = false) {
  const size = PROVIDERS[provider].chunkSize;
  const calls = Math.max(1, Math.ceil(count / size));
  if (provider === 'dataforseo') {
    const usd = calls * 0.09;
    return {
      calls,
      usd,
      units: null,
      text: `${calls} live task(s) x $0.09 = $${usd.toFixed(2)} estimated (actual charge is read back from the response "cost" field)`,
    };
  }
  if (provider === 'semrush') {
    const units = count * 10;
    return {
      calls,
      usd: null,
      units,
      text: `${calls} call(s), up to ${units} API units (10 units per returned line). Semrush does not publish a USD price per unit, so the USD cost of this run is unknown and cannot be checked against --max-spend.`,
    };
  }
  // `calls` stays at the planned chunk count rather than being inflated to calls+1,
  // because on the common path the fallback never fires and calls+1 would overstate
  // the cost. The conditional extra call is disclosed in words instead.
  const probe = extraProbePossible
    ? ` One extra probe call may also be needed, for up to ${calls + 1} calls in total: the first chunk is sent with the unverified "${AHREFS_HISTORY_COLUMN}" column and, if Ahrefs rejects it, that chunk is re-sent without it. The verdict is then cached, so later runs do not pay for the probe again.`
    : ` A cached probe already says "${AHREFS_HISTORY_COLUMN}" is unsupported, so no extra probe call is needed and ${calls} is the full count.`;
  return {
    calls,
    usd: null,
    units: null,
    extraProbePossible,
    text:
      `${calls} planned call(s). Ahrefs' units-cost formula is not in the verified spec, so no unit or USD estimate is predicted here; the actual cost is read back from the x-api-units-cost-total-actual / x-api-units-cost-total / x-api-rows response headers after every call, including a rejected one.` +
      probe,
  };
}

/** Exits 4 (over budget) or 2 (declined) when appropriate. */
function costPreflight(provider, queries, pending, opts, state) {
  if (provider === 'csv') {
    info(`provider csv: parsing ${opts.keywords} for ${queries.length} query/queries. No API calls, no cost.`);
    return;
  }
  // The sandbox host is free, so there is nothing to gate or confirm. The banner is
  // the point of this branch: it must appear before the fixture numbers do.
  if (opts.sandbox) {
    writeSandboxBanner();
    info(
      `provider ${SANDBOX_SOURCE}: ${queries.length} query/queries, country ${opts.country}. ` +
        'The sandbox host is free, so no spend gate and no confirmation apply, and the cache is ' +
        'bypassed in both directions.',
    );
    return;
  }
  info(
    `provider ${provider}: ${queries.length} query/queries, ${pending} not served from cache, ` +
      `country ${opts.country}`,
  );
  if (pending === 0) {
    info('everything is cached; no paid call will be made, estimated spend $0.00.');
    return;
  }

  const extraProbePossible = provider === 'ahrefs' && state.ahrefsHistorySupported !== false;
  const est = estimateSpend(provider, pending, extraProbePossible);
  info(`estimated spend: ${est.text}`);

  // --max-spend 0 means "spend nothing". For semrush and ahrefs the USD cost of a
  // call is unknown, so it cannot be shown to be zero, and the call is refused.
  if (est.usd === null && opts.maxSpend === 0) {
    process.stderr.write(
      `${SCRIPT}: error: --max-spend 0 forbids any spend, and the USD cost of one ${provider} call is ` +
        'not published, so it cannot be shown to be zero. No API call was made. Raise --max-spend to ' +
        'proceed, or use --check-keys for the free probes.\n',
    );
    process.exit(4);
  }

  if (est.usd !== null && est.usd > opts.maxSpend) {
    if (!opts.yes) {
      process.stderr.write(
        `${SCRIPT}: error: estimated spend $${est.usd.toFixed(2)} exceeds --max-spend ` +
          `$${opts.maxSpend.toFixed(2)}. No API call was made. Raise --max-spend or pass --yes to proceed.\n`,
      );
      process.exit(4);
    }
    warn(
      `estimated spend $${est.usd.toFixed(2)} exceeds --max-spend $${opts.maxSpend.toFixed(2)}, ` +
        'proceeding because --yes was passed.',
    );
  }

  if (opts.yes) return;

  // The prompt must never understate how many paid calls may be issued, so the
  // conditional ahrefs probe is named here as "up to N+1" rather than hidden.
  const callText = est.extraProbePossible
    ? `up to ${est.calls + 1} paid ${provider} call(s) (${est.calls} planned, plus one extra probe only if history-column support still has to be detected)`
    : `${est.calls} paid ${provider} call(s)`;
  const q =
    est.usd !== null
      ? `${SCRIPT}: spend about $${est.usd.toFixed(2)} on ${provider}? [y/N] `
      : `${SCRIPT}: proceed with ${callText}? The USD cost is unknown. [y/N] `;
  const answer = promptYesNo(q);
  if (answer === null) {
    info('no controlling terminal; proceeding without interactive confirmation (pass --yes to silence this).');
    return;
  }
  if (!answer) {
    process.stderr.write(`${SCRIPT}: aborted at the spend confirmation; no API call was made.\n`);
    process.exit(2);
  }
}

/* =========================================================================
 * Provider: DataForSEO
 * https://docs.dataforseo.com/v3/keywords_data/google_ads/search_volume/live/
 * ========================================================================= */

const DFS_PATH = '/v3/keywords_data/google_ads/search_volume/live';
const DFS_LIVE_ENDPOINT = `https://api.dataforseo.com${DFS_PATH}`;
const DFS_SANDBOX_ENDPOINT = `https://sandbox.dataforseo.com${DFS_PATH}`;

/**
 * The sandbox host accepts the same credentials, charges nothing, and returns the
 * identical envelope shape, but its result[] is canned fixture data with no relation
 * to the request. A one-keyword request has been observed returning result_count 4
 * with the rows "seo", "phone", "lkjhgfvbnm" and "watch".
 *
 * Because the keyword-field matching in fetchDataForSEO is by name and never by array
 * position, those fixture rows cannot land on a requested query: they match nothing
 * and are discarded, and the real query comes back NoData. The labeling below exists
 * for the case where a fixture row DOES happen to share a requested keyword, and so
 * that no sandbox row can ever be mistaken for a measurement downstream.
 */
const SANDBOX_SOURCE = 'dataforseo-sandbox';

function writeSandboxBanner() {
  const bar = '='.repeat(80);
  process.stderr.write(
    `${[
      '',
      bar,
      'SANDBOX MODE. THE NUMBERS IN THIS OUTPUT ARE NOT REAL SEARCH VOLUMES.',
      '',
      'This run queried the DataForSEO sandbox host',
      `  ${DFS_SANDBOX_ENDPOINT}`,
      'which returns canned fixture rows that bear no relation to the keywords that',
      'were sent. A single-keyword request has been observed coming back with four',
      'unrelated rows such as "seo", "phone" and "watch".',
      '',
      `Every row produced here is labeled confidence "Sandbox" and source`,
      `"${SANDBOX_SOURCE}", and none of it is written to the cache.`,
      '',
      'Do not use these numbers for analysis, for scoring, or for any decision. This',
      'flag exists only to integration-test the adapter without spending money.',
      bar,
      '',
    ].join('\n')}`,
  );
}

// Only us=2840 is verified first-hand. Any other market needs an explicit
// DATAFORSEO_LOCATION_CODE rather than a guessed code.
const DFS_LOCATION_CODES = { us: 2840 };

function dfsLocationCode(country) {
  const override = toInt(process.env.DATAFORSEO_LOCATION_CODE);
  if (override !== null) return override;
  const known = DFS_LOCATION_CODES[country];
  if (known !== undefined) return known;
  fail(
    `DataForSEO needs a numeric location_code and only "us" (2840) is verified in this build. ` +
      `Set DATAFORSEO_LOCATION_CODE to the code for "${country}" (see ` +
      'https://docs.dataforseo.com/v3/keywords_data/google_ads/locations/ ) or pick another provider.',
  );
}

/** DataForSEO keyword constraints from the verified spec: <=80 chars, <=10 words. */
function dfsKeywordRejection(kw) {
  if (kw.length > 80) return 'longer than the 80-character DataForSEO limit';
  if (kw.split(/\s+/).filter(Boolean).length > 10) return 'more than the 10-word DataForSEO limit';
  return null;
}

async function fetchDataForSEO(queries, country, state) {
  const results = new Map();
  const locationCode = dfsLocationCode(country);
  const languageCode = process.env.DATAFORSEO_LANGUAGE_CODE || 'en';
  const auth = Buffer.from(
    `${process.env.DATAFORSEO_LOGIN}:${process.env.DATAFORSEO_PASSWORD}`,
  ).toString('base64');

  const usable = [];
  for (const q of queries) {
    const reason = dfsKeywordRejection(q);
    if (reason) {
      warn(`skipping "${q}": ${reason}.`);
      continue;
    }
    usable.push(q);
  }

  const chunks = chunk(usable, PROVIDERS.dataforseo.chunkSize);
  for (let ci = 0; ci < chunks.length; ci++) {
    if (ci > 0) await sleep(PROVIDERS.dataforseo.delayMs);
    const batch = chunks[ci];
    const body = JSON.stringify([
      {
        keywords: batch,
        location_code: locationCode,
        language_code: languageCode,
        search_partners: false,
        include_adult_keywords: false,
      },
    ]);
    try {
      const { res, text } = await httpRequest(
        'dataforseo',
        state.sandbox ? DFS_SANDBOX_ENDPOINT : DFS_LIVE_ENDPOINT,
        {
          method: 'POST',
          headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
          body,
        },
      );
      if (!res.ok) {
        throw new Error(
          `dataforseo: HTTP ${res.status} ${res.statusText} — ${text.slice(0, 400) || '(empty body)'}`,
        );
      }
      let json;
      try {
        json = JSON.parse(text);
      } catch {
        throw new Error(`dataforseo: HTTP ${res.status} but the body was not JSON — ${text.slice(0, 200)}`);
      }
      if (toInt(json.status_code) !== 20000) {
        throw new Error(
          `dataforseo: HTTP ${res.status}, API status_code ${json.status_code} — ${json.status_message || 'no status_message'}`,
        );
      }
      const cost = toNum(json.cost);
      if (cost !== null) state.dfsCost += cost;

      const tasks = Array.isArray(json.tasks) ? json.tasks : [];
      if (!tasks.length) throw new Error(`dataforseo: HTTP ${res.status} but the response contained no tasks`);

      for (const task of tasks) {
        if (toInt(task.status_code) !== 20000) {
          throw new Error(
            `dataforseo: HTTP ${res.status}, task ${task.id || '?'} status_code ${task.status_code} — ` +
              `${task.status_message || 'no status_message'}`,
          );
        }
        for (const item of Array.isArray(task.result) ? task.result : []) {
          if (!item || item.keyword == null) continue;
          const series = cleanSeries(
            (Array.isArray(item.monthly_searches) ? item.monthly_searches : []).map((m) => ({
              year: m && m.year,
              month: m && m.month,
              volume: m && m.search_volume,
            })),
          );
          // competition_index is 0-100; `competition` itself is a LOW/MEDIUM/HIGH
          // enum on this endpoint, so it is only used when it happens to be numeric.
          let competition = null;
          const idx = toNum(item.competition_index);
          if (idx !== null) competition = Math.max(0, Math.min(1, idx / 100));
          else if (typeof item.competition === 'number') competition = item.competition;

          results.set(norm(item.keyword), {
            volume: item.search_volume === null || item.search_volume === undefined ? null : toInt(item.search_volume),
            trend: series ? deriveTrend(series.map((p) => p.volume)) : null,
            trend_series: series,
            cpc: toNum(item.cpc),
            competition,
          });
        }
      }
    } catch (e) {
      state.failed = true;
      process.stderr.write(`${SCRIPT}: error: ${e.message}\n`);
      process.stderr.write(
        `${SCRIPT}: error: the above dataforseo chunk of ${batch.length} keyword(s) produced no data; ` +
          'those queries are emitted as NoData and the run continues.\n',
      );
    }
  }
  return results;
}

/* =========================================================================
 * Provider: Semrush
 * https://developer.semrush.com/api/v3/analytics/keyword-reports/
 * ========================================================================= */

function parseSemicolonCsv(text) {
  const lines = text.split(/\r?\n/).filter((l) => l.trim() !== '');
  if (!lines.length) return { header: [], rows: [] };
  const header = lines[0].split(';').map((h) => h.trim());
  const rows = lines.slice(1).map((l) => l.split(';'));
  return { header, rows };
}

async function fetchSemrush(queries, country, state) {
  const results = new Map();
  const key = process.env.SEMRUSH_API_KEY;

  const usable = [];
  for (const q of queries) {
    // phrase_these joins keywords with ";", so a keyword containing ";" cannot be
    // expressed in the request at all. It is reported, not silently mangled.
    if (q.includes(';')) {
      warn(`skipping "${q}": a semicolon cannot be sent in a Semrush phrase_these request.`);
      continue;
    }
    usable.push(q);
  }

  const chunks = chunk(usable, PROVIDERS.semrush.chunkSize);
  for (let ci = 0; ci < chunks.length; ci++) {
    if (ci > 0) await sleep(PROVIDERS.semrush.delayMs);
    const batch = chunks[ci];
    const url = new URL('https://api.semrush.com/');
    url.searchParams.set('type', batch.length === 1 ? 'phrase_this' : 'phrase_these');
    url.searchParams.set('key', key);
    url.searchParams.set('phrase', batch.join(';'));
    url.searchParams.set('database', country);
    url.searchParams.set('export_columns', 'Ph,Nq,Cp,Co,Nr,Td');

    try {
      const { res, text } = await httpRequest('semrush', url);
      const body = text.trim();
      if (!res.ok) {
        throw new Error(`semrush: HTTP ${res.status} ${res.statusText} — ${body.slice(0, 400) || '(empty body)'}`);
      }
      // Semrush signals problems with a plain-text "ERROR nn :: MESSAGE" body and
      // HTTP 200. ERROR 50 (NOTHING FOUND) is a legitimate empty result, not a fault.
      if (/^ERROR\s/i.test(body)) {
        if (/^ERROR\s+50\b/i.test(body)) {
          warn(`semrush returned NOTHING FOUND for a chunk of ${batch.length} keyword(s); emitting NoData for them.`);
          continue;
        }
        throw new Error(`semrush: HTTP ${res.status} with API error body — ${body.slice(0, 300)}`);
      }
      const { header, rows } = parseSemicolonCsv(body);
      if (!header.length) throw new Error(`semrush: HTTP ${res.status} but the body was empty`);
      const col = (name) => header.indexOf(name);
      const iPh = col('Ph');
      const iNq = col('Nq');
      if (iPh < 0 || iNq < 0) {
        throw new Error(
          `semrush: HTTP ${res.status} but the response header lacks Ph and/or Nq — got "${header.join(';')}"`,
        );
      }
      const iCp = col('Cp');
      const iCo = col('Co');
      const iTd = col('Td');

      for (const r of rows) {
        const phrase = r[iPh];
        if (phrase == null || phrase === '') continue;
        state.semrushLines += 1;
        // Td is 12 comma-separated RELATIVE values in 0.00-1.00, not volumes, so it
        // is used for direction only and never surfaced as trend_series.
        let trend = null;
        if (iTd >= 0 && r[iTd]) {
          const rel = String(r[iTd]).split(',').map(toNum).filter((n) => n !== null);
          trend = deriveTrend(rel);
        }
        let competition = toNum(iCo >= 0 ? r[iCo] : null);
        if (competition !== null && competition > 1) competition = competition / 100;
        results.set(norm(phrase), {
          volume: toInt(r[iNq]),
          trend,
          trend_series: null,
          cpc: toNum(iCp >= 0 ? r[iCp] : null),
          competition,
        });
      }
    } catch (e) {
      state.failed = true;
      process.stderr.write(`${SCRIPT}: error: ${e.message}\n`);
      process.stderr.write(
        `${SCRIPT}: error: the above semrush chunk of ${batch.length} keyword(s) produced no data; ` +
          'those queries are emitted as NoData and the run continues.\n',
      );
    }
  }
  return results;
}

/* =========================================================================
 * Provider: Ahrefs
 * https://docs.ahrefs.com/en/api/reference/keywords-explorer/get-overview
 * ========================================================================= */

const AHREFS_BASE_SELECT = ['keyword', 'volume', 'volume_monthly', 'global_volume', 'difficulty', 'cpc'];
const AHREFS_HISTORY_COLUMN = 'volume_monthly_history';

/**
 * Ahrefs' volume_monthly_history is typed array<object> and the official docs render
 * its example as [{}] with no inner keys, so its shape is UNVERIFIED. Rather than
 * assuming {date, volume}, inspect the keys present at runtime: accept any key that
 * looks like a date/month/year and any key that looks like a volume. If the mapping
 * cannot be made confidently, return null so the caller gets trend: null instead of
 * a fabricated series.
 */
function parseAhrefsHistory(history, keyword) {
  if (!Array.isArray(history) || history.length === 0) return null;
  const sample = history.find((h) => h && typeof h === 'object' && !Array.isArray(h));
  if (!sample) return null;
  const keys = Object.keys(sample);
  if (!keys.length) {
    warn(
      `ahrefs ${AHREFS_HISTORY_COLUMN} for "${keyword}" came back as objects with no keys, exactly as the ` +
        'official docs render it; trend left null rather than guessed.',
    );
    return null;
  }

  const dateKey = keys.find((k) => /date|month|year|period/i.test(k) && !/volume|search/i.test(k));
  const volKey = keys.find((k) => /volume|search/i.test(k));
  if (!volKey) {
    warn(
      `ahrefs ${AHREFS_HISTORY_COLUMN} for "${keyword}" has keys [${keys.join(', ')}] with no recognizable ` +
        'volume field; trend left null rather than guessed.',
    );
    return null;
  }

  // Separate explicit year/month keys are also possible.
  const yearKey = keys.find((k) => /^year$/i.test(k)) || keys.find((k) => /year/i.test(k) && !/volume/i.test(k));
  const monthKey = keys.find((k) => /^month$/i.test(k)) || keys.find((k) => /month/i.test(k) && !/volume/i.test(k));

  const points = [];
  for (const h of history) {
    if (!h || typeof h !== 'object') continue;
    const volume = toInt(h[volKey]);
    if (volume === null) continue;

    let year = null;
    let month = null;
    if (yearKey && monthKey && toInt(h[yearKey]) !== null && toInt(h[monthKey]) !== null) {
      year = toInt(h[yearKey]);
      month = toInt(h[monthKey]);
    } else if (dateKey && h[dateKey] != null) {
      const m = /^(\d{4})-(\d{2})/.exec(String(h[dateKey]));
      if (m) {
        year = Number(m[1]);
        month = Number(m[2]);
      } else {
        const t = Date.parse(String(h[dateKey]));
        if (Number.isFinite(t)) {
          const d = new Date(t);
          year = d.getUTCFullYear();
          month = d.getUTCMonth() + 1;
        }
      }
    }
    if (year === null || month === null) continue;
    points.push({ year, month, volume });
  }

  if (points.length < 2) {
    warn(
      `ahrefs ${AHREFS_HISTORY_COLUMN} for "${keyword}" could not be mapped to year/month/volume ` +
        `(keys were [${keys.join(', ')}]); trend left null rather than guessed.`,
    );
    return null;
  }
  return cleanSeries(points);
}

function monthWindow(monthsBack) {
  const now = new Date();
  const to = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 0)); // last day of previous month
  const from = new Date(Date.UTC(to.getUTCFullYear(), to.getUTCMonth() - (monthsBack - 1), 1));
  return { from: todayISO(from), to: todayISO(to) };
}

/**
 * Ahrefs has no numeric spend gate at all, because its USD price per unit is not
 * published, so this readback is the only spend visibility this provider has. It must
 * therefore run on EVERY response, including a non-OK one that is about to be thrown
 * away: whether Ahrefs bills a request it rejects as invalid is unverified, and an
 * unverified charge cannot be assumed to be zero.
 */
function readAhrefsCostHeaders(res, state, label) {
  const actual = res.headers.get('x-api-units-cost-total-actual');
  const total = res.headers.get('x-api-units-cost-total');
  const rows = res.headers.get('x-api-rows');
  state.ahrefsHeaders.push({ actual, total, rows });
  info(
    `ahrefs cost headers (${label}, HTTP ${res.status}): ` +
      `x-api-units-cost-total-actual=${actual ?? 'absent'} ` +
      `x-api-units-cost-total=${total ?? 'absent'} x-api-rows=${rows ?? 'absent'}`,
  );
}

async function fetchAhrefs(queries, country, state) {
  const results = new Map();
  if (!/^[a-z]{2}$/.test(country)) {
    fail(`ahrefs requires --country as a two-letter lowercase ISO 3166-1 alpha-2 code; got "${country}".`);
  }
  const headers = { Authorization: `Bearer ${process.env.AHREFS_API_KEY}`, Accept: 'application/json' };

  const usable = [];
  for (const q of queries) {
    // The keywords param is a comma-separated list, so a keyword containing a comma
    // cannot be expressed. Reported rather than silently split.
    if (q.includes(',')) {
      warn(`skipping "${q}": a comma cannot be sent in the Ahrefs comma-separated keywords list.`);
      continue;
    }
    usable.push(q);
  }

  if (state.ahrefsHistorySupported === false) {
    info(
      `ahrefs: a cached probe says "${AHREFS_HISTORY_COLUMN}" is unsupported, so the base columns are ` +
        `requested directly and no extra probe call is paid for. trend will be null. The verdict is ` +
        `re-probed after ${AHREFS_HISTORY_PROBE_TTL_DAYS} days.`,
    );
  }

  const window = monthWindow(12);
  const chunks = chunk(usable, PROVIDERS.ahrefs.chunkSize);

  for (let ci = 0; ci < chunks.length; ci++) {
    if (ci > 0) await sleep(PROVIDERS.ahrefs.delayMs);
    const batch = chunks[ci];

    const build = (withHistory) => {
      const u = new URL('https://api.ahrefs.com/v3/keywords-explorer/overview');
      const select = withHistory ? [...AHREFS_BASE_SELECT, AHREFS_HISTORY_COLUMN] : AHREFS_BASE_SELECT;
      u.searchParams.set('select', select.join(','));
      u.searchParams.set('country', country);
      u.searchParams.set('keywords', batch.join(','));
      u.searchParams.set('limit', String(batch.length));
      u.searchParams.set('output', 'json');
      if (withHistory) {
        u.searchParams.set('volume_monthly_date_from', window.from);
        u.searchParams.set('volume_monthly_date_to', window.to);
      }
      return u;
    };

    try {
      // The history column and its date params are unverified, so try them once and
      // fall back to the verified base columns if Ahrefs rejects the request.
      const withHistory = state.ahrefsHistorySupported !== false;
      let attempt = build(withHistory);
      let { res, text } = await httpRequest('ahrefs', attempt, { headers });
      // Read the cost of this response NOW. On the fallback path it is discarded
      // below, and a discarded response's charge is still a charge.
      readAhrefsCostHeaders(res, state, withHistory ? 'history probe' : 'base columns');

      if (!res.ok && withHistory && (res.status === 400 || res.status === 422)) {
        warn(
          `ahrefs rejected the request including "${AHREFS_HISTORY_COLUMN}" with HTTP ${res.status}; ` +
            'retrying without it. Trend will be null for this provider. That extra probe call is ' +
            'counted in the ahrefs usage summary at the end of the run.',
        );
        state.ahrefsHistorySupported = false;
        persistAhrefsHistorySupport(state, false);
        attempt = build(false);
        ({ res, text } = await httpRequest('ahrefs', attempt, { headers }));
        readAhrefsCostHeaders(res, state, 'base columns after fallback');
      }

      if (!res.ok) {
        throw new Error(`ahrefs: HTTP ${res.status} ${res.statusText} — ${text.slice(0, 400) || '(empty body)'}`);
      }
      let json;
      try {
        json = JSON.parse(text);
      } catch {
        throw new Error(`ahrefs: HTTP ${res.status} but the body was not JSON — ${text.slice(0, 200)}`);
      }
      const rows = json && Array.isArray(json.keywords) ? json.keywords : null;
      if (!rows) {
        throw new Error(
          `ahrefs: HTTP ${res.status} but the response had no "keywords" array — got keys [${Object.keys(json || {}).join(', ')}]`,
        );
      }
      if (state.ahrefsHistorySupported === undefined) {
        state.ahrefsHistorySupported = true;
        persistAhrefsHistorySupport(state, true);
      }

      for (const item of rows) {
        if (!item || item.keyword == null) continue;
        const series = parseAhrefsHistory(item[AHREFS_HISTORY_COLUMN], item.keyword);
        const difficulty = toNum(item.difficulty);
        results.set(norm(item.keyword), {
          // `volume` is the 12-month average; volume_monthly is a single latest month
          // and is only used when the average is absent.
          volume:
            item.volume === null || item.volume === undefined
              ? item.volume_monthly === null || item.volume_monthly === undefined
                ? null
                : toInt(item.volume_monthly)
              : toInt(item.volume),
          trend: series ? deriveTrend(series.map((p) => p.volume)) : null,
          trend_series: series,
          // CPC units are not documented in the verified spec; passed through as-is.
          cpc: toNum(item.cpc),
          competition: difficulty === null ? null : Math.max(0, Math.min(1, difficulty / 100)),
        });
      }
    } catch (e) {
      state.failed = true;
      process.stderr.write(`${SCRIPT}: error: ${e.message}\n`);
      process.stderr.write(
        `${SCRIPT}: error: the above ahrefs chunk of ${batch.length} keyword(s) produced no data; ` +
          'those queries are emitted as NoData and the run continues.\n',
      );
    }
  }
  return results;
}

/* =========================================================================
 * Source: local CSV export  (--keywords <file>)
 * ========================================================================= */

const KEYWORD_HEADERS = [/^keyword$/i, /^keywords$/i, /^phrase$/i, /^ph$/i, /^query$/i, /^search term$/i, /keyword/i];
const VOLUME_HEADERS = [
  /^nq$/i,
  /^volume$/i,
  /^search volume$/i,
  /^avg\.?\s*monthly searches/i,
  /^monthly searches/i,
  /^searches$/i,
  /volume/i,
  /searches/i,
];
const CPC_HEADERS = [/^cp$/i, /^cpc$/i, /cost per click/i, /^top of page bid \(low range\)$/i, /top of page bid/i];
const COMP_HEADERS = [/^co$/i, /^competition$/i, /^competition \(indexed value\)$/i, /^difficulty$/i, /^kd$/i, /competition/i, /difficulty/i];

function findColumn(header, patterns) {
  for (const p of patterns) {
    const i = header.findIndex((h) => p.test(String(h).trim()));
    if (i >= 0) return i;
  }
  return -1;
}

function sniffDelimiter(text) {
  const head = text.split(/\r?\n/).slice(0, 25).join('\n');
  const counts = [
    ['\t', (head.match(/\t/g) || []).length],
    [';', (head.match(/;/g) || []).length],
    [',', (head.match(/,/g) || []).length],
  ];
  counts.sort((a, b) => b[1] - a[1]);
  return counts[0][1] > 0 ? counts[0][0] : ',';
}

function parseDelimited(text, delim) {
  const rows = [];
  let field = '';
  let row = [];
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += c;
      }
      continue;
    }
    if (c === '"') {
      inQuotes = true;
    } else if (c === delim) {
      row.push(field);
      field = '';
    } else if (c === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (c !== '\r') {
      field += c;
    }
  }
  if (field !== '' || row.length) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

/** "1.5K", "10,000", "1 000", "10K - 100K" -> number. Ranges take the low bound. */
function parseMagnitude(s) {
  const m = /^([0-9][0-9.,\s ]*?)\s*([kKmM])?$/.exec(String(s).trim());
  if (!m) return null;
  const base = Number(m[1].replace(/[,\s ]/g, ''));
  if (!Number.isFinite(base)) return null;
  const mult = m[2] ? (m[2].toLowerCase() === 'k' ? 1e3 : 1e6) : 1;
  return base * mult;
}

function parseVolumeCell(cell) {
  if (cell == null) return null;
  const t = String(cell).trim().replace(/[–—]|--/g, '-');
  if (!t) return null;
  const nums = t
    .split('-')
    .map((x) => x.trim())
    .filter(Boolean)
    .map(parseMagnitude)
    .filter((n) => n !== null);
  if (!nums.length) return null;
  // Keyword Planner buckets volume into ranges like "10K - 100K". The low bound is
  // the conservative read, so a range never overstates demand.
  return Math.round(Math.min(...nums));
}

function ingestCsv(file, country) {
  let text;
  try {
    text = decodeTextBuffer(fs.readFileSync(file));
  } catch (e) {
    fail(`cannot read --keywords file "${file}": ${e.message}`);
  }
  const delim = sniffDelimiter(text);
  const rows = parseDelimited(text, delim).filter((r) => r.some((c) => String(c).trim() !== ''));
  if (!rows.length) fail(`--keywords file "${file}" is empty`);

  // Keyword Planner exports begin with a few preamble lines before the real header.
  let headerIdx = -1;
  for (let i = 0; i < Math.min(rows.length, 12); i++) {
    const h = rows[i];
    if (findColumn(h, KEYWORD_HEADERS) >= 0 && findColumn(h, VOLUME_HEADERS) >= 0) {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx < 0) {
    fail(
      `could not find a header row with both a keyword column and a volume column in "${file}". ` +
        `Delimiter detected: ${JSON.stringify(delim)}. First row seen: ${JSON.stringify(rows[0].slice(0, 12))}`,
    );
  }
  const header = rows[headerIdx].map((h) => String(h).trim());
  const iKw = findColumn(header, KEYWORD_HEADERS);
  const iVol = findColumn(header, VOLUME_HEADERS);
  const iCpc = findColumn(header, CPC_HEADERS);
  const iCo = findColumn(header, COMP_HEADERS);

  info(
    `csv: delimiter ${JSON.stringify(delim)}, header at non-blank row ${headerIdx + 1}, ` +
      `keyword="${header[iKw]}", volume="${header[iVol]}"` +
      `${iCpc >= 0 ? `, cpc="${header[iCpc]}"` : ''}${iCo >= 0 ? `, competition="${header[iCo]}"` : ''}`,
  );

  const map = new Map();
  for (const r of rows.slice(headerIdx + 1)) {
    const kw = r[iKw];
    if (kw == null || String(kw).trim() === '') continue;
    let competition = toNum(iCo >= 0 ? r[iCo] : null);
    if (competition !== null && competition > 1) competition = competition / 100;
    map.set(norm(kw), {
      volume: parseVolumeCell(r[iVol]),
      trend: null,
      trend_series: null,
      cpc: toNum(iCpc >= 0 ? r[iCpc] : null),
      competition,
    });
  }
  info(`csv: ${map.size} keyword row(s) loaded from ${file} (country reported as ${country})`);
  return map;
}

/* =========================================================================
 * Main
 * ========================================================================= */

async function main() {
  const opts = parseArgs(process.argv.slice(2));

  if (opts.help) {
    process.stdout.write(HELP);
    return 0;
  }
  if (opts.checkKeys) {
    return checkKeys();
  }
  if (!opts.queries) {
    process.stderr.write(`${SCRIPT}: error: --queries <file|-> is required (or use --check-keys / --help)\n`);
    return 1;
  }
  if (!opts.country || !/^[a-z0-9_-]{2,16}$/.test(opts.country)) {
    fail(`--country "${opts.country}" does not look like a market code`);
  }

  const provider = resolveProvider(opts);
  if (opts.provider && opts.keywords) {
    warn(`--provider ${opts.provider} takes precedence over --keywords; the CSV file will not be read.`);
  }

  const queries = readQueries(opts.queries);
  if (!queries.length) fail('no queries found after ignoring blank and # lines');

  // The Ahrefs history-support verdict is loaded from disk, not just from this
  // process, so a provider that genuinely rejects the column is not re-probed (and
  // re-charged) on every single invocation. --no-cache bypasses row reads only; the
  // verdict is a capability fact about the API, not keyword data, so it still applies.
  const ahrefsHistoryLoaded = provider === 'ahrefs' ? loadAhrefsHistorySupport() : undefined;

  // Sandbox rows are fixtures, not measurements. They get their own source string and
  // their own confidence value so that a piped or re-read row can never be mistaken
  // for real data, and they are never cached, because caching a fixture under a real
  // provider key would poison every later live run.
  const sourceLabel = opts.sandbox ? SANDBOX_SOURCE : provider;
  const dataConfidence = opts.sandbox ? 'Sandbox' : 'Data';

  const state = {
    sandbox: opts.sandbox,
    failed: false,
    dfsCost: 0,
    semrushLines: 0,
    ahrefsHeaders: [],
    ahrefsHistorySupported: ahrefsHistoryLoaded,
    ahrefsHistoryLoaded,
    ahrefsHistoryPersisted: false,
  };

  /* ---- cache read ------------------------------------------------------- */
  const cacheable = provider !== 'csv' && !opts.sandbox;
  const store = cacheable ? loadCache() : {};
  const fromCache = new Map();
  const toFetch = [];
  for (const q of queries) {
    if (!cacheable || opts.noCache) {
      toFetch.push(q);
      continue;
    }
    const entry = store[cacheKey(provider, opts.country, q)];
    if (cacheIsFresh(entry, provider)) fromCache.set(norm(q), entry);
    else toFetch.push(q);
  }
  if (fromCache.size) info(`cache: ${fromCache.size} of ${queries.length} query/queries served from ${CACHE_FILE}`);
  if (opts.noCache && cacheable) info('cache: reads bypassed by --no-cache; fresh results will still be written');

  /* ---- cost preflight --------------------------------------------------- */
  costPreflight(provider, queries, toFetch.length, opts, state);

  /* ---- fetch ------------------------------------------------------------ */
  let fetched = new Map();
  if (provider === 'csv') {
    fetched = ingestCsv(opts.keywords, opts.country);
  } else if (toFetch.length) {
    if (provider === 'dataforseo') fetched = await fetchDataForSEO(toFetch, opts.country, state);
    else if (provider === 'semrush') fetched = await fetchSemrush(toFetch, opts.country, state);
    else if (provider === 'ahrefs') fetched = await fetchAhrefs(toFetch, opts.country, state);
  }

  /* ---- assemble output, one record per query, input order --------------- */
  const rows = [];
  const writes = [];
  for (const q of queries) {
    const k = norm(q);
    const cached = fromCache.get(k);
    if (cached) {
      rows.push({ ...cached.payload, query: q, fetched: cached.fetched });
      continue;
    }
    // Looked up by the normalized query, never by position, so a provider row that
    // matches no request is simply never read and a request with no row is NoData.
    const hit = fetched.get(k);
    if (!hit) {
      rows.push(noDataRow(q, sourceLabel, opts.country));
      continue;
    }
    const row = makeRow({
      query: q,
      volume: hit.volume,
      trend: hit.trend ?? null,
      trend_series: hit.trend_series ?? null,
      cpc: hit.cpc ?? null,
      competition: hit.competition ?? null,
      source: sourceLabel,
      confidence: dataConfidence,
      country: opts.country,
    });
    rows.push(row);
    if (cacheable) writes.push([cacheKey(provider, opts.country, q), row]);
  }

  /* ---- cache write (always, even with --no-cache) ----------------------- */
  if (cacheable && writes.length) {
    // Always re-read from disk rather than reusing the snapshot taken before the
    // fetch. The fetch itself can write to the cache (the Ahrefs history verdict),
    // and another run may have written rows meanwhile; reusing the stale snapshot
    // would silently clobber both.
    const fresh = loadCache();
    for (const [key, row] of writes) fresh[key] = { fetched: row.fetched, payload: row };
    saveCache(fresh);
    info(`cache: wrote ${writes.length} row(s) to ${CACHE_FILE}`);
  }

  /* ---- emit ------------------------------------------------------------- */
  if (opts.json) {
    process.stdout.write(`${JSON.stringify(rows, null, 2)}\n`);
  } else {
    for (const r of rows) process.stdout.write(`${JSON.stringify(r)}\n`);
  }

  /* ---- actual cost reporting ------------------------------------------- */
  if (provider === 'dataforseo' && state.dfsCost > 0) {
    info(
      `actual ${sourceLabel} cost reported by the API: $${state.dfsCost.toFixed(4)}` +
        (opts.sandbox ? ' (sandbox; a non-zero figure here is fixture data too)' : ''),
    );
  }
  if (provider === 'semrush' && state.semrushLines > 0) {
    info(
      `actual semrush usage: ${state.semrushLines} line(s) returned = ${state.semrushLines * 10} API units. ` +
        'The USD value of a Semrush API unit is not published, so no USD figure is given.',
    );
  }
  if (provider === 'ahrefs' && state.ahrefsHeaders.length) {
    const sum = (field) =>
      state.ahrefsHeaders.reduce((acc, h) => {
        const n = toNum(h[field]);
        return n === null ? acc : acc + n;
      }, 0);
    info(
      `actual ahrefs usage across ${state.ahrefsHeaders.length} call(s): ` +
        `units-cost-total-actual=${sum('actual')} units-cost-total=${sum('total')} rows=${sum('rows')}. ` +
        'Ahrefs does not publish a USD price per unit, so no USD figure is given.',
    );
  }

  const count = (c) => rows.filter((r) => r.confidence === c).length;
  info(
    `done: ${rows.length} record(s), ${count(dataConfidence)} ${dataConfidence}, ` +
      `${count('NoData')} NoData, source ${sourceLabel}`,
  );

  // Repeated after the rows so the warning cannot scroll out of sight above them.
  if (opts.sandbox) writeSandboxBanner();

  return state.failed ? 5 : 0;
}

main()
  .then((code) => process.exit(code))
  .catch((e) => {
    process.stderr.write(`${SCRIPT}: fatal: ${e && e.stack ? e.stack : e}\n`);
    process.exit(1);
  });
