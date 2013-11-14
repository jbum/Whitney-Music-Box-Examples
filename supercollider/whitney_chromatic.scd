// Whitney Music Box - Chromatic Pitch Assignment - Jim Bumgardner

(
    var n = 48;
    var period = 180;

    SynthDef(\singrain, { |freq = 440, amp = 0.2, sustain = 1|
	  var sig;
	  sig = SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
	  Out.ar(0, sig ! 2);    // sig ! 2 is the same as [sig, sig]
    }).add;

    for(0,n,{
	  arg i;
	  var r;
	  i.postln;
	  r = Routine({
            var delta = period / (i+1);
            loop {
			Synth(\singrain, [freq: 55*(2**(i/12)), amp: 1/48.0, sustain: delta * 0.8]);
	          delta.yield;
	        }
	  });
	  r.play;
    })
)

