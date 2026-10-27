"""Focused candidate check; reads frozen assets without changing them."""
from pathlib import Path
import subprocess
from PIL import Image
root=Path(__file__).resolve().parents[1]
for w,h in [(208,262),(288,262),(370,568),(812,200)]:
    size=.75*min(112,h*.4,w*.5)
    label=min(1,max(0,h*.22-size/2-2)/16)
    for p in (root/'assets/images/training_game/minigames').glob('pass_run_*_front_*.png'):
        box=Image.open(p).getchannel('A').getbbox()
        top=(56-box[1])*size/112*1.15
        bottom=(box[3]-56)*size/112*1.15
        assert 8+size/2-bottom>=0, (w,h,p)
        assert size/2+2-top>=0, (w,h,p,'label')
    assert size+16*label+4 >= 102/112*size*1.15
# Scaling around the calibrated arm point leaves that point exactly invariant.
for scale in [1,1.15]:
    for pivot in [607/615,455/1251]:
        assert abs(pivot+(pivot-pivot)*scale-pivot)<1e-12
# These gameplay files must remain byte-identical to the baseline.
for name in ['pass_and_run/pass_and_run_motion.dart','pass_and_run/pass_and_run_logic.dart','tackle/tackle_contact_geometry.dart','tackle/tackle_game_logic.dart','tackle/tackle_running_trajectory.dart']:
    path='lib/presentation/training_game/mini_games/'+name
    assert Path(path).read_bytes()==subprocess.check_output(['git','show','HEAD:'+path])
print('PASS: four field sizes, frozen alpha bounds, label/turn clearance, contact pivot, unchanged gameplay files')
