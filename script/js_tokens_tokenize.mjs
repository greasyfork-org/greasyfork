import { readFileSync } from 'node:fs';
import jsTokens from 'js-tokens';

const code = readFileSync(0, 'utf8');
const tokens = [];

for (const token of jsTokens(code)) {
  if (
    token.type !== 'WhiteSpace' &&
    token.type !== 'LineTerminatorSequence' &&
    token.type !== 'SingleLineComment' &&
    token.type !== 'MultiLineComment' &&
    token.type !== 'HashbangComment'
  ) {
    tokens.push(token.value);
  }
}

process.stdout.write(JSON.stringify(tokens));
