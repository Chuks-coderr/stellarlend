import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
test('reports modified and added wasm without false positives', () => {
 const root=mkdtempSync(join(tmpdir(),'wasm-diff-'));const a=join(root,'a'),b=join(root,'b');mkdirSync(a);mkdirSync(b);
 writeFileSync(join(a,'same.wasm'),'same');writeFileSync(join(b,'same.wasm'),'same');
 writeFileSync(join(a,'changed.wasm'),'old');writeFileSync(join(b,'changed.wasm'),'new');
 writeFileSync(join(b,'added.wasm'),'added');
 const result=spawnSync(process.execPath,[new URL('./compare.mjs',import.meta.url).pathname,a,b],{encoding:'utf8'});
 assert.equal(result.status,0,result.stderr);assert.match(result.stdout,/changed.wasm \| modified/);assert.match(result.stdout,/added.wasm \| added/);assert.match(result.stdout,/same.wasm \| unchanged/);
});
