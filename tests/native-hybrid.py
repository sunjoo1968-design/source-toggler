"""Real libobs regression: Hybrid private copies isolate camera choice and layout."""
from pathlib import Path
base=Path(__file__).with_name('native-groups.py')
code=base.read_text(encoding='utf-8')
marker="    print('PASS: full-frame MIX no brightness dip"
probe='''    module = P()
    dll = root / '.local/hybrid/build/Release/camera-mix-hybrid.dll'
    assert open_module(C.byref(module), str(dll).encode(), str(root).encode()) == 0
    assert api('obs_init_module', C.c_bool, P)(module)
    uuid = api('obs_source_get_uuid', C.c_char_p, P)
    duplicate = api('obs_source_duplicate', P, P, C.c_char_p, C.c_bool)
    get_by_uuid = api('obs_get_source_by_uuid', P, C.c_char_p)
    found = get_by_uuid(uuid(fade)); assert found == fade; release(found)
    def hybrid(name, live, target, duration=300):
        data = create_data(); set_string(data, b'live_uuid', uuid(live)); set_string(data,b'snapshot_uuid',uuid(target))
        api('obs_data_set_int',None,P,C.c_char_p,C.c_longlong)(data,b'mix_duration_ms',duration)
        result = create(b'camera_mix_hybrid_output', name.encode(), data, None)
        release_data(data); assert result; extra_sources.append(result); return result
    # ME1 clone shows a complete scene, even after the original selection changes.
    api('obs_source_media_set_time', None, P, C.c_longlong)(direct_output, 0)
    time.sleep(.3)
    me1 = hybrid('Hybrid ME1 Probe', direct_output, scene_source(extra_scenes[0]))
    api('obs_set_output_source', None, C.c_uint32, P)(0, me1); time.sleep(.3)
    me1_before = snapshot('hybrid-me1-before.png')
    me1_copy = duplicate(me1, b'Frozen ME1', True); assert me1_copy and me1_copy != me1
    extra_sources.append(me1_copy)
    api('obs_source_media_set_time', None, P, C.c_longlong)(direct_output, 1000)
    time.sleep(.3)
    api('obs_set_output_source', None, C.c_uint32, P)(0, me1_copy); time.sleep(.3)
    assert snapshot('hybrid-me1-frozen.png').tobytes() == me1_before.tobytes()
    api('obs_set_output_source', None, C.c_uint32, P)(0, me1); time.sleep(.3)
    assert snapshot('hybrid-me1-live.png').tobytes() != me1_before.tobytes()
    print('PASS Hybrid ME1: copied scene stays selected while live Preview changes')
    # ME2 copies the private view synchronously and freezes group placement.
    transition_set(fade, scene_source(views[1]))
    me2 = hybrid('Hybrid ME2 Probe', fade, scene_source(views[1]))
    api('obs_set_output_source', None, C.c_uint32, P)(0, me2); time.sleep(.3)
    me2_before = snapshot('hybrid-me2-before.png')
    assert me2_before.getpixel((850,400))[0] > 100
    me2_copy = duplicate(me2, b'Frozen ME2', True); assert me2_copy and me2_copy != me2
    extra_sources.append(me2_copy)
    transition_set(fade, scene_source(views[0]))
    set_pos(view_items[1], C.byref(Vec(300,350)))
    inner = api('obs_sceneitem_group_get_scene',P,P)(mix_groups[1])
    moved_camera = api('obs_scene_find_source',P,P,C.c_char_p)(inner,b'MixGray')
    assert moved_camera
    set_pos(moved_camera,C.byref(Vec(50,20)))
    api('obs_scene_prune_sources',None,P)(mix_manager)
    api('obs_set_output_source', None, C.c_uint32, P)(0, me2_copy); time.sleep(.3)
    assert snapshot('hybrid-me2-frozen.png').tobytes() == me2_before.tobytes()
    another_copy = duplicate(me2_copy,b'Frozen ME2 Again',True)
    assert another_copy; extra_sources.append(another_copy)
    api('obs_set_output_source',None,C.c_uint32,P)(0,another_copy); time.sleep(.3)
    assert snapshot('hybrid-me2-copy-of-copy.png').tobytes() == me2_before.tobytes()
    print('PASS Hybrid ME2: no black frame, camera and placement frozen')
    # Duplicating the actual outer output scene preserves captions too.
    outer = scene_create(b'Hybrid Output Probe'); extra_scenes.append(outer)
    add(outer, me2)
    caption_source = color('Hybrid Caption', 160,150,0xff00dd00); extra_sources.append(caption_source)
    add(outer, caption_source)
    outer_copy = api('obs_scene_duplicate', P, P, C.c_char_p, C.c_int)(outer,b'Frozen Hybrid Output',3)
    assert outer_copy; private_scenes.append(outer_copy)
    api('obs_set_output_source', None, C.c_uint32, P)(0, scene_source(outer_copy)); time.sleep(.3)
    assert snapshot('hybrid-outer-copy.png').getpixel((75,75))[1] > 100
    # Release all completed copies before checking recurring allocations.
    api('obs_set_output_source', None, C.c_uint32, P)(0, None)
    api('obs_wait_for_destroy_queue', C.c_bool)(); time.sleep(.3)
    allocations = api('bnum_allocs', C.c_longlong)
    before = allocations()
    for i in range(500):
        copy = duplicate(me2,b'Stress Copy',True); assert copy; release(copy)
        if i % 25 == 0: api('obs_wait_for_destroy_queue', C.c_bool)()
    api('obs_wait_for_destroy_queue', C.c_bool)(); time.sleep(.3)
    after = allocations()
    assert after == before, (before, after)
    print('PASS Hybrid copy lifetime: 500 clones, allocations', before, '->', after)
    # TAKE during a MIX retains its current contribution and finishes independently.
    mix_a=color('Take Red',1280,720,0xff0000ff); mix_b=color('Take Green',1280,720,0xff00ff00)
    extra_sources.extend([mix_a,mix_b])
    live_mix=api('obs_source_create_private',P,C.c_char_p,C.c_char_p,P)(b'fade_transition',b'Take Live MIX',None)
    extra_sources.append(live_mix); transition_set(live_mix,mix_a)
    take_output=hybrid('Take MIX Output',live_mix,mix_b,2000)
    api('obs_set_output_source',None,C.c_uint32,P)(0,take_output)
    assert start_transition(live_mix,0,2000,mix_b); time.sleep(.45)
    take_copy=duplicate(take_output,b'Take Mid MIX',True); assert take_copy; extra_sources.append(take_copy)
    transition_set(live_mix,mix_a) # Preview now differs from captured Program.
    api('obs_set_output_source',None,C.c_uint32,P)(0,take_copy); time.sleep(.08)
    first=snapshot('take-mid-mix-first.png').getpixel((600,400))[:3]
    assert first[2]>30 and first[1]>30,first
    time.sleep(.45)
    second=snapshot('take-mid-mix-next.png').getpixel((600,400))[:3]
    assert second[1]>first[1]+20 and second[2]<first[2]-20,(first,second)
    take_again=duplicate(take_copy,b'Take Mid MIX Again',True); assert take_again; extra_sources.append(take_again)
    api('obs_set_output_source',None,C.c_uint32,P)(0,take_again); time.sleep(2.1)
    last=snapshot('take-mid-mix-completed.png').getpixel((600,400))[:3]
    assert last[2]<5 and last[1]>245,last
    completed_copy=duplicate(take_again,b'Take Completed MIX Again',True); assert completed_copy; extra_sources.append(completed_copy)
    api('obs_set_output_source',None,C.c_uint32,P)(0,completed_copy); time.sleep(.15)
    assert snapshot('take-completed-copy.png').getpixel((600,400))[1]>245
    transition_set(live_mix,mix_a); assert start_transition(live_mix,1,2000,mix_b)
    manual_time(live_mix,.5); time.sleep(.2)
    api('obs_wait_for_destroy_queue',C.c_bool)(); mixed_baseline=allocations()
    for _ in range(100):
        temporary=duplicate(take_output,b'Mid MIX Stress',True); assert temporary; release(temporary)
        api('obs_wait_for_destroy_queue',C.c_bool)()
    time.sleep(.2); api('obs_wait_for_destroy_queue',C.c_bool)(); mixed_final=allocations()
    assert mixed_final==mixed_baseline,(mixed_baseline,mixed_final)
    print('PASS MIX-copy lifetime: 100 active-blend copies, allocations',mixed_baseline,'->',mixed_final)
    print('PASS MIX TAKE: captured blend advances independently, clone-of-clone and completed-copy stay live')
'''
at=code.index(marker)
code=code[:at]+probe+code[at:]
exec(compile(code,str(base),'exec'),{'__file__':str(base),'__name__':'__main__'})
