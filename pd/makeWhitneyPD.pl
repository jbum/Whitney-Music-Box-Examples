#!/usr/local/bin/perl

# script to make polyphonic whitney music box patch - Jim Bumgardner
#
# V1.0 10-12-2012 Based on makeorgan.pl

$syntax = <<EOT;

makeWhitneyPD.pl [options]

-o outfile           name of output file (default=o.mid)
-tines n             nbr tines
-len l               length of piece (in minutes, default=3)
-vw w                width of voice (in pixels)
-chromatic           use chromatic pitches (instead of harmonics, the default)
-basefreq            lowest frequency
-rev                 reverse pitches
EOT

$ofile = 'untitled_whitney.pd';
$nbrTines = 48;
$periodSeconds = 180;
$voiceName = 'voice~';
$voiceWidth = 30;
$chromaticMode = 0;
$revMode = 0;
$baseFreq = 0; # automatically compute basefreq if not supplied
$baseNote = 0;
$myArgs = join ' ', @ARGV;

while ($_ = shift)
{
  if (/^-o$/)
  {
    $ofile = shift;
  }
  elsif (/^-tines/)
  {
    $nbrTines = shift;
  }
  elsif (/^-len/)
  {
    $periodSeconds = (shift)*60;
  }
  elsif (/^-voice/)
  {
    $voiceName = shift;
  }
  elsif (/^-vw/)
  {
    $voiceWidth = shift;
  }
  elsif (/^-chromatic/)
  {
    $chromaticMode = 1;
  }
  elsif (/^-basefreq/)
  {
    $baseFreq = shift;
  }
  elsif (/^-rev/)
  {
    $revMode = 1;
  }
  else {
    print $syntax;
    exit;
  }
}

if ($baseFreq == 0) {
  if ($chromaticMode) {
    if ($baseNote == 0) {
      $baseNote = 64 - $nbrTines/2;
      $baseNote = 0 if $baseNote < 0;
    }
    # $f = 440*2**(($n-57)/12);
  } else {
    $baseFreq = 20;
  }
}

sub idxToFreq($)
{
  my ($idx) = @_; # 0 to N-1

  if ($revMode) {
    $idx = ($nbrTines-1) - $idx;
  }
  if ($chromaticMode) {
    my $n = $baseNote + $idx;
    return 440*2**(($n-57)/12);
  } else {
    return ($idx+1)*$baseFreq;
  }
}

$lm = 48;                                       # left margin
$cw = $nbrTines * $voiceWidth + $lm*2;          # canvas width
$ch = 460;                                      # canvas height
$cx = int($cw/2);                               # canvas horizontal center
$cy = int($ch/2);                               # vertical center (unused)
$cx2 = $cx + 20;
$cx1 = $cx - 20;

$toggleIdx = 1;                                  # module indices
$multIdx = 2;
$revIdx = 3;
$add1Idx = 4;
$add2Idx = 5;
$dacIdx = 6;
$firstVoiceIdx = 7;

$mixDown = 1.0/$nbrTines;                      # mix down ratio

open (OFILE, ">$ofile") or die "Can't open $ofile for output\n";

print OFILE <<EOT;
#N canvas 100 100 $cw $ch 10;
#X text 20 8 Created with makeWhitneyPD.pl $myArgs;
#X obj $cx 40 tgl 15 0 empty empty empty 17 7 0 10 -262144 -1 -1 0 1;
#X obj $cx 280 *~ $mixDown;
#X obj $cx2 340 rev3~ 100 92 3000 40;
#X obj $cx1 380 +~;
#X obj $cx2 380 +~;
#X obj $cx 420 dac~;
EOT
foreach my $i (0..$nbrTines-1) {
  my $id = $i+1;
  my $noteMetro = $periodSeconds*1000/$id;
  my $yOffset = ($i & 1)? 10 : -10;
  printf OFILE "#X obj %d %d metro %f;\n", $i*$voiceWidth+$lm,$yOffset+80+sin($i*3.1415/$nbrTines)*30,$noteMetro;
  printf OFILE "#X obj %d %d bng 15 250 50 0 empty empty empty 17 7 0 10 -262144 -1 -1;\n", $i*$voiceWidth+$lm,120+sin($i*3.1415/$nbrTines)*30;
  printf OFILE "#X msg %d %d %d %d;\n", $i*$voiceWidth+$lm,$yOffset+160+sin($i*3.1415/$nbrTines)*30,idxToFreq($i),$noteMetro/2;
  printf OFILE "#X obj %d %d %s;\n", $i*$voiceWidth+$lm,$yOffset+200+sin($i*3.1415/$nbrTines)*30,$voiceName;
}
print OFILE <<EOT;
#X connect $multIdx 0 $add1Idx 0;
#X connect $multIdx 0 $add2Idx 0;
#X connect $multIdx 0 $revIdx 0;
#X connect $multIdx 0 $revIdx 1;
#X connect $revIdx 0 $add1Idx 1;
#X connect $revIdx 1 $add2Idx 1;
#X connect $add1Idx 0 $dacIdx 0;
#X connect $add2Idx 0 $dacIdx 1;
EOT
foreach my $i (0..$nbrTines-1) {
  printf OFILE "#X connect %d %d %d %d;\n", $toggleIdx, 0, $firstVoiceIdx+$i*4, 0;
  printf OFILE "#X connect %d %d %d %d;\n", $firstVoiceIdx+$i*4, 0, $firstVoiceIdx+$i*4+1, 0;
  printf OFILE "#X connect %d %d %d %d;\n", $firstVoiceIdx+$i*4+1, 0, $firstVoiceIdx+$i*4+2, 0;
  printf OFILE "#X connect %d %d %d %d;\n", $firstVoiceIdx+$i*4+2, 0, $firstVoiceIdx+$i*4+3, 0;
  printf OFILE "#X connect %d %d %d %d;\n", $firstVoiceIdx+$i*4+3, 0, $multIdx, 0;
}  
close OFILE;
print "Output $nbrTines voices to $ofile\n";
