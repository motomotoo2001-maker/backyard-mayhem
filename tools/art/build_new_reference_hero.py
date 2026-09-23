from pathlib import Path
from PIL import Image
import numpy as np
import math

ROOT = Path(__file__).resolve().parents[2]
MOVE_SRC = ROOT / 'assets/source/user_pack/hero_new_8dir_movement_sheet.png'
CLEAN_SRC = ROOT / 'assets/source/user_pack/hero_clean_8dir_reference.png'
ACTION_SRC = ROOT / 'assets/source/user_pack/hero_new_action_sheet.png'
OUT = ROOT / 'assets/runtime/characters/builder_hero'
OUT.mkdir(parents=True, exist_ok=True)
CANVAS = (320, 320)
ANCHOR = (160, 306)
TARGET_MAIN_HEIGHT = 244
DIRECTIONS = ['front','front_right','right','back_right','back','back_left','left','front_left']


def component_boxes(alpha: np.ndarray, min_area=40):
    mask=alpha>18; h,w=mask.shape
    labels=np.zeros((h,w),dtype=np.int32); comps=[]; idx=0
    for y in range(h):
        for x in range(w):
            if not mask[y,x] or labels[y,x]!=0: continue
            idx+=1; stack=[(x,y)]; labels[y,x]=idx
            area=0; x0=x1=x; y0=y1=y
            while stack:
                px,py=stack.pop(); area+=1
                x0=min(x0,px); x1=max(x1,px); y0=min(y0,py); y1=max(y1,py)
                for nx,ny in ((px-1,py),(px+1,py),(px,py-1),(px,py+1)):
                    if 0<=nx<w and 0<=ny<h and mask[ny,nx] and labels[ny,nx]==0:
                        labels[ny,nx]=idx; stack.append((nx,ny))
            if area>=min_area:
                comps.append((area,idx,x0,y0,x1-x0+1,y1-y0+1))
    comps.sort(reverse=True)
    return labels,comps


def bbox_gap(a,b):
    _,_,ax,ay,aw,ah=a; _,_,bx,by,bw,bh=b
    ar,ab=ax+aw,ay+ah; br,bb=bx+bw,by+bh
    dx=max(0,bx-ar,ax-br)
    dy=max(0,by-ab,ay-bb)
    return dx,dy


def extract_cell(image: Image.Image, box, keep_near=False):
    cell=image.crop(tuple(map(int,box))).convert('RGBA')
    arr=np.array(cell)
    labels, comps=component_boxes(arr[:,:,3], 35)
    if not comps:
        raise RuntimeError(f'no foreground in {box}')
    main=comps[0]
    keep={main[1]}
    if keep_near:
        for comp in comps[1:]:
            area,idx,x,y,w,h=comp
            if area < 55:
                continue
            dx,dy=bbox_gap(main,comp)
            # authored muzzle flash / smoke can be detached but stays close to the weapon
            if dx <= 75 and dy <= 40:
                keep.add(idx)
    alpha=np.zeros(arr.shape[:2],dtype=np.uint8)
    for idx in keep:
        alpha[labels==idx]=arr[:,:,3][labels==idx]
    arr[:,:,3]=alpha
    ys,xs=np.nonzero(alpha>0)
    if len(xs)==0:
        raise RuntimeError(f'empty foreground in {box}')
    # main bbox in cell coordinates before combined crop
    _,_,mx,my,mw,mh=main
    x0,x1=xs.min(),xs.max()+1; y0,y1=ys.min(),ys.max()+1
    crop=Image.fromarray(arr[y0:y1,x0:x1], 'RGBA')
    main_rel=(mx-x0,my-y0,mw,mh)
    return crop, main_rel


