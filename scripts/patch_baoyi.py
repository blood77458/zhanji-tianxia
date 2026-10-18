"""把 ChapterMapScene 里被注释掉的「爆衣」代码放开，产出一个改过的 lua。

格式（实测）：IV(16) || AES-128-CBC(PKCS#7(正文))，正文可能是 zlib 压缩流。
输出：
  work/patch_out/ChapterMapScene.lua          明文（便于 diff / 复查）
  work/patch_out/ChapterMapScene.enc.lua      加密后（可直接放 Caches/src）
  work/patch_out/INFO.txt                     旧/新文件名、md5、大小
"""
import hashlib
import os
import re
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import pad, unpad         # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
APK = r'E:\deepseek_projects\app_server\client\zjt_pack_enablefix_signed.apk'
OUT = r'E:\deepseek_projects\app_server\work\patch_out'
TARGET = 'assets/src/canon/scene/'


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    zipped = False
    if pt[:1] == b'\x78':                      # zlib magic
        try:
            pt = zlib.decompress(pt)
            zipped = True
        except Exception:
            pass
    return pt, zipped


def encrypt(pt, zipped):
    if zipped:
        pt = zlib.compress(pt, 9)
    iv = os.urandom(16)
    return iv + AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(pt, 16))


def main():
    os.makedirs(OUT, exist_ok=True)
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith(TARGET) and n.split('/')[-1].startswith('ChapterMapScene.')]
    if not entry:
        print('!! APK 里找不到 ChapterMapScene'); return 1
    entry = entry[0]
    blob = z.read(entry)
    pt, zipped = decrypt(blob)
    src = pt.decode('utf-8', 'replace')
    print('文件: %s' % entry)
    print('解密: %d 字节, zlib=%s' % (len(pt), zipped))

    # 找包住 Cardbattle_blood 的那段 --[[ ... ]]
    i = src.find('Cardbattle_blood')
    if i < 0:
        print('!! 没找到 Cardbattle_blood'); return 1
    open_at = src.rfind('--[[', 0, i)
    close_at = src.find(']]', i)
    if open_at < 0 or close_at < 0:
        print('!! 找不到注释边界'); return 1
    close_at += 2
    block = src[open_at:close_at]
    print('注释块: 偏移 %d..%d, %d 字节, 含 %d 行'
          % (open_at, close_at, len(block), block.count('\n')))

    new_block = block.replace('--[[', '', 1)
    new_block = new_block[:new_block.rfind(']]')]          # 去掉收尾 ]]
    # 原代码是按行注释里带缩进的，去掉每行开头多出来的一个空格保持缩进正常
    patched = src[:open_at] + new_block + src[close_at:]

    name = os.path.basename(entry)
    old_md5 = name.split('.')[-2]
    enc = encrypt(patched.encode('utf-8'), zipped)
    new_md5 = hashlib.md5(enc).hexdigest()
    new_name = 'ChapterMapScene.%s.lua' % new_md5

    open(os.path.join(OUT, 'ChapterMapScene.lua'), 'wb').write(patched.encode('utf-8'))
    open(os.path.join(OUT, 'ChapterMapScene.enc.lua'), 'wb').write(enc)
    info = ('old_name=%s\nold_md5=%s\nnew_name=%s\nnew_md5=%s\nenc_size=%d\nzipped=%s\n'
            % (name, old_md5, new_name, new_md5, len(enc), zipped))
    open(os.path.join(OUT, 'INFO.txt'), 'w', encoding='utf-8').write(info)
    print(info)
    # 便于人眼确认补丁只动了这一块
    open(os.path.join(OUT, 'block_after.txt'), 'w', encoding='utf-8').write(new_block)
    return 0


if __name__ == '__main__':
    sys.exit(main())
