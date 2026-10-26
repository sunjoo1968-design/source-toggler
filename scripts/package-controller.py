"""Package the matching OBS32/33 Controller, SunjooAn."""
from pathlib import Path
import argparse,re,shutil,zipfile,hashlib,json
root=Path(__file__).resolve().parents[1]
a=argparse.ArgumentParser();a.add_argument('--obs-major',choices=['32','33'],required=True);args=a.parse_args()
major=args.obs_major
lua=root/'scripts/camera-mix-hybrid.lua';version=re.search("local VERSION, AUTHOR = '([^']+)'",lua.read_text(encoding='utf-8'))[1]
dll=root/('.local/hybrid/build/Release/camera-mix-hybrid.dll' if major=='32' else '.local/obs33/controller-build/Release/camera-mix-hybrid.dll')
stage=root/'release'/f'controller-{version}-obs{major}'
def copy(src,dst):
 p=stage/dst;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/src,p)
module='camera-mix-hybrid'
binpath=f'obs-plugins/64bit/{module}.dll' if major=='32' else f'plugins/{module}/{module}.dll'
datapath=f'data/obs-plugins/{module}' if major=='32' else f'plugins/{module}/data'
copy(dll.relative_to(root),binpath)
copy(lua.relative_to(root),'scripts/camera-mix-hybrid.lua')
copy(lua.relative_to(root),'source/scripts/camera-mix-hybrid.lua')
for name in ['output.cpp','CMakeLists.txt','LICENSE']:
 copy('native/camera-mix-hybrid/'+name,'source/native/camera-mix-hybrid/'+name)
for name in ['LICENSE-OBS','LICENSE-source-switcher']:
 copy('vendor/'+name,'licenses/'+name)
copy('docs/CONTROLLER-UI-20261026.md','README.md')
copy('docs/CONTROLLER-UI-20261026.md','VALIDATION.md')
p=stage/datapath;p.mkdir(parents=True,exist_ok=True)
(p/'manifest.json').write_text(json.dumps(dict(name=module,id='com.sunjoo.obs-link.'+module,display_name='Sunjoo OBS Link Controller',version=version,os_arch='windows-x64',description='SunjooAn / OBS '+major,urls={})),encoding='utf-8')
files=sorted(p for p in stage.rglob('*') if p.is_file() and p.name!='SHA256SUMS.txt')
for p in files:
 assert not any(x in p.relative_to(stage).as_posix().lower() for x in ['.local/','node_modules','local-resume','layout.json','config.json'])
(stage/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(stage).as_posix()+'\n' for p in files),encoding='utf-8')
out=root/'release'/f'sunjoo-obs-link-controller-{version}-obs{major}-windows-x64.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in stage.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(stage).as_posix())
with zipfile.ZipFile(out) as z:
 for line in z.read('SHA256SUMS.txt').decode().splitlines():
  expected,name=line.split('  ',1);assert hashlib.sha256(z.read(name)).hexdigest()==expected
 assert version.encode() in z.read('README.md') and version.encode() in z.read('scripts/camera-mix-hybrid.lua')
print(str(out),hashlib.sha256(out.read_bytes()).hexdigest())
