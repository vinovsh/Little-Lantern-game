"""Deterministically compile forty authored room routes and puzzle graphs."""
from pathlib import Path
import json,math,runpy
ROOT=Path(__file__).resolve().parents[1]
briefs=runpy.run_path(str(ROOT/'docs/campaign_briefs.py'))['LEVELS']
# Room centers, not variations of one shared platform chain. Branches below join these routes.
ROUTES=[
[(180,580),(650,580),(1100,520),(1560,580),(2100,550)],
[(180,660),(700,595),(1240,530),(1760,595),(2300,660)],
[(180,1380),(600,1315),(1000,1250),(600,1185),(1000,1120),(600,1055),(1000,990),(1400,925),(1800,860)],
[(180,650),(700,650),(1200,650),(1700,650),(2200,650)],
[(180,730),(750,730),(1300,730),(1900,730),(2450,730)],
[(180,620),(700,620),(1250,620),(1800,620),(2400,620)],
[(180,420),(650,485),(1100,550),(1550,615),(2000,680),(2450,745),(2900,810),(3150,420)],
[(180,760),(750,760),(1350,760),(2000,760),(2650,760)],
[(180,800),(750,800),(1400,800),(2050,800),(2700,800)],
[(180,620),(750,620),(1350,620),(1950,620),(2550,620)],
[(180,620),(1050,620),(2100,620),(2950,620)],
[(180,620),(650,900),(1250,900),(1900,620),(2450,480)],
[(180,1480),(650,1415),(1100,1285),(650,1155),(1100,1025),(650,895),(1100,765),(1550,635),(1950,570)],
[(180,700),(700,700),(1250,700),(1800,700),(2350,700)],
[(180,660),(950,660),(1700,660),(2500,660),(3250,660)],
[(180,540),(650,735),(1150,930),(1750,1125),(2350,1255)],
[(180,650),(750,900),(1400,620),(2050,900),(2650,650)],
[(180,700),(850,700),(1500,700),(2200,700),(2850,700)],
[(180,1000),(750,1000),(1400,1000),(2050,1000),(2700,740)],
[(180,650),(800,650),(1400,650),(2000,650),(2600,650)],
[(180,620),(700,620),(1200,620),(1800,620),(2400,620)],
[(180,650),(750,650),(1400,650),(2100,650),(2800,650)],
[(180,1100),(650,970),(1100,840),(1500,710),(1950,580),(2400,515)],
[(180,900),(700,770),(1250,640),(1800,510),(2350,640),(2900,770)],
[(180,650),(750,650),(1250,650),(2050,650),(2700,650)],
[(180,680),(800,680),(1450,680),(2100,680),(2700,680)],
[(180,620),(1100,620),(2050,620),(3000,620)],
[(180,800),(800,800),(1450,800),(2100,800),(2750,800)],
[(180,900),(800,900),(1450,900),(2150,900),(2850,900)],
[(180,680),(850,680),(1500,680),(2150,680),(2800,680)],
[(180,600),(900,600),(1650,535),(2400,600),(3100,535)],
[(180,750),(800,750),(1450,750),(2100,750),(2750,750)],
[(180,430),(850,560),(1500,690),(2150,820),(2800,950)],
[(180,1550),(650,1420),(1150,1290),(650,1160),(1150,1030),(1650,900),(2150,770),(2650,640)],
[(180,680),(900,680),(1650,680),(2400,680),(3100,680)],
[(180,820),(800,820),(1450,820),(2100,820),(2750,820)],
[(180,620),(1150,620),(2100,620),(3050,620)],
[(180,1000),(800,1000),(1450,1000),(2150,1000),(2850,740)],
[(180,650),(950,650),(1800,650),(2650,650),(3500,650)],
[(180,800),(900,800),(1650,800),(2400,800),(3150,670)]
]
BRANCHES={
2:[[(700,595),(950,660),(1450,660),(1760,595)]],
4:[[(700,650),(700,520),(1200,455),(1700,520),(1700,650)]],
5:[[(750,730),(750,535),(1300,470),(1900,535),(1900,730)]],
6:[[(700,620),(900,425),(1600,425),(1800,620)]],
7:[[(650,485),(1200,420)]],
8:[[(750,760),(750,565),(1350,565),(1350,760)],[(1350,760),(1600,955),(2000,955),(2000,760)]],
9:[[(750,800),(750,605),(1200,605),(1400,800)],[(1400,800),(1400,995),(2050,995),(2050,800)]],
12:[[(180,620),(600,490),(1300,490),(1900,620)]],
14:[[(700,700),(900,570),(1600,570),(1800,700)]],
15:[[(950,660),(1250,530),(1600,530),(1700,660)]],
17:[[(750,900),(750,620),(1400,620),(2050,620),(2050,900)]],
19:[[(750,1000),(750,740),(1400,740),(1400,1000)],[(1400,1000),(1400,1260),(2050,1260),(2050,1000)]],
23:[[(1100,840),(1500,970),(1950,840)]],
24:[[(700,770),(1250,900),(2350,900),(2900,770)]],
25:[[(750,650),(750,455),(1100,455),(1250,650)]],
28:[[(800,800),(800,605),(1450,605),(1450,800)],[(1450,800),(1800,995),(2100,995),(2100,800)]],
29:[[(800,900),(800,640),(1450,640),(1450,900)],[(1450,900),(1800,1160),(2150,1160),(2150,900)]],
31:[[(180,600),(600,795),(1150,795),(1650,535)]],
33:[[(850,560),(850,755),(1500,885),(2150,820)]],
35:[[(900,680),(900,940),(1650,940),(1650,680)]],
36:[[(800,820),(800,625),(1450,625),(1450,820)],[(1450,820),(1800,1015),(2100,1015),(2100,820)]],
38:[[(800,1000),(800,740),(1450,740),(1450,1000)],[(1450,1000),(1450,1260),(2150,1260),(2150,1000)]],
39:[[(950,650),(1200,845),(1800,650)]],
40:[[(900,800),(900,605),(1650,605),(1650,800)],[(1650,800),(2000,1060),(2400,800)]]}
CUTS={11:[0,1,2],15:[0,2,3],21:[2],25:[2],27:[0,1,2],31:[0,1,2,3],35:[0,2],37:[0,1,2]}
ALL=[]
for brief,route in zip(briefs,ROUTES):
 n=brief['number']; chapter=(n-1)//10
 level=dict(id=n,title=brief['title'],theme=chapter,chapter=chapter,objective=brief['mission'],clue=brief['lock'],story=brief['twist'],discovery=brief['secret'],topology=brief['meta'],route=route,platforms=[],objects=[],enemies=[],zones=[],vehicles=[],rules=[],requires=[],checkpoints=[route[0]],spawn=route[0],exit=[route[-1][0]+80,route[-1][1]],width=max(x for x,y in route)+650,height=max(y for x,y in route)+300)
 def platform(x,y,w=320,**kw):
  row=dict(x=round(x-w/2,2),y=round(y,2),w=w,h=100,material='ice' if chapter==3 and n!=31 else ('basalt' if chapter==2 else 'moss'));row.update(kw)
  if not any(abs(p['x']-row['x'])<3 and abs(p['y']-row['y'])<3 for p in level['platforms']):level['platforms'].append(row)
 def link(nodes,cuts=()):
  for x,y in nodes:platform(x,y,400)
  for i,((x,y),(xx,yy)) in enumerate(zip(nodes,nodes[1:])):
   if i in cuts:continue
   steps=max(1,math.ceil(abs(xx-x)/260),math.ceil(abs(yy-y)/65))
   for k in range(1,steps):platform(x+(xx-x)*k/steps,y+(yy-y)*k/steps,240)
 link(route,CUTS.get(n,[]))
 branch_routes=BRANCHES.get(n)
 if not branch_routes:
  bx,by=route[len(route)//2];branch_routes=[[(bx,by),(bx+260,by-65),(bx+520,by-130)]]
 for branch in branch_routes:link(branch)
 if len(route)>5:level['checkpoints'] += [route[len(route)//2]]
 else:level['checkpoints'] += [route[2]]
 # Every collectible is over stable, reachable terrain; optional discovery lies on a branch.
 picks=[route[int(i*(len(route)-1)/4)] for i in range(5)]
 level['fireflies']=[[x+45,y-68] for x,y in picks]
 side=branch_routes[0]
 level['secret']=[side[len(side)//2][0]+75,side[len(side)//2][1]-10]
 def pos(slot):return list(route[min(slot,len(route)-1)]) if isinstance(slot,int) else list(slot)
 def obj(uid,kind,slot,label,needs=(),**kw):
  o=dict(id=uid,kind=kind,pos=pos(slot),label=label,needs=list(needs));o.update(kw);level['objects'].append(o);return o
 def enemy(kind,slot,offset=0,**kw):
  x,y=pos(slot);e=dict(kind=kind,pos=[x+offset,y-26],span=75);e.update(kw);level['enemies'].append(e)
 def zone(kind,rect,**kw):z=dict(kind=kind,rect=rect);z.update(kw);level['zones'].append(z)
 def water(x,y,w,h=300,**kw):zone('water',[x,y,w,h],**kw);platform(x+w/2,y+h,w+200,material='stone')
 def vehicle(uid,kind,nodes,needs=()):level['vehicles'].append(dict(id=uid,kind=kind,nodes=nodes,needs=list(needs)))
 def receiver(uid,slot,needs=(),**kw):return obj(uid,'receiver',slot,'Illuminate the sun seal',needs,**kw)
 def lever(uid,slot,label,needs=(),**kw):return obj(uid,'lever',slot,label,needs,**kw)
 def key(uid,slot,label='Collect quest item',needs=()):return obj(uid,'key',slot,label,needs)
 def crate(uid,slot,target,label='Hold USE and drag to push',needs=(),**kw):return obj(uid,'crate',slot,label,needs,target=pos(target),**kw)
 def gate(needs):level['requires']=list(needs)
 def ring(uid,slot,target,needs=()):obj(uid,'ring',slot,'Set ring  Leaf • Moon • Sun',needs,target=target)
 def valve(uid,slot,label,target=1,needs=(),**kw):return obj(uid,'valve',slot,label,needs,target=target,**kw)
 def mirrors():
  obj('mirror_a','mirror',1,'Turn first mirror',target=1);obj('mirror_b','mirror',3,'Turn second mirror',target=2);receiver('roof',2,['mirror_a','mirror_b']);gate(['roof'])
 def guardian(kind,stages):
  enemy(kind,2,0,boss=True);level['boss']=kind
  for i,st in enumerate(stages):
   uid,kind2,slot,needs,opts=st
   obj(uid,kind2,slot,f'Restore beacon phase {i+1}',needs,**opts)
  gate([stages[-1][0]])
 if n==1:
  crate('branch',1,[route[1][0]+90,route[1][1]],'Hold USE and move the branch');receiver('bridge',2,['branch']);gate(['bridge'])
 elif n==2:
  key('acorn',2,'Acorn key');obj('tree_door','door',4,'Use acorn key',['acorn']);gate(['tree_door']);enemy('crawler',2,-80)
 elif n==3:
  crate('root_weight',1,[route[1][0]+85,route[1][1]]);obj('upper_root','plate',3,'Stand on the root plate');level['rules']=[dict(needs=['root_weight','upper_root'],sets='root_lift')];vehicle('root_lift','lift',[[1350,1320],[1350,860]],['root_lift']);gate(['root_lift']);enemy('crawler',4,-80);enemy('crawler',6,75)
 elif n==4:
  lever('decoy',1,'Light moth decoy');lever('rescue',3,'Free the gardener',['decoy']);gate(['rescue']);enemy('moth',2,-50);enemy('moth',2,50)
 elif n==5:
  obj('mirror_a','mirror',[750,535],'Turn first mirror',target=1);obj('mirror_b','mirror',[1900,535],'Turn second mirror',target=2);receiver('roof',[1300,470],['mirror_a','mirror_b']);gate(['roof']);enemy('crawler',1,-110);enemy('crawler',3,110);enemy('moth',2)
 elif n==6:
  key('brass',3,'Brass key');receiver('slit',3,['brass']);obj('mill_door','door',4,'Open the mill',['brass','slit']);gate(['mill_door']);enemy('sentinel',2);enemy('crawler',1,-80);enemy('crawler',4,0)
 elif n==7:
  key('gear_a',2,'First gear tooth');crate('shutter',4,[route[4][0]+90,route[4][1]]);key('gear_b',5,'Second gear tooth',['shutter']);lever('repair',6,'Install both gear teeth',['gear_a','gear_b']);vehicle('orchard_lift','lift',[[2950,810],[2950,420]],['repair']);gate(['repair']);enemy('moth',4);enemy('moth',5);enemy('crawler',3)
  zone('brittle',[1450,615,200,25],uid='orchard_branch');platform(1550,745,500,material='stone')
 elif n==8:
  receiver('upper_latch',[750,565]);lever('decoy',[1600,955],'Light the moth cage');obj('cage','cage',[2000,955],'Lure the moth onto the plate',['decoy']);gate(['upper_latch','cage']);enemy('moth',[1800,955]);enemy('crawler',1,-100);enemy('crawler',2,100);enemy('crawler',3,90)
 elif n==9:
  key('gear',[750,605],'Travel lock gear');lever('installed',1,'Install the gear',['gear']);ring('ring_a',[1250,800],0,['installed']);ring('ring_b',[1420,800],1,['installed']);ring('ring_c',[1590,800],2,['installed']);receiver('travel_seal',3,['ring_a','ring_b','ring_c']);gate(['travel_seal']);water(500,1040,1800,160,raise_flag='installed',rise=45);enemy('sentinel',[1400,995]);enemy('sentinel',[2050,995]);enemy('crawler',2,-250);enemy('crawler',3,150)
 elif n==10:
  receiver('phase1',1);obj('mirror','mirror',2,'Turn the stag mirror',['phase1'],target=2);receiver('phase2',3,['phase1','mirror']);lever('decoy',[1800,620],'Light the cracked root lure',['phase2']);obj('anchor','anchor',[1800,620],'Lure a charge into this brace',['phase2','decoy']);receiver('phase3',4,['phase2','anchor']);enemy('stag',2,boss=True);level['boss']='stag';gate(['phase3']);enemy('moth',3,100,needs=['phase2']);enemy('moth',4,-50,needs=['phase2'])
 elif n==11:
  water(380,650,2300,350,current=-45);vehicle('ferry','raft',[[500,620],[900,620],[1950,620],[2700,620]]);valve('village',2,'Open village sluice');gate(['village']);enemy('crawler',1,-90)
 elif n==12:
  water(450,900,1300,200,control='water',levels=[900,700,500]);crate('cargo',2,[1400,500],buoyant=True,when=['water:2']);valve('water',1,'Water height  Low • Middle • High',target=2,water_control=True);gate(['cargo']);enemy('skimmer',1,100);enemy('skimmer',3,-100)
 elif n==13:
  water(420,1450,1000,220,control='water',levels=[1450,1080,600]);key('gear',1,'Reservoir gear');lever('installed',2,'Power the reservoir',['gear']);valve('water',3,'Choose reservoir water height',target=2,water_control=True,needs=['installed']);key('tide_key',6,'Tide key',['water:1']);obj('outlet','door',8,'Open upper outlet',['tide_key','water:2']);gate(['outlet']);enemy('skimmer',1,80);enemy('skimmer',3,-80);enemy('crawler',6,70)
 elif n==14:
  water(550,810,1450,230,control='water',levels=[810,735,660]);valve('water',1,'Set pool to middle waterline',target=1,water_control=True);valve('inlet',3,'Close rippling inlet');obj('reflection','reflect',2,'Reflect into ceiling seal',['water:1','inlet']);gate(['reflection']);enemy('crab',1,-80);enemy('crab',3,80)
 elif n==15:
  water(400,690,2700,350,current=-60,reverse_flag='dock_a');key('rudder',0,'Ferry rudder');lever('repair',1,'Install ferry rudder',['rudder']);vehicle('ferry','raft',[[500,660],[1300,660],[2150,660],[3000,660]],['repair']);valve('dock_a',[1250,530],'Reverse first dock current');valve('dock_b',3,'Reverse second dock current');gate(['dock_a','dock_b']);enemy('skimmer',2,-70);enemy('skimmer',3,80);enemy('crab',1,80)
 elif n==16:
  water(400,580,2400,1020,current=20);key('pearl',1,'Glow pearl');obj('air_door','door',4,'Open air chamber',['pearl']);gate(['air_door']);enemy('eel',1,80);enemy('eel',2,-70);enemy('eel',3,70);enemy('crab',4,-90)
 elif n==17:
  water(450,960,650,180,control='left',levels=[960,880,800,700]);water(1750,960,650,180,control='right',levels=[960,880,800,700]);obj('left','gauge',1,'Left tank target two units',initial=1);obj('right','gauge',3,'Right tank target one unit',initial=2);obj('transfer','transfer',2,'Transfer one unit between tanks');valve('supply_a',[1100,620],'Close left supply');valve('supply_b',[1700,620],'Close right supply');crate('weight',1,[route[1][0]+90,route[1][1]]);gate(['left:2','right:1','supply_a','supply_b','weight']);enemy('crab',1,-90);enemy('crab',3,90);enemy('skimmer',1,130);enemy('skimmer',3,-130)
 elif n==18:
  water(400,800,2300,260);valve('chamber_a',1,'Stop first pressure cycle');valve('chamber_b',2,'Stop second pressure cycle',1,needs=['chamber_a']);valve('chamber_c',3,'Stop final pressure cycle',needs=['chamber_b']);gate(['chamber_a','chamber_b','chamber_c'])
  for i,x in enumerate([650,1300,2000]):zone('pressure',[x,650,160,90],disable=['chamber_a','chamber_b','chamber_c'][i],reverse=i==2)
  enemy('eel',1,130);enemy('skimmer',2,100);enemy('eel',3,100);enemy('skimmer',4,-100)
 elif n==19:
  water(500,1210,1800,250,control='water',levels=[1210,1020,760]);valve('water',2,'Change archive water height',target=2,water_control=True);key('wave',[750,740],'Wave inscription');key('reed',[1400,1260],'Reed inscription');key('shell',3,'Shell inscription');ring('archive_a',[2450,870],2,['wave','reed','shell']);ring('archive_b',[2600,805],0,['wave','reed','shell']);ring('archive_c',4,1,['wave','reed','shell']);receiver('archive',4,['archive_a','archive_b','archive_c']);gate(['archive']);enemy('crab',1);enemy('crab',3);enemy('eel',[1400,1260]);enemy('eel',2,100);enemy('skimmer',3,120)
 elif n==20:
  water(500,770,1900,360,control='water',levels=[770,690,580],current=-70,reverse_flag='phase2');valve('water',1,'Lower the warden basin',target=0,water_control=True,initial=2);receiver('phase1',1,['water:0']);crate('valve_weight',2,[route[2][0]+90,route[2][1]],needs=['phase1']);receiver('phase2',3,['phase1','valve_weight']);lever('decoy',[2200,650],'Light broken grate lure',['phase2']);obj('grate','anchor',[2200,650],'Lure the warden into the grate',['phase2','decoy']);receiver('phase3',4,['phase2','grate']);enemy('warden',2,boss=True);level['boss']='warden';gate(['phase3']);enemy('skimmer',3,90,needs=['phase2']);enemy('skimmer',4,-100,needs=['phase2'])
 elif n==21:
  obj('brazier','brazier',2,'Heat the brazier with Ember',lens=1);gate(['brazier']);enemy('hopper',3)
 elif n==22:
  valve('fuel_a',1,'Close first furnace feed');valve('fuel_b',3,'Close second furnace feed');lever('bellows',4,'Open bellows exit',['fuel_a','fuel_b']);gate(['bellows'])
  for x,flag in [(900,'fuel_a'),(1650,'fuel_b'),(2300,'bellows')]:zone('vent',[x,590,180,90],disable=flag)
  enemy('hopper',1,-90);enemy('hopper',3,100);enemy('wasp',2,100)
 elif n==23:
  crate('brace',2,[route[2][0]+90,route[2][1]],'Brace the falling stair');obj('vines','brazier',3,'Burn the marked dry vines',['brace'],lens=1,unstable=True);lever('winch',2,'Reset the fallen stair',reset=True);gate(['vines']);enemy('hopper',1);enemy('hopper',3,-100);enemy('wasp',4,80)
 elif n==24:
  obj('heat_a','brazier',1,'Light outer heat decoy',lens=1);obj('heat_b','brazier',4,'Light outer heat decoy',lens=1);obj('heat_inner','brazier',2,'Inner heat decoy',lens=1);key('insulated',3,'Insulated key',['heat_a','heat_b','!heat_inner']);obj('service','door',5,'Open service lift',['insulated']);gate(['service']);enemy('wasp',2,-80);enemy('wasp',3,100);enemy('wasp',4,90);enemy('hopper',1,90)
 elif n==25:
  valve('feed',[750,455],'Close the furnace feed');obj('spout','mirror',2,'Aim cooling spout',['feed'],target=2);lever('cooled',3,'Release measured water burst',['feed','spout']);gate(['cooled']);enemy('crab',1,-100);enemy('crab',[750,455],90);enemy('hopper',3,80);enemy('hopper',4,80)
 elif n==26:
  lever('decoy',2,'Light the marked chain lure');obj('chain','anchor',2,'Lure a hammer strike here',['decoy']);receiver('forge_seal',3,['chain']);gate(['forge_seal']);enemy('guard',2,-100);enemy('hopper',1,-90);enemy('hopper',3,100);enemy('wasp',4,-80)
 elif n==27:
  lever('track',0,'Align the cargo track');valve('rail',1,'Cool missing rail socket',needs=['track']);key('prism',2,'Rail prism',['rail']);obj('station','door',3,'Install prism in station lock',['prism']);vehicle('carriage','train',[[450,620],[900,620],[1850,620],[2750,620]],['track']);gate(['station']);enemy('wasp',1,100);enemy('wasp',2,-100);enemy('hopper',1,-120);enemy('hopper',2,120);level['checkpoints']=[route[0],route[1],route[2]]
 elif n==28:
  lever('clear_a',1,'Vent upper library room');lever('clear_b',2,'Vent lower library room');key('code_a',[800,605],'Leaf plaque',['clear_a']);key('code_b',[1800,995],'Moon plaque',['clear_b']);key('code_c',3,'Mirrored sun plaque');ring('library_a',[2450,800],0,['code_a','code_b','code_c']);ring('library_b',[2600,800],1,['code_a','code_b','code_c']);ring('library_c',4,2,['code_a','code_b','code_c']);gate(['library_a','library_b','library_c']);zone('smoke',[600,420,600,380],disable='clear_a');zone('smoke',[1650,850,550,300],disable='clear_b');enemy('guard',[800,605]);enemy('wasp',[1800,995]);enemy('wasp',3)
 elif n==29:
  valve('pressure',[800,640],'Stop the vent tower');valve('channel',[1800,1160],'Cool the channel');lever('workshop',3,'Release the heart door chain');gate(['pressure','channel','workshop']);enemy('guard',1);enemy('guard',3);enemy('hopper',2,-90);enemy('hopper',4,-90);enemy('wasp',[800,640],100);enemy('wasp',[1800,1160],100)
 elif n==30:
  valve('fuel',1,'Close the core fuel');receiver('phase1',1,['fuel']);obj('mirror','mirror',2,'Aim core water release',['phase1'],target=2);receiver('phase2',3,['phase1','mirror']);lever('cooled',3,'Release water onto the core',['phase2']);receiver('phase3',4,['phase2','cooled']);enemy('furnace',2,boss=True);level['boss']='furnace';gate(['phase3']);zone('vent',[1350,590,300,120],disable='phase3');vehicle('ring','ring',[[900,610],[1200,545],[1650,610]],['phase1']);enemy('hopper',3,100,needs=['phase2']);enemy('hopper',4,-100,needs=['phase2'])
 elif n==31:
  obj('vane','mirror',0,'Turn wind vane toward observatory',target=1);gate(['vane']);enemy('crawler',4,50)
  for x in [450,1200,1950,2700]:zone('wind',[x,200,500,650],force=[95,-340])
 elif n==32:
  crate('anchor',1,[route[1][0]+120,route[1][1]],'Hold USE and push the heavy anchor');lever('brake',3,'Release windmill brake',['anchor']);gate(['brake']);zone('wind',[550,530,1850,260],force=[-80,0]);enemy('stalker',2,-90);enemy('stalker',3,90)
 elif n==33:
  key('clapper',[850,755],'Bell clapper');obj('bell','door',4,'Repair and ring the valley bell',['clapper']);gate(['bell']);enemy('stalker',1,100);enemy('stalker',3,-100);enemy('kite',2)
 elif n==34:
  obj('vane_a','mirror',2,'Aim first spire shutter',target=1);receiver('beacon_a',2,['vane_a']);obj('vane_b','mirror',5,'Aim second spire shutter',['beacon_a'],target=3);receiver('beacon_b',6,['vane_b']);gate(['beacon_a','beacon_b']);enemy('kite',2);enemy('kite',4);enemy('kite',6);enemy('stalker',3)
  for x,y in route[1:-1]:zone('wind',[x-150,y-350,400,450],force=[45,-480])
 elif n==35:
  water(400,710,2400,450);obj('ice_a','ice',[600,710],'Freeze marked water socket',lens=2);obj('ice_b','ice',[2050,710],'Freeze marked water socket',['ice_a'],lens=2);lever('causeway',4,'Open causeway door',['ice_b']);gate(['causeway']);enemy('stalker',1);enemy('stalker',3);enemy('kite',2,100)
 elif n==36:
  obj('false_a','star',[800,625],'Test star pedestal',target=1,wrong=True);obj('real','star',2,'Match the unbroken star shadow',target=2);obj('false_b','star',[1800,1015],'Test star pedestal',target=0,wrong=True);receiver('vault',3,['real']);gate(['vault']);enemy('wisp',[800,625],100);enemy('wisp',[1800,1015],-100);enemy('stalker',1,-90);enemy('stalker',3,90)
 elif n==37:
  obj('vane_a','mirror',0,'Align first wagon coupling',target=1);lever('coupling_a',0,'Connect first wagon',['vane_a']);obj('vane_b','mirror',1,'Align second wagon coupling',target=2);lever('coupling_b',1,'Connect second wagon',['vane_b']);obj('vane_c','mirror',2,'Align final wagon coupling',target=3);lever('coupling_c',2,'Connect final wagon',['vane_c']);key('core',2,'Supply lantern core',['coupling_a','coupling_b','coupling_c']);obj('station','door',3,'Power the storm station',['core']);vehicle('convoy','train',[[450,620],[950,620],[1900,620],[2800,620]]);gate(['station']);zone('wind',[600,250,2100,430],force=[70,0]);enemy('kite',1);enemy('kite',2);enemy('wisp',1,120);enemy('wisp',2,-120);level['checkpoints']=[route[0],route[1],route[2]]
 elif n==38:
  water(1350,1080,950,400);lever('submerged',[1450,1260],'Open water room switch');obj('thaw','brazier',[800,740],'Thaw the marked stair latch',lens=1);obj('ice','ice',[2150,1030],'Freeze a stepping socket',lens=2);obj('vane','mirror',3,'Aim the final wind tower',['ice'],target=2);gate(['submerged','thaw','vane']);enemy('eel',[1450,1260],100);enemy('guard',[800,740],100);enemy('kite',3,90);enemy('kite',4,-80)
 elif n==39:
  crate('root',1,[route[1][0]+90,route[1][1]],'Anchor the restored root lift');valve('ferry',2,'Raise the ferry receiver');obj('forge','brazier',3,'Heat the forge release',['ferry'],lens=1);lever('cable',4,'Connect cooled forge cable',['forge']);gate(['root','ferry','cable']);water(1000,810,700,250);enemy('moth',1,-70);enemy('moth',1,70);enemy('crab',2,-80);enemy('guard',3);enemy('kite',4,100);level['checkpoints']=[route[0],route[1],route[2],route[3]]
 elif n==40:
  valve('ground',1,'Divert water to ground storm circuit');receiver('phase1',1,['ground']);obj('thaw','brazier',[900,605],'Thaw the frozen mirror',['phase1'],lens=1);obj('mirror','mirror',[1650,605],'Aim the beacon mirror',['thaw'],target=2);receiver('phase2',2,['phase1','mirror']);obj('ice','ice',[2400,830],'Freeze final stepping stone',['phase2'],lens=2);receiver('phase3',4,['phase2','ice']);enemy('stormkeeper',2,boss=True);level['boss']='stormkeeper';gate(['phase3']);enemy('wisp',3,-80,needs=['phase2']);enemy('wisp',4,-90,needs=['phase2']);zone('wind',[2450,250,550,650],force=[80,-330]);water(1800,1060,900,250)
 for threat in list(level['enemies']):
  if threat['kind'] in ['sentinel','guard','stag','warden','furnace','stormkeeper']:
   x,y=threat['pos'];obj('cover_'+str(len(level['objects'])),'cover',[x-135,y+26],'Shelter')
 # Breakable platforms have safe recovery terrain underneath.
 for z in level['zones']:
  if z['kind']=='brittle':
   for p in level['platforms']:
    if abs(p['y']-z['rect'][1])<1 and p['x']<=z['rect'][0]+z['rect'][2]/2<=p['x']+p['w']:p['break_id']=z['uid']
 if n==23:
  for p in level['platforms']:
   if abs(p['y']-710)<1 and p['x']<1600 and p['x']+p['w']>1450:p['falls_if']='fallen_stair'
 if n==40:obj('false_star','star',[2600,670],'Inspect the broken cable',wrong=True,target=1)
 level['state_flags']=['fallen_stair'] if n==23 else []
 # Give movable weights a clear flat runway, separate from valve controls.
 for c in [o for o in level['objects'] if o['kind']=='crate']:
  for other in level['objects']:
   if other is not c and other['kind']=='valve' and other['pos']==c['pos']:
    c['pos'][0]-=110;other['pos'][0]+=90
  for p in level['platforms']:
   if 0<c['pos'][1]-p['y']<=100 and p['x']<c['target'][0]+80 and p['x']+p['w']>c['pos'][0]-80:
    p['x']=c['target'][0]+80
 if n in [4,8,11,21,31]:
  roles={4:'GARDENER',8:'MILLKEEPER',11:'FERRYMAN',21:'FORGE KEEPER',31:'SKY TRAVELER'}
  slot=[route[3][0]+115,route[3][1]] if n==4 else [route[0][0]+330,route[0][1]]
  obj('traveler','npc',slot,'Talk to '+roles[n].lower(),['rescue'] if n==4 else [],role=roles[n],dialogue=brief['twist'])
 # A reset pedestal and journal are always accessible at the start. Every vehicle has a call post at each dock.
 obj('reset','reset',[route[0][0]-95,route[0][1]],'Reset loose puzzle objects')
 obj('journal','clue',[route[0][0]+120,route[0][1]],'Read the trail inscription',text=brief['lock'])
 if n>=21:obj('lens','lens',[route[0][0]+220,route[0][1]],'Choose lantern lens')
 if n>=35:obj('lens_mid','lens',[route[len(route)//2][0]-120,route[len(route)//2][1]],'Choose Ember or Frost lens')
 for v in level['vehicles']:
  for j,(x,y) in enumerate(v['nodes']):
   sx,sy=min(route,key=lambda p:abs(p[0]-x)+abs(p[1]-y))
   obj(v['id']+'_call_'+str(j),'call',[max(sx-150,min(sx+150,x)),sy],'Recall the moving platform',vehicle=v['id'],dock=j)
 # Bridge gaps have a distinct mechanism, and cannot be crossed by scenery swaps alone.
 if n in [1,21,25]:
  a,b=route[2:4];flag={1:'bridge',21:'brazier',25:'cooled'}[n]
  if n==1:
   # Small tutorial bridge above a safe recovery shelf.
   platform(1350,650,500,material='stone')
  for x in range(int(a[0]+220),int(b[0]-180),180):platform(x,max(a[1],b[1]),190,needs=[flag],material='light' if n==1 else 'stone')
 # Collectible positions and props may live in optional branches; include their bounds in camera extents.
 level['height']=max(level['height'],max((p['y']+p['h'] for p in level['platforms']),default=0)+180)
 level['width']=max(level['width'],max((p['x']+p['w'] for p in level['platforms']),default=0)+150)
 if chapter==2:
  zone('lava',[350,max(p['y'] for p in level['platforms'])+180,level['width']-450,150])
 ALL.append(level)
assert len(ALL)==40
assert len({json.dumps(x['platforms'],sort_keys=True) for x in ALL})==40
for l in ALL:
 ids=[o['id'] for o in l['objects']];assert len(ids)==len(set(ids)),l['id']
 assert len(l['fireflies'])==5
(ROOT/'assets/data/campaign.json').write_text(json.dumps(ALL,indent=2))
print('Built forty unique room routes and puzzle graphs')
