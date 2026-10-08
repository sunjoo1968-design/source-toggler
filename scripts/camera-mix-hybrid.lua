-- Sunjoo OBS Link Controller / SunjooAn / Source Switcher and camera-mix-hybrid required
local obs = obslua
local VERSION, AUTHOR = '0.1.1', 'SunjooAn'
local MAX_ME, MAX_CAM = 8, 16
local banks, hotkeys, callbacks = {}, {}, {}
local me_count, linked_pending = 1, nil
local script_settings = nil
local loaded, sync_hotkeys = false, nil
local legacy_manager_name = 'ME Camera Inputs'
local manager_updated = -1000
local restore_due = 0
local frontend_event
local restore_outputs
local synchronize_groups, migrate_managers
local ANCHOR_NAME = 'Camera MIX Transparent Canvas'
local function key(n, name) return n == 1 and name or 'me' .. n .. '_' .. name end
local function now_ms() return obs.os_gettime_ns() / 1000000 end
local function controller_flag(data, role)
    -- Read previous hidden metadata while writing only the controller namespace.
    return obs.obs_data_get_bool(data, 'camera_mix_hybrid_' .. role)
end
local function log(b, text)
    obs.script_log(obs.LOG_WARNING, '[Camera MIX' .. (b and ' ME' .. b.number or '') .. '] ' .. text)
end
local function is_manager_name(name)
    if name == legacy_manager_name then return true end
    for n = 2, me_count do if banks[n] ~= nil and name == banks[n].manager then return true end end
    return false
end
local function input_names(b)
    local names = {}
    for i, name in ipairs(b.cameras) do names[i] = b.wrap and b.prefix .. i or name end
    return names
