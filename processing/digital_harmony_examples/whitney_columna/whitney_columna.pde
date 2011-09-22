// Transcription of program columnA
// originally prepared by Paul Rother for John Whitney for his book "Digital Harmony"
// ported by Jim Bumgardner

static float deg=PI/180;

float stepstart = 0,
      stepend = 1/60.0,
      xleft = 38, 
      ybottom = 18;

int  npoints = 60, 
     nframes = 30,
     ilength = 170;

void setup()
{
  size(280,192);
  frameRate(10);
  noStroke();
  fill(255);
}

void draw()
{
  background(0); // erase
  float ftime = millis()*.001;
  float step = stepstart + (ftime * (stepend - stepstart));

  for (int point = 0; point < npoints; ++point)
  {
    float x = xleft + ilength * point/(float)npoints;
    float y = ilength * point * step;
    y = ybottom + ( Math.round(y) % ilength );
    ellipse((int) x, (int) y, 4, 4);
    // set((int) x, (int) y, color(255));
  }
}

