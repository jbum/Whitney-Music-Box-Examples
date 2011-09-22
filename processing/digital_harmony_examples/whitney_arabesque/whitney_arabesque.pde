// Transcription of program arabesque
// originally prepared by Paul Rother for John Whitney for the book "Digital Harmony"
// ported to the Processing language by Jim Bumgardner

static float deg=PI/180;

float stepstart = 0,
      stepend = 1/60.0,
      xleft = 38, 
      ybottom = 18,
      
      radius = 85,
      xcenter,
      ycenter;

int  npoints = 360, 
     nframes = 32,
     frame = 0,
     ilength = 170;

void setup()
{
  size(640,480);
  xleft = width*.1;
  radius = height*.88/2;
  xcenter = width/2;
  ycenter = height/2;
  frameRate(24);
  noStroke();
  fill(255);
}

void draw()
{
  background(0); // erase

  float ftime = millis()*.0001;
  float step = stepstart + (ftime * (stepend - stepstart));

  for (int i = 0; i < npoints; ++i)
  {
    float ratio = i/(float)npoints;
    float r = 3*radius;
    float a = -90 + 360 * ratio;
    float x = cos(a*deg) * ratio + i*step*r;
    int ix = (int) (xcenter - (r/2) + int(x+r/2)%Math.round(r));
    int iy = int( ycenter + sin(a*deg) * radius );
    ellipse(ix, iy, 4,4);
  }
}

