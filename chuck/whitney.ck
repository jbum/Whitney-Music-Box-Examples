// Whitney Music Box
//
// Jim Bumgardner jbum@jbum.com

48 => int nbrDots;
55 => float baseFreq;
180 => float durationOfPiece;
2.0/nbrDots => float dotGain;

fun void whitneyDot(float baseFreq, float secs, int nDots)
{
	StifKarp voc => dac;
	dotGain => voc.gain;
	for (0 => int i; i < nDots; ++i)
	{
	  baseFreq => voc.freq;
	  1 => voc.noteOn;
	  secs::second => now;
	  1 => voc.noteOff;
	}
}

// Sample Chromatic Pitch Function
fun float pitchFuncC(float baseFreq, int noteIdx)
{
  return baseFreq*Math.pow(2,noteIdx/12.0);
}

// Sample Reversed Harmonics Pitch Function
fun float pitchFuncH(float baseFreq, int noteIdx)
{
  return baseFreq*(nbrDots-noteIdx);
}

for (0 => int i; i < nbrDots; ++i)
{
  spork ~ whitneyDot(pitchFuncC(baseFreq,i), durationOfPiece/(i+1), i+1);
}

durationOfPiece::second => now;
