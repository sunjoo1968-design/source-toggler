"""Reproduce current Source Switcher and Fade copy limitations in isolated libobs."""
from pathlib import Path

base = Path(__file__).with_name('native-groups.py')
code = base.read_text(encoding='utf-8')
marker = "    print('PASS: full-frame MIX no brightness dip"
at = code.index(marker)
probe = '''    duplicate_source = api('obs_source_duplicate', P, P, C.c_char_p, C.c_bool)
    switcher_copy = duplicate_source(direct_output, b'Private ME1 Copy Probe', True)
    assert switcher_copy == direct_output, 'Source Switcher duplication policy changed'
    release(switcher_copy)
    print('CONFIRMED ME1: Source Switcher private copy returns the original instance')
    copied_output = api('obs_scene_duplicate', P, P, C.c_char_p, C.c_int)(mix_output, b'Copy Probe ME2', 3)
    assert copied_output; private_scenes.append(copied_output)
    api('obs_set_output_source', None, C.c_uint32, P)(0, scene_source(copied_output))
    time.sleep(.3)
    copied_frame = snapshot('source-copy-probe-me2.png')
    assert max(copied_frame.getpixel((850,400))[:3]) < 10, 'Fade copy behavior changed'
    assert copied_frame.getpixel((75,75))[1] > 150, 'Decorations should still be duplicated'
    print('CONFIRMED ME2: full source copy preserves caption but leaves copied Fade camera output empty')
'''
code = code[:at] + probe + code[at:]
exec(compile(code, str(base), 'exec'), {'__file__': str(base), '__name__': '__main__'})
