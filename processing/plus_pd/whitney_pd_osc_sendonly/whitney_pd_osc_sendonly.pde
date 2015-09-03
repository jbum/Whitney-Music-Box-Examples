// Whitney Music Box - Jim Bumgardner
//
// use with WhitneyOSC_rcveonly.pd (which works with organ48_vfad~.pd)
//
// Processing+PD implementation jbum 9/9/2012
//
// Plays whitneymusic box via OSC messages by sending messages to PD (or any other compatible server).
// Similar to whitney_pd_tcp, this enables PD to be used without pdlib, making it easier to debug/visualize patches.
//
// Version 1.0 - modified version of whitney_pd_tcp
//
//
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

// Play with these...
int   nbrPoints = 48;         // Number of notes - current patch has 16 voice polyphony
float cycleLength = .5 * 60;   // Length of the full cycle in seconds

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

  // Pd setup - connect via port 3001
  oscP5 = new OscP5(this,9000);
  myRemoteLocation = new NetAddress("127.0.0.1",8000);
  
  tines = new float[nbrPoints];
  lastSound = new long[nbrPoints];
  for (int i = 0; i < nbrPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
  }
  lastMS = millis();
}

void sendNote(int ctr, float freq, float amp, float dur) {
   OscMessage myMessage = new OscMessage("/note");
   myMessage.add(ctr);
   myMessage.add(freq);
   myMessage.add(amp);
   myMessage.add(dur);
   oscP5.send(myMessage, myRemoteLocation); 
}


void draw()
{
//  if (myClient.available() > 0) { 
//    int dataIn = myClient.read(); 
//  } 

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
        // myClient.write((64-nbrPoints/2+i) + " " + 90 + " " + (minDur+durRange - i*durIncrement) + ";\n");
        // Harmonic Mapping
        sendNote(i,baseFreq+i*baseFreq,.1,(minDur+durRange - i*durIncrement));
        // myClient.write(i + " " + (baseFreq+i*baseFreq) + " " + .1 + " " + (minDur+durRange - i*durIncrement) + ";");
        // pd.sendList("tinehit", i, baseFreq+i*baseFreq,  minDur+durRange - i*durIncrement);
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


