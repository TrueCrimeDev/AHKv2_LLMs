import { cp, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const dist = join(root, 'dist');
const client = join(dist, 'client');
const server = join(dist, 'server');

const rootExtensions = new Set(['.html', '.css', '.js', '.svg']);
const sourceDirectories = ['cloudahk', 'examples', 'posts', 'prompts', 'wiki'];
const rootEntries = await readdir(root, { withFileTypes: true });

await rm(dist, { recursive: true, force: true });
await mkdir(client, { recursive: true });
await mkdir(server, { recursive: true });

for (const entry of rootEntries) {
  if (!entry.isFile()) continue;
  const extension = entry.name.slice(entry.name.lastIndexOf('.'));
  if (!rootExtensions.has(extension)) continue;
  await cp(join(root, entry.name), join(client, entry.name));
}

for (const directory of sourceDirectories) {
  await cp(join(root, directory), join(client, directory), { recursive: true });
}

await mkdir(join(client, 'scripts'), { recursive: true });
await cp(join(root, 'scripts', 'ahk-scripts.json'), join(client, 'scripts', 'ahk-scripts.json'), {
  recursive: true,
});

try {
  await cp(join(root, 'public'), client, { recursive: true });
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}

const sourceOrigin = 'https://truecrimedev.github.io/AHKv2_LLMs';
const builtHomepagePath = join(client, 'index.html');
const builtHomepage = (await readFile(builtHomepagePath, 'utf8'))
  .replaceAll(`${sourceOrigin}/public/og.png`, '__SITE_ORIGIN__/og.png')
  .replaceAll(sourceOrigin, '__SITE_ORIGIN__');
await writeFile(builtHomepagePath, builtHomepage, 'utf8');

const htmlAssetHash = createHash('sha256').update(await readFile(join(root, 'style.css')));
for (const htmlFile of rootEntries.filter(entry => entry.isFile() && entry.name.endsWith('.html')).map(entry => entry.name).sort()) {
  htmlAssetHash.update(await readFile(join(root, htmlFile)));
}
const htmlAssetVersion = htmlAssetHash.digest('hex').slice(0, 12);

const workerSource = `
const HTML_ASSET_VERSION = '${htmlAssetVersion}';

const worker = {
  async fetch(request, env) {
    const url = new URL(request.url);
    let assetRequest = request;
    const lastSegment = url.pathname.split('/').pop() || '';

    if (url.pathname !== '/' && !lastSegment.includes('.')) {
      const assetUrl = new URL(url);
      assetUrl.pathname = url.pathname + '.html';
      assetUrl.searchParams.set('__asset_version', HTML_ASSET_VERSION);
      assetRequest = new Request(assetUrl, { headers: request.headers });
    }

    let response = await env.ASSETS.fetch(assetRequest);

    if (response.status === 404 && url.pathname.endsWith('/')) {
      const indexUrl = new URL('index.html', url);
      indexUrl.searchParams.set('__asset_version', HTML_ASSET_VERSION);
      response = await env.ASSETS.fetch(new Request(indexUrl, { headers: request.headers }));
    }

    const contentType = response.headers.get('content-type') || '';
    if (response.ok && contentType.includes('text/html')) {
      const html = (await response.text()).replaceAll('__SITE_ORIGIN__', url.origin);
      const headers = new Headers(response.headers);
      headers.delete('content-length');
      return new Response(html, { status: response.status, statusText: response.statusText, headers });
    }

    return response;
  },
};

export default worker;
`;

await writeFile(join(server, 'index.js'), workerSource.trimStart(), 'utf8');

const manifest = JSON.parse(await readFile(join(root, 'posts', 'posts.json'), 'utf8'));
const board = JSON.parse(await readFile(join(root, 'posts', 'ahk-eval', 'board.json'), 'utf8'));
console.log(`Built AHK Benchmarks: ${manifest.length} posts, ${board.rows.length} leaderboard entries.`);
