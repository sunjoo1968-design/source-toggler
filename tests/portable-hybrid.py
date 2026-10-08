"""Run only our separate portable OBS: real Lua setup, restart, and normal shutdown."""
from pathlib import Path
import json, subprocess, time, sys
root=Path(__file__).resolve().parents[1]
sandbox=root/'.local/hybrid/obs-shutdown-sandbox'
exe=sandbox/'bin/64bit/obs64.exe'
assert exe.exists(), 'Prepare isolated OBS test runtime first'
cfg=sandbox/'config/obs-studio'
def put(name,content):
    p=cfg/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content,encoding='utf-8')
driver=root/'.local/hybrid/lua-integration.lua'
driver.write_text((root/'scripts/camera-mix-hybrid.lua').read_text(encoding='utf-8')+'\n'+(root/'tests/fixtures/hybrid-smoke.lua').read_text(encoding='utf-8-sig'),encoding='utf-8')
ini='[General]\nFirstRun=true\nLanguage=en-US\n[Basic]\nProfile=HybridTest\nProfileDir=HybridTest\nSceneCollection=HybridTest\nSceneCollectionFile=HybridTest\n[BasicWindow]\nWarnBeforeExit=false\nPreviewEnabled=true\nSceneDuplicationMode=true\nEditPropertiesMode=true\n'
put('global.ini',ini);put('user.ini',ini)
put('basic/profiles/HybridTest/basic.ini','[General]\nName=HybridTest\n[Video]\nBaseCX=1280\nBaseCY=720\nOutputCX=1280\nOutputCY=720\nFPSCommon=30\n[Output]\nMode=Simple\n')
put('plugin_config/obs-websocket/config.json',json.dumps({'first_load':False,'server_enabled':False,'alerts_enabled':False}))
sources=[]
for i in (1,2):
    sources.append({'name':f'Test Camera {i}','id':'color_source_v3','versioned_id':'color_source_v3','settings':{'width':1280,'height':720,'color':0xff3030dd if i==1 else 0xffdd3030}})
    sources.append({'name':f'Test Scene {i}','id':'scene','settings':{'items':[{'name':f'Test Camera {i}','id':i,'visible':True,'pos':{'x':0,'y':0},'scale':{'x':1,'y':1},'rot':0,'align':5}]}})
put('basic/scenes/HybridTest.json',json.dumps({'name':'HybridTest','current_scene':'Test Scene 1','current_program_scene':'Test Scene 1','scene_order':[{'name':'Test Scene 1'},{'name':'Test Scene 2'}],'sources':sources,'transition_duration':300,'modules':{'scripts-tool':[{'path':str(driver).replace('\\','/'),'settings':{}}]}}))
for cycle,expected in ((1,'CREATED'),(2,'RESTORED')):
    marker=driver.parent/'lua-smoke-ok.txt';marker.unlink(missing_ok=True)
    child=subprocess.Popen([str(exe),'--portable','--multi','--disable-updater','--disable-missing-files-check','--profile','HybridTest','--collection','HybridTest'],cwd=exe.parent,creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        for _ in range(150):
            if marker.exists():break
            assert child.poll() is None, 'Test OBS exited before Lua completed'
            time.sleep(.2)
        assert marker.exists(), 'Lua smoke timed out; inspect isolated OBS log'
        assert marker.read_text()==expected
        closed=subprocess.run([sys.executable,str(root/'tests/close-hybrid-obs.py'),str(child.pid),str(exe)],capture_output=True,text=True)
        assert closed.returncode==0,closed.stderr
        assert child.wait(timeout=20)==0,'Test OBS crashed on normal exit'
        print(f'PASS portable OBS {cycle}: {expected}, normal shutdown exit=0',flush=True)
    finally:
        if child.poll() is None:
            subprocess.run([sys.executable,str(root/'tests/close-hybrid-obs.py'),str(child.pid),str(exe)],capture_output=True)
            try:child.wait(timeout=10)
            except subprocess.TimeoutExpired:child.terminate();child.wait(timeout=10)
logs=sorted((cfg/'logs').glob('*.txt'),key=lambda p:p.stat().st_mtime)[-2:]
for log in logs:
    text=log.read_text(encoding='utf-8-sig')
    assert 'Error calling' not in text and 'Double destroy' not in text, log
print('PASS actual frontend Lua setup and restart; no Lua errors or double destroy',flush=True)
