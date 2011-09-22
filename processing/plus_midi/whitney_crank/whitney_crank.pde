// Whitney Music Box - a Processing + MIDI implementaton - 10/17/2008 Jim Bumgardner
//
// Todo - fix for negative time.
//
// See what's going on with visual feedback.
// Fix line to look better (see RadialSweep.pde)
// Add visual crank?


import rwmidi.*;

MidiOutput midiOutput;

// Modify these to your taste...
int   kMaxNbrPoints = 128;
int   nbrPoints = 20;           // number of notes
int   lowestNoteNumber = 69;    // 69 = A 440
boolean reversePitches = false;
String[] titles = {"Whitney Music Box","Var. 17","Hand-cranked"};
int kVariationLength = 60*1000;
int   kMidiChannel = 0; // HARPSICHORD IS GOOD
int   kDefaultVelocity = 90;


float cycleLength = 3 * 60;     // 3 Minute Cycle
final int kDefWidth = screen.width;
final int kDefHeight = screen.height;

int   kWidth = kDefWidth;             // width of graphics
int   kHeight = kDefHeight;            // height of graphics
int   kNoteDuration = 8000; // 8000
int   cx = kWidth/2,cy = kHeight/2;          // center coordinates
float circleRadius;  
float[] tines;        // keeps track of current position of note, by angle
long[] lastSound;     // keeps track of time last note sounded
boolean[] isOn;
boolean isMute = false;
float angD = 0;

PFont  titleFont;
long  startOfVariation;

PImage  bgImage;

int[] diatonic = {0,2,4,5,7,9,11};
int[] blues = {0,3,4,5,6,7,10};
int[] blues2 = {0,2,3,4,5,6,7,10};
int[] minor = {0,2,3,5,7,8,10};
int[] minorh = {0,2,3,5,7,8,11};

int[] pscale = blues;
int lenScale = pscale.length;



void setup()
{
  size(kDefWidth, kDefHeight);
  circleRadius = (min(width,height)/2) * 0.95;
  noStroke();
  smooth();
  colorMode(HSB, 1);
  background(0);

  tines = new float[kMaxNbrPoints];
  lastSound = new long[kMaxNbrPoints];
  isOn = new boolean[kMaxNbrPoints];
  for (int i = 0; i < kMaxNbrPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
    isOn[i] = false;
  }

  // Show available MIDI output devices here
  MidiOutputDevice devices[] = RWMidi.getOutputDevices();
  for (int i = 0; i < devices.length; i++) {
    println(i + ": " + devices[i].getName());
  }
  // Currently we assume the first device (#0) is the one we want
  midiOutput = RWMidi.getOutputDevices()[0].createOutput();
  println("\nPress SPACE to MUTE (all notes off)");
  titleFont = loadFont("FranklinGothic-Book-22.vlw");
  textFont(titleFont, 22);
  startOfVariation = millis();

  bgImage = loadImage("radial_axis.png");
  frameRate(24); // Helps keep CPU usage down..
  resetBox();
}

void resetBox()
{
  startOfVariation = millis();
  reversePitches = !reversePitches;
  pscale = null;
  
  switch (int(random(3))) {
  case 0:  nbrPoints = 32;  break;
  case 1:  nbrPoints = 48;  break;
  case 2:  nbrPoints = 60;  break;
  }
  lowestNoteNumber = 64-nbrPoints/2;
  String scaleStr = "";
  if (nbrPoints < 60 && int(random(3)) > 0) {
      reversePitches = false;
      switch (int(random(6))) {
      case 0:  pscale = diatonic;  scaleStr = ", Diatonic";  break;
      case 1:  pscale = diatonic;  scaleStr = ", Diatonic";  break;
      case 2:  pscale = blues;     scaleStr = ", Blues 1";    break;
      case 3:  pscale = blues2;    scaleStr = ", Blues 2";   break;
      case 4:  pscale = minor;    scaleStr = ", Minor";   break;
      case 5:  pscale = minorh;    scaleStr = ", Minor #7";   break;
      }
      lenScale = pscale.length;
      lowestNoteNumber = int(72 - (nbrPoints*12/lenScale)/2);
  }
  titles[2] = "Hand-cranked, " + nbrPoints + " tines" + scaleStr;
  kMidiChannel = (kMidiChannel + 1) % 5;
}

