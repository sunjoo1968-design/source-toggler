"""Isolated libobs process: real groups, coordinates, and Source Switcher."""
import ctypes as C
import os
import time
from pathlib import Path

root = Path(__file__).resolve().parents[1]
binary = Path(r'C:\Program Files\obs-studio\bin\64bit')
os.chdir(binary)
directory = os.add_dll_directory(str(binary))
lib = C.CDLL(str(binary / 'obs.dll'))
P = C.c_void_p
def api(name, result, *args):
    f = getattr(lib, name); f.restype = result; f.argtypes = list(args); return f
class Video(C.Structure):
    _fields_ = [('graphics', C.c_char_p), ('fps_num', C.c_uint32), ('fps_den', C.c_uint32),
                ('base_width', C.c_uint32), ('base_height', C.c_uint32), ('output_width', C.c_uint32),
                ('output_height', C.c_uint32), ('format', C.c_int), ('adapter', C.c_uint32),
                ('gpu', C.c_bool), ('colorspace', C.c_int), ('range', C.c_int), ('scale', C.c_int)]
class Vec(C.Structure):
    _fields_ = [('x', C.c_float), ('y', C.c_float)]
class Frame(C.Structure):
    _fields_ = [('data', P * 8), ('linesize', C.c_uint32 * 8), ('timestamp', C.c_uint64)]
last_frame = []
@C.CFUNCTYPE(None, P, C.POINTER(Frame))
def receive(_, frame):
    f = frame.contents
    last_frame[:] = [C.string_at(f.data[0], f.linesize[0] * 720), f.linesize[0]]
