from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,csv,re,base64,struct,json
from collections import deque
root=Path(__file__).resolve().parents[2];out=root/'lib/presentation/training_game/sametaroh_registration_layers.dart'
# Geometry only: clips continue drawing the untouched original PNGs.
colors=np.array([(199,231,241),(128,205,232),(82,156,193),(24,83,149),(0,163,218),(245,249,240),(6,41,83),(175,102,162),(136,189,63),(127,172,166),(223,224,153),(175,170,144)])
records={r['asset']:r for r in csv.DictReader(open(Path(__file__).parent/'anchor-registration.csv'))}
for r in records.values():r['action']=r['pose'].split('_')[0]
def pixels(asset):return np.array(Image.open(root/asset).convert('RGBA')).astype(int)
def labels(a):return ((a[:,:,:3,None]-colors.T[None,None,:,:])**2).sum(axis=2).argmin(axis=2)
def rects(mask):
 rs=[];prev={}
 for y,row in enumerate(mask):
  spans=[];xs=np.flatnonzero(row)
  if len(xs):
   cuts=np.where(np.diff(xs)>1)[0]+1
   for run in np.split(xs,cuts):spans.append((int(run[0]),int(run[-1])+1))
  curr={}
  for span in spans:
   if span in prev:
    idx=prev[span];rs[idx][3]+=1;curr[span]=idx
   else:curr[span]=len(rs);rs.append([span[0],y,span[1]-span[0],1])
  prev=curr
 return rs
