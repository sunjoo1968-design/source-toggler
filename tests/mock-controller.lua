local sources, buttons, keys, messages = {}, {}, {}, {}
local clock, selections, timer = 0, {}, nil
local data_refs, source_refs = 0, 0
local bindings, registrations = {}, {}
obslua = {
    LOG_WARNING=1, LOG_INFO=2, OBS_TRANSITION_SCALE_ASPECT=1,
    OBS_TEXT_DEFAULT=0, OBS_EDITABLE_LIST_TYPE_STRINGS=0,
    OBS_COMBO_TYPE_LIST=0, OBS_COMBO_FORMAT_STRING=0, OBS_COMBO_FORMAT_INT=1, OBS_GROUP_NORMAL=0
}
local o = obslua
function o.os_gettime_ns() return clock*1000000 end
function o.script_log(_, message) table.insert(messages,message) end
function o.obs_data_create() data_refs=data_refs+1; return {} end
function o.obs_data_addref(_) data_refs=data_refs+1 end
function o.obs_data_release(_) data_refs=data_refs-1 end
function o.obs_data_array_create() data_refs=data_refs+1; return {} end
function o.obs_data_array_release(_) data_refs=data_refs-1 end
function o.obs_data_array_count(a) return #a end
function o.obs_data_array_item(a,i) data_refs=data_refs+1; return a[i+1] end
function o.obs_data_array_push_back(a,v) table.insert(a,v) end
function o.obs_data_get_array(s,k) data_refs=data_refs+1; return s[k] or {} end
function o.obs_data_set_array(s,k,a) s[k]=a end
function o.obs_data_get_string(s,k) return s[k] or "" end
function o.obs_data_get_int(s,k) return s[k] or 0 end
function o.obs_data_get_bool(s,k) assert(s,debug.traceback()); return s[k] == true end
function o.obs_data_set_string(s,k,v) s[k]=v end
o.obs_data_set_int=o.obs_data_set_string
o.obs_data_set_bool=o.obs_data_set_string
o.obs_data_get_double=o.obs_data_get_int
o.obs_data_set_double=o.obs_data_set_string
function o.obs_data_set_default_string(s,k,v) if s[k]==nil then s[k]=v end end
o.obs_data_set_default_int=o.obs_data_set_default_string
o.obs_data_set_default_bool=o.obs_data_set_default_string
function o.obs_get_source_by_name(n)
    if sources[n] then source_refs=source_refs+1; sources[n].refs=(sources[n].refs or 1)+1 end
    return sources[n]
end
function o.obs_source_get_ref(s) source_refs=source_refs+1; s.refs=s.refs+1; return s end
function o.obs_source_release(s)
    source_refs=source_refs-1
    s.refs=s.refs-1
    if s.refs==0 then sources[s.name]=nil end