def normalize_to_canvas(crop: Image.Image, main_rel, target_h=TARGET_MAIN_HEIGHT):
    mx,my,mw,mh=main_rel
    scale=target_h/max(1,mh)
    # preserve VFX but fit into canvas
    scale=min(scale, 306/max(1,crop.width), 300/max(1,crop.height))
    nw=max(1,round(crop.width*scale)); nh=max(1,round(crop.height*scale))
    resized=crop.resize((nw,nh),Image.Resampling.LANCZOS)
    main_bottom=(my+mh)*scale
    main_center_x=(mx+mw/2)*scale
    px=round(ANCHOR[0]-main_center_x)
    py=round(ANCHOR[1]-main_bottom)
    canvas=Image.new('RGBA',CANVAS,(0,0,0,0))
    canvas.alpha_composite(resized,(px,py))
    return canvas


def subtle_idle(base: Image.Image, dy: int):
    out=Image.new('RGBA',CANVAS,(0,0,0,0))
    out.alpha_composite(base,(0,dy))
    return out


def clean_reference_frames():
    im=Image.open(CLEAN_SRC).convert('RGB')
    W,H=im.size; cw=W//4; boxes=[]
    for row in range(2):
        y0,y1=(18,356) if row==0 else (397,716)
        for col in range(4): boxes.append((col*cw,y0,(col+1)*cw,y1))
    result={}
    for direction,box in zip(DIRECTIONS,boxes):
        rgb=np.array(im.crop(box)).astype(np.float32)
        dist=255-rgb.min(axis=2); alpha=np.clip((dist-5)*10,0,255)
        af=np.maximum(alpha/255.0,1e-4); fg=(rgb-255*(1-af[:,:,None]))/af[:,:,None]
        rgba=np.dstack([np.clip(fg,0,255).astype(np.uint8),alpha.astype(np.uint8)])
        ys,xs=np.nonzero(alpha>16); x0,x1=xs.min(),xs.max()+1; y0,y1=ys.min(),ys.max()+1
        crop=Image.fromarray(rgba[y0:y1,x0:x1],'RGBA')
        result[direction]=normalize_to_canvas(crop,(0,0,crop.width,crop.height))
    return result

