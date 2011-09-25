// Whitney Music Box - a Processing + MIDI implementaton - 10/17/2008 Jim Bumgardner
//
// Inspired by the motion graphics of John Whitney
// Music by Jim Bumgardner
//
// Press SPACE to for allNotesOff (mute)
//
// http://www.coverpop.com/whitney/

import themidibus.*; //Import the library
MidiBus midiOutput; //The first MidiBus

// Modify these to your taste...
int   nbrPoints = 48 ;           // number of notes
// int   lowestNoteNumber = 72-nbrPoints/2;    // lowest MIDI pitch
int   lowestNoteNumber = 67;    // lowest MIDI pitch
boolean reversePitches = false;
float cycleLength = 1 * 60;     // 3 Minute Cycle

int   kWidth = 500;             // width of graphics
int   kHeight = 500;            // height of graphics
int   kMidiChannel = 0;
int   kDefaultVelocity = 64;
int   kNoteDuration = 8000; // 8000
int   cx = kWidth/2,cy = kHeight/2;          // center coordinates
float circleRadius;  
float[] tines;        // keeps track of current position of note, by angle
long[] lastSound;     // keeps track of time last note sounded
boolean[] isOn;
boolean isMute = false;

void setup()
{
  size(kWidth, kHeight);
  circleRadius = (min(width,height)/2) * 0.95;
  noStroke();
  smooth();
  colorMode(HSB, 1);
  background(0);

  tines = new float[nbrPoints];
  lastSound = new long[nbrPoints];
  isOn = new boolean[nbrPoints];
  for (int i = 0; i < nbrPoints; ++i)
  {
    tines[i] = -10;
    lastSound[i] = millis();
    isOn[i] = false;
  }

  MidiBus.list();
  // Currently we assume output #0 is the one we want, use the list to determine
  int midiOutputIndex =0 ;

  String outName = MidiBus.availableOutputs()[midiOutputIndex];
  println("Output = " + outName);
  midiOutput = new MidiBus(this, -1, outName);

  println("\nPress SPACE to MUTE (all notes off)");
}

int pitchAssign(int i)
{
  if (reversePitches)
    return lowestNoteNumber+(nbrPoints-1)-i;
  else
    return lowestNoteNumber+i;
}

int velAssign(int i)
{
    return kDefaultVelocity;
}

void draw()
{
  background(0);

  stroke(.2);
  line(cx,cy,width,cy); // delete this line of code to get of the graphical line

  float mx = mouseX/(float)width;
  float my = mouseY/(float)height;
  float speed = (2*PI*nbrPoints) / cycleLength;

  long cMillis = millis();
  float timer = cMillis*.001*speed;

  float pi2 = 2*PI;
  noStroke();

  for (int i = 0; i < nbrPoints; ++i)
  {
    float r = (i+1)/(float)nbrPoints;

    float a = timer * r;
    float len = circleRadius * (1 + 1.0 /nbrPoints - r);

    if ((int) (a/pi2) != (int) (tines[i]/pi2))
    {
      // Sound Note Here...
      if (!isMute) {
        midiOutput.sendNoteOn(kMidiChannel, pitchAssign(i), velAssign(i));
        isOn[i] = true;
      }
      lastSound[i] = millis();
    }
    else if (isOn[i] && millis() - lastSound[i] > kNoteDuration)
    {
        midiOutput.sendNoteOff(kMidiChannel, pitchAssign(i), 0);
        isOn[i] = false;
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
}

