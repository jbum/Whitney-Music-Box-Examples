/* 
  Todos:
     * Figure out how to use dials for params (e.g. make dial send named functions).
     * Make option to sync off timeline clock.
	 * Add descent mapping option for notes.



 */


inlets = 1;
outlets = 5;
// 0 = pitch
// 1 = velocity
// 2 = duration
// 3 = sketch commands
// 4 = render commands

post("Reloading JS!");

outlet(3,["reset"]);
outlet(3,["smooth_shading", 1]);



var period = 180000;
var nbrDots = 48;
var basePitch = 50;
var startTime = max.time; // (new Date()).getTime();
var lastHit = [];
var tines = [];
var clrs = [];
var isMuted = true;
var isFirstTime = true;

whit_reset();

function loadbang() {
	post("loadbang invoked\n");
	whit_reset();
}

function getElapsed() {
	return max.time - startTime;
}

function lerpColor(clr1, clr2, r) {
	return [clr1[0]+(clr2[0]-clr1[0])*r,
	        clr1[1]+(clr2[1]-clr1[1])*r,
			clr1[2]+(clr2[2]-clr1[2])*r,
			clr1[3]+(clr2[3]-clr1[3])*r];
}

function doIdle() {
	var ms = getElapsed();
	
	outlet(3,["reset"]);
	// outlet(3,["glbegin"]);

	for (var i = 0; i < nbrDots; ++i) {
		var r = (i+1)/nbrDots;
		var pitch = (i+1)*basePitch;
		var dperiod = period/(nbrDots-i);
		var ctr = Math.floor(ms/dperiod);

		var a = ms*Math.PI*2/dperiod;
		var rad = r*0.8;
		var px = Math.cos(a)*rad;
		var py = -Math.sin(a)*rad;
		var dotRad = 0.01 + r*0.03;

		if (tines[i] != ctr) {
			tines[i] = ctr;
			lastHit[i] = ms;
			if (!isMuted) {
				var noteDur = Math.min(10000,dperiod/2);
				outlet(2, noteDur); // duration
				outlet(1, 64);   // velocity
				outlet(0, pitch);   // pitch
			}
		}

		var dElapsed = ms - lastHit[i];
		var clr;
		if (dElapsed < 2000) {
			clr = lerpColor([1.,1.,1.,1.],clrs[i],dElapsed/2000);
		} else {
			clr = clrs[i];
		}
		outlet(3,["glcolor",clr[0],clr[1],clr[2],clr[3]]);
		outlet(3,["glpushmatrix"]);
		outlet(3,["moveto",px,py]);
		outlet(3,["circle",dotRad]);
		outlet(3,["glpopmatrix"]);
	}
	// outlet(3,["glend"]);
	// jsketch.glend();
	outlet(4,["erase"]);
	outlet(4,["drawswap"]);
}

function bang()
{
	doIdle(); 
}

var savedElapsed = 0;

function msg_int(v)
{
	isMuted = !v;
	if (isMuted) {
		savedElapsed = getElapsed();
		// remember current time
	} else {
		startTime = max.time - savedElapsed;
	}
	post("Muted: " + isMuted + "\n");
}

function silentChange() {
	if (!isMuted) {
		// reset notes
		isMuted = true;
		doIdle();
		isMuted = false;
	}
}

function resetColors() {
	clrs = [];
	for (var i = 0; i < nbrDots; ++i) {
		var rat = (i+1.0)/nbrDots;
		var ang = rat*Math.PI*2;
		var r = 0.5 + Math.cos(ang)/2;
		var g = 0.5 + Math.cos(ang+2)/2;
		var b = 0.5 + Math.cos(ang+4)/2;
		clrs.push([r,g,b,1]);
	}
}

function whit_reset() {
	post("reset\n");
	for (var i = 0; i < nbrDots; ++i) {
		tines[i] = -1;
	}
	resetColors();
	startTime = max.time;
	savedElapsed = 0;
}

function whit_params(_nbrDots,_period,_basePitch) {
	post("Got params, nbrdots=" + _nbrDots + " elapsed: " + getElapsed() + "\n");
	nbrDots = _nbrDots;
	period = _period;
	basePitch = _basePitch;
	resetColors();
	silentChange();
}

function whit_nbrDots(v) {
	nbrDots = v;
	resetColors();
	silentChange();
}

function whit_period(v) {
	period = v;
	silentChange();
}

function whit_basePitch(v) {
	basePitch = v;
	silentChange();
}

