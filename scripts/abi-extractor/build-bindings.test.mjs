import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
test('binding build fails closed and runs extraction before generation', () => {
 const text=readFileSync(new URL('./build-bindings.sh',import.meta.url),'utf8');
 assert.match(text,/set -euo pipefail/);
 assert.ok(text.indexOf('extract.sh') < text.indexOf('generate-types.js'));
 assert.match(text,/No ABIs extracted/);
});
