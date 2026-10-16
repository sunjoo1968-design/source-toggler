"""Package the GPL Source Switcher OBS33 unofficial rebuild, SunjooAn."""
from pathlib import Path
import json,shutil,hashlib,zipfile
root=Path(__file__).resolve().parents[1]
source=root/'native/source-switcher-obs33'
spec=json.loads((source/'buildspec.json').read_text(encoding='utf-8'))
v=spec['version'];stage=root/'release'/('source-switcher-'+v)
data=stage/'plugins/source-switcher/data'
data.mkdir(parents=True,exist_ok=True)
shutil.copytree(source/'data',data,dirs_exist_ok=True)
shutil.copy2(root/'.local/obs33/source-switcher-build/Release/source-switcher.dll',data.parent/'source-switcher.dll')
(data/'manifest.json').write_text(json.dumps(dict(name='source-switcher',id='com.sunjoo.obs-link.source-switcher',display_name='Source Switcher — OBS33 rebuild (unofficial)',version=v,os_arch='windows-x64',description='Original Exeldro; OBS33 rebuild SunjooAn',urls={'repository':'https://github.com/sunjoo1968-design/source-toggler','website':spec['upstream']})),encoding='utf-8')
shutil.copytree(source,stage/'source',dirs_exist_ok=True)
shutil.copy2(source/'REBUILD.md',stage/'README.md')
shutil.copy2(source/'LICENSE',stage/'LICENSE')
shutil.copy2(root/'vendor/LICENSE-OBS',stage/'LICENSE-OBS')
files=sorted(p for p in stage.rglob('*') if p.is_file() and p.name!='SHA256SUMS.txt')
(stage/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(stage).as_posix()+'\n' for p in files),encoding='utf-8')
output=root/'release'/f'source-switcher-{v}-windows-x64.zip'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
 for p in stage.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(stage).as_posix())
with zipfile.ZipFile(output) as z:
 for line in z.read('SHA256SUMS.txt').decode().splitlines():
  digest,name=line.split('  ',1);assert hashlib.sha256(z.read(name)).hexdigest()==digest
print(output,hashlib.sha256(output.read_bytes()).hexdigest())
