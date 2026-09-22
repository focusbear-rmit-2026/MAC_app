import { build } from 'esbuild';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const result = await build({ entryPoints: ['src/editor.js'], bundle: true, format: 'iife',
  platform: 'browser', target: ['safari14'], minify: true, legalComments: 'inline', write: false, metafile: true,
  define: { 'process.env.NODE_ENV': '"production"' } });
const bundle = result.outputFiles[0].text;
const destination = 'Resources/ProjectNoteEditorWeb/editor.bundle.js';
const packages = new Map();
for (const input of Object.keys(result.metafile.inputs).filter(name => name.startsWith('node_modules/'))) {
  let directory = path.dirname(input);
  while (directory !== '.') {
    try {
      const manifest = JSON.parse(await readFile(path.join(directory, 'package.json'), 'utf8'));
      if (manifest.name && manifest.version) { packages.set(manifest.name, { directory, manifest }); break; }
    } catch {}
    directory = path.dirname(directory);
  }
}
let licenses = 'Third-party packages included in the Focus Bear project-note editor\n\n';
for (const [name, { directory, manifest }] of [...packages].sort(([a], [b]) => a.localeCompare(b))) {
  let license;
  for (const filename of ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'license', 'license.md', 'license.txt', 'COPYING']) {
    try { license = await readFile(path.join(directory, filename), 'utf8'); break; } catch {}
  }
  if (!license && name.startsWith('@tiptap/')) license = await readFile('licenses/tiptap.txt', 'utf8');
  if (!license) throw new Error(`Missing license for ${name}`);
  licenses += `${name}@${manifest.version}\n${'='.repeat(60)}\n${license.trim()}\n\n`;
}
const licenseDestination = 'Resources/ProjectNoteEditorWeb/THIRD-PARTY-LICENSES.txt';
licenses = `${licenses.trimEnd()}\n`;
if (process.argv.includes('--check')) {
  if (await readFile(destination, 'utf8') !== bundle) throw new Error('Checked-in editor bundle differs from pinned sources');
  if (await readFile(licenseDestination, 'utf8') !== licenses) throw new Error('Checked-in licenses differ from bundled packages');
} else { await writeFile(destination, bundle); await writeFile(licenseDestination, licenses); }
