"""Original deterministic ambient loops for the elemental chapters."""
from pathlib import Path
import math,random,struct,wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
for name,notes,seed in [('river',[146.83,220,293.66,440],21),('ember',[110,164.81,220,329.63],31),('sky',[174.61,261.63,349.23,523.25],41)]:
 rng=random.Random(seed);rate=22050;seconds=16;data=bytearray()
 for i in range(rate*seconds):
  t=i/rate;env=.65+.35*math.sin(2*math.pi*t/seconds)**2
  value=sum(math.sin(2*math.pi*f*t)*(.016 if j else .028)*(1+.2*math.sin(2*math.pi*t*(j+1)/seconds)) for j,f in enumerate(notes))
  value+=rng.uniform(-.002,.002)
  fade=min(1,t/.12,(seconds-t)/.12)
  data.extend(struct.pack('<h',int(max(-.95,min(.95,value*env*fade))*32767)))
 with wave.open(str(root/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(data)
 print(name)
