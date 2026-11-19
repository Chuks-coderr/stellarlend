#!/usr/bin/env node
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
const [base, head] = process.argv.slice(2);
if (!base || !head) { console.error('Usage: compare.mjs <base-dir> <head-dir>'); process.exit(2); }
const list = (dir) => readdirSync(dir).filter(n => n.endsWith('.wasm')).sort();
const oldFiles = new Set(list(base)), newFiles = new Set(list(head));
const all = [...new Set([...oldFiles, ...newFiles])].sort();
if (!all.length) { console.error('No WASM artifacts found'); process.exit(1); }
const sha = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');
console.log('| Contract | Change | Base bytes | PR bytes | SHA-256 changed |');
console.log('| --- | --- | ---: | ---: | --- |');
for (const file of all) {
  const before = oldFiles.has(file) ? readFileSync(join(base, file)) : null;
  const after = newFiles.has(file) ? readFileSync(join(head, file)) : null;
  const kind = !before ? 'added' : !after ? 'removed' : before.equals(after) ? 'unchanged' : 'modified';
  console.log(`| ${file} | ${kind} | ${before?.length ?? '-'} | ${after?.length ?? '-'} | ${before && after ? (sha(join(base,file)) !== sha(join(head,file))) : 'n/a'} |`);
}
