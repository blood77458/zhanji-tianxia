#!/usr/bin/env node
/**
 * 解密 APK 内 assets/src/**.lua
 * 格式: IV(16) || AES-128-CBC( PKCS#7( zlib(luasrc) ) )
 * 密钥来源于运行时 .bss (见 ARCHITECTURE.md §3)
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');

const KEY = Buffer.from('e9747d92cc322e7d112e7c3451d7b36a', 'hex');
const SRC = process.argv[2] || path.join(__dirname, '..', 'apk_extract', 'assets', 'src');
const DST = process.argv[3] || path.join(__dirname, '..', 'apk_luasrc');

function decrypt(blob) {
  const iv = blob.subarray(0, 16);
  const ct = blob.subarray(16);
  const d = crypto.createDecipheriv('aes-128-cbc', KEY, iv);
  d.setAutoPadding(false);
  let out = Buffer.concat([d.update(ct), d.final()]);
  // 手动去 PKCS#7 填充
  const pad = out[out.length - 1];
  if (pad >= 1 && pad <= 16 && pad <= out.length) out = out.subarray(0, out.length - pad);
  try { return zlib.inflateSync(out); } catch (e) { return out; }
}

let ok = 0, fail = 0;
const failures = [];
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { walk(p); continue; }
    if (!e.name.endsWith('.lua')) continue;
    const rel = path.relative(SRC, p);
    const out = path.join(DST, rel);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    try {
      const pt = decrypt(fs.readFileSync(p));
      fs.writeFileSync(out, pt);
      ok++;
    } catch (err) {
      fail++;
      failures.push(rel + ' -> ' + err.message);
      fs.copyFileSync(p, out);
    }
  }
}
walk(SRC);
console.log('decrypted ok=' + ok + ' fail=' + fail);
failures.slice(0, 10).forEach(f => console.log('  ' + f));