startup = api('obs_startup', C.c_bool, C.c_char_p, C.c_char_p, P)
assert startup(b'en-US', None, None)
extra_scenes, extra_sources, private_scenes = [], [], []
try:
    video = Video(b'libobs-d3d11', 30, 1, 1280, 720, 1280, 720, 6, 0, True, 2, 1, 1)
    assert api('obs_reset_video', C.c_int, C.POINTER(Video))(C.byref(video)) == 0
    open_module = api('obs_open_module', C.c_int, C.POINTER(P), C.c_char_p, C.c_char_p)
    for name in ('image-source', 'obs-transitions', 'source-switcher', 'obs-filters'):
        module = P()
        dll = binary.parent.parent / 'obs-plugins/64bit' / (name + '.dll')
        data = binary.parent.parent / 'data/obs-plugins' / name
        assert open_module(C.byref(module), str(dll).encode(), str(data).encode()) == 0
        assert api('obs_init_module', C.c_bool, P)(module)
    create_data = api('obs_data_create', P)
    set_int = api('obs_data_set_int', None, P, C.c_char_p, C.c_longlong)
    set_string = api('obs_data_set_string', None, P, C.c_char_p, C.c_char_p)
    set_bool = api('obs_data_set_bool', None, P, C.c_char_p, C.c_bool)
    release_data = api('obs_data_release', None, P)
    create = api('obs_source_create', P, C.c_char_p, C.c_char_p, P, P)
    release = api('obs_source_release', None, P)
    add = api('obs_scene_add', P, P, P)
    width = api('obs_source_get_width', C.c_uint32, P)
    height = api('obs_source_get_height', C.c_uint32, P)
    def color(name, w, h, rgba):
        s = create_data()
        for k, v in ((b'width', w), (b'height', h), (b'color', rgba)): set_int(s, k, v)
        source = create(b'color_source_v3', name.encode(), s, None); release_data(s)
        assert source; return source
    scene = api('obs_scene_create', P, C.c_char_p)(b'GroupTestManager')
    api('obs_set_output_source', None, C.c_uint32, P)(0, api('obs_scene_get_source', P, P)(scene))
    anchor, camera = color('Anchor', 1280, 720, 0), color('Camera', 200, 150, 0xff3030dd)
    anchor_id = api('obs_source_get_unversioned_id', C.c_char_p, P)(anchor).decode()
    print('ANCHOR UNVERSIONED ID:', anchor_id, flush=True)
    groups = []
    group_records = []
    set_pos = api('obs_sceneitem_set_pos', None, P, C.POINTER(Vec))
    for i, x in enumerate((100, 800), 1):
        item = api('obs_scene_add_group2', P, P, C.c_char_p, C.c_bool)(scene, f'Group{i}'.encode(), True)
        inside = api('obs_sceneitem_group_get_scene', P, P)(item)
        base = add(inside, anchor)
        camera_item = add(inside, camera)
        set_pos(camera_item, C.byref(Vec(x, 350)))
        api('obs_sceneitem_set_visible', None, P, C.c_bool)(item, False)
        groups.append(api('obs_sceneitem_get_source', P, P)(item))
        group_records.append((item, base, camera_item))
    time.sleep(0.2)
    print('GROUP DIMENSIONS:', [(width(source), height(source)) for source in groups], flush=True)
    for source in groups: assert (width(source), height(source)) == (1280, 720), (width(source), height(source))
    settings = api('obs_data_create_from_json', P, C.c_char_p)(b'{"sources":[{"value":"Group1"},{"value":"Group2"}],"transition":"fade_transition","transition_duration":300,"time_switch":false,"transition_resize":false}')
    output = create(b'source_switcher', b'GroupOutput', settings, None); release_data(settings)
    assert output
    api('obs_set_output_source', None, C.c_uint32, P)(0, output)
    api('obs_add_raw_video_callback', None, P, type(receive), P)(None, receive, None)
    time.sleep(0.2)
    from PIL import Image
    def snapshot(name):
        assert last_frame
        image = Image.frombytes('RGBA', (1280, 720), last_frame[0], 'raw', 'RGBA', last_frame[1])
        image.save(root / 'tests' / name)
        return image
    left = snapshot('group-left.png')
    assert max(left.getpixel((150, 400))[:3]) > 100 and max(left.getpixel((850, 400))[:3]) < 10
    api('obs_source_media_set_time', None, P, C.c_longlong)(output, 1000)
    time.sleep(0.13)
    mid = snapshot('group-mix.png')
    assert max(mid.getpixel((150, 400))[:3]) > 20 and max(mid.getpixel((850, 400))[:3]) > 20
    assert (width(output), height(output)) == (1280, 720)
    time.sleep(0.3)
    right = snapshot('group-right.png')
    assert max(right.getpixel((150, 400))[:3]) < 10 and max(right.getpixel((850, 400))[:3]) > 100
    assert api('obs_source_media_get_time', C.c_longlong, P)(output) == 1000
    s = api('obs_source_get_settings', P, P)(output)
    set_string(s, b'transition', b'cut_transition')
    api('obs_source_update', None, P, P)(output, s); release_data(s)
    time.sleep(0.1)  # video-source settings are applied on a later video tick
    api('obs_source_media_set_time', None, P, C.c_longlong)(output, 0)
    time.sleep(0.25)  # raw video delivery is buffered; wait for the CUT frame
    assert api('obs_source_media_get_time', C.c_longlong, P)(output) == 0
    cut = snapshot('group-cut.png')
    assert max(cut.getpixel((150, 400))[:3]) > 100 and max(cut.getpixel((850, 400))[:3]) < 10
    # ME1 switches intact decorated scenes, rather than flattened camera groups.
    scene_create = api('obs_scene_create', P, C.c_char_p)
    scene_source = api('obs_scene_get_source', P, P)
    decoration = color('Decoration', 100, 80, 0xff20dd20)
    extra_sources.append(decoration)
    for i, x in enumerate((100, 800), 1):
        decorated = scene_create(f'+cam{i} #0{i}'.encode()); extra_scenes.append(decorated)
        add(decorated, anchor)
        item = add(decorated, camera); set_pos(item, C.byref(Vec(x, 350)))
        item = add(decorated, decoration); set_pos(item, C.byref(Vec(50 if i == 1 else 1050, 50)))
    settings = api('obs_data_create_from_json', P, C.c_char_p)(b'{"sources":[{"value":"+cam1 #01"},{"value":"+cam2 #02"}],"transition":"fade_transition","transition_duration":300,"transition_resize":false}')
    direct_output = create(b'source_switcher', b'DirectSceneME1', settings, None); release_data(settings)
    assert direct_output; extra_sources.append(direct_output)
    api('obs_set_output_source', None, C.c_uint32, P)(0, direct_output)
    time.sleep(0.3)
    first_scene = snapshot('scene-me1-first.png')
    assert first_scene.getpixel((75, 75))[1] > 100 and first_scene.getpixel((1075, 75))[1] < 10
    api('obs_source_media_set_time', None, P, C.c_longlong)(direct_output, 1000)
    time.sleep(0.13)
    scene_mix = snapshot('scene-me1-mix.png')
    assert scene_mix.getpixel((75, 75))[1] > 20 and scene_mix.getpixel((1075, 75))[1] > 20
    time.sleep(0.3)
    second_scene = snapshot('scene-me1-second.png')
    assert second_scene.getpixel((75, 75))[1] < 10 and second_scene.getpixel((1075, 75))[1] > 100
    s = api('obs_source_get_settings', P, P)(direct_output)
    set_string(s, b'transition', b'cut_transition')
    api('obs_source_update', None, P, P)(direct_output, s); release_data(s)
    time.sleep(0.1)
    api('obs_source_media_set_time', None, P, C.c_longlong)(direct_output, 0)
    time.sleep(0.25)
    assert snapshot('scene-me1-cut.png').getpixel((75, 75))[1] > 100
    # ME2 group holds a raw camera AND an intact scene; each item has its own layout.
    item = api('obs_scene_add_group2', P, P, C.c_char_p, C.c_bool)(scene, b'MixedGroup', True)
    inside = api('obs_sceneitem_group_get_scene', P, P)(item)
    mixed_anchor = add(inside, anchor)
    mixed_group_item = item
    raw_item = add(inside, camera); set_pos(raw_item, C.byref(Vec(100, 350)))
    nested_item = add(inside, scene_source(extra_scenes[0]))
    api('obs_sceneitem_set_scale', None, P, C.POINTER(Vec))(nested_item, C.byref(Vec(0.5, 0.5)))
    set_pos(nested_item, C.byref(Vec(400, 250)))
    api('obs_sceneitem_set_visible', None, P, C.c_bool)(item, False)
    # Groups rendered directly by Source Switcher do not render their manager.
    # Update the parent's recursive transforms even while it is hidden.
    api('obs_scene_prune_sources', None, P)(scene)
    settings = api('obs_data_create_from_json', P, C.c_char_p)(b'{"sources":[{"value":"MixedGroup"},{"value":"Group2"}],"transition":"cut_transition","transition_resize":false}')
    mixed_output = create(b'source_switcher', b'MixedME2', settings, None); release_data(settings)
    assert mixed_output; extra_sources.append(mixed_output)
    api('obs_set_output_source', None, C.c_uint32, P)(0, mixed_output)
    time.sleep(0.3)
    mixed = snapshot('scene-me2-mixed-group.png')
    nested_pos, nested_scale = Vec(), Vec()
    api('obs_sceneitem_get_pos', None, P, C.POINTER(Vec))(nested_item, C.byref(nested_pos))
    api('obs_sceneitem_get_scale', None, P, C.POINTER(Vec))(nested_item, C.byref(nested_scale))
    print('NESTED TRANSFORM:', nested_pos.x, nested_pos.y, nested_scale.x, nested_scale.y, flush=True)
    assert max(mixed.getpixel((150, 400))[:3]) > 100
    assert max(mixed.getpixel((475, 450))[:3]) > 100
    assert mixed.getpixel((435, 285))[1] > 100
    assert (width(mixed_output), height(mixed_output)) == (1280, 720)
    # Stable fixed-frame filtering, including off-canvas moves and group translation.
    filters = {}
    get_pos = api('obs_sceneitem_get_pos', None, P, C.POINTER(Vec))
    get_double = api('obs_data_get_double', C.c_double, P, C.c_char_p)
    set_double = api('obs_data_set_double', None, P, C.c_char_p, C.c_double)
    enum_type = C.CFUNCTYPE(C.c_bool, P, P, P)
    def sync_group(group_item, anchor_item):
        source = api('obs_sceneitem_get_source', P, P)(group_item)
        if group_item not in filters:
            s = create_data(); set_bool(s, b'relative', False)
            f = api('obs_source_create_private', P, C.c_char_p, C.c_char_p, P)(b'crop_filter', b'FixedFrame', s)
            release_data(s); assert f
            api('obs_source_filter_add', None, P, P)(source, f)
            filters[group_item] = f; extra_sources.append(f)
        f = filters[group_item]
        s = api('obs_source_get_settings', P, P)(f)
        ap, gp = Vec(), Vec(); get_pos(anchor_item, C.byref(ap)); get_pos(group_item, C.byref(gp))
        dx = gp.x + ap.x - get_double(s, b'camera_mix_anchor_x')
        dy = gp.y + ap.y - get_double(s, b'camera_mix_anchor_y')
        @enum_type
        def shift(_, child, __):
            if child != anchor_item:
                p = Vec(); get_pos(child, C.byref(p)); set_pos(child, C.byref(Vec(p.x + dx, p.y + dy)))
            return True
        api('obs_scene_enum_items', None, P, enum_type, P)(api('obs_sceneitem_group_get_scene', P, P)(group_item), shift, None)
        set_pos(group_item, C.byref(Vec(0, 0)))
        api('obs_scene_prune_sources', None, P)(scene)
        get_pos(anchor_item, C.byref(ap))
        set_int(s, b'left', round(ap.x)); set_int(s, b'top', round(ap.y))
        set_int(s, b'cx', 1280); set_int(s, b'cy', 720)
        set_double(s, b'camera_mix_anchor_x', ap.x); set_double(s, b'camera_mix_anchor_y', ap.y)
        api('obs_source_update', None, P, P)(f, s); release_data(s)
        set_pos(group_item, C.byref(Vec(0, 0)))
    sync_group(mixed_group_item, mixed_anchor)
    set_pos(nested_item, C.byref(Vec(-5, 250)))
    sync_group(mixed_group_item, mixed_anchor)
    api('obs_set_output_source', None, C.c_uint32, P)(0, mixed_output)
    time.sleep(0.3)
    mixed_negative = snapshot('group-fixed-nested-negative.png')
    assert max(mixed_negative.getpixel((150, 400))[:3]) > 100
    assert mixed_negative.getpixel((30, 285))[1] > 100
    assert (width(mixed_output), height(mixed_output)) == (1280, 720)
    for group_item, base, _ in group_records: sync_group(group_item, base)
    first_group, first_anchor, first_camera = group_records[0]
    set_pos(first_camera, C.byref(Vec(-5, 350)))
    sync_group(first_group, first_anchor)
    api('obs_set_output_source', None, C.c_uint32, P)(0, output)
    time.sleep(0.3)
    negative = snapshot('group-fixed-negative.png')
    assert max(negative.getpixel((190, 400))[:3]) > 100 and max(negative.getpixel((197, 400))[:3]) < 10
    assert width(groups[0]) == 1280 and width(output) == 1280
    # Re-rendering the manager between edits must not double the group resize shift.
    api('obs_scene_prune_sources', None, P)(scene)
    sync_group(first_group, first_anchor)
    time.sleep(0.15)
    repeated = snapshot('group-fixed-negative-repeat.png')
    assert repeated.tobytes() == negative.tobytes()
    # Apply only after dragging ends, so repeated absolute drag updates do not accumulate.
    for x in (10, 20, 30): set_pos(first_group, C.byref(Vec(x, 20)))
    sync_group(first_group, first_anchor)
    time.sleep(0.2)
    translated = snapshot('group-fixed-translated.png')
    assert max(translated.getpixel((30, 380))[:3]) > 100 and max(translated.getpixel((20, 380))[:3]) < 10
    # Move a larger camera beyond the right edge; fixed frame must not shrink it.
    ap = Vec(); get_pos(first_anchor, C.byref(ap))
    set_pos(first_camera, C.byref(Vec(1260 + ap.x, 350 + ap.y)))
    sync_group(first_group, first_anchor)
    time.sleep(0.2)
    edge = snapshot('group-fixed-right-edge.png')
    assert max(edge.getpixel((1265, 400))[:3]) > 100 and max(edge.getpixel((1250, 400))[:3]) < 10
    s = api('obs_source_get_settings', P, P)(output); set_string(s, b'transition', b'fade_transition')
    api('obs_source_update', None, P, P)(output, s); release_data(s); time.sleep(0.1)
    api('obs_source_media_set_time', None, P, C.c_longlong)(output, 1000); time.sleep(0.13)
    edge_mix = snapshot('group-fixed-edge-mix.png')
    assert max(edge_mix.getpixel((1265, 400))[:3]) > 20 and max(edge_mix.getpixel((850, 400))[:3]) > 20
    assert width(output) == 1280
    # Move an existing group instance between managers, retaining the same source.
    new_manager = scene_create(b'ME2 Camera Inputs'); extra_scenes.append(new_manager)
    same_group = api('obs_sceneitem_get_source', P, P)(first_group)
    moved_group = add(new_manager, same_group)
    assert moved_group
    api('obs_sceneitem_remove', None, P)(first_group)
    assert api('obs_sceneitem_get_source', P, P)(moved_group) == same_group
    s = api('obs_source_get_settings', P, P)(output); set_string(s, b'transition', b'cut_transition')
    api('obs_source_update', None, P, P)(output, s); release_data(s); time.sleep(0.1)
    api('obs_source_media_set_time', None, P, C.c_longlong)(output, 0); time.sleep(0.25)
    assert max(snapshot('per-me-manager-migration.png').getpixel((1265, 400))[:3]) > 100
    # Proposal only: scene-item visibility Fade works without transparent anchors.
    no_anchor = scene_create(b'NoAnchorProposal'); extra_scenes.append(no_anchor)
    no_anchor_groups = []
    for i, x in enumerate((100, 800), 1):
        group = api('obs_scene_add_group2', P, P, C.c_char_p, C.c_bool)(no_anchor, f'NoAnchor{i}'.encode(), True)
        inner = api('obs_sceneitem_group_get_scene', P, P)(group)
        cam_item = add(inner, camera); set_pos(cam_item, C.byref(Vec(x, 350)))
        no_anchor_groups.append(group)
    api('obs_scene_prune_sources', None, P)(no_anchor)
    api('obs_sceneitem_set_visible', None, P, C.c_bool)(no_anchor_groups[1], False)
    for group in no_anchor_groups:
        for show in (True, False):
            fade = api('obs_source_create_private', P, C.c_char_p, C.c_char_p, P)(b'fade_transition', b'GroupFade', None)
            assert fade; extra_sources.append(fade)
            api('obs_sceneitem_set_transition', None, P, C.c_bool, P)(group, show, fade)
            api('obs_sceneitem_set_transition_duration', None, P, C.c_bool, C.c_uint32)(group, show, 300)
    api('obs_set_output_source', None, C.c_uint32, P)(0, scene_source(no_anchor))
    time.sleep(0.3)
    no_anchor_first = snapshot('no-anchor-proposal-first.png')
    assert max(no_anchor_first.getpixel((150, 400))[:3]) > 100
    assert max(no_anchor_first.getpixel((850, 400))[:3]) < 10
    api('obs_sceneitem_set_visible', None, P, C.c_bool)(no_anchor_groups[0], False)
    api('obs_sceneitem_set_visible', None, P, C.c_bool)(no_anchor_groups[1], True)
    time.sleep(0.13)
    no_anchor_mix = snapshot('no-anchor-proposal-mix.png')
    assert max(no_anchor_mix.getpixel((150, 400))[:3]) > 20 and max(no_anchor_mix.getpixel((850, 400))[:3]) > 20
    time.sleep(0.3)
    assert max(snapshot('no-anchor-proposal-second.png').getpixel((850, 400))[:3]) > 100
    assert width(scene_source(no_anchor)) == 1280
    # Broadcast MIX: one full-frame transition, sharing the existing groups.
    gray = color('MixGray', 200, 150, 0xff808080); extra_sources.append(gray)
    mix_manager = scene_create(b'MixManager'); extra_scenes.append(mix_manager)
    mix_groups, views, view_items = [], [], []
    for i in range(2):
        group = api('obs_scene_add_group2', P, P, C.c_char_p, C.c_bool)(mix_manager, f'MixGroup{i}'.encode(), True)
        inner = api('obs_sceneitem_group_get_scene', P, P)(group)
        add(inner, gray)
        set_pos(group, C.byref(Vec(100, 350)))
        api('obs_scene_prune_sources', None, P)(mix_manager)
        view = api('obs_scene_create_private', P, C.c_char_p)(f'MixView{i}'.encode()); private_scenes.append(view)
        item = add(view, api('obs_sceneitem_get_source', P, P)(group))
        set_pos(item, C.byref(Vec(100, 350)))
        views.append(view); view_items.append(item); mix_groups.append(group)
    fade = api('obs_source_create_private', P, C.c_char_p, C.c_char_p, P)(b'fade_transition', b'FullFrameMIX', None)
    extra_sources.append(fade)
    api('obs_transition_set_size', None, P, C.c_uint32, C.c_uint32)(fade, 1280, 720)
    transition_set = api('obs_transition_set', None, P, P)
    start_transition = api('obs_transition_start', C.c_bool, P, C.c_int, C.c_uint32, P)
    manual_time = api('obs_transition_set_manual_time', None, P, C.c_float)
    transition_set(fade, scene_source(views[0]))
    mix_output = scene_create(b'MixPublicOutput'); extra_scenes.append(mix_output)
    add(mix_output, fade)
    # Caption is outside the camera transition.
    caption_item = add(mix_output, decoration); set_pos(caption_item, C.byref(Vec(50, 50)))
    api('obs_set_output_source', None, C.c_uint32, P)(0, scene_source(mix_output))
    time.sleep(.35)
    base_mix = snapshot('broadcast-mix-first.png').getpixel((150, 400))[:3]
    assert min(base_mix) > 100, base_mix
    assert start_transition(fade, 1, 300, scene_source(views[1]))
    for t in (.25, .5, .75):
        manual_time(fade, t); time.sleep(.3)
        frame = snapshot(f'broadcast-mix-equal-{t}.png')
        pixel = frame.getpixel((150, 400))[:3]
        assert max(abs(a-b) for a,b in zip(pixel,base_mix)) <= 3, (t, base_mix, pixel)
        assert frame.getpixel((75,75))[1] > 150
    transition_set(fade, scene_source(views[0]))
    set_pos(mix_groups[1], C.byref(Vec(800, 350)))
    set_pos(view_items[1], C.byref(Vec(800, 350)))
    assert start_transition(fade, 1, 300, scene_source(views[1]))
    manual_time(fade,.5); time.sleep(.3)
    different = snapshot('broadcast-mix-different-layouts.png')
    assert different.getpixel((150,400))[0] > 40 and different.getpixel((850,400))[0] > 40
    assert different.getpixel((75,75))[1] > 150
    transition_set(fade, scene_source(views[1])); time.sleep(.3)
    final_mix = snapshot('broadcast-mix-final.png')
    assert final_mix.getpixel((150,400))[0] < 10 and final_mix.getpixel((850,400))[0] > 100
    print('PASS: full-frame MIX no brightness dip at 25/50/75%, different layouts, constant caption, CUT')
    api('obs_remove_raw_video_callback', None, type(receive), P)(receive, None)
    api('obs_set_output_source', None, C.c_uint32, P)(0, None)
    print('PASS: real libobs pixels: fixed-frame CUT/MIX and layouts; per-ME manager group migration; anchor-free scene-item Fade proposal')
finally:
    api('obs_set_output_source', None, C.c_uint32, P)(0, None)
    if 'output' in globals() and output: release(output)
    for source in reversed(extra_sources): release(source)
    if 'anchor' in globals() and anchor: release(anchor)
    if 'camera' in globals() and camera: release(camera)
    if 'scene' in globals() and scene:
        api('obs_canvas_scene_remove', None, P)(scene)
        api('obs_scene_release', None, P)(scene)
    for extra_scene in extra_scenes:
        api('obs_canvas_scene_remove', None, P)(extra_scene)
        api('obs_scene_release', None, P)(extra_scene)
    for private_scene in private_scenes:
        api('obs_scene_release', None, P)(private_scene)
    api('obs_wait_for_destroy_queue', C.c_bool)()
    api('obs_shutdown', None)()
