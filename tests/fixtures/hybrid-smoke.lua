-- Appended to Hybrid Lua by the isolated OBS smoke test only.
local hybrid_load = script_load
function script_load(settings)
    local restored = obs.obs_data_get_bool(settings, 'hybrid_test_initialized')
    if not restored then
        obs.obs_data_set_int(settings, 'me_count', 2)
        obs.obs_data_set_int(settings, 'setup_count', 2)
        obs.obs_data_set_int(settings, 'me2_setup_count', 2)
        obs.obs_data_set_string(settings, 'pick_1', 'Test Scene 1')
        obs.obs_data_set_string(settings, 'pick_2', 'Test Scene 2')
        obs.obs_data_set_string(settings, 'me2_pick_1', 'Test Camera 1')
        obs.obs_data_set_string(settings, 'me2_pick_2', 'Test Camera 2')
    end
    hybrid_load(settings)
    local function run()
        obs.timer_remove(run)
        if not restored then
            assert(setup_all(), 'Hybrid setup failed')
            assert(setup_all(), 'Hybrid repeat apply failed')
            select_independent(banks[2],2)
            obs.obs_data_set_bool(settings,'hybrid_test_initialized',true)
        else
            restore_due=0; restore_outputs()
        end
        assert(banks[2].selected == 2 and not banks[2].restore_pending, 'Hybrid restore/selection failed')
        local source = obs.obs_get_source_by_name('Hybrid ME2 SUB Output')
        assert(source)
        local items = obs.obs_scene_enum_items(obs.obs_scene_from_source(source))
        local count = 0
        for _, item in ipairs(items) do
            if obs.obs_source_get_unversioned_id(obs.obs_sceneitem_get_source(item)) == 'camera_mix_hybrid_output' then count = count + 1 end
        end
        assert(count == 1, 'Hybrid duplicate runtime output')
        obs.sceneitem_list_release(items); obs.obs_source_release(source)
        local function finish()
            local file = assert(io.open(script_path() .. 'lua-smoke-ok.txt','wb'))
            file:write(restored and 'RESTORED' or 'CREATED'); file:close()
        end
        if restored then finish(); return end
        local function pgm_snapshot()
            local transition = obs.obs_get_output_source(0)
            local program = obs.obs_transition_get_active_source(transition)
            assert(program and obs.obs_source_get_name(program) == banks[2].scene, 'Studio did not copy output')
            local scene = obs.obs_scene_from_source(program)
            assert(scene)
            local result
            local list = obs.obs_scene_enum_items(scene)
            for _, item in ipairs(list) do
                local child = obs.obs_sceneitem_get_source(item)
                if obs.obs_source_get_unversioned_id(child) == 'camera_mix_hybrid_output' then
                    local data = obs.obs_source_get_settings(child)
                    local snapshot = obs.obs_get_source_by_uuid(obs.obs_data_get_string(data,'frozen_uuid'))
                    assert(snapshot and obs.obs_source_get_width(child) > 0, 'Studio clone has empty output')
                    local meta = obs.obs_source_get_private_settings(snapshot)
                    result = obs.obs_data_get_string(meta,'camera_mix_hybrid_original_uuid')
                    obs.obs_data_release(meta); obs.obs_source_release(snapshot); obs.obs_data_release(data)
                end
            end
            obs.sceneitem_list_release(list); obs.obs_source_release(program); obs.obs_source_release(transition)
            assert(result and result ~= '', 'Studio copy provenance missing')
            return result
        end
        obs.obs_frontend_set_preview_program_mode(true)
        local output = obs.obs_get_source_by_name(banks[2].scene)
        obs.obs_frontend_set_current_preview_scene(output); obs.obs_source_release(output)
        obs.obs_frontend_preview_program_trigger_transition()
        local second
        local first
        first = function()
            obs.timer_remove(first)
            local original = pgm_snapshot()
            assert(original == obs.obs_source_get_uuid(obs.obs_scene_get_source(banks[2].engine.views[2])), 'TAKE did not copy camera 2')
            select_independent(banks[2],1)
            assert(pgm_snapshot() == original, 'Preview change modified PGM')
            local preview = obs.obs_get_source_by_name(banks[2].scene)
            obs.obs_frontend_set_current_preview_scene(preview); obs.obs_source_release(preview)
            obs.obs_frontend_preview_program_trigger_transition()
            obs.timer_add(second,700)
        end
        second = function()
            obs.timer_remove(second)
            assert(pgm_snapshot() == obs.obs_source_get_uuid(obs.obs_scene_get_source(banks[2].engine.views[1])), 'Second TAKE did not copy camera 1')
            select_independent(banks[2],2)
            obs.script_log(obs.LOG_INFO,'PASS Hybrid Studio source-copy: Preview independent, TAKE updates PGM')
            finish()
        end
        obs.timer_add(first,700)
    end
    local finished
    finished = function(event)
        if event == obs.OBS_FRONTEND_EVENT_FINISHED_LOADING then
            obs.obs_frontend_remove_event_callback(finished)
            run()
        end
    end
    obs.obs_frontend_add_event_callback(finished)
end


