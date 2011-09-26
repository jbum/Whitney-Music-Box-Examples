// Whitney Music Box - Jim Bumgardner
//
// Processing+PD implementation jbum 9/9/2012
//
// Version 1.3 9-25-2011 OSC Support, reworked how motion is tracked.
// Version 1.2 9-12-2011 Improved voice design and message passing.
// Version 1.1 9-10-2011 Simplified Organ implementation.  Voices can be increased using makeorgan.pl
//
//
// Many thanks to Peter Kirn for introducing me to pdlib.


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

long lastMS;


float gA;     // position of slowest dot, in radians
float gSpeed; // velocity of slowest dot, in radians per millisecond
float maxSpeed = 2*PI/((.5*60)*1000);
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

 
  // OSC setup
  oscP5 = new OscP5(this,8000);
  myRemoteLocation = new NetAddress("192.168.2.3",9000);

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
  
  // Produce correct slider values...
  sendFader(1, (gSpeed-minSpeed)/(maxSpeed-minSpeed));
  sendFader(2, sqrt((nbrPoints-8.0)/(maxPoints-8.0)));
  sendFader(3, sqrt((baseFreq-20)/(440*4)));

  tines = new float[maxPoints];
  lastSound = new long[maxPoints];
  for (int i = 0; i < maxPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
  }
  lastMS = millis();

}

// Not yet working on monome emulation.
public void sendMlr(int x,int y, int v)
{
  OscMessage myMessage = new OscMessage("/mlr/press");
  myMessage.add(x);
  myMessage.add(y);
  myMessage.add(v);
  oscP5.send(myMessage, myRemoteLocation); 
}

public void sendFader(int fidx, float v)
{
  /* TouchOsc */
  OscMessage myMessage = new OscMessage("/1/fader" + fidx);
  myMessage.add(v);
  oscP5.send(myMessage, myRemoteLocation); 

  /* Monome */
/*  myMessage = new OscMessage("/slider" + fidx);
  myMessage.add(v);
  oscP5.send(myMessage, myRemoteLocation); 
*/
}

public void test(int a, int b) {
  println("### PLUG event method. received a message /test : " + a + ", " + b);
}

public void fader1(float a) {
  println("### fader1 (speed): " + a);

  gSpeed = map(a, 0, 1, minSpeed, maxSpeed);
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
        sendMlr(i % 8, i/8, 1);
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
  lastMS = cMillis;
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


