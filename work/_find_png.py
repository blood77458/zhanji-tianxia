import os
root=r'E:\deepseek_projects\app_server\work\decoded\assets\resource\card'
real=[]
hqce=0
for dirpath,_,files in os.walk(root):
  for f in files:
    if not (f.endswith('.png') or f.endswith('.temp') or 'sdandard' in f or 'full' in f):
      continue
    p=os.path.join(dirpath,f)
    try:
      b=open(p,'rb').read(8)
    except: continue
    if b[:4]==b'\x89PNG':
      real.append(p)
    elif b[:4]==b'HQCE':
      hqce+=1
print('real png',len(real),'hqce',hqce)
for p in real[:40]:
  print(p.replace(root+'\\',''))
