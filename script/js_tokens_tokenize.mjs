import { readFileSync } from 'node:fs';
import jsTokens from 'js-tokens';

const code = readFileSync(0, 'utf8');
const tokens = [];
let byteOffset = 0;

for (const token of jsTokens(code)) {
  const start = byteOffset;
  byteOffset += Buffer.byteLength(token.value, 'utf8');

  if (
    token.type !== 'WhiteSpace' &&
    token.type !== 'LineTerminatorSequence' &&
    token.type !== 'SingleLineComment' &&
    token.type !== 'MultiLineComment' &&
    token.type !== 'HashbangComment'
  ) {
    tokens.push({ value: token.value, start, end: byteOffset });
  }
}

process.stdout.write(JSON.stringify(tokens));
