// Whitney.as - Jim Bumgardner
//
// From ideas by John Whitney -- see his book "Digital Harmony"
//
// Version 1.1 - modified for flash 8, and to draw dots instead of filled circles
//               corrected floating point rendering error in center dots
//               by restricting rotation to 0-360
// 7-29-2007

if (!nbrPoints)
	nbrPoints = 48;
if (!cycleLength)
	cycleLength = 3*60;  // 3 minute cycle

// Spin speed
speed360 = 360*nbrPoints / cycleLength;  // Revolutions per second of the fastest point
                                  // The slowest node goes 1/nbrPoints this speed.

width = Stage.width;
height = Stage.height;
cx = width/2;
cy = height/2;
cRad = width/2*.95;

// Function to return a spectrum of color from 0-1
//
getColor = function(ratio)
{
    var a = 2*Math.PI*ratio;
    // trace(a);
    
    var r = 128+Math.cos(a)*127;
    var g = 128+Math.cos(a+2*Math.PI/3)*127;
    var b = 128+Math.cos(a+4*Math.PI/3)*127;
    return (r << 16) | (g << 8) | b;
}

// Set up the points as movieclips which have their
// origin at the center.  Rotating each clip will spin the dots.
//
for (var i = 0; i < nbrPoints; ++i)
{
    var mc = _root.createEmptyMovieClip("mc"+i, 100+i);
    var r = i/nbrPoints;
    var len = (i+1)*cRad/nbrPoints;
    var rad = Math.max(2, r*8);
    mc._x = cx;
    mc._y = cy;
    mc.len = len;
    
    mc.createEmptyMovieClip("dot", 1);
    mc.dot._x = len;
    mc.dot._y = 0;
    mc.dot.clear();
	mc.dot.lineStyle(rad*2,getColor(r), 100);
	mc.dot.moveTo(-.2,-.2);
	mc.dot.lineTo(.2,.2);

    mc.createEmptyMovieClip("outline", 2);
    mc.outline.clear();
    mc.outline._x = len;
    mc.outline._y = 0;
	mc.outline.lineStyle(rad*2+2,getColor(r) | 0xF0F0F0, 100);
	mc.outline.moveTo(-.2,-.2);
	mc.outline.lineTo(.2,.2);
}

// Animate the points
startTime = getTimer()*.001;
_root.onEnterFrame = function()
{
    var elapsed = (getTimer()*.001 - startTime);

	// this corrects floating point accumulation errors
 	// which show up in the central dots...
 	if (elapsed >= cycleLength)
 		startTime += cycleLength;
 
    // var t = elapsed*nbrPoints*360/cycleLength;
    var t = elapsed*speed360; // optimization for cpu
    var ti = t/nbrPoints;

    // var tl = elapsed*speed*2*Math.PI;
    // var tli = tl/nbrPoints;
    for (var i = 0; i < nbrPoints; ++i)
    {
        var mc = _root['mc'+i];
        // var r = 1-i/nbrPoints;
        // Draw outline if we passed the 0 degree point
        var ad = t/360;
        ad -= int(ad);
        mc._rotation = ad*360;
        t -= ti;
        if (ad < .1) {
            if (mc.outline._visible == false) {
                mc.outline._visible = true;
                mc.outline._alpha = 100;
            }
            else {
                mc.outline._alpha *= .95;
            }
        }
        else
            mc.outline._visible = false;
    }
}

// Draw zero-degree line
_root.clear();
_root.lineStyle(.5, 0x555555,  100);
_root.moveTo(cx,cy);
_root.lineTo(width, cy);