def bed_masks(a):
 lab=labels(a);opaque=a[:,:,3]>0;h,w=lab.shape
 exactMat=(a[:,:,:3]==colors[0]).all(axis=2)&opaque
 matTop=int(np.where(exactMat)[0].min())
 yy,xx=np.indices((h,w))
 nearMat=((a[:,:,:3]-colors[0])**2).sum(axis=2)<900
 nearRail=((a[:,:,:3]-colors[1])**2).sum(axis=2)<900
 mat=(lab==0)&nearMat&(yy>=matTop)&opaque
 cyan=(lab==1)&nearRail&((xx>=w*.88)|(yy>=matTop+65))&opaque
 bed=mat|cyan
 body=(lab==2)&opaque;seen=np.zeros(body.shape,bool);base=np.zeros_like(bed)
 for y,x in zip(*np.where(body)):
  if seen[y,x]:continue
  q=deque([(y,x)]);seen[y,x]=1;pts=[]
  while q:
   yy,xx=q.popleft();pts.append((yy,xx))
   for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
    ny,nx=yy+dy,xx+dx
    if 0<=ny<h and 0<=nx<w and body[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((ny,nx))
  minx=min(x for y,x in pts);maxx=max(x for y,x in pts);miny=min(y for y,x in pts)
  israil=minx>w*.8
  isbase=miny>h*.55 and (minx<30 or maxx>w*.85)
  if israil or isbase:
   for yy,xx in pts:bed[yy,xx]=1;base[yy,xx]=isbase
 # Fill occluded flat furniture surfaces underneath the dynamic character.
 fills=[]
 for label,color,mask in [(0,0xffc7e7f1,mat),(1,0xff80cde8,cyan),(2,0xff529cc1,base)]:
  fill=np.zeros_like(bed)
  for y,row in enumerate(mask):
   xs=np.flatnonzero(row)
   if len(xs)>2:
    # right post remains an exact clipped source; avoid bridging its bottom notch.
    if label==2:xs=xs[xs<w*.955]
    if len(xs)>2:fill[y,xs.min():xs.max()+1]=1
  if label==0:
   ys,xs=np.where(mask);top=int(ys.min());bottom=int(ys.max());left=int(xs.min());right=int(xs.max())
   for y in range(top,bottom+1):
    l=round(left+.4*(bottom-y));r=round(right-.4*(bottom-y))
    fill[y,l:r+1]=1
  fills.append((color,rects(fill)))
 dynamicBed = bed | (((lab==0)&(yy>=matTop-2) | (lab==1)&((xx>=w*.8)|(yy>=matTop+50)))&opaque)
 return bed,opaque&~dynamicBed,fills
entryFills={};entries=[];masks={};fills={};offsets={};mirrors={};mirrorAnchors={}
for asset,r in records.items():
 if r['action'] not in ('clean','rest'):continue
 p=Path(asset);body=r['body'];action=r['action'];group=body+'_'+action
 first=next((a for a,z in records.items() if z['body']==body and z['action']==action and z['pose'].endswith('_1')))
 a=pixels(asset);base=pixels(first);h,w=a.shape[:2];bh,bw=base.shape[:2]
 offset=(0,0)
 if action=='rest':
  static,dynamic,ff=bed_masks(a)
  if group not in masks:
   bs,_,bfill=bed_masks(base);masks[group]=rects(bs);fills[group]=bfill
 else:
  # Preserve the first pose's connected lower silhouette. The broom is foreground.
  bodyBlue=(base[:,:,0]==82)&(base[:,:,1]==156)&(base[:,:,2]==193)&(base[:,:,3]>80)
  waist=int(np.where(bodyBlue)[0].max())-8
  yy,xx=np.indices((h,w));localwaist=waist-(bh-h)
  dark=(a[:,:,2]>a[:,:,1]+40)&(a[:,:,1]<130)&(a[:,:,2]>a[:,:,0]+40)&(a[:,:,3]>0)
  lab=labels(a)
  broom=np.isin(lab,[9,10,11])
  dynamic=(a[:,:,3]>0)&((yy<localwaist)|broom)
  if group not in masks:
   by,bx=np.indices((bh,bw));bd=(base[:,:,2]>base[:,:,1]+40)&(base[:,:,1]<130)&(base[:,:,2]>base[:,:,0]+40)&(base[:,:,3]>0)
   baseBroom=np.isin(labels(base),[9,10,11])
   lower=(by>=waist)&(base[:,:,3]>0)&~baseBroom
   # Discard detached torso fragments on the opposite side of the broom.
   keep=np.zeros_like(lower);seenLower=np.zeros_like(lower)
   for sy,sx in zip(*np.where(lower)):
    if seenLower[sy,sx]:continue
    q=deque([(sy,sx)]);seenLower[sy,sx]=1;pts=[]
    while q:
     py,px=q.popleft();pts.append((py,px))
     for oy,ox in ((1,0),(-1,0),(0,1),(0,-1)):
      ny,nx=py+oy,px+ox
      if 0<=ny<bh and 0<=nx<bw and lower[ny,nx] and not seenLower[ny,nx]:seenLower[ny,nx]=1;q.append((ny,nx))
    if max(py for py,px in pts)>=bh-22:
     for py,px in pts:keep[py,px]=1
   # A continuous hip bridge sits behind the moving belly, not at the soles.
   bottom=int(np.where(bodyBlue)[0].max());top=waist
   tx=np.where(bodyBlue[top])[0];end=min(bottom+10,bh-1)
   ex=np.where(keep[end])[0]
   bridge=np.zeros_like(keep)
   if len(tx) and len(ex):
    for y in range(top,end+1):
     t=(y-top)/(end-top);l=round(tx.min()*(1-t)+ex.min()*t);rr=round(tx.max()*(1-t)+ex.max()*t)
     bridge[y,max(0,l-2):min(bw,rr+1+round(5*(1-t)))]=1
    keep[(by>=top)&(by<=end)&~bridge]=False
   masks[group]=rects(keep);fills[group]=[(0xff185395,rects(bridge))]
   fy=int(np.where(bd&(base[:,:,3]>80))[0].max())
   anchor={'pr':75.5,'sh':78.5,'wtb':85.0,'base':76.0}[body];mirrorAnchors[group]=anchor
   # The unobscured left sole supplies its hidden opposite under the broom.
   candidate=bd&(by>=waist)&(bx<anchor-2)&((by>=fy-15)|(bx>=anchor-38))
   visible=np.zeros_like(candidate);seen=np.zeros_like(candidate)
   for cy,cx in zip(*np.where(candidate)):
    if seen[cy,cx]:continue
    q=deque([(cy,cx)]);seen[cy,cx]=1;pts=[]
    while q:
     py,px=q.popleft();pts.append((py,px))
     for oy,ox in ((1,0),(-1,0),(0,1),(0,-1)):
      ny,nx=py+oy,px+ox
      if 0<=ny<bh and 0<=nx<bw and candidate[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;q.append((ny,nx))
    if max(py for py,px in pts)>=fy-5:
     for py,px in pts:visible[py,px]=1
   mirrors[group]=rects(visible)
 if action=='clean':
  # Join the current torso and the fixed hips with a convex local silhouette.
  # The contact band and the legs below this small bridge are untouched.
  combined=np.zeros((bh,bw),bool)
  for x,y,rw,rh in masks[group]:combined[y:y+rh,x:x+rw]=1
  shift=json.loads((Path(__file__).parent/'clean-pelvis-offsets.json').read_text())[asset]
  dx=shift+(bw-w)/2
  lab=labels(a);actor=(a[:,:,3]>200)&np.isin(lab,[2,3,6])
  for py,px in zip(*np.where(actor)):
   nx=round(px+dx);ny=py+(bh-h)
   if 0<=ny<bh and 0<=nx<bw:combined[ny,nx]=1
  by,bx=np.indices((bh,bw));roi=combined&(by>=waist-5)&(by<=waist+22)&(bx>=mirrorAnchors[group]-35)
  pts=sorted((int(x),int(y)) for y,x in zip(*np.where(roi)))
  def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
  lower=[];upper=[]
  for pt in pts:
   while len(lower)>=2 and cross(lower[-2],lower[-1],pt)<=0:lower.pop()
   lower.append(pt)
  for pt in reversed(pts):
   while len(upper)>=2 and cross(upper[-2],upper[-1],pt)<=0:upper.pop()
   upper.append(pt)
  im=Image.new('1',(bw,bh));ImageDraw.Draw(im).polygon(lower[:-1]+upper[:-1],fill=1)
  entryFills[asset]=[(0xff185395,rects(np.array(im,dtype=bool)))]
 offsets[group]=offset
 if action=='rest':
  expanded=dynamic.copy()
  for oy,ox in ((1,0),(-1,0),(0,1),(0,-1)):
   expanded |= np.roll(dynamic,(oy,ox),(0,1))
  dynamic=expanded&(a[:,:,3]>0)&(np.indices((h,w))[1]<w*.9)
 entries.append((asset,first,bw,bh,group,rects(dynamic)))
text='''// Generated clip geometry from unchanged original PNGs; see tool/no67/generate_registration_layers.py.\nimport 'dart:convert';\nimport 'dart:typed_data';\nimport 'package:flutter/material.dart';\n\nclass RegisteredFrameLayers {\n  const RegisteredFrameLayers(this.staticAsset, this.staticSize, this.staticClip, this.dynamicClip, this.fills, this.staticOffset, this.mirrorClip, this.mirrorAnchor);\n  final String staticAsset;\n  final Size staticSize;\n  final List<int> staticClip;\n  final List<int> dynamicClip;\n  final Map<int, List<int>> fills;
  final Offset staticOffset;
  final List<int>? mirrorClip;
  final double mirrorAnchor;\n}\n\nPath registrationPath(List<int> runs) {\n  final path = Path();\n  for (var i=0;i<runs.length;i+=4) {\n    path.addRect(Rect.fromLTWH(runs[i].toDouble(),runs[i+1].toDouble(),runs[i+2].toDouble(),runs[i+3].toDouble()));\n  }\n  return path;\n}\n\n'''
def packed(rs):
 values=[v for r in rs for v in r];encoded=base64.b64encode(struct.pack('<'+'H'*len(values),*values)).decode()
 return "_runs('"+encoded+"')"
text+="List<int> _runs(String encoded) { final bytes=base64Decode(encoded); final data=ByteData.sublistView(bytes); return List<int>.generate(bytes.length~/2,(i)=>data.getUint16(i*2,Endian.little),growable:false); }\n"
for group,rs in masks.items():
 text+=f'final _{group} = '+packed(rs)+';\n'
 if group in mirrors:text+=f'final _{group}Mirror = '+packed(mirrors[group])+';\n'

text+='\nfinal registeredFrameLayers = <String,RegisteredFrameLayers>{\n'
for asset,first,w,h,g,rs in entries:text+=f"'{asset}': RegisteredFrameLayers('{first}',Size({w},{h}),_{g},"+packed(rs)+',<int,List<int>>{'+','.join(hex(c)+':'+packed(rr) for c,rr in entryFills.get(asset,fills[g]))+'},'+f'Offset({offsets[g][0]},{offsets[g][1]}),'+(f'_{g}Mirror' if g in mirrors else 'null')+f',{mirrorAnchors.get(g,0)}),\n'
text+='};\n'
for b in ['base','pr','sh','wtb']:
 for ac in ['clean','rest']:text=text.replace('_'+b+'_'+ac,'_'+b+ac.title())
out.write_text(text)
print('geometry bytes',out.stat().st_size,'frames',len(entries))
