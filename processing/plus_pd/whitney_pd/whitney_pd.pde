// Whitney Music Box - Jim Bumgardner
//
// Processing+PD implementation jbum 9/9/2012
//
// Version 1.3 9-25-2011 Reworked how motion is tracked.
// Version 1.2 9-12-2011 Improved voice design and message passing.
// Version 1.1 9-10-2011 Simplified Organ implementation.  Voices can be increased using makeorgan.pl
//
//
// Many thanks to Peter Kirn for introducing me to pdlib.


import netP5.*;
import com.noisepages.nettoyeur.processing.*;

PureDataP5Jack pd;

// Play with these...
int   nbrPoints = 88;         // Number of notes - current patch has 16 voice polyphony
float cycleLength = 3 * 60;   // Length of the full cycle in seconds

float durRange = cycleLength*1000/nbrPoints;        // Duration range
float minDur = durRange/2;    // Minimum duration
float baseFreq = 30;          // Minimum frequency

int   kWidth = 500;             // width of graphics
int   kHeight = 500;            // height of graphics

int   cx = kWidth/2,cy = kHeight/2;          // center coordinates
float circleRadius;  
float[] tines;        // keeps track of current position of note, by angle
long[] lastSound;     // keeps track of time last note sounded
boolean isMute = false;

long lastMS;


float gA;     // position of slowest dot, in radians
float gSpeed; // velocity of slowest dot, in radians per millisecond
float maxSpeed = 2*PI/(30*1000); // maximum cycle is 30 seconds
float minSpeed = -maxSpeed;

void setup() {
  size(kWidth,kHeight);
  circleRadius = (min(width,height)/2) * 0.95;
  noStroke();
  smooth();
  colorMode(HSB,1);
  background(0);

  gA = 0;
  gSpeed = 2*PI/(cycleLength*1000);

  // PDlib setup
  pd = new PureDataP5Jack(this, 1, 2, "system", "system");
  pd.openPatch(dataFile("organplayerbells.pd"));
  pd.start();
  pd.sendFloat("amp", 0);

  tines = new float[nbrPoints];
  lastSound = new long[nbrPoints];
  for (int i = 0; i < nbrPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
  }
  lastMS = millis();
}

void draw()
{
  background(0);

  stroke(.2);
  line(cx,cy,width,cy); // delete this line of code to get rid of the graphical line

  float mx = mouseX/(float)width;
  float my = mouseY/(float)height;

  long cMillis = millis();
  long elapsed = cMillis - lastMS;

  gA += gSpeed*elapsed;

  float pi2 = 2*PI;
  noStroke();
  
  float durIncrement = (durRange/nbrPoints);

  for (int i = 0; i < nbrPoints; ++i)
  {
    float r = (i+1)/(float)nbrPoints;

    float a = gA * (i+1);

    float len = circleRadius * (1 + 1.0 /nbrPoints - r);

    if ((int) (a/pi2) != (int) (tines[i]/pi2))
    {
      // Sound Note Here...
      if (!isMute) {
        int ii = (nbrPoints-1)-i;
        // Chromatic Mapping
        // pd.sendList("tinehit", i, baseFreq*(pow(2,i/12.0)),  minDur+durRange - i*durIncrement);
        // Harmonic Mapping
        pd.sendList("tinehit", i, baseFreq+i*baseFreq,  minDur+durRange - i*durIncrement);
      }
      lastSound[i] = millis();
    }

    float x = (cx + cos(a)*len);
    float y = (cy + sin(a)*len);
    float minRad = 20-r*16;
    float radv = max( (minRad+6)-6*(cMillis-lastSound[i])/500.0 , minRad);

    float huev = r;
    float satv = min(.5, (cMillis-lastSound[i])/1000.0);
    float valv = 1;
    
    fill(color(huev,satv,valv));
    ellipse(x,y,radv,radv);

    tines[i] = a;
  }
  lastMS = cMillis;
}


void keyPressed() {
  if (key == ' ') 
  {
    isMute = !isMute;
    println("MUTE " + (isMute? "ON" : "OFF"));
  }
}


