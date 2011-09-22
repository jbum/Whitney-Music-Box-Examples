// Transcription of program columnBC
// originally prepared by Paul Rother for John Whitney for the book "Digital Harmony"
// ported to the Processing language by Jim Bumgardner

float stepstart = 0,
      stepend = 1/60.0,
      xleft = 38, 
      ybottom = 18,
      
      radius = 85,
      xcenter = 140,
      ycenter = 96,
      speed = .1;

int  npoints = 360,
     ilength = 170;

void setup()
{
  size(500,500);
  radius = height*.9/2;
  xcenter = width/2;
  ycenter = height/2;
  frameRate(24);
  noStroke();
  fill(255);
}

void draw()
{
  background(0); // erase
  float ftime = millis()*.001*speed;
  float step = stepstart + (ftime * (stepend - stepstart));

  for (int i = 0; i < npoints; ++i)
  {
    float a = 2*PI * step * i;
    float radiusi = radius; // radius*sin(a*ftime); VERY NICE
    float x = xcenter + cos(a) * (i/(float)npoints) * radiusi;
    float y = ycenter + sin(a) * (i/(float)npoints) * radiusi;
    ellipse((int) x, height-(int) y, 4,4);
  }
}

