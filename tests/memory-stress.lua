-- Run the existing scenarios, then exercise controller ownership repeatedly.
local f = assert(io.open('tests/mock-controller.lua', 'rb'))
local code = f:read('*a'); f:close()
local stress = [[
local live_views = 0
local create_view, release_view = o.obs_scene_create_private, o.obs_scene_release
o.obs_scene_create_private = function(name)
    local view = create_view(name)
    if view then live_views = live_views + 1 end
    return view
end
o.obs_scene_release = function(view)
    if view.private then live_views = live_views - 1 end
    return release_view(view)
end
for cycle = 1, 100 do
    script_load(settings); script_properties()
    for apply = 1, 10 do
        buttons.setup_all()
        for camera = 1, 3 do
            clock = clock + 1000
            buttons['me2_camera_' .. camera]()
            camera_mix_tick()
        end
        assert(live_views == #settings.me2_cameras, 'private views accumulated')
        local selected_visible = {}
        for i, item in ipairs(manager.items) do selected_visible[i] = item.visible end
        settings.me_count = 1; script_update(settings)
        assert(live_views == 0 and #output.scene.items == 2, 'inactive ME retained engine')
        assert(output.scene.items[1].visible, 'saved manager connection must remain visible')
        settings.me_count = 2; script_update(settings)
        camera_mix_tick()
        assert(live_views == #settings.me2_cameras and #output.scene.items == 3, 'ME did not restore')
        for i, item in ipairs(manager.items) do assert(item.visible == selected_visible[i], 'selection lost') end
        assert(group.pos.x == 510 and group.source.group.items[2].source.name == 'caption', 'layout or decoration lost')
        -- Mock-only event history must not retain old engine objects.
        bus_transitions = {}; selections = {}; messages = {}
    end
    script_unload()
    assert(data_refs == 0 and source_refs == 0 and item_refs == 0, 'reference leak')
    assert(live_views == 0, 'private view leak')
    assert(timer == nil and frontend_callback == nil and next(keys) == nil, 'callback leak')
    collectgarbage('collect')
end
print('PASS memory stress: 100 load/unload cycles, 1000 applies, 3000 selections; references, private views, callbacks return to zero')
]]
local marker = "assert(script_description():find('SunjooAn')"
local offset = assert(code:find(marker, 1, true))
code = code:sub(1, offset - 1) .. stress .. code:sub(offset)
assert(loadstring(code, '@tests/mock-controller.lua + memory stress'))()