def procedural_run(base: Image.Image, index: int):
    phase=2.0*math.pi*index/8.0
    bob=round(-3.0*abs(math.sin(phase)))
    sway=round(2.5*math.sin(phase))
    squash=1.0-0.018*abs(math.sin(phase))
    stretch=1.0+0.012*abs(math.sin(phase))
    bbox=base.getchannel('A').getbbox(); crop=base.crop(bbox)
    nw=max(1,round(crop.width*stretch)); nh=max(1,round(crop.height*squash))
    crop=crop.resize((nw,nh),Image.Resampling.LANCZOS)
    out=Image.new('RGBA',CANVAS,(0,0,0,0))
    out.alpha_composite(crop,(ANCHOR[0]-nw//2+sway,ANCHOR[1]-nh+bob))
    return out


def movement_frames():
    clean=clean_reference_frames(); result={}
    for direction in DIRECTIONS:
        base=clean[direction]
        result[(direction,'idle')]=[subtle_idle(base,dy) for dy in (0,-1,-2,-1)]
        result[(direction,'run')]=[procedural_run(base,i) for i in range(8)]
    return result


def action_frames(movement):
    im=Image.open(ACTION_SRC).convert('RGBA')
    W,H=im.size
    result={}
    colw=W/8.0
    fire_rows=[(72,220),(220,375),(375,530)]
    for c,direction in enumerate(DIRECTIONS):
        frames=[]
        for y0,y1 in fire_rows:
            box=(c*colw,y0,(c+1)*colw,y1)
            crop,main=extract_cell(im,box,True)
            frames.append(normalize_to_canvas(crop,main))
        # authored smoke followed by clean directional recovery pose
        frames.append(movement[(direction,'idle')][0].copy())
        result[(direction,'fire')]=frames

    # deploy/build: 8 authored frames across the sheet
    build=[]
    for c in range(8):
        box=(c*colw,555,(c+1)*colw,755)
        crop,main=extract_cell(im,box,False)
        build.append(normalize_to_canvas(crop,main))
    result[('generic','build')]=build

    # hurt/stagger: six authored frames on bottom-left
    hurt=[]
    hurt_x1=930.0; hurt_col=hurt_x1/6.0
    for c in range(6):
        box=(c*hurt_col,775,(c+1)*hurt_col,941)
        crop,main=extract_cell(im,box,False)
        hurt.append(normalize_to_canvas(crop,main))
    result[('generic','hurt')]=hurt

    # defeat: four authored frames on bottom-right
    defeat=[]
    dx0=930.0; dcol=(W-dx0)/4.0
    for c in range(4):
        box=(dx0+c*dcol,785,dx0+(c+1)*dcol,900)
        crop,main=extract_cell(im,box,False)
        defeat.append(normalize_to_canvas(crop,main))
    result[('generic','defeat')]=defeat
    return result


def save_frames(movement, actions):
    # remove only generated runtime PNGs; preserve tres until rewritten
    for p in OUT.glob('*.png'):
        p.unlink()
    generated={}
    for (direction,state),frames in movement.items():
        names=[]
        for i,frame in enumerate(frames):
            name=f'{state}_{direction}_{i:02d}.png'
            frame.save(OUT/name); names.append(name)
        generated[(state,direction)]=names
    for (direction,state),frames in actions.items():
        names=[]
        keydir=direction
        for i,frame in enumerate(frames):
            name=f'{state}_{keydir}_{i:02d}.png' if keydir!='generic' else f'{state}_{i:02d}.png'
            frame.save(OUT/name); names.append(name)
        generated[(state,keydir)]=names
    # generic compatibility fallbacks
    fallback='front_right'
    for state in ['idle','run','fire']:
        src_names=generated[(state,fallback)]
        generic=[]
        for i,name in enumerate(src_names):
            src=Image.open(OUT/name).convert('RGBA')
            outname=f'{state}_{i:02d}.png'; src.save(OUT/outname); generic.append(outname)
        generated[(state,'generic')]=generic
    # directional build names all use the authored deploy sequence, not synthetic transforms
    build_names=generated[('build','generic')]
    for direction in DIRECTIONS:
        generated[('build',direction)]=build_names
    return generated


def write_spriteframes(generated):
    specs=[]
    def add(name,names,loop,speed): specs.append((name,names,loop,speed))
    add('idle',generated[('idle','generic')],True,4.5)
    add('run',generated[('run','generic')],True,11.5)
    add('fire',generated[('fire','generic')],False,13.0)
    add('build',generated[('build','generic')],False,12.0)
    add('hurt',generated[('hurt','generic')],False,11.0)
    add('defeat',generated[('defeat','generic')],False,6.0)
    for direction in DIRECTIONS:
        add(f'idle_{direction}',generated[('idle',direction)],True,4.5)
        add(f'run_{direction}',generated[('run',direction)],True,11.5)
        add(f'fire_{direction}',generated[('fire',direction)],False,13.0)
        add(f'build_{direction}',generated[('build',direction)],False,12.0)

    ext=[]; blocks=[]; rid=0
    for name,names,loop,speed in specs:
        ids=[]
        for file in names:
            rid+=1; eid=f't{rid}'; ids.append(eid)
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/runtime/characters/builder_hero/{file}" id="{eid}"]')
        fr=', '.join(f'{{"duration": 1.0, "texture": ExtResource("{eid}")}}' for eid in ids)
        blocks.append('{\n'+f'"frames": [{fr}],\n"loop": {str(loop).lower()},\n"name": &"{name}",\n"speed": {speed:.1f}\n'+'}')
    text='\n'.join([f'[gd_resource type="SpriteFrames" load_steps={rid+1} format=3]','',*ext,'','[resource]','animations = [',', '.join(blocks),']',''])
    (OUT/'builder_hero_frames.tres').write_text(text,encoding='utf-8')


if __name__=='__main__':
    movement=movement_frames()
    actions=action_frames(movement)
    generated=save_frames(movement,actions)
    write_spriteframes(generated)
    print('movement directions:',len(DIRECTIONS),'run frames each:',len(generated[('run','front')]))
    print('build:',len(generated[('build','generic')]),'hurt:',len(generated[('hurt','generic')]),'defeat:',len(generated[('defeat','generic')]))
