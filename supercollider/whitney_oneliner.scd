// Whitney music box in one line - by Nathaniel Virgo
play{mean({|i|99**(-1-LFSaw.kr(i+1/180,1))*SinOsc.ar(i+1*55)}!48)!2}

// Explanations by Jim B:

//	{|i| i.postln; }!10;  // basic iterator

// Envelope generation:
// {LFSaw.kr(2,1)}.plot(1);           // produces ascending ramp from -1 to 1
// {-1 - LFSaw.kr(2,1)}.plot(1);      // produces descending ramp from 0 - -2
// {99**(-1-LFSaw.kr(2,1))}.plot(1);  // Produces a nice envelope from 1 to 0 at the desired rate
                                      // 99 ** 0 is 1    99 ** -2 is a small value

// mean() is used to mix all the signals so we don't have to explicitly sent amplitude to 1/n

// !2 is for the stereo channels