end
local function read_array(settings, name)
    local array, values = obs.obs_data_get_array(settings, name), {}
    for i = 0, obs.obs_data_array_count(array) - 1 do
        local entry = obs.obs_data_array_item(array, i)
        values[#values + 1] = obs.obs_data_get_string(entry, 'value')
        obs.obs_data_release(entry)
    end
    obs.obs_data_array_release(array)
    return values
end
local function write_array(settings, name, values)
    local array = obs.obs_data_array_create()
    for _, value in ipairs(values) do
        local entry = obs.obs_data_create()
        obs.obs_data_set_string(entry, 'value', value)
        obs.obs_data_array_push_back(array, entry)
        obs.obs_data_release(entry)
    end
    obs.obs_data_set_array(settings, name, array)
    obs.obs_data_array_release(array)
end
local function mode_settings(settings, mode, duration)
    obs.obs_data_set_string(settings, 'transition', mode == 'MIX' and 'fade_transition' or 'cut_transition')
    obs.obs_data_set_int(settings, 'transition_duration', duration)
    obs.obs_data_set_string(settings, 'show_transition', '')
    obs.obs_data_set_string(settings, 'hide_transition', '')
    for _, name in ipairs({'time_switch', 'media_state_switch', 'current_source_file'}) do
        obs.obs_data_set_bool(settings, name, false)
    end
end
local function output_source(b)
    local source = obs.obs_get_source_by_name(b.output)
    if source == nil then log(b, '출력 소스가 없습니다. 이 ME의 생성/적용 버튼을 실행하세요.'); return nil end
    if obs.obs_source_get_unversioned_id(source) ~= (b.number == 1 and 'source_switcher' or 'scene') then
        obs.obs_source_release(source); log(b, '출력 이름이 다른 소스와 충돌합니다.'); return nil
    end
    local data = obs.obs_source_get_settings(source)
    local owned = controller_flag(data, b.number == 1 and 'output' or 'manager')
    obs.obs_data_release(data)
    if not owned then obs.obs_source_release(source); log(b, '다른 버전의 출력은 제어하지 않습니다.'); return nil end
    return source
end
local function forbidden_source(source, seen)
    if obs.obs_source_get_unversioned_id(source) == 'camera_mix_hybrid_output' then return true end
    local name = obs.obs_source_get_name(source)
    for n = 1, me_count do
        if name == banks[n].output or name == banks[n].scene then return true end
    end
    if seen[name] then return false end
    seen[name] = true
    local scene = obs.obs_scene_from_source(source) or obs.obs_group_from_source(source)
    if scene == nil then return false end
    local items = obs.obs_scene_enum_items(scene)
    local found = false
    if items ~= nil then
        for _, item in ipairs(items) do
            if forbidden_source(obs.obs_sceneitem_get_source(item), seen) then found = true; break end
        end
        obs.sceneitem_list_release(items)
    end
    return found
end
local function scene_info(source, name)
    local scene = obs.obs_scene_from_source(source)
    if scene == nil then return nil, 0, false end
    local items = obs.obs_scene_enum_items(scene)
    local count, found = items ~= nil and #items or 0, false
    if items ~= nil then
        for _, item in ipairs(items) do
            if obs.obs_source_get_name(obs.obs_sceneitem_get_source(item)) == name then found = true end
        end
        obs.sceneitem_list_release(items)
    end
    return scene, count, found
end
local function validate_names() return true end

local function validate(b)
    if not validate_names() then return false end
    if b.number == 1 and b.wrap then log(b, 'ME1은 기존 카메라 장면을 직접 사용합니다. 간편 설정에서 장면을 선택해 적용하세요.'); return false end
    if #b.cameras < 2 or #b.cameras > MAX_CAM then log(b, '카메라를 2~16개 등록하세요.'); return false end
    local seen, names = {}, input_names(b)
    for i, name in ipairs(b.cameras) do
        if seen[name] then log(b, '카메라 이름이 중복됩니다: ' .. name); return false end
        seen[name] = true
        local source = obs.obs_get_source_by_name(name)
        if source == nil then log(b, '소스를 찾을 수 없습니다: ' .. name); return false end
        local invalid = forbidden_source(source, {})
        local is_scene = obs.obs_scene_from_source(source) ~= nil
        obs.obs_source_release(source)
        if invalid then log(b, '카메라 입력에 ME 출력이 포함되어 순환합니다: ' .. name); return false end
        if b.number == 1 and not is_scene then log(b, 'ME1에는 카메라 장면을 선택하세요: ' .. name); return false end
        if b.wrap then
            for _, generated in ipairs(names) do
                if name == generated then log(b, '원본 카메라 이름을 입력하세요: ' .. name); return false end
            end
            local existing = obs.obs_get_source_by_name(names[i])
            if existing ~= nil then
                local scene, count, found = scene_info(existing, name)
                local recursive = forbidden_source(existing, {})
                obs.obs_source_release(existing)
                if scene == nil or (count > 0 and not found) or recursive then
                    log(b, '기존 배치 장면의 입력이 다르거나 순환합니다. 접두사를 바꾸세요: ' .. names[i]); return false
                end
            end
        end
    end
    return true
end
local function ensure_layouts(b)
    if not validate(b) then return false end
    if not b.wrap then return true end
    for i, name in ipairs(b.cameras) do
        local scene_name = b.prefix .. i
        local existing = obs.obs_get_source_by_name(scene_name)
        local scene, count, found
        if existing ~= nil then scene, count, found = scene_info(existing, name)
        else scene = obs.obs_scene_create(scene_name) end
        if scene == nil then
            if existing ~= nil then obs.obs_source_release(existing) end
            log(b, '배치 장면 생성 실패: ' .. scene_name); return false
        end
        local connected = found
        if not found then
            local camera = obs.obs_get_source_by_name(name)
            if camera ~= nil then
                connected = obs.obs_scene_add(scene, camera) ~= nil
                obs.obs_source_release(camera)
            end
        end
        if existing ~= nil then obs.obs_source_release(existing) else obs.obs_scene_release(scene) end
        if not connected then log(b, '배치 장면 입력 연결 실패: ' .. scene_name); return false end
    end
    return true
end
local function apply_list(b)
    if now_ms() < b.locked_until then log(b, '전환이 끝난 뒤 적용하세요.'); return false end
    if b.number > 1 then
        local source = obs.obs_get_source_by_name(b.manager)
        if not source then log(b, '전체 적용을 먼저 실행하세요.'); return false end
        obs.obs_source_release(source)
        return true
    end
    if not ensure_layouts(b) then return false end
    local source = obs.obs_get_source_by_name(b.output)
    if source ~= nil and obs.obs_source_get_unversioned_id(source) ~= (b.number == 1 and 'source_switcher' or 'scene') then
        obs.obs_source_release(source); log(b, '출력 이름이 다른 소스와 충돌합니다.'); return false
    end
    local settings = source ~= nil and obs.obs_source_get_settings(source) or obs.obs_data_create()
    if source and not controller_flag(settings, 'output') then
        obs.obs_data_release(settings); obs.obs_source_release(source)
        log(b, '기존 다른 버전의 출력은 수정하지 않습니다. 별도 출력 이름을 지정하세요.'); return false
    end
    obs.obs_data_set_bool(settings, 'camera_mix_hybrid_output', true)
    write_array(settings, 'sources', input_names(b))
    mode_settings(settings, 'CUT', b.duration)
    obs.obs_data_set_int(settings, 'playback_behavior', 0)
    obs.obs_data_set_int(settings, 'transition_scale', obs.OBS_TRANSITION_SCALE_ASPECT)
    obs.obs_data_set_bool(settings, 'transition_resize', false)
    if source == nil then
        source = obs.obs_source_create('source_switcher', b.output, settings, nil)
        if source ~= nil then
            if b.held ~= nil then obs.obs_source_release(b.held) end
            b.held = obs.obs_source_get_ref(source)
        end
    else obs.obs_source_update(source, settings) end
    if source == nil then
        obs.obs_data_release(settings); log(b, 'Source Switcher 플러그인을 설치하고 OBS를 다시 시작하세요.'); return false
    end
    obs.obs_source_media_set_time(source, 0)
    mode_settings(settings, b.mode, b.duration)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
    b.pending, linked_pending = nil, nil
    b.selected, b.restore_pending = 1, false
    obs.obs_data_set_int(script_settings, key(b.number, 'last_camera'), 1)
    return true
end
local function copy_transform(from, to)
    local info, crop = obs.obs_transform_info(), obs.obs_sceneitem_crop()
    obs.obs_sceneitem_get_info2(from, info); obs.obs_sceneitem_get_crop(from, crop)
    obs.obs_sceneitem_set_info2(to, info); obs.obs_sceneitem_set_crop(to, crop)
    obs.obs_sceneitem_set_scale_filter(to, obs.obs_sceneitem_get_scale_filter(from))
    obs.obs_sceneitem_set_blending_mode(to, obs.obs_sceneitem_get_blending_mode(from))
    obs.obs_sceneitem_set_blending_method(to, obs.obs_sceneitem_get_blending_method(from))
end
local function hybrid_source(b, live, snapshot)
    if not obs.obs_source_get_display_name('camera_mix_hybrid_output') then
        log(b, 'Sunjoo OBS Link Controller 출력 플러그인을 설치한 뒤 사용하세요.'); return nil
    end
    local name = b.label .. ' Hybrid Copy Output'
    local source = obs.obs_get_source_by_name(name)
    if source and obs.obs_source_get_unversioned_id(source) ~= 'camera_mix_hybrid_output' then
        obs.obs_source_release(source); log(b, '복제 출력 이름이 다른 소스와 충돌합니다: ' .. name); return nil
    end
    local data = obs.obs_data_create()
    obs.obs_data_set_int(data, 'camera_mix_hybrid_bank', b.number)
    obs.obs_data_set_string(data, 'live_uuid', obs.obs_source_get_uuid(live))
    if snapshot then obs.obs_data_set_string(data, 'snapshot_uuid', obs.obs_source_get_uuid(snapshot)) end
    if source then obs.obs_source_update(source, data)
    else source = obs.obs_source_create('camera_mix_hybrid_output', name, data, nil) end
    obs.obs_data_release(data)
    return source
end
local function connect_hybrid_me1(b, scene)
    local live = obs.obs_get_source_by_name(b.output)
    if not live then return false end
    local snapshot = obs.obs_get_source_by_name(b.cameras[b.selected or 1] or '')
    local wrapper = snapshot and hybrid_source(b, live, snapshot)
    if snapshot then obs.obs_source_release(snapshot) end
    obs.obs_source_release(live)
    if not wrapper then return false end
    local base = obs.obs_scene_find_source(scene, b.output)
    local item = obs.obs_scene_find_source(scene, obs.obs_source_get_name(wrapper))
    if not item then item = obs.obs_scene_add(scene, wrapper); if base and item then copy_transform(base, item) end end
    local items = obs.obs_scene_enum_items(scene)
    for _, old in ipairs(items or {}) do
        local old_source = obs.obs_sceneitem_get_source(old)
        if obs.obs_source_get_name(old_source) ~= obs.obs_source_get_name(wrapper) and obs.obs_source_get_unversioned_id(old_source) == 'camera_mix_hybrid_output' then
            local data = obs.obs_source_get_settings(old_source)
            local owned = obs.obs_data_get_int(data, 'camera_mix_hybrid_bank') == b.number
            obs.obs_data_release(data)
            if owned then if item then copy_transform(old, item) end; obs.obs_sceneitem_remove(old) end
        end
    end
    if items then obs.sceneitem_list_release(items) end
    if base and item then obs.obs_sceneitem_set_visible(base, false) end
    obs.obs_source_release(wrapper)
    return item ~= nil
end
local function release_engine(b)
    local engine = b.engine
    if not engine then return end
    if engine.item then
        copy_transform(engine.item, engine.base)
        obs.obs_sceneitem_set_visible(engine.base, true)
        obs.obs_sceneitem_remove(engine.item)
        obs.obs_sceneitem_release(engine.item)
    end
    obs.obs_transition_clear(engine.fade)
    obs.obs_source_release(engine.fade)
    for _, view in ipairs(engine.views) do obs.obs_scene_release(view) end
    obs.obs_sceneitem_release(engine.base)
    b.engine = nil
end
local function sync_engine(b)
    if not b.engine then return end
    if b.engine.item then copy_transform(b.engine.item, b.engine.base) end
    local source = obs.obs_get_source_by_name(b.manager)
    local manager = source and obs.obs_scene_from_source(source)
    if manager then
        obs.obs_scene_prune_sources(manager)
        for i, name in ipairs(b.cameras) do
            local group = obs.obs_scene_get_group(manager, name)
            if group and b.engine.items[i] then copy_transform(group, b.engine.items[i]) end
        end
    end
    if source then obs.obs_source_release(source) end
end
local function ensure_engine(b, output_scene)
    release_engine(b)
    local manager_source = obs.obs_get_source_by_name(b.manager)
    local manager = manager_source and obs.obs_scene_from_source(manager_source)
    if not manager then if manager_source then obs.obs_source_release(manager_source) end; return false end
    local engine = {views={}, items={}}
    local existing = obs.obs_scene_enum_items(output_scene)
    for _, item in ipairs(existing or {}) do
        local data = obs.obs_sceneitem_get_private_settings(item)
        local runtime = obs.obs_data_get_bool(data, 'camera_mix_hybrid_runtime')
        obs.obs_data_release(data)
        local child = obs.obs_sceneitem_get_source(item)
        local owned = false
        if obs.obs_source_get_unversioned_id(child) == 'camera_mix_hybrid_output' then
            local settings = obs.obs_source_get_settings(child)
            owned = obs.obs_data_get_int(settings, 'camera_mix_hybrid_bank') == b.number
            obs.obs_data_release(settings)
        end
        if runtime or owned then obs.obs_sceneitem_remove(item)
        elseif obs.obs_source_get_name(obs.obs_sceneitem_get_source(item)) == b.manager then engine.base = item end
    end
    if existing then obs.sceneitem_list_release(existing) end
    if not engine.base then obs.obs_source_release(manager_source); return false end
    engine.fade = obs.obs_source_create_private('fade_transition', b.label .. ' Camera MIX', nil)
    if not engine.fade then obs.obs_source_release(manager_source); return false end
    b.engine = engine
    obs.obs_sceneitem_addref(engine.base)
    local selected = b.selected
    local infer_selected = not selected or selected < 1 or selected > #b.cameras
    if infer_selected then selected = 1 end
    for i, name in ipairs(b.cameras) do
        local group = obs.obs_scene_get_group(manager, name)
        local view = obs.obs_scene_create_private(b.label .. ' MIX view ' .. i)
        if not group or not view then if view then obs.obs_scene_release(view) end; obs.obs_source_release(manager_source); release_engine(b); return false end
        engine.views[i] = view
        engine.items[i] = obs.obs_scene_add(view, obs.obs_sceneitem_get_source(group))
        if not engine.items[i] then obs.obs_source_release(manager_source); release_engine(b); return false end
        copy_transform(group, engine.items[i])
        obs.obs_sceneitem_set_transition(group, true, nil); obs.obs_sceneitem_set_transition(group, false, nil)
        if infer_selected and obs.obs_sceneitem_visible(group) then selected = i end
    end
    local video = obs.obs_video_info(); obs.obs_get_video_info(video)
    obs.obs_transition_set_size(engine.fade, video.base_width, video.base_height)
    obs.obs_transition_set(engine.fade, obs.obs_scene_get_source(engine.views[selected]))
    local wrapper = hybrid_source(b, engine.fade, obs.obs_scene_get_source(engine.views[selected]))
    engine.item = wrapper and obs.obs_scene_add(output_scene, wrapper)
    if wrapper then obs.obs_source_release(wrapper) end
    if not engine.item then obs.obs_source_release(manager_source); release_engine(b); return false end
    obs.obs_sceneitem_addref(engine.item)
    copy_transform(engine.base, engine.item)
    obs.obs_sceneitem_set_order_position(engine.item, obs.obs_sceneitem_get_order_position(engine.base) + 1)
    local data = obs.obs_sceneitem_get_private_settings(engine.item)
    obs.obs_data_set_bool(data, 'camera_mix_hybrid_runtime', true); obs.obs_data_release(data)
    obs.obs_sceneitem_set_visible(engine.base, false)
    b.selected = selected
    for i, name in ipairs(b.cameras) do obs.obs_sceneitem_set_visible(obs.obs_scene_get_group(manager, name), i == selected) end
    if script_settings then obs.obs_data_set_int(script_settings, key(b.number, 'last_camera'), selected) end
    obs.obs_source_release(manager_source)
    return true
end
local function create_scene(b)
    local existing = obs.obs_get_source_by_name(b.scene)
    local scene, count, connected
    if existing ~= nil then
        scene, count, connected = scene_info(existing, b.output)
        if scene == nil or (count > 0 and not connected) then
            obs.obs_source_release(existing)
            log(b, '기존 장면에 다른 소스가 있습니다. 새 장면 이름을 지정하거나 출력을 직접 추가하세요.'); return false
        end
    end
    if not apply_list(b) then
        if existing ~= nil then obs.obs_source_release(existing) end
        return false
    end
    if scene == nil then scene = obs.obs_scene_create(b.scene) end
    if scene == nil then log(b, '출력 장면 생성 실패'); return false end
    if not connected then
        local source = output_source(b)
        if source ~= nil then
            connected = obs.obs_scene_add(scene, source) ~= nil
            obs.obs_source_release(source)
        end
    end
    if connected then
        if b.number > 1 then connected = ensure_engine(b, scene)
        else connected = connect_hybrid_me1(b, scene) end
    end
    if existing ~= nil then obs.obs_source_release(existing) else obs.obs_scene_release(scene) end
    if not connected then log(b, '출력 장면 연결 실패'); return false end
    b.restore_pending = false
    if b.held ~= nil then obs.obs_source_release(b.held); b.held = nil end
    obs.script_log(obs.LOG_INFO, '[Camera MIX ME' .. b.number .. '] 출력 장면 준비 완료: ' .. b.scene)
    return true
end
local function prepared_source(b, index)
    if b.restore_pending then return nil end
    if index < 1 or index > #b.cameras then return nil end
    local source = output_source(b)
    if not source then return nil end
    local valid = true
    if b.number > 1 then
        local scene = obs.obs_scene_from_source(source)
        valid = b.engine ~= nil and #b.engine.views == #b.cameras
        for _, name in ipairs(b.cameras) do if not obs.obs_scene_get_group(scene, name) then valid = false end end
    else
        local data = obs.obs_source_get_settings(source)
        local actual = read_array(data, 'sources'); obs.obs_data_release(data)
        valid = #actual == #b.cameras
        for i, name in ipairs(b.cameras) do if actual[i] ~= name then valid = false end end
    end
    if not valid then obs.obs_source_release(source); log(b, '전체 적용을 먼저 실행하세요.'); return nil end
    return source
end

local function hybrid_snapshot(b, index)
    local wrapper = obs.obs_get_source_by_name(b.label .. ' Hybrid Copy Output')
    if not wrapper then return end
    local target
    if b.number == 1 then target = obs.obs_get_source_by_name(b.cameras[index] or '')
    elseif b.engine and b.engine.views[index] then target = obs.obs_source_get_ref(obs.obs_scene_get_source(b.engine.views[index])) end
    if target then
        local data = obs.obs_source_get_settings(wrapper)
        obs.obs_data_set_string(data, 'snapshot_uuid', obs.obs_source_get_uuid(target))
        obs.obs_source_update(wrapper, data); obs.obs_data_release(data)
        obs.obs_source_release(target)
    end
    obs.obs_source_release(wrapper)
end
local function execute_selection(b, source, index, mode, duration)
    b.commit = nil
    if b.number > 1 then
        if b.selected == index then return end
        if not b.engine then log(b, '전체 적용을 먼저 실행하세요.'); return end
        sync_engine(b)
        local target = obs.obs_scene_get_source(b.engine.views[index])
        if mode == 'MIX' then
            if not obs.obs_transition_start(b.engine.fade, obs.OBS_TRANSITION_MODE_AUTO, duration, target) then
                log(b, 'MIX 시작 실패'); return
            end
        else obs.obs_transition_set(b.engine.fade, target) end
        local scene = obs.obs_scene_from_source(source)
        for i, name in ipairs(b.cameras) do
            local item = obs.obs_scene_get_group(scene, name)
            obs.obs_sceneitem_set_visible(item, i == index)
        end
        b.selected = index
        hybrid_snapshot(b, index)
        obs.obs_data_set_int(script_settings, key(b.number, 'last_camera'), index)
        b.locked_until = now_ms() + (mode == 'MIX' and duration + 50 or 0)
        return
    end
    local current = obs.obs_source_media_get_time(source) / 1000
    local settings = obs.obs_source_get_settings(source)
    local transition = mode == 'MIX' and 'fade_transition' or 'cut_transition'
    local changed = obs.obs_data_get_string(settings, 'transition') ~= transition or obs.obs_data_get_int(settings, 'transition_duration') ~= duration
    if changed then
        mode_settings(settings, mode, duration)
        obs.obs_source_update(source, settings)
        local video = obs.obs_video_info()
        obs.obs_get_video_info(video)
        local gap = video.fps_num > 0 and 2000 * video.fps_den / video.fps_num + 25 or 125
        b.commit = {index=index,due=now_ms()+gap}
        b.locked_until = now_ms()+gap+(current ~= index-1 and mode=='MIX' and duration+50 or 0)
    else
        obs.obs_source_media_set_time(source, (index - 1) * 1000)
        b.selected = index
        hybrid_snapshot(b, index)
        obs.obs_data_set_int(script_settings, key(b.number, 'last_camera'), index)
        if current ~= index - 1 and mode == 'MIX' then b.locked_until = now_ms() + duration + 50 end
    end
    obs.obs_data_release(settings)
end
local function select_independent(b, index)
    linked_pending = nil
    if b.restore_pending then b.pending = {index=index, mode=b.mode, duration=b.duration}; return end
    local source = prepared_source(b, index)
    if source == nil then return end
    if now_ms() < b.locked_until then b.pending = {index = index, mode = b.mode, duration = b.duration}
    else b.pending = nil; execute_selection(b, source, index, b.mode, b.duration) end
    obs.obs_source_release(source)
end
local function linked_request(index)
    if not validate_names() then return end
    local request = {index = index, modes = {}, durations = {}, count = me_count}
    local restoring = false
    for n = 1, me_count do
        request.modes[n], request.durations[n] = banks[n].mode, banks[n].duration
        if banks[n].restore_pending and #banks[n].cameras >= 2 then restoring = true end
    end
    if restoring then linked_pending = request; return end
    local sources, valid = {}, true
    for n = 1, me_count do
        sources[n] = prepared_source(banks[n], index)
        if sources[n] == nil then valid = false end
        request.modes[n], request.durations[n] = banks[n].mode, banks[n].duration
    end
    for _, source in pairs(sources) do obs.obs_source_release(source) end
    if not valid then log(nil, '연동 선택 취소: 모든 활성 ME의 목록과 출력을 먼저 준비하세요.'); return end
    for n = 1, me_count do banks[n].pending = nil end
    linked_pending = request
    camera_mix_tick()
end
restore_outputs = function()
    if not loaded or now_ms() < restore_due then return end
    restore_due = now_ms() + 500
    for n = 1, me_count do
        local b = banks[n]
        if b.restore_pending and #b.cameras >= 2 then
            local source = obs.obs_get_source_by_name(b.output)
            if n == 1 then
                if source and obs.obs_source_get_unversioned_id(source) == 'source_switcher' then
                    local data = obs.obs_source_get_settings(source)
                    local actual = read_array(data, 'sources'); obs.obs_data_release(data)
                    local valid = #actual == #b.cameras
                    for i, name in ipairs(b.cameras) do
                        local input = obs.obs_get_source_by_name(name)
                        if not input or actual[i] ~= name then valid = false end
                        if input then obs.obs_source_release(input) end
                    end
                    if valid then
                        local index = b.selected or 1
                        execute_selection(b, source, math.max(1, math.min(#b.cameras, index)), 'CUT', b.duration)
                        local output = obs.obs_get_source_by_name(b.scene)
                        local scene = output and obs.obs_scene_from_source(output)
                        if scene and connect_hybrid_me1(b, scene) then b.restore_pending = false end
                        if output then obs.obs_source_release(output) end
                    end
                end
            elseif source then
                local manager = obs.obs_scene_from_source(source)
                local valid = manager ~= nil
                for _, name in ipairs(b.cameras) do if not manager or not obs.obs_scene_get_group(manager, name) then valid = false end end
                local output = obs.obs_get_source_by_name(b.scene)
                local scene = output and obs.obs_scene_from_source(output)
                local connected = false
                if output then local _, _, found = scene_info(output, b.manager); connected = found end
                if valid and scene and connected and ensure_engine(b, scene) then b.restore_pending = false end
                if output then obs.obs_source_release(output) end
            end
            if source then obs.obs_source_release(source) end
        end
    end
end
function camera_mix_tick()
    restore_outputs()
    local tick_time = now_ms()
    for n = 2, me_count do sync_engine(banks[n]) end
    for n = 1, me_count do
        local b = banks[n]
        if b.commit ~= nil and now_ms() >= b.commit.due then
            local request = b.commit
            b.commit = nil
            local source = prepared_source(b, request.index)
            if source ~= nil then
                obs.obs_source_media_set_time(source, (request.index-1)*1000)
                b.selected = request.index
                hybrid_snapshot(b, request.index)
                obs.obs_data_set_int(script_settings, key(n, 'last_camera'), request.index)
                obs.obs_source_release(source)
            end
        end
    end
    if linked_pending ~= nil then
        local request = linked_pending
        for n = 1, request.count do if banks[n].restore_pending then return end end
        for n = 1, request.count do if now_ms() < banks[n].locked_until then return end end
        local sources, valid = {}, true
        for n = 1, request.count do
            sources[n] = prepared_source(banks[n], request.index)
            if sources[n] == nil then valid = false end
        end
        linked_pending = nil
        if valid then
            for n = 1, request.count do execute_selection(banks[n], sources[n], request.index, request.modes[n], request.durations[n]) end
        end
        for _, source in pairs(sources) do obs.obs_source_release(source) end
    end
    for n = 1, me_count do
        local b = banks[n]
        if b.pending ~= nil and not b.restore_pending and now_ms() >= b.locked_until then
            local request = b.pending
            b.pending = nil
            local source = prepared_source(b, request.index)
            if source ~= nil then
                execute_selection(b, source, request.index, request.mode, request.duration)
                obs.obs_source_release(source)
            end
        end
    end
end
local function set_mode(mode, number)
    -- The optional number is retained for old shortcut callbacks only.
    for n = 1, MAX_ME do
        banks[n].mode = mode
        if script_settings then obs.obs_data_set_string(script_settings, key(n, 'mode'), mode) end
    end
end
local function origin_name(name)
    local seen = {}
    while name ~= '' and not seen[name] do
        seen[name] = true
        local source = obs.obs_get_source_by_name(name)
        if source == nil then break end
        local settings = obs.obs_source_get_settings(source)
        local origin = obs.obs_data_get_bool(settings, 'camera_mix_group') and obs.obs_data_get_string(settings, 'camera_mix_origin') or ''
        obs.obs_data_release(settings); obs.obs_source_release(source)
        if origin == '' then break end
        name = origin
    end
    return name
end
local function apply_names()
    local plan, targets = {}, {}
    local function propose(old, new)
        if new == '' or targets[new] then log(nil, '이름이 비어 있거나 중복됩니다: ' .. new); return false end
        targets[new] = true
        local source = obs.obs_get_source_by_name(old)
        local collision = obs.obs_get_source_by_name(new)
        -- SWIG may return different Lua wrappers for the same native source.
        local blocked = collision and (not source or obs.obs_source_get_name(collision) ~= obs.obs_source_get_name(source))
        if collision then obs.obs_source_release(collision) end
        if source then obs.obs_source_release(source) end
        if blocked then log(nil, '이름이 이미 사용 중입니다. 글로벌 옵션에서 다른 이름을 지정하세요: ' .. new); return false end
        plan[#plan + 1] = {old=old, new=new}
        return true
    end
    local desired = {}
    for n = 1, me_count do
        local b = banks[n]
        local old_output, old_scene = b.output, b.scene
        if now_ms() < b.locked_until then log(b, '전환 종료 후 이름을 적용하세요.'); return false end
        local existing = obs.obs_get_source_by_name(b.output)
        if existing then
            local data = obs.obs_source_get_settings(existing)
            local owned = n == 1 and obs.obs_source_get_unversioned_id(existing) == 'source_switcher' and controller_flag(data, 'output') or n > 1 and controller_flag(data, 'manager')
            obs.obs_data_release(data); obs.obs_source_release(existing)
            if not owned then old_output = '__camera_mix_unconfigured_output_' .. n end
        end
        local existing_scene = obs.obs_get_source_by_name(b.scene)
        if existing_scene then
            local scene, count, connected = scene_info(existing_scene, b.output)
            obs.obs_source_release(existing_scene)
            if not scene or (count > 0 and not connected) then old_scene = '__camera_mix_unconfigured_scene_' .. n end
        end
        local label = obs.obs_data_get_string(script_settings, 'me_label_' .. n):match('^%s*(.-)%s*$')
        if label == '' then log(b, 'ME 이름을 입력하세요.'); return false end
        local scene = obs.obs_data_get_string(script_settings, 'output_name_' .. n):match('^%s*(.-)%s*$')
        local manager = obs.obs_data_get_string(script_settings, 'input_name_' .. n):match('^%s*(.-)%s*$')
        if scene == '' then scene = label .. (n == 1 and ' PGM Output' or ' SUB Output') end
        if manager == '' then manager = label .. ' Camera Inputs' end
        local output = n == 1 and label .. ' PGM Camera MIX' or manager
        if not propose(old_scene, scene) or not propose(old_output, output) then return false end
        local slots = read_array(script_settings, key(n, 'slots'))
        if n > 1 then
            if #slots == 0 then slots = b.cameras end
            local manager_source = obs.obs_get_source_by_name(b.manager)
            local parent = manager_source and obs.obs_scene_from_source(manager_source)
            if not parent then slots = {} end
            for i, old in ipairs(slots) do
                local group = parent and obs.obs_scene_get_group(parent, old)
                if group then
                    local data = obs.obs_source_get_settings(obs.obs_sceneitem_get_source(group))
                    local owned = controller_flag(data, 'group')
                    obs.obs_data_release(data)
                    if not owned then if manager_source then obs.obs_source_release(manager_source) end; log(b, '소유 그룹만 이름을 변경할 수 있습니다.'); return false end
                    local target = label .. '-' .. origin_name(old)
                    if not propose(old, target) then if manager_source then obs.obs_source_release(manager_source) end; return false end
                    slots[i] = target
                end
            end
            if manager_source then obs.obs_source_release(manager_source) end
        end
        desired[n] = {scene=scene, output=output, manager=manager, slots=slots, label=label, count=#b.cameras}
    end
    -- All names are checked before any source is renamed.
    for _, entry in ipairs(plan) do
        if entry.old ~= entry.new then
            local source = obs.obs_get_source_by_name(entry.old)
            if source then obs.obs_source_set_name(source, entry.new); obs.obs_source_release(source) end
        end
    end
    for n, names in ipairs(desired) do
        local b = banks[n]
        b.scene, b.output, b.manager, b.label = names.scene, names.output, names.manager, names.label
        if b.engine then obs.obs_source_set_name(b.engine.fade, b.label .. ' Camera MIX') end
        for _, field in ipairs({'scene','output','manager'}) do obs.obs_data_set_string(script_settings, key(n, field), b[field]) end
        if n > 1 then
            b.cameras = {}
            for i = 1, names.count do if names.slots[i] then b.cameras[i] = names.slots[i] end end
            write_array(script_settings, key(n, 'cameras'), b.cameras)
            write_array(script_settings, key(n, 'slots'), names.slots)
        end
    end
    return true
end
local function convert_groups(b)
    local source = obs.obs_get_source_by_name(b.manager)
    local manager = source and obs.obs_scene_from_source(source)
    if source then
        local data = obs.obs_source_get_settings(source)
        local owned = controller_flag(data, 'manager')
        obs.obs_data_release(data)
        if not manager or not owned then obs.obs_source_release(source); log(b, '입력 장면 이름 충돌'); return false end
    else
        manager = obs.obs_scene_create(b.manager)
        if not manager then return false end
        local data = obs.obs_data_create()
        obs.obs_data_set_bool(data, 'camera_mix_hybrid_manager', true)
        obs.obs_source_update(obs.obs_scene_get_source(manager), data)
        obs.obs_data_release(data)
    end
    local groups = {}
    local slots = read_array(script_settings, key(b.number, 'slots'))
    for i, name in ipairs(b.cameras) do
        local groupname = b.label .. '-' .. name
        local group = obs.obs_scene_get_group(manager, slots[i] or groupname) or obs.obs_scene_get_group(manager, groupname)
        local collision = obs.obs_get_source_by_name(groupname)
        if collision and (not group or obs.obs_source_get_name(collision) ~= obs.obs_source_get_name(obs.obs_sceneitem_get_source(group))) then
            obs.obs_source_release(collision)
            if source then obs.obs_source_release(source) else obs.obs_scene_release(manager) end
            log(b, '그룹 이름이 이미 사용 중입니다: ' .. groupname); return false
        end
        if collision then obs.obs_source_release(collision) end
        if group then obs.obs_source_set_name(obs.obs_sceneitem_get_source(group), groupname) end
        if not group then group = obs.obs_scene_add_group2(manager, groupname, true) end
        if not group then if source then obs.obs_source_release(source) else obs.obs_scene_release(manager) end; return false end
        local inner = obs.obs_sceneitem_group_get_scene(group)
        local items = obs.obs_scene_enum_items(inner)
        local primary
        for _, item in ipairs(items or {}) do
            local data = obs.obs_sceneitem_get_private_settings(item)
            if controller_flag(data, 'primary') then primary = item end
            obs.obs_data_release(data)
        end
        if items then obs.sceneitem_list_release(items) end
        if not primary or obs.obs_source_get_name(obs.obs_sceneitem_get_source(primary)) ~= name then
            local input = obs.obs_get_source_by_name(name)
            if not input then if source then obs.obs_source_release(source) else obs.obs_scene_release(manager) end; return false end
            obs.obs_sceneitem_defer_group_resize_begin(group)
            local item = obs.obs_scene_add(inner, input)
            obs.obs_source_release(input)
            if not item then obs.obs_sceneitem_defer_group_resize_end(group); if source then obs.obs_source_release(source) else obs.obs_scene_release(manager) end; return false end
            if primary then
                local info, crop = obs.obs_transform_info(), obs.obs_sceneitem_crop()
                obs.obs_sceneitem_get_info2(primary, info); obs.obs_sceneitem_get_crop(primary, crop)
                obs.obs_sceneitem_set_info2(item, info); obs.obs_sceneitem_set_crop(item, crop)
                obs.obs_sceneitem_set_locked(item, obs.obs_sceneitem_locked(primary))
                obs.obs_sceneitem_set_visible(item, obs.obs_sceneitem_visible(primary))
                obs.obs_sceneitem_set_scale_filter(item, obs.obs_sceneitem_get_scale_filter(primary))
                obs.obs_sceneitem_set_blending_mode(item, obs.obs_sceneitem_get_blending_mode(primary))
                obs.obs_sceneitem_set_blending_method(item, obs.obs_sceneitem_get_blending_method(primary))
                local order = obs.obs_sceneitem_get_order_position(primary)
                obs.obs_sceneitem_remove(primary)
                obs.obs_sceneitem_set_order_position(item, order)
            end
            local data = obs.obs_sceneitem_get_private_settings(item)
            obs.obs_data_set_bool(data, 'camera_mix_hybrid_primary', true); obs.obs_data_release(data)
            obs.obs_sceneitem_defer_group_resize_end(group)
        end
        local data = obs.obs_source_get_settings(obs.obs_sceneitem_get_source(group))
        obs.obs_data_set_bool(data, 'camera_mix_group', true)
        obs.obs_data_set_bool(data, 'camera_mix_hybrid_group', true)
        obs.obs_data_set_string(data, 'camera_mix_origin', name)
        obs.obs_source_update(obs.obs_sceneitem_get_source(group), data); obs.obs_data_release(data)
        groups[i] = groupname
    end
    -- Unused stable slots are kept hidden so their added decorations are not lost.
    local items = obs.obs_scene_enum_items(manager)
    for _, item in ipairs(items or {}) do
        if obs.obs_sceneitem_is_group(item) then
            obs.obs_sceneitem_set_transition(item, true, nil); obs.obs_sceneitem_set_transition(item, false, nil)
            obs.obs_sceneitem_set_visible(item, obs.obs_source_get_name(obs.obs_sceneitem_get_source(item)) == groups[1])
        end
    end
    if items then obs.sceneitem_list_release(items) end
    if source then obs.obs_source_release(source) else obs.obs_scene_release(manager) end
    b.cameras, b.wrap, b.selected = groups, false, 1
    write_array(script_settings, key(b.number, 'cameras'), groups)
    for i, name in ipairs(groups) do slots[i] = name end
    write_array(script_settings, key(b.number, 'slots'), slots)
    obs.obs_data_set_bool(script_settings, key(b.number, 'wrap'), false)
    return true
end

local function reuse_existing(b)
    if now_ms() < b.locked_until then log(b, '전환이 끝난 뒤 재사용을 적용하세요.'); return false end
    if #b.cameras < 2 then log(b, '카메라 목록을 먼저 등록하세요.'); return false end
    local reused = {}
    for i, name in ipairs(b.cameras) do
        local candidate = 'ME' .. b.number .. '-' .. name
        local direct = obs.obs_get_source_by_name(name)
        local direct_scene = direct ~= nil and obs.obs_scene_from_source(direct) or nil
        if direct ~= nil then obs.obs_source_release(direct) end
        if not b.wrap and direct_scene ~= nil then candidate = name end
        local source = obs.obs_get_source_by_name(candidate)
        if source == nil then log(b, '기존 배치 장면을 찾을 수 없습니다: ' .. candidate .. '. 목록에 기존 장면 이름을 직접 입력하고 생성 옵션을 끄세요.'); return false end
        local scene, _, found = scene_info(source, name)
        local invalid = forbidden_source(source, {})
        obs.obs_source_release(source)
        if scene == nil or invalid or (candidate ~= name and not found) then
            log(b, '기존 장면의 카메라 입력이 다르거나 순환합니다: ' .. candidate); return false
        end
        reused[i] = candidate
    end
    local old_cameras, old_wrap = b.cameras, b.wrap
    b.cameras, b.wrap = reused, false
    if not apply_list(b) then b.cameras, b.wrap = old_cameras, old_wrap; return false end
    write_array(script_settings, key(b.number, 'cameras'), reused)
    obs.obs_data_set_bool(script_settings, key(b.number, 'wrap'), false)
    if loaded then sync_hotkeys() end
    obs.script_log(obs.LOG_INFO, '[Camera MIX ME' .. b.number .. '] 기존 배치 장면으로 전환했습니다. 새 장면은 생성하지 않았습니다.')
    return true
end
function script_description()
    return 'Sunjoo OBS Link Controller ' .. VERSION .. ' / 제작자: ' .. AUTHOR .. '\n개발판: Lua + 복제 지원 플러그인 / ME1~ME8 / OBS 재시작 시 마지막 카메라와 설정 자동 복원\n글로벌 옵션에서 ME 이름·공통 전환 타입과 시간을 지정하세요.\nME1: 기존 장면 전환. ME2 이후: 배치 포함 화면을 하나의 Fade로 MIX.\n입력 교체 시 그룹의 배치와 추가 항목을 유지합니다.\n전체 적용 버튼을 누르면 카메라 1로 전환됩니다.'
end

local function original_input(b, index)
    return origin_name(input_names(b)[index] or '')
end
local function ready(b)
    if not b or #b.cameras < 2 then return false end
    local source = obs.obs_get_source_by_name(b.output)
    if not source then return false end
    local valid = obs.obs_source_get_unversioned_id(source) == (b.number == 1 and 'source_switcher' or 'scene')
    if valid and b.number > 1 then
        local scene = obs.obs_scene_from_source(source)
        for _, name in ipairs(b.cameras) do if not obs.obs_scene_get_group(scene, name) then valid = false end end
    elseif valid then
        local data = obs.obs_source_get_settings(source)
        local actual = read_array(data, 'sources'); obs.obs_data_release(data)
        valid = #actual == #b.cameras
        for i, name in ipairs(b.cameras) do if actual[i] ~= name then valid = false end end
    end
    obs.obs_source_release(source)
    local output = obs.obs_get_source_by_name(b.scene)
    if not output then return false end
    local _, _, connected = scene_info(output, b.output)
    obs.obs_source_release(output)
    return valid and connected
end

local function setup_all()
    if not obs.obs_source_get_display_name('camera_mix_hybrid_output') then
        log(nil, 'Sunjoo OBS Link Controller 출력 플러그인을 먼저 설치하세요.'); return false
    end
    if not apply_names() then return false end
    -- Preflight every bank before creating any output.
    for n = 1, me_count do
        if n > 1 then
            local manager = obs.obs_get_source_by_name(banks[n].manager)
            local parent = manager and obs.obs_scene_from_source(manager)
            if manager then
                local data = obs.obs_source_get_settings(manager)
                local owned = controller_flag(data, 'manager')
                obs.obs_data_release(data); obs.obs_source_release(manager)
                if not owned then log(banks[n], '입력 장면 이름이 다른 장면과 충돌합니다.'); return false end
            end
            for i = 1, obs.obs_data_get_int(script_settings, key(n, 'setup_count')) do
                local slots = read_array(script_settings, key(n, 'slots'))
                local groupname = slots[i] or banks[n].label .. '-' .. obs.obs_data_get_string(script_settings, key(n, 'pick_' .. i))
                local existing = obs.obs_get_source_by_name(groupname)
                if existing then
                    local data = obs.obs_source_get_settings(existing)
                    local owned = controller_flag(data, 'group')
                    obs.obs_data_release(data)
                    local belongs = parent and obs.obs_scene_get_group(parent, groupname)
                    obs.obs_source_release(existing)
                    if not owned or not belongs then log(banks[n], '그룹 이름이 다른 소스와 충돌합니다.'); return false end
                end
            end
        end
        local count = obs.obs_data_get_int(script_settings, key(n, 'setup_count'))
        if count < 2 or count > MAX_CAM then log(banks[n], '카메라 수는 2~16대로 지정하세요.'); return false end
        local seen = {}
        for i = 1, count do
            local name = obs.obs_data_get_string(script_settings, key(n, 'pick_' .. i))
            if seen[name] then log(banks[n], '같은 소스를 두 번 선택했습니다: ' .. name); return false end
            seen[name] = true
            local source = obs.obs_get_source_by_name(name)
            if source == nil then log(banks[n], '카메라 ' .. i .. '의 OBS 소스를 선택하세요.'); return false end
            local invalid = forbidden_source(source, {}) or is_manager_name(name) or name == ANCHOR_NAME
            local is_scene = obs.obs_scene_from_source(source) ~= nil
            obs.obs_source_release(source)
            if invalid then log(banks[n], '카메라 입력으로 사용할 수 없는 소스입니다: ' .. name); return false end
            if n == 1 and not is_scene then log(banks[n], 'ME1에는 카메라 장면을 선택하세요: ' .. name); return false end
        end
        if now_ms() < banks[n].locked_until then log(banks[n], '전환이 끝난 뒤 적용하세요.'); return false end
        local output = obs.obs_get_source_by_name(banks[n].output)
        if output ~= nil then
            local valid = obs.obs_source_get_unversioned_id(output) == (n == 1 and 'source_switcher' or 'scene')
            obs.obs_source_release(output)
            if not valid then log(banks[n], '출력 이름이 사용 중입니다. 고급 설정에서 출력 소스 이름을 바꾸세요.'); return false end
        end
        local output_scene = obs.obs_get_source_by_name(banks[n].scene)
        if output_scene ~= nil then
            local scene, count, connected = scene_info(output_scene, banks[n].output)
            obs.obs_source_release(output_scene)
            if scene == nil or (count > 0 and not connected) then log(banks[n], '출력 장면 이름이 사용 중입니다. 고급 설정에서 출력 장면 이름을 바꾸세요.'); return false end
        end
    end
    for n = 1, me_count do
        local b, picks = banks[n], {}
        local retained = input_names(b)
        local count = obs.obs_data_get_int(script_settings, key(n, 'setup_count'))
        local unchanged = #b.cameras == count
        for i = 1, count do
            picks[i] = obs.obs_data_get_string(script_settings, key(n, 'pick_' .. i))
            if picks[i] ~= original_input(b, i) then unchanged = false
            elseif n > 1 and retained[i] ~= nil then picks[i] = retained[i] end
        end
        local old_cameras, old_wrap = b.cameras, b.wrap
        if n == 1 then
            b.cameras, b.wrap = picks, false
            if not create_scene(b) then b.cameras, b.wrap = old_cameras, old_wrap; return false end
            write_array(script_settings, 'cameras', picks)
            obs.obs_data_set_bool(script_settings, 'wrap', false)
        else
            for i = 1, count do picks[i] = obs.obs_data_get_string(script_settings, key(n, 'pick_' .. i)) end
            b.cameras, b.wrap = picks, false
            if not convert_groups(b) then b.cameras, b.wrap = old_cameras, old_wrap; return false end
            if not create_scene(b) then return false end
        end
    end
    if loaded then sync_hotkeys() end
    obs.script_log(obs.LOG_INFO, '[Camera MIX] 전체 설정 완료. 카메라 전환을 사용할 수 있습니다.')
    return true
end
local function refresh_options(props)
    local names, listed, scenes = {}, {}, {}
    local function collect(sources)
        if sources == nil then return end
        for _, source in ipairs(sources) do
            local name = obs.obs_source_get_name(source)
            scenes[name] = obs.obs_scene_from_source(source) ~= nil
            local s = obs.obs_source_get_settings(source)
            local generated = obs.obs_data_get_bool(s, 'camera_mix_group') or obs.obs_data_get_bool(s, 'camera_mix_anchor')
            obs.obs_data_release(s)
            if not listed[name] and not generated and not is_manager_name(name) and not forbidden_source(source, {}) then names[#names + 1] = name; listed[name] = true end
        end
        obs.source_list_release(sources)
    end
    collect(obs.obs_enum_sources())
    collect(obs.obs_frontend_get_scenes())
    table.sort(names)
    for n = 1, MAX_ME do
        for i = 1, MAX_CAM do
            local prop = obs.obs_properties_get(props, key(n, 'pick_' .. i))
            obs.obs_property_list_clear(prop)
            obs.obs_property_list_add_string(prop, n == 1 and '카메라 장면을 선택하세요' or '카메라 소스 또는 장면을 선택하세요', '')
            for _, name in ipairs(names) do
                if n > 1 or scenes[name] then obs.obs_property_list_add_string(prop, name .. (scenes[name] and ' [장면]' or ' [소스]'), name) end
            end
            local current = obs.obs_data_get_string(script_settings, key(n, 'pick_' .. i))
            if current ~= '' and (not listed[current] or (n == 1 and not scenes[current])) then obs.obs_property_list_add_string(prop, current .. ' (다시 선택 필요)', current) end
        end
    end
    local status = {}
    for n = 1, me_count do status[#status + 1] = 'ME' .. n .. ': ' .. (ready(banks[n]) and '준비됨' or '설정 필요') end
    obs.obs_property_set_description(obs.obs_properties_get(props, 'status'), table.concat(status, ' / '))
end
local function edit_layout(b)
    if not obs.obs_frontend_preview_program_mode_active() then
        log(b, '배치 편집은 OBS 스튜디오 모드를 켠 뒤 실행하세요. 미리보기에서 편집할 수 있습니다.'); return false
    end
    local index = obs.obs_data_get_int(script_settings, key(b.number, 'edit_camera'))
    local name = input_names(b)[index]
    if b.number == 1 then
        local scene = name ~= nil and obs.obs_get_source_by_name(name) or nil
        if scene == nil then log(b, '먼저 카메라 장면을 선택해 적용하세요.'); return false end
        if obs.obs_scene_from_source(scene) == nil then obs.obs_source_release(scene); log(b, 'ME1의 입력을 카메라 장면으로 다시 적용하세요.'); return false end
        obs.obs_frontend_set_current_preview_scene(scene)
        obs.obs_source_release(scene)
        return true
    end
    local source = obs.obs_get_source_by_name(b.manager)
    local manager = source ~= nil and obs.obs_scene_from_source(source) or nil
    if manager == nil then
        if source ~= nil then obs.obs_source_release(source) end
        log(b, '먼저 설정 완료 / 전체 적용을 실행하세요.'); return false
    end
    local chosen = name ~= nil and obs.obs_scene_get_group(manager, name) or nil
    if chosen == nil then obs.obs_source_release(source); log(b, '이 카메라의 배치를 먼저 적용하세요.'); return false end
    local items = obs.obs_scene_enum_items(manager)
    if items ~= nil then
        for _, item in ipairs(items) do
            local selected = obs.obs_source_get_name(obs.obs_sceneitem_get_source(item)) == name
            -- Selecting an item for editing never changes broadcast visibility.
            obs.obs_sceneitem_select(item, selected)
        end
        obs.sceneitem_list_release(items)
    end
    obs.obs_frontend_set_current_preview_scene(source)
    obs.obs_source_release(source)
    return true
end
local function apply_group_position(b) return true end

local function visibility(props, _, settings)
    local count = math.max(1, math.min(MAX_ME, obs.obs_data_get_int(settings, 'me_count')))
    local selected = math.max(1, math.min(count, obs.obs_data_get_int(settings, 'selected_me')))
    obs.obs_data_set_int(settings, 'selected_me', selected)
    local advanced = obs.obs_data_get_bool(settings, 'show_settings')
    for n = 1, MAX_ME do
        for _, field in ipairs({'me_label_', 'output_name_', 'input_name_'}) do
            obs.obs_property_set_visible(obs.obs_properties_get(props, field .. n), advanced and n <= count and (field ~= 'input_name_' or n > 1))
        end
    end
    obs.obs_property_set_visible(obs.obs_properties_get(props, 'apply_names'), advanced)
    local expert = obs.obs_data_get_bool(settings, 'expert_settings')
    local target = math.max(0, math.min(count, obs.obs_data_get_int(settings, 'control_target')))
    obs.obs_data_set_int(settings, 'control_target', target)
    local selector = obs.obs_properties_get(props, 'selected_me')
    obs.obs_property_list_clear(selector)
    for n = 1, count do obs.obs_property_list_add_int(selector, obs.obs_data_get_string(settings, 'me_label_' .. n) .. (n == 1 and ' — 장면 전환' or ' — 그룹 배치'), n) end
    obs.obs_property_set_visible(obs.obs_properties_get(props, 'me_count'), advanced)
    for _, name in ipairs({'selected_me', 'setup_all', 'setup_help', 'refresh_sources', 'independent_hotkeys'}) do
        obs.obs_property_set_visible(obs.obs_properties_get(props, name), advanced)
    end
    obs.obs_property_set_visible(obs.obs_properties_get(props, 'expert_settings'), false)
    obs.obs_property_set_visible(obs.obs_properties_get(props, 'common'), target == 0)
    local target_prop = obs.obs_properties_get(props, 'control_target')
    obs.obs_property_list_clear(target_prop)
    obs.obs_property_list_add_int(target_prop, '전체 ME 연동', 0)
    for n = 1, count do obs.obs_property_list_add_int(target_prop, obs.obs_data_get_string(settings, 'me_label_' .. n) .. '만 전환', n) end
    local common_count = MAX_CAM
    for n = 1, count do common_count = math.min(common_count, #read_array(settings, key(n, 'cameras'))) end
    for i = 1, MAX_CAM do obs.obs_property_set_visible(obs.obs_properties_get(props, 'camera_' .. i), i <= common_count) end
    for n = 1, MAX_ME do
        local chosen = n == selected
        local camera_count = #read_array(settings, key(n, 'cameras'))
        local wrap = obs.obs_data_get_bool(settings, key(n, 'wrap'))
        obs.obs_property_set_visible(obs.obs_properties_get(props, 'independent_' .. n), target == n and n <= count)
        obs.obs_property_set_visible(obs.obs_properties_get(props, 'me' .. n .. '_cut_button'), false)
        obs.obs_property_set_visible(obs.obs_properties_get(props, 'me' .. n .. '_mix_button'), false)
        obs.obs_property_set_visible(obs.obs_properties_get(props, 'bank_' .. n), advanced and chosen)
        obs.obs_property_set_visible(obs.obs_properties_get(props, key(n, 'group_position')), false)
        for _, name in ipairs({'output', 'scene', 'manager', 'cameras', 'wrap', 'group_prefix', 'groups', 'apply', 'create', 'reuse'}) do
            local group_option = name == 'manager' or name == 'wrap' or name == 'group_prefix' or name == 'groups' or name == 'reuse'
            obs.obs_property_set_visible(obs.obs_properties_get(props, key(n, name)), false)
        end
        obs.obs_property_set_visible(obs.obs_properties_get(props, key(n, 'prefix')), false)
        obs.obs_property_set_visible(obs.obs_properties_get(props, key(n, 'layouts')), false)
        local setup_count = obs.obs_data_get_int(settings, key(n, 'setup_count'))
        for i = 1, MAX_CAM do obs.obs_property_set_visible(obs.obs_properties_get(props, key(n, 'pick_' .. i)), i <= setup_count) end
        for i = 1, MAX_CAM do obs.obs_property_set_visible(obs.obs_properties_get(props, 'me' .. n .. '_camera_' .. i), chosen and i <= camera_count) end
    end
    return true
end
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, 'credits', AUTHOR .. ' | Sunjoo OBS Link Controller v' .. VERSION, obs.OBS_TEXT_INFO)
    local global = obs.obs_properties_create()
    for n = 1, MAX_ME do
        obs.obs_properties_add_text(global, 'me_label_' .. n, 'Hybrid ME' .. n .. ' 이름', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(global, 'output_name_' .. n, 'ME' .. n .. ' 출력 장면 이름 (비우면 자동)', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(global, 'input_name_' .. n, 'ME' .. n .. ' 입력 장면 이름 (비우면 자동)', obs.OBS_TEXT_DEFAULT)
    end
    obs.obs_properties_add_button(global, 'apply_names', '이름만 적용 (배치·카메라 선택 유지)', function() local ok = apply_names(); refresh_options(props); return ok end)
    obs.obs_properties_add_group(props, 'global_options', '글로벌 옵션 — 이름 / 전환 타입 / 시간', obs.OBS_GROUP_NORMAL, global)
    local status = {}
    for n = 1, me_count do status[#status + 1] = 'ME' .. n .. ': ' .. (ready(banks[n]) and '준비됨' or '설정 필요') end
    obs.obs_properties_add_text(props, 'status', table.concat(status, ' / '), obs.OBS_TEXT_INFO)
    local target = obs.obs_properties_add_list(props, 'control_target', '제어 대상', obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
    obs.obs_property_set_modified_callback(target, visibility)
    local mode = obs.obs_properties_add_list(global, 'mode', '공통 전환 타입 (모든 ME)', obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_list_add_string(mode, 'MIX', 'MIX')
    obs.obs_property_list_add_string(mode, 'CUT', 'CUT')
    obs.obs_properties_add_int(global, 'duration', '공통 MIX 시간 (ms)', 50, 5000, 10)
    local advanced = obs.obs_properties_add_bool(props, 'show_settings', '카메라·화면 설정 열기')
    obs.obs_property_set_modified_callback(advanced, visibility)
    obs.obs_properties_add_text(props, 'setup_help', 'ME1 = 카메라 장면 그대로 전환 / ME2 이후 = 카메라별 그룹 배치\n① 설정할 ME 선택 → ② 목록에서 입력 선택 → ③ 아래 전체 적용\n적용 시 모든 ME가 카메라 1로 전환됩니다.', obs.OBS_TEXT_INFO)
    local expert = obs.obs_properties_add_bool(props, 'expert_settings', '고급 설정 (사용하지 않음)')
    obs.obs_property_set_modified_callback(expert, visibility)
    obs.obs_properties_add_button(props, 'refresh_sources', 'OBS 소스 목록 / 준비 상태 새로고침', function() refresh_options(props); return true end)
    obs.obs_properties_add_bool(props, 'independent_hotkeys', 'ME별 독립 단축키 사용')
    local selector = obs.obs_properties_add_list(props, 'selected_me', '① 설정할 ME', obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
    obs.obs_property_set_modified_callback(selector, visibility)
    local count = obs.obs_properties_add_int(props, 'me_count', '사용할 ME 개수 (1~8)', 1, MAX_ME, 1)
    obs.obs_property_set_modified_callback(count, visibility)
    local common = obs.obs_properties_create()
    obs.obs_properties_add_button(common, 'all_cut', '전체 ME: CUT 모드', function() set_mode('CUT'); return false end)
    obs.obs_properties_add_button(common, 'all_mix', '전체 ME: MIX 모드', function() set_mode('MIX'); return false end)
    for i = 1, MAX_CAM do
        local index = i
        obs.obs_properties_add_button(common, 'camera_' .. i, '연동 카메라 ' .. i, function() linked_request(index); return false end)
    end
    obs.obs_properties_add_group(props, 'common', '전체 ME 연동 선택', obs.OBS_GROUP_NORMAL, common)
    for n = 1, MAX_ME do
        local number = n
        local p = obs.obs_properties_create()
        local size = obs.obs_properties_add_int(p, key(n, 'setup_count'), '카메라 수', 2, MAX_CAM, 1)
        obs.obs_property_set_modified_callback(size, visibility)
        for i = 1, MAX_CAM do
            obs.obs_properties_add_list(p, key(n, 'pick_' .. i), '카메라 ' .. i .. (n == 1 and ' → 전환할 장면' or ' → 그룹에 넣을 소스 / 장면'), obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
        end
        obs.obs_properties_add_int(p, key(n, 'edit_camera'), '배치 편집할 카메라 번호', 1, MAX_CAM, 1)
        obs.obs_properties_add_button(p, key(n, 'edit_layout'), n == 1 and '선택 카메라 장면 열기 (미리보기)' or '선택 카메라 그룹 열기 (미리보기)', function() edit_layout(banks[number]); return false end)
        obs.obs_properties_add_button(p, key(n, 'group_position'), '그룹 전체 위치를 출력에 적용', function() apply_group_position(banks[number]); return false end)
        local help = n == 1 and '기존 장면의 자막·장식을 포함해 전환합니다.' or '그룹 자체 또는 안의 항목을 이동·크기 조정하세요. 바로 반영됩니다.\n배치 편집 버튼은 표시 상태를 바꾸지 않습니다. 현재 선택 카메라가 보입니다.\n이 입력 장면은 방송 출력과 공유됩니다. 배치는 방송 전에 조정하세요.'
        obs.obs_properties_add_text(p, key(n, 'edit_help'), help, obs.OBS_TEXT_INFO)
        obs.obs_properties_add_text(p, key(n, 'manager'), '이 ME의 입력 관리 장면 이름', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(p, key(n, 'output'), '출력 소스 이름', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(p, key(n, 'scene'), '출력 장면 이름', obs.OBS_TEXT_DEFAULT)
        local cameras = obs.obs_properties_add_editable_list(p, key(n, 'cameras'), '카메라 목록 (기존 장면/소스 이름, 같은 번호끼리 연동)', obs.OBS_EDITABLE_LIST_TYPE_STRINGS, nil, nil)
        obs.obs_property_set_modified_callback(cameras, visibility)
        local wrap = obs.obs_properties_add_bool(p, key(n, 'wrap'), '새 배치 장면이 필요할 때만 생성 (원본 이름 등록)')
        obs.obs_property_set_modified_callback(wrap, visibility)
        obs.obs_properties_add_text(p, key(n, 'prefix'), '배치 장면 접두사 (예: ME2-CAM)', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_text(p, key(n, 'group_prefix'), '카메라 그룹 접두사 (예: ME2-GCAM)', obs.OBS_TEXT_DEFAULT)
        obs.obs_properties_add_button(p, key(n, 'groups'), '이 ME: 그룹 입력으로 변환/적용', function()
            if convert_groups(banks[number]) then visibility(props, nil, script_settings); return true end
            return false
        end)
        obs.obs_properties_add_button(p, key(n, 'layouts'), '이 ME: 배치 장면만 생성/확인', function() ensure_layouts(banks[number]); return false end)
        obs.obs_properties_add_button(p, key(n, 'apply'), '이 ME: 목록 적용 / 출력 소스 생성', function() apply_list(banks[number]); return false end)
        obs.obs_properties_add_button(p, key(n, 'create'), '이 ME: 출력 장면 생성/확인', function() create_scene(banks[number]); return false end)
        obs.obs_properties_add_button(p, key(n, 'reuse'), '이 ME: 기존 ME번호-cam 장면 재사용', function()
            if reuse_existing(banks[number]) then visibility(props, nil, script_settings); return true end
            return false
        end)
        obs.obs_properties_add_group(props, 'bank_' .. n, n == 1 and 'ME1 — 장면 전환 (자막·장식 포함)' or ('ME' .. n .. ' — 그룹 전환 (카메라별 자유 배치)'), obs.OBS_GROUP_NORMAL, p)
        local controls = obs.obs_properties_create()
        obs.obs_properties_add_button(controls, 'me' .. n .. '_cut_button', '공통 CUT 모드', function() set_mode('CUT', number); return false end)
        obs.obs_properties_add_button(controls, 'me' .. n .. '_mix_button', '공통 MIX 모드', function() set_mode('MIX', number); return false end)
        for i = 1, MAX_CAM do
            local index = i
            obs.obs_properties_add_button(controls, 'me' .. n .. '_camera_' .. i, 'ME' .. n .. '만: 카메라 ' .. i, function() select_independent(banks[number], index); return false end)
        end
        obs.obs_properties_add_group(props, 'independent_' .. n, 'ME' .. n .. ' 개별 제어', obs.OBS_GROUP_NORMAL, controls)
    end
    obs.obs_properties_add_button(props, 'setup_all', '③ 설정 완료 / 전체 적용', function() setup_all(); refresh_options(props); visibility(props, nil, script_settings); return true end)
    if script_settings ~= nil then refresh_options(props); visibility(props, nil, script_settings) end
    return props
end
function script_defaults(settings)
    obs.obs_data_set_default_int(settings, 'me_count', 1)
    obs.obs_data_set_default_int(settings, 'selected_me', 1)
    obs.obs_data_set_default_bool(settings, 'show_settings', false)
    obs.obs_data_set_default_bool(settings, 'expert_settings', false)
    obs.obs_data_set_default_int(settings, 'control_target', 0)
    obs.obs_data_set_default_string(settings, 'anchor_name', 'Camera MIX Transparent Canvas')
    obs.obs_data_set_default_bool(settings, 'independent_hotkeys', false)
    obs.obs_data_set_default_string(settings, 'group_manager', 'Hybrid Camera Inputs')
    for n = 1, MAX_ME do
        obs.obs_data_set_default_string(settings, 'me_label_' .. n, 'Hybrid ME' .. n)
        obs.obs_data_set_default_string(settings, 'output_name_' .. n, '')
        obs.obs_data_set_default_string(settings, 'input_name_' .. n, '')
        -- Existing configured sources are resolved before new defaults replace old defaults.
        obs.obs_data_set_default_string(settings, key(n, 'manager'), 'Hybrid ME' .. n .. ' Camera Inputs')
        obs.obs_data_set_default_string(settings, key(n, 'output'), n == 1 and 'Hybrid ME1 PGM Camera MIX' or 'Hybrid ME' .. n .. ' Camera Inputs')
        obs.obs_data_set_default_string(settings, key(n, 'scene'), 'Hybrid ME' .. n .. (n == 1 and ' PGM Output' or ' SUB Output'))
        obs.obs_data_set_default_string(settings, key(n, 'mode'), 'CUT')
        obs.obs_data_set_default_int(settings, key(n, 'duration'), 300)
        obs.obs_data_set_default_int(settings, key(n, 'edit_camera'), 1)
        -- 2.0 used wrap=true as a default, which may not be stored as a user value.
        -- Preserve already configured raw-camera banks on first upgrade; new banks
        -- remain direct/reuse mode. An explicit saved checkbox always wins.
        local existing = read_array(settings, key(n, 'cameras'))
        obs.obs_data_set_default_int(settings, key(n, 'setup_count'), math.max(2, #existing > 0 and #existing or 4))
        local legacy_wrap = n > 1 and #existing > 0
        local all_scenes = #existing > 0
        for _, name in ipairs(existing) do
            local source = obs.obs_get_source_by_name(name)
            if source == nil or obs.obs_scene_from_source(source) == nil then all_scenes = false end
            if source ~= nil then obs.obs_source_release(source) end
        end
        obs.obs_data_set_default_bool(settings, key(n, 'wrap'), legacy_wrap and not all_scenes)
        obs.obs_data_set_default_string(settings, key(n, 'prefix'), 'Hybrid ME' .. n .. '-CAM')
        obs.obs_data_set_default_string(settings, key(n, 'group_prefix'), 'Hybrid ME' .. n .. '-CAM')
        local defaults = existing
        for i = 1, MAX_CAM do
            local name = defaults[i] or ''
            if #existing > 0 and obs.obs_data_get_bool(settings, key(n, 'wrap')) then
                local layout_name = obs.obs_data_get_string(settings, key(n, 'prefix')) .. i
                local layout = obs.obs_get_source_by_name(layout_name)
                if layout ~= nil then name = layout_name; obs.obs_source_release(layout) end
            end
            name = origin_name(name)
            obs.obs_data_set_default_string(settings, key(n, 'pick_' .. i), name)
        end
    end
    obs.obs_data_set_int(settings, 'workflow_version', 270)
end
function script_update(settings)
    if script_settings ~= settings then
        obs.obs_data_addref(settings)
        if script_settings ~= nil then obs.obs_data_release(script_settings) end
        script_settings = settings
    end
    local new_count = math.max(1, math.min(MAX_ME, obs.obs_data_get_int(settings, 'me_count')))
    local previous_count = me_count
    local changed = new_count ~= me_count
    me_count = new_count
    legacy_manager_name = obs.obs_data_get_string(settings, 'group_manager')
    ANCHOR_NAME = obs.obs_data_get_string(settings, 'anchor_name')
    for n = 1, MAX_ME do
        local b = banks[n] or {number = n, locked_until = 0}
        local old_output, old_scene, old_mode, old_duration, old_wrap, old_prefix = b.output, b.scene, b.mode, b.duration, b.wrap, b.prefix
        local old_cameras = b.cameras or {}
        b.output, b.scene = obs.obs_data_get_string(settings, key(n, 'output')), obs.obs_data_get_string(settings, key(n, 'scene'))
        b.mode = obs.obs_data_get_string(settings, 'mode') == 'CUT' and 'CUT' or 'MIX'
        b.duration = math.max(50, math.min(5000, obs.obs_data_get_int(settings, 'duration')))
        obs.obs_data_set_string(settings, key(n, 'mode'), b.mode)
        obs.obs_data_set_int(settings, key(n, 'duration'), b.duration)
        b.wrap, b.prefix = obs.obs_data_get_bool(settings, key(n, 'wrap')), obs.obs_data_get_string(settings, key(n, 'prefix'))
        b.manager = obs.obs_data_get_string(settings, key(n, 'manager'))
        b.label = obs.obs_data_get_string(settings, 'me_label_' .. n)
        b.group_prefix = obs.obs_data_get_string(settings, key(n, 'group_prefix'))
        b.cameras = read_array(settings, key(n, 'cameras'))
        local bank_changed = old_output ~= b.output or old_scene ~= b.scene or old_mode ~= b.mode or old_duration ~= b.duration or old_wrap ~= b.wrap or old_prefix ~= b.prefix or #old_cameras ~= #b.cameras
        for i, name in ipairs(b.cameras) do if name ~= old_cameras[i] then bank_changed = true end end
        if bank_changed then b.pending = nil; changed = true end
        banks[n] = b
    end
    if changed then
        linked_pending = nil
        for _, b in ipairs(banks) do b.pending, b.commit = nil, nil end
    end
    if loaded then
        for n = new_count + 1, previous_count do
            release_engine(banks[n])
            banks[n].locked_until = 0
            banks[n].restore_pending = true
        end
        for n = previous_count + 1, new_count do
            banks[n].locked_until = 0
            banks[n].restore_pending = true
        end
        if new_count ~= previous_count then restore_due = 0 end
        sync_hotkeys()
    end
end
local function save_hotkey(name, id, settings)
    local array = obs.obs_hotkey_save(id)
    obs.obs_data_set_array(settings, 'hotkey_' .. name, array)
    obs.obs_data_array_release(array)
end
local function hotkey_label(name)
    if name == 'mode_cut' then return '전체 CUT 모드' end
    if name == 'mode_mix' then return '전체 MIX 모드' end
    local camera = name:match('^camera_(%d+)$')
    if camera then return '연동 카메라 ' .. camera end
    local me, index = name:match('^me(%d+)_camera_(%d+)$')
    if me then return 'ME' .. me .. '만: 카메라 ' .. index end
    local number, mode = name:match('^me(%d+)_(%a+)$')
    return '공통 ' .. mode:upper() .. ' 모드 (기존 ME' .. number .. ' 키)'
end
sync_hotkeys = function()
    local wanted = {mode_cut = true, mode_mix = true}
    local common_count = MAX_CAM
    for n = 1, me_count do common_count = math.min(common_count, #banks[n].cameras) end
    for i = 1, common_count do wanted['camera_' .. i] = true end
    if obs.obs_data_get_bool(script_settings, 'independent_hotkeys') then
        for n = 1, me_count do
            local count = math.min(MAX_CAM, #banks[n].cameras)
            if count > 0 then
                wanted['me' .. n .. '_cut'], wanted['me' .. n .. '_mix'] = true, true
                for i = 1, count do wanted['me' .. n .. '_camera_' .. i] = true end
            end
        end
    end
    local removed = {}
    for name, id in pairs(hotkeys) do
        if not wanted[name] then
            save_hotkey(name, id, script_settings)
            obs.obs_hotkey_unregister(callbacks[name])
            removed[#removed + 1] = name
        end
    end
    for _, name in ipairs(removed) do hotkeys[name] = nil end
    -- Deterministic registration order, without replacing existing active IDs.
    local names = {}
    for name in pairs(wanted) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        if hotkeys[name] == nil then
            local id = obs.obs_hotkey_register_frontend('camera_mix_hybrid.' .. name, 'Sunjoo OBS Link Controller: ' .. hotkey_label(name), callbacks[name])
            hotkeys[name] = id
            local array = obs.obs_data_get_array(script_settings, 'hotkey_' .. name)
            obs.obs_hotkey_load(id, array)
            obs.obs_data_array_release(array)
        end
    end
end
function script_load(settings)
    script_update(settings)
    restore_due = 0
    for n = 1, MAX_ME do
        local saved = obs.obs_data_get_int(settings, key(n, 'last_camera'))
        banks[n].selected = saved >= 1 and saved <= #banks[n].cameras and saved or nil
        banks[n].locked_until = 0
        banks[n].restore_pending = true
    end
    for i = 1, MAX_CAM do
        local index = i
        callbacks['camera_' .. i] = function(pressed) if pressed then linked_request(index) end end
    end
    callbacks.mode_cut = function(pressed) if pressed then set_mode('CUT') end end
    callbacks.mode_mix = function(pressed) if pressed then set_mode('MIX') end end
    for n = 1, MAX_ME do
        local number = n
        for i = 1, MAX_CAM do
            local index = i
            callbacks['me' .. n .. '_camera_' .. i] = function(pressed)
                if pressed and number <= me_count then select_independent(banks[number], index) end
            end
        end
        callbacks['me' .. n .. '_cut'] = function(pressed) if pressed and number <= me_count then set_mode('CUT', number) end end
        callbacks['me' .. n .. '_mix'] = function(pressed) if pressed and number <= me_count then set_mode('MIX', number) end end
    end
    loaded = true
    restore_outputs()
    frontend_event = function(event)
        if event == obs.OBS_FRONTEND_EVENT_FINISHED_LOADING then restore_due = 0; restore_outputs() end
    end
    obs.obs_frontend_add_event_callback(frontend_event)
    sync_hotkeys()
    obs.timer_add(camera_mix_tick, 25)
end
function script_save(settings)
    for n = 1, MAX_ME do
        local b = banks[n]
        if n == 1 and not b.restore_pending then
            local source = obs.obs_get_source_by_name(b.output)
            if source then
                local index = math.floor(obs.obs_source_media_get_time(source) / 1000) + 1
                if index >= 1 and index <= #b.cameras then b.selected = index end
                obs.obs_source_release(source)
            end
        end
        if b.selected then obs.obs_data_set_int(settings, key(n, 'last_camera'), b.selected) end
        if b.engine then sync_engine(b) end
        obs.obs_data_set_string(settings, key(n, 'mode'), banks[n].mode)
        obs.obs_data_set_bool(settings, key(n, 'wrap'), banks[n].wrap)
    end
    for name in pairs(callbacks) do
        local id = hotkeys[name]
        if id ~= nil then save_hotkey(name, id, settings)
        else
            local array = obs.obs_data_get_array(script_settings, 'hotkey_' .. name)
            obs.obs_data_set_array(settings, 'hotkey_' .. name, array)
            obs.obs_data_array_release(array)
        end
    end
end
function script_unload()
    if script_settings then script_save(script_settings) end
    loaded = false
    obs.timer_remove(camera_mix_tick)
    if frontend_event then obs.obs_frontend_remove_event_callback(frontend_event); frontend_event = nil end
    for n = 2, MAX_ME do if banks[n] then release_engine(banks[n]) end end
    for name, id in pairs(hotkeys) do
        save_hotkey(name, id, script_settings)
        obs.obs_hotkey_unregister(callbacks[name])
    end
    for _, b in ipairs(banks) do if b.held ~= nil then obs.obs_source_release(b.held); b.held = nil end end
    for _, b in ipairs(banks) do b.pending, b.commit = nil, nil end
    if script_settings ~= nil then obs.obs_data_release(script_settings); script_settings = nil end
    hotkeys, callbacks, linked_pending = {}, {}, nil
end
