from pathlib import Path
from PIL import Image
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
 if r['action'] not in ('clean','rest','squat'):continue
 p=Path(asset);body=r['body'];action=r['action'];group=body+'_'+action
 if action=='squat':
  a=pixels(asset);h,w=a.shape[:2];opaque=a[:,:,3]>0
  prop=opaque&(((a[:,:,0]>130)&(a[:,:,1]<145))|((a[:,:,0]>160)&(a[:,:,1]>140)&(a[:,:,2]<200)&(a[:,:,0]-a[:,:,2]>20)))
  group=body+'_squat_'+r['pose'];masks[group]=rects(prop);fills[group]=[];offsets[group]=(0,0)
  entries.append((asset,asset,w,h,group,rects(opaque&~prop)));continue

 if action=='clean':
  a=pixels(asset);h,w=a.shape[:2]
  group=group+'_'+r['pose']
  broom=np.isin(labels(a),[9,10,11])&(a[:,:,3]>0)
  masks[group]=rects(broom);fills[group]=[];offsets[group]=(0,0)
  entries.append((asset,asset,w,h,group,rects((a[:,:,3]>0)&~broom)))
  continue

 first=next((a for a,z in records.items() if z['body']==body and z['action']==action and z['pose'].endswith('_1')))
 a=pixels(asset);base=pixels(first);h,w=a.shape[:2];bh,bw=base.shape[:2]
 offset=(0,0)
 if action=='rest':
  static,dynamic,ff=bed_masks(a)
  if group not in masks:
   bs,_,bfill=bed_masks(base);masks[group]=rects(bs);fills[group]=bfill
 offsets[group]=offset
 if action=='rest':
  expanded=dynamic.copy()
  for oy,ox in ((1,0),(-1,0),(0,1),(0,-1)):
   expanded |= np.roll(dynamic,(oy,ox),(0,1))
  dynamic=expanded&(a[:,:,3]>0)
  if body not in ('sh','wtb'):
   dynamic &= np.indices((h,w))[1]<w*.9
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
 if group not in {e[4] for e in entries}:continue
 text+=f'final _{group} = '+packed(rs)+';\n'
 if group in mirrors:text+=f'final _{group}Mirror = '+packed(mirrors[group])+';\n'

text+='\nfinal registeredFrameLayers = <String,RegisteredFrameLayers>{\n'
for asset,first,w,h,g,rs in entries:text+=f"'{asset}': RegisteredFrameLayers('{first}',Size({w},{h}),_{g},"+packed(rs)+',<int,List<int>>{'+','.join(hex(c)+':'+packed(rr) for c,rr in entryFills.get(asset,fills[g]))+'},'+f'Offset({offsets[g][0]},{offsets[g][1]}),'+(f'_{g}Mirror' if g in mirrors else 'null')+f',{mirrorAnchors.get(g,0)}),\n'
text+='};\n'
for b in ['base','pr','sh','wtb']:
 for ac in ['clean','rest','squat']:text=text.replace('_'+b+'_'+ac,'_'+b+ac.title())
text=re.sub(r'_([a-z]+)(Squat|Clean)_(?:squat|clean)_([a-z0-9]+)',lambda m:'_'+m[1]+m[2]+m[3].title(),text)
out.write_text(text)
print('geometry bytes',out.stat().st_size,'frames',len(entries))
