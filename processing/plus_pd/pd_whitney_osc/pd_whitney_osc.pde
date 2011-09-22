// Whitney Music Box - Jim Bumgardner
//
// Processing+PD implementation jbum 9/9/2012
//
// Version 1.2 9-12-2011 Improved voice design and message passing.
// Version 1.1 9-10-2011 Simplified Organ implementation.  Voices can be increased using makeorgan.pl
//
//
// Many thanks to Peter Kirn!


import oscP5.*;
import netP5.*;
import com.noisepages.nettoyeur.processing.*;

PureDataP5Jack pd;
OscP5 oscP5;
NetAddress myRemoteLocation;

// Play with these...
int  maxPoints = 512;
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

long startMS;


void setup() {
  size(kWidth,kHeight);
  circleRadius = (min(width,height)/2) * 0.95;
  noStroke();
  smooth();
  colorMode(HSB,1);
  background(0);

  // PDlib setup
  pd = new PureDataP5Jack(this, 1, 2, "system", "system");
  pd.openPatch(dataFile("organplayerbells.pd"));
  pd.start();
  pd.sendFloat("amp", 0);
 
  // OSC setup
  oscP5 = new OscP5(this,8000);
  myRemoteLocation = new NetAddress("127.0.0.1",12000);
  oscP5.plug(this,"fader1","/1/fader1","f");
  oscP5.plug(this,"fader2","/1/fader2","f");
  oscP5.plug(this,"fader3","/1/fader3","f");
  oscP5.plug(this,"fader4","/1/fader4","f");
  oscP5.plug(this,"mt1","/1/multitoggle1","f");
  oscP5.plug(this,"oscmsg","/1");
  oscP5.plug(this,"test","/test");

  oscP5.plug(this,"fader1","/slider1","f");
  oscP5.plug(this,"fader2","/slider2","f");
  oscP5.plug(this,"mlr","/mlr/press","iii");


  tines = new float[maxPoints];
  lastSound = new long[maxPoints];
  for (int i = 0; i < maxPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
  }
  startMS = millis();
}

public void test(int a, int b) {
  println("### PLUG event method. received a message /test : " + a + ", " + b);
}

public void fader1(float a) {
  println("### fader1 (speed): " + a);
  long cMillis = millis();
  long elapsed = cMillis - startMS;
  float phase = elapsed*.001/cycleLength;
  float a1 = 1-a;

//  float minSpeed = (2*PI*nbrPoints) / 10;
//  float maxSpeed = (2*PI*nbrPoints) / 10;
//  float speed = minSpeed+a*(maxSpeed-minSpeed);
  cycleLength = 10 + 20*60*a1*a1;
  // float speed = (2*PI*nbrPoints) / cycleLength;
  // cycleLength = 60*60*a1*a1;
  // Insure phase stays the same...
  startMS = round(-((phase*cycleLength)/.001 - cMillis));
}

public void fader2(float a) {
  println("### fader2 (nbr): " + a);
  nbrPoints = round(8 + (maxPoints-8)*a*a);
}

public void fader3(float a) {
  println("### fader3 (pitch): " + a);
  baseFreq = 20 + a*a*440*4;
}

public void fader4(float a) {
  println("### fader4 (phase): " + a);
}


public void mlr(int y, int x, int pressed) {
  println("### PLUG event method. received a message /mlr: " + x + "," + y + " = " + pressed);
}


public void mt1(int a) {
  println("### PLUG event method. received a message /mt1: " + a);
}

public void oscmsg(String a, int b) {
  println("### PLUG event method. received a message /fader: " + a + " ," + b);
}



/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* with theOscMessage.isPlugged() you check if the osc message has already been
   * forwarded to a plugged method. if theOscMessage.isPlugged()==true, it has already 
   * been forwared to another method in your sketch. theOscMessage.isPlugged() can 
   * be used for double posting but is not required.
  */  
  if(theOscMessage.isPlugged()==false) {
  /* print the address pattern and the typetag of the received OscMessage */
    println("### received an osc message: " +   
              theOscMessage.addrPattern() + " :: " + 
              theOscMessage.typetag());
  }
}

void draw()
{
  background(0);

  stroke(.2);
  line(cx,cy,width,cy); // delete this line of code to get rid of the graphical line

  float mx = mouseX/(float)width;
  float my = mouseY/(float)height;
  float speed = (2*PI*nbrPoints) / cycleLength;

  long cMillis = millis();
  long elapsed = cMillis - startMS;
  float timer = elapsed*.001*speed;

  float pi2 = 2*PI;
  noStroke();
  
  float durIncrement = (durRange/nbrPoints);

  for (int i = 0; i < nbrPoints; ++i)
  {
    float r = (i+1)/(float)nbrPoints;

    float a = timer * r;
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

    // swap sin & cos here if you want the notes to sound on the top or bottom, instead of left or right
    // use -cos or -sin to flip the bar from right to left, or bottom to top
    
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
  timer -= speed;

}


void mousePressed() 
{
}


void keyPressed() {
  if (key == ' ') 
  {
    isMute = !isMute;
    println("MUTE " + (isMute? "ON" : "OFF"));
  }
}