end
function o.obs_source_get_name(s) return s.name end
function o.obs_source_set_name(s,name) sources[s.name]=nil; s.name=name; sources[name]=s end
function o.obs_enum_sources() local list={}; for _,s in pairs(sources) do if not s.scene then list[#list+1]=s end end; return list end
function o.obs_frontend_get_scenes() local list={}; for _,s in pairs(sources) do if s.scene then list[#list+1]=s end end; return list end
function o.source_list_release(_) end
function o.obs_source_get_unversioned_id(s) return s.id=='color_source_v3' and 'color_source' or s.id end
function o.obs_source_get_settings(s) data_refs=data_refs+1; s.settings=s.settings or {}; return s.settings end
function o.obs_source_update(s,v) s.settings=v end
function o.obs_source_create(id,name,settings)
    local s={name=name,id=id,settings=settings,time=0,refs=1}
    sources[name]=s; source_refs=source_refs+1; return s
end
function o.obs_source_create_private(id,name,settings)
    source_refs=source_refs+1; return {name=name,id=id,settings=settings,refs=1,private=true,enabled=true}
end
function o.obs_source_filter_add(s,f) s.filter_list=s.filter_list or {}; s.filter_list[#s.filter_list+1]=f; f.refs=f.refs+1 end
function o.obs_source_get_filter_by_name(s,name)
    for _,f in ipairs(s.filter_list or {}) do if f.name==name then return o.obs_source_get_ref(f) end end
end
function o.obs_source_set_enabled(s,value) s.enabled=value end
function o.obs_source_enabled(s) return s.enabled~=false end
function o.obs_source_media_get_time(s) return s.time end
function o.obs_source_media_set_time(s,v)
    s.time=v
    table.insert(selections,{time=clock,index=v/1000,mode=s.settings.transition,source=s.name})
end
function o.obs_scene_from_source(s) return s.scene end
function o.obs_group_from_source(s) return s.group end
local preview, program='initial-preview','initial-program'
function o.obs_frontend_preview_program_mode_active() return true end
function o.obs_frontend_set_current_preview_scene(s) preview=s.name end
function o.obs_sceneitem_is_group(item) return item.source.group~=nil end
function o.obs_sceneitem_select(item,value) item.selected=value end
function o.obs_scene_enum_items(s) return s.items end
function o.obs_scene_prune_sources(_) end
function o.obs_sceneitem_get_source(i) return i.source or i end
function o.sceneitem_list_release(_) end
function o.obs_scene_create(n)
    local s={items={}}
    sources[n]={id="scene",name=n,scene=s}; s.source=sources[n]; return s
end
function o.obs_scene_get_source(s) return s.source end
function o.obs_scene_add(s,v)
    v.refs=v.refs+1
    local item={source=v,pos={x=0,y=0},parent=s}
    table.insert(s.items,item); return item
end
function o.obs_scene_release(_) end
function o.obs_source_filter_count(s) return (s.filters or 0)+#(s.filter_list or {}) end
function o.vec2() return {x=0,y=0} end
function o.obs_sceneitem_get_pos(item,p) p.x,p.y=item.pos.x,item.pos.y end
function o.obs_sceneitem_set_pos(item,p) item.pos={x=p.x,y=p.y} end
function o.obs_video_info() return {base_width=1280,base_height=720,fps_num=30,fps_den=1} end
function o.obs_get_video_info(_) return true end
function o.obs_scene_get_group(scene,name)
    for _,item in ipairs(scene.items) do if item.source.group and item.source.name==name then return item end end
end
function o.obs_scene_add_group2(scene,name,_)
    local source={name=name,id='group',group={items={}},settings={},refs=1}
    sources[name]=source
    local item={source=source,pos={x=0,y=0},parent=scene}
    table.insert(scene.items,item); return item
end
function o.obs_sceneitem_group_get_scene(item) return item.source.group end
function o.obs_sceneitem_remove(item)
    for i,v in ipairs(item.parent.items) do if v==item then table.remove(item.parent.items,i); item.source.refs=item.source.refs-1; break end end
end
function o.obs_transform_info() return {} end
function o.obs_sceneitem_crop() return {} end
function o.obs_sceneitem_get_info2(item,info) info.pos={x=item.pos.x,y=item.pos.y} end
function o.obs_sceneitem_set_info2(item,info) item.pos={x=info.pos.x,y=info.pos.y} end
function o.obs_sceneitem_get_crop(item,crop) crop.left=(item.crop and item.crop.left) or 0 end
function o.obs_sceneitem_set_crop(item,crop) item.crop={left=crop.left} end
function o.obs_sceneitem_visible(item) return item.visible~=false end
function o.obs_sceneitem_set_visible(item,v) item.visible=v end
function o.obs_sceneitem_locked(item) return item.locked==true end
function o.obs_sceneitem_set_locked(item,v) item.locked=v end
function o.obs_sceneitem_get_scale_filter(item) return item.scale_filter or 0 end
function o.obs_sceneitem_set_scale_filter(item,v) item.scale_filter=v end
function o.obs_sceneitem_get_blending_mode(item) return item.blend_mode or 0 end
function o.obs_sceneitem_set_blending_mode(item,v) item.blend_mode=v end
function o.obs_sceneitem_get_blending_method(item) return item.blend_method or 0 end
function o.obs_sceneitem_set_blending_method(item,v) item.blend_method=v end
function o.obs_properties_create() return {} end
local function property(p,name)
    local prop={name=name,visible=true,values={}}
    p[name]=prop; return prop
end
function o.obs_properties_add_button(p,name,_,fn) buttons[name]=fn; return property(p,name) end
function o.obs_properties_add_list(p,name) return property(p,name) end
function o.obs_property_list_add_string(p,label,value) table.insert(p.values,{label=label,value=value}) end
o.obs_property_list_add_int=o.obs_property_list_add_string
function o.obs_property_list_clear(p) p.values={} end
o.obs_properties_add_text=property
o.obs_properties_add_int=property
o.obs_properties_add_bool=property
function o.obs_properties_add_group(p,name,_,_,children)
    local group=property(p,name); group.children=children; return group
end
function o.obs_properties_get(p,name)
    if p[name] then return p[name] end
    for _,prop in pairs(p) do
        if prop.children then
            local found=o.obs_properties_get(prop.children,name)
            if found then return found end
        end
    end
end
function o.obs_property_set_visible(p,v) assert(p~=nil); p.visible=v end
function o.obs_property_set_description(p,v) p.description=v end
function o.obs_property_set_modified_callback(p,fn) p.modified=fn end
o.obs_properties_add_editable_list=property
function o.obs_hotkey_register_frontend(name,_,fn)
    assert(keys[name]==nil, 'duplicate hotkey registration')
    keys[name]=fn; registrations[name]=(registrations[name] or 0)+1; return name
end
function o.obs_hotkey_load(id,array) bindings[id]=array end
function o.obs_hotkey_save(id) data_refs=data_refs+1; return bindings[id] or {} end
function o.obs_hotkey_unregister(id) keys[id]=nil; bindings[id]=nil end
function o.timer_add(fn) timer=fn end
function o.timer_remove() timer=nil end

function o.obs_sceneitem_get_private_settings(item) item.private=item.private or {}; data_refs=data_refs+1; return item.private end
function o.obs_sceneitem_defer_group_resize_begin(_) end
function o.obs_sceneitem_defer_group_resize_end(_) end
function o.obs_sceneitem_get_order_position(item) for i,v in ipairs(item.parent.items) do if v==item then return i-1 end end end
function o.obs_sceneitem_set_order_position(item,position)
    local list=item.parent.items
    for i,v in ipairs(list) do if v==item then table.remove(list,i); break end end
    table.insert(list,position+1,item)
end
function o.obs_sceneitem_set_transition(item,show,source) item[show and 'show_transition' or 'hide_transition']=source end
function o.obs_sceneitem_set_transition_duration(item,show,duration) item[show and 'show_duration' or 'hide_duration']=duration end
local bus_transitions={}
o.OBS_TRANSITION_MODE_AUTO=0
function o.obs_scene_create_private(name) local source={name=name,id='scene',private=true,refs=1}; local scene={source=source,items={},private=true}; source.scene=scene; return scene end
function o.obs_scene_release(scene) if scene.private then for _,item in ipairs(scene.items) do item.source.refs=item.source.refs-1 end; scene.items={} end end
function o.obs_transition_set_size(source,w,h) source.size={w,h} end
function o.obs_transition_set(source,target) source.target=target end
function o.obs_transition_start(source,_,duration,target) source.target=target; table.insert(bus_transitions,{source=source,duration=duration,target=target}); return true end
function o.obs_transition_clear(source) source.target=nil end
local item_refs=0
function o.obs_sceneitem_addref(_) item_refs=item_refs+1 end
function o.obs_sceneitem_release(_) item_refs=item_refs-1 end
local frontend_callback
o.OBS_FRONTEND_EVENT_FINISHED_LOADING=100
function o.obs_frontend_add_event_callback(fn) frontend_callback=fn end
function o.obs_frontend_remove_event_callback(fn) if frontend_callback==fn then frontend_callback=nil end end
for _,name in ipairs({'cam1','cam2','cam3','caption'}) do sources[name]={name=name,id='test',settings={},refs=1} end
for i=1,3 do local scene=o.obs_scene_create('Scene '..i); o.obs_scene_add(scene,sources['cam'..i]); o.obs_scene_add(scene,sources.caption) end
dofile('scripts/camera-mix-controller.lua')
local settings={me_count=2,setup_count=2,me2_setup_count=2,pick_1='Scene 1',pick_2='Scene 2',me2_pick_1='cam1',me2_pick_2='cam2'}
script_defaults(settings); script_load(settings); script_properties()
assert(settings.mode=='CUT')
buttons.setup_all()
assert(sources['ME2 SUB Output'],table.concat(messages,'\n'))
local manager=sources['ME2 Camera Inputs'].scene
local group=o.obs_scene_get_group(manager,'ME2-cam1')
local other=o.obs_scene_get_group(manager,'ME2-cam2')
assert(group and other and #manager.items==2)
assert(#group.source.group.items==1 and not sources['Camera MIX Transparent Canvas'])
group.pos={x=70,y=100}
local primary=group.source.group.items[1]; primary.pos={x=30,y=40}; primary.crop={left=7}; primary.locked=true
o.obs_scene_add(group.source.group,sources.caption)
settings.me2_pick_1='Scene 3'; script_update(settings); buttons.setup_all()
assert(#manager.items==2 and #group.source.group.items==2)
assert(group.source.group.items[1].source.name=='Scene 3')
assert(group.source.group.items[1].pos.x==30 and group.source.group.items[1].crop.left==7)
assert(group.source.group.items[2].source.name=='caption' and group.pos.x==70)
for i=1,8 do settings.me2_pick_1=i%2==0 and 'cam1' or 'Scene 3'; script_update(settings); buttons.setup_all() end
assert(#manager.items==2 and #group.source.group.items==2)
buttons.all_mix()
buttons.me2_camera_2()
assert(not group.visible and other.visible and not other.show_transition)
assert(bus_transitions[#bus_transitions].duration==300 and group.pos.x==70)
buttons.me2_camera_1(); clock=400; camera_mix_tick(); assert(group.visible and not other.visible)
clock=800; buttons.me2_cut_button(); buttons.me2_camera_2()
assert(other.visible and not other.show_transition)
settings.me2_setup_count=3; settings.me2_pick_3='cam3'; script_update(settings); buttons.setup_all()
assert(#manager.items==3)
settings.me2_setup_count=2; script_update(settings); buttons.setup_all()
assert(#manager.items==3 and not manager.items[3].visible)
settings.me2_setup_count=3; script_update(settings); buttons.setup_all(); assert(#manager.items==3)
clock=1200; buttons.me2_camera_2()
settings.me2_edit_camera=1; buttons.me2_edit_layout(); assert(other.visible and not group.visible)
assert(keys['camera_mix_controller.camera_1'] and not keys['camera_mix.camera_1'])
settings.independent_hotkeys=true; script_update(settings); assert(keys['camera_mix_controller.me2_camera_2'])
settings.independent_hotkeys=false; script_update(settings); assert(not keys['camera_mix_controller.me2_camera_2'])
local old=group.source.settings.camera_mix_controller_group
group.source.settings.camera_mix_controller_group=false
local saved=group.source.group.items[1].source.name
settings.me2_pick_1='cam3'; script_update(settings); buttons.setup_all()
assert(group.source.group.items[1].source.name==saved and #manager.items==3)
group.source.settings.camera_mix_controller_group=old
assert(data_refs==1,'data references '..data_refs)
settings.duration=620; settings.me2_duration=90; settings.me2_mode='CUT'; settings.mode='MIX'; script_update(settings)
assert(settings.me2_duration==620 and settings.me2_mode=='MIX')
clock=2000; buttons.me2_camera_1(); assert(bus_transitions[#bus_transitions].duration==620)
buttons.me2_cut_button(); assert(settings.mode=='CUT' and settings.me2_mode=='CUT')
clock=3000; buttons.camera_2(); clock=3200; camera_mix_tick()
assert(not other.show_transition and sources['ME1 PGM Camera MIX'].settings.transition=='cut_transition')
settings.me2_pick_1='cam1'
local output=sources['ME2 SUB Output']
o.obs_scene_add(output.scene,sources.caption)
settings.me_label_2='하단'; settings.output_name_2='하단 카메라 출력'; settings.input_name_2='하단 입력'
script_update(settings); buttons.apply_names()
assert(sources['하단 입력'].scene==manager and sources['하단 카메라 출력']==output)
assert(sources['하단-cam1']==group.source and group.pos.x==70)
local caption_found=false; for _,item in ipairs(output.scene.items) do if item.source.name=='caption' then caption_found=true end end
assert(other.visible and not group.visible and caption_found)
assert(not sources['ME2 Camera Inputs'] and not sources['ME2 SUB Output'])
settings.me_label_2='충돌'; settings.output_name_2='Scene 1'
script_update(settings); buttons.apply_names()
assert(sources['하단 입력'].scene==manager and sources['하단 카메라 출력']==output and not sources['충돌-cam1'])
settings.me_label_2='하단'; settings.output_name_2='하단 카메라 출력'
script_update(settings); buttons.setup_all()
assert(#manager.items==3 and #group.source.group.items==2)
-- Simulate old names stored by 1.1.0, then migrate the same objects.
o.obs_source_set_name(output,'ME2 Simple Output'); o.obs_source_set_name(manager.source,'ME2 Simple Camera Inputs')
o.obs_source_set_name(group.source,'ME2-SIMPLE-CAM1')
settings.me2_scene='ME2 Simple Output'; settings.me2_output='ME2 Simple Camera Inputs'; settings.me2_manager='ME2 Simple Camera Inputs'
settings.me2_cameras[1].value='ME2-SIMPLE-CAM1'; settings.me2_slots[1].value='ME2-SIMPLE-CAM1'
settings.me_label_2='ME2'; settings.output_name_2=''; settings.input_name_2=''
script_update(settings); buttons.apply_names()
assert(sources['ME2 SUB Output']==output and sources['ME2 Camera Inputs'].scene==manager and sources['ME2-cam1']==group.source)
-- OBS SWIG wrappers can differ despite referring to the same native source.
local original_get=o.obs_get_source_by_name
o.obs_get_source_by_name=function(name)
    local native=original_get(name)
    if not native then return nil end
    return setmetatable({}, {__index=native, __newindex=function(_,k,v) native[k]=v end})
end
local before_groups=#manager.items
for i=1,4 do buttons.setup_all() end
assert(#manager.items==before_groups and #group.source.group.items==2)
assert(group.source.group.items[2].source.name=='caption' and group.pos.x==70)
assert(messages[#messages]:find('전체 설정 완료'))
o.obs_get_source_by_name=original_get
local current_runtime
for _,item in ipairs(output.scene.items) do if item.private and item.private.camera_mix_runtime then current_runtime=item end end
assert(current_runtime and current_runtime.source.size[1]==1280)
group.pos={x=510,y=210}; clock=5000; camera_mix_tick()
local active_views=bus_transitions[#bus_transitions].source
-- Engine keeps the output item transform on the saved manager reference.
current_runtime.pos={x=20,y=30}; clock=5100; camera_mix_tick()
assert(output.scene.items[1].pos.x==20 and output.scene.items[1].pos.y==30)
script_save(settings); script_unload(); assert(data_refs==0)
assert(output.scene.items[1].visible and #output.scene.items==2)
script_load(settings); script_properties(); assert(#output.scene.items==3)
local runtime
for _,item in ipairs(output.scene.items) do if item.private and item.private.camera_mix_runtime then runtime=item end end
assert(runtime and runtime.pos.x==20)
clock=9000; buttons.all_mix(); buttons.me2_camera_2(); assert(bus_transitions[#bus_transitions].duration==620)
assert(bus_transitions[#bus_transitions].target.scene.items[1].pos.x==other.pos.x)
script_unload(); assert(data_refs==0 and #output.scene.items==2)
assert(item_refs==0 and source_refs==0, 'runtime reference leak')
group.source.settings.camera_mix_controller_group=false
group.source.settings.camera_mix_simple_group=true
manager.source.settings.camera_mix_controller_manager=false
manager.source.settings.camera_mix_simple_manager=true
group.source.group.items[1].private.camera_mix_controller_primary=false
group.source.group.items[1].private.camera_mix_simple_primary=true
script_load(settings); script_properties()
clock=10000
settings.me2_pick_1='Scene 3'; script_update(settings); buttons.setup_all()
assert(#group.source.group.items==2 and group.source.group.items[1].source.name=='Scene 3')
assert(group.source.group.items[2].source.name=='caption')
script_unload(); assert(item_refs==0 and source_refs==0 and data_refs==0)
-- Cold start: script loads before the scene collection, then resumes itself.
script_load(settings); script_properties(); clock=12000
buttons.all_cut(); buttons.me1_camera_2(); clock=12300; camera_mix_tick()
buttons.me2_camera_3()
settings.duration=440; settings.mode='MIX'; script_update(settings)
script_save(settings)
assert(settings.last_camera==2 and settings.me2_last_camera==3)
script_unload()
local saved_manager=sources[settings.me2_manager]
local saved_output=sources[settings.me2_scene]
sources[settings.me2_manager]=nil; sources[settings.me2_scene]=nil
sources[settings.output].time=0
for i,item in ipairs(manager.items) do item.visible=i==1 end
local message_count=#messages
script_load(settings); script_properties(); buttons.camera_2()
assert(#messages==message_count,'startup must not emit missing-output errors')
clock=12500; camera_mix_tick(); assert(#output.scene.items==2)
sources[settings.me2_manager]=saved_manager; sources[settings.me2_scene]=saved_output
frontend_callback(o.OBS_FRONTEND_EVENT_FINISHED_LOADING)
assert(#output.scene.items==3 and manager.items[3].visible and not manager.items[1].visible)
assert(settings.mode=='MIX' and settings.duration==440 and group.pos.x==510)
clock=13000; camera_mix_tick(); clock=13200; camera_mix_tick()
assert(other.visible and not manager.items[3].visible, 'startup camera request must execute after restoration')
script_unload(); assert(item_refs==0 and source_refs==0 and data_refs==0 and frontend_callback==nil)
-- Filename migration imports once and leaves later user edits unchanged.
script_path=function() return 'tests/fixtures/' end
function o.obs_data_create_from_json(text) assert(text:find('"cameras"')); local d=o.obs_data_create(); d.duration=455; d.mode='MIX'; return d end
function o.obs_data_apply(target,from) for k,v in pairs(from) do target[k]=v end end
local migrated={duration=100}; script_defaults(migrated)
assert(migrated.duration==455 and migrated.controller_settings_migrated)
migrated.duration=320; script_defaults(migrated); assert(migrated.duration==320 and data_refs==0)
script_path=nil
assert(script_description():find('SunjooAn') and script_description():find('1.3.4'))
print('PASS Controller: stable slots, primary replacement, decorations/transforms, MIX/CUT, queued switching, editing visibility, hotkeys, data ownership')
