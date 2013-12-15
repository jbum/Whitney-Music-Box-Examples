# Whitney Music Box in Pyo - Jim Bumgardner

from pyo import *

nbrDots = 60              # Number of dots
period = 60.0             # Duration of cycle in seconds
chromatic = True          # use Chromatic Scale vs harmonics
basePitch = 60-nbrDots/2  # base midi pitch for Chromatic version
baseFreq = 50             # fundamental frequency for Harmonics
reverse = True            # reverse order of pitches/harmonics

s = Server().boot()
s.start()

durs = [period/(i+1) for i in range(nbrDots)]
freqs = [(midiToHz(basePitch+i) if chromatic else baseFreq*(i+1)) for i in range(nbrDots)]
if reverse:
  freqs = list(reversed(freqs))
trig = Metro(durs,True).play()
env = TrigExpseg(trig, [(0,0),(0.01,1),(5,0)])
v = Sine(freq=freqs,mul=env*2.0/nbrDots).out()

s.gui(locals())
