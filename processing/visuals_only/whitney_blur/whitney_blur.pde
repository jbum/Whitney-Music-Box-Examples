// WhitneyScope - Jim Bumgardner
//
// From ideas by John Whitney -- see his book "Digital Harmony"
// This was uses an added BLUR effect.

int   nbrPoints = 200;
int   cx,cy;
float crad;
float cycleLength;
float startTime;
int   counter =0 ;
float   speed = 1;
boolean classicStyle = true; // when this is false, there is additional complexity

void setup()
{
  size(300, 300);
  cx = width/2;
  cy = height/2;
  crad = (min(width,height)/2) * 0.95;
  noStroke();
  smooth();
  colorMode(HSB, 1);

  background(0);
  
  if (classicStyle)
    cycleLength = 15*60;
  else
    cycleLength = 2000*15*60;
  speed = (2*PI*nbrPoints) / cycleLength;
  startTime = -random(cycleLength);
  // speed = 10;
}

void mousePressed()
{
  classicStyle = !classicStyle;
  if (classicStyle)
    cycleLength = 15*60;
  else
    cycleLength = 2000*15*60;
  speed = (2*PI*nbrPoints) / cycleLength;
}



void draw()
{
 startTime = -(cycleLength*mouseY) / (float) height;
 float timer = (millis()*.001 - startTime)*speed;

  // background(0);
  filter(BLUR, 1);
  counter = int(timer / cycleLength);

  for (int i = 0; i < nbrPoints; ++i)
  {
  
    float r = i/(float)nbrPoints;
    if ((counter & 1) == 0)
      r = 1-r;

    float a = timer * r; // pow(i * .001,2);
    // float a = timer*2*PI/(cycleLength/i); same thing
    float len = i*crad/(float)nbrPoints;
    float rad = max(2,len*.05);
    if (!classicStyle)
       len *= sin(a*timer);  // big fun!
    int x = (int) (cx + cos(a)*len);
    int y = (int) (cy + sin(a)*len);
    float hue = r + timer * .01;
    hue -= int(hue);
    fill(hue,.5,1-r/2);
    ellipse(x,y,rad,rad);
  }
}
