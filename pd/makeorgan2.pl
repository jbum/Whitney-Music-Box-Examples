#!/usr/local/bin/perl

# script to make polyphonic organ patch - Jim Bumgardner
#
# V1.1 9-12-2011  Improved voice message passing.
# usage: perl makeorgan2.pl 60 | pdsend 3002 localhost
#

$nbrVoices = shift;
$voiceName = shift;

$nbrVoices = 24 if !$nbrVoices;
$voiceName = 'voice_fav~' if !$voiceName;
$voiceWidth = 20;

$routeList = join ' ', (0..$nbrVoices-1);

$lm = 48;                                       # left margin
$cw = $nbrVoices * $voiceWidth + $lm*2;         # canvas width
$ch = 460;                                      # canvas height
$cx = int($cw/2);                               # canvas horizontal center
$cy = int($ch/2);                               # vertical center (unused)
$cx1 = $cx-50;
$cx2 = $cx+50;

$inletIdx = 1;                                  # module indices
$routeIdx = 2;
$mixIdx = 3;
$throw1Idx = 4;
$throw2Idx = 5;
$firstVoiceIdx = 6;

$mixDown = 1.0/$nbrVoices;                      # mix down ratio

print <<EOT;
clear;
text 20 8 Created with makeorgan2.pl $nbrVoices | pdsend 3002 localhost;
obj $cx 40 r notebus_vfad;
obj $cx 200 route $routeList;
obj $cx 360 *~ $mixDown;
obj $cx1 420 throw~ aout;
obj $cx2 420 throw~ bout;
EOT
foreach my $i (0..$nbrVoices-1) {
  printf "obj %d %d %s;\n", $i*$voiceWidth+$lm,260+sin($i*3.1415/$nbrVoices)*30,$voiceName;
}
print <<EOT;
connect $inletIdx 0 $routeIdx 0;
connect $mixIdx 0 $throw1Idx 0;
connect $mixIdx 0 $throw2Idx 0;
EOT
foreach my $i (0..$nbrVoices-1) {
  printf "connect %d %d %d %d;\n", $routeIdx, $i, $firstVoiceIdx+$i, 0;
}  
foreach my $i (0..$nbrVoices-1) {
  printf "connect %d %d %d %d;\n", $firstVoiceIdx+$i, 0, $mixIdx, 0;
}  