// int [] pscale = null;
// int lenScale = 0;

int pitchAssign(int i)
{
  if (pscale != null)
  {
      i = (pscale[i % lenScale] + 12*int(i/lenScale));
  }    
  if (reversePitches)
    return lowestNoteNumber+(nbrPoints-1)-i;
  else
    return lowestNoteNumber+i;
}

int velAssign(int i)
{
    return kDefaultVelocity;
}

long cMillis = 0;

void draw()
{
  // long cMillis = millis();
  long eMillis = millis();

  if (eMillis - startOfVariation > kVariationLength) {
    resetBox();
  }

  background(0);
  image(bgImage, width/2, height/2);

  if (eMillis - startOfVariation < 15000) {
    float elapsed = (eMillis - startOfVariation)/1000.0;
    float clr = elapsed < 5? elapsed/5 : elapsed > 10? 1-(elapsed-10)/5 : 1;
    fill(clr);
    stroke(clr);
    int xo = (width-height)/2 + 30;
    int yo = 30+22;
    for (int i = 0; i < titles.length; ++i)
      text(titles[i],xo,yo+32*i);
    noFill();
  }


  // stroke(.2);
  // line(cx,cy,width,cy); // delete this line of code to get of the graphical line

  float mx = mouseX/(float)width;
  float my = mouseY/(float)height;
  float speed = (2*PI*nbrPoints) / cycleLength;

  
  

  if (abs(angD) > 0.01) {
    cMillis += (angD*100);
    // crankMC._rotation += angD;
    // crankMC.knob._rotation = -crankMC._rotation;
    angD *= .92;
  }
  float timer = cMillis*.001*speed;



  float pi2 = 2*PI;
  noStroke();

  for (int i = 0; i < nbrPoints; ++i)
  {
    float r = (i+1)/(float)nbrPoints;

    float a = timer * r;
    float len = circleRadius * (1 + 1.0 /nbrPoints - r);

    if (floor(a/pi2) != floor(tines[i]/pi2))
    {
      // Sound Note Here...
      if (!isMute) {
        midiOutput.sendNoteOn(kMidiChannel, pitchAssign(i), velAssign(i));
        isOn[i] = true;
      }
      lastSound[i] = eMillis;
    }
    else if (isOn[i] && eMillis - lastSound[i] > kNoteDuration)
    {
        midiOutput.sendNoteOff(kMidiChannel, pitchAssign(i), 0);
        isOn[i] = false;
    }

    // swap sin & cos here if you want the notes to sound on the top or bottom, instead of left or right
    // use -cos or -sin to flip the bar from right to left, or bottom to top
    
    float x = (cx + cos(a)*len);
    float y = (cy + sin(a)*len);
    float minRad = 20-r*16;
    float radv = max( (minRad+6)-6*(eMillis-lastSound[i])/500.0 , minRad);

    float huev = r;
    float satv = min(.5, (eMillis-lastSound[i])/1000.0);
    float valv = 1;
    
    fill(color(huev,satv,valv));
    ellipse(x,y,radv,radv);

    tines[i] = a;
  }
  timer -= speed;

}

void allNotesOff()
{
  for (int i = 0; i < 128; ++i)
    midiOutput.sendNoteOff(kMidiChannel, i, 0);
}

void keyPressed() {
  if (key == ' ') 
  {
    isMute = !isMute;
    if (isMute) {
      allNotesOff();
    }
    println("MUTE " + (isMute? "ON" : "OFF"));
  }
  else if (key == 'r') {
    resetBox();
  }
  else if (keyCode == LEFT || keyCode == UP)
    angD -= .25;
  else if (keyCode == RIGHT || keyCode == DOWN)
    angD += .25;
}

