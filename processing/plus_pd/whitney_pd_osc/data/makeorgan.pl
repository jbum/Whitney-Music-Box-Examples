#!/usr/local/bin/perl

# script to make polyphonic organ patch - Jim Bumgardner
#
# V1.1 9-12-2011  Improved voice message passing.

$nbrVoices = shift;
$voiceName = shift;

$nbrVoices = 24 if !$nbrVoices;
$voiceName = 'voice~' if !$voiceName;
$voiceWidth = 20;

$routeList = join ' ', (0..$nbrVoices-1);

$lm = 48;                                       # left margin
$cw = $nbrVoices * $voiceWidth + $lm*2;         # canvas width
$ch = 460;                                      # canvas height
$cx = int($cw/2);                               # canvas horizontal center
$cy = int($ch/2);                               # vertical center (unused)

$inletIdx = 1;                                  # module indices
$unpackIdx = 2;
$modIdx = 3;
$packIdx = 4;
$mixIdx = 5;
$routeIdx = 6;
$outletIdx = 7;
$firstVoiceIdx = 8;

$mixDown = 1.0/$nbrVoices;                      # mix down ratio

print <<EOT;
#N canvas 100 100 $cw $ch 10;
#X text 20 8 Created with makeorgan.pl;
#X obj $cx 40 inlet;
#X obj $cx 80 unpack f f f;
#X obj $cx 120 mod $nbrVoices;
#X obj $cx 160 pack f f f;
#X obj $cx 360 *~ $mixDown;
#X obj $cx 200 route $routeList;
#X obj $cx 420 outlet~;
EOT
foreach my $i (0..$nbrVoices-1) {
  printf "#X obj %d %d %s;\n", $i*$voiceWidth+$lm,260+sin($i*3.1415/$nbrVoices)*30,$voiceName;
}
print <<EOT;
#X connect $inletIdx 0 $unpackIdx 0;
#X connect $unpackIdx 0 $modIdx 0;
#X connect $unpackIdx 1 $packIdx 1;
#X connect $unpackIdx 2 $packIdx 2;
#X connect $modIdx 0 $packIdx 0;
#X connect $packIdx 0 $routeIdx 0;
#X connect $mixIdx 0 $outletIdx 0;
EOT
foreach my $i (0..$nbrVoices-1) {
  printf "#X connect %d %d %d %d;\n", $routeIdx, $i, $firstVoiceIdx+$i, 0;
}  
foreach my $i (0..$nbrVoices-1) {
  printf "#X connect %d %d %d %d;\n", $firstVoiceIdx+$i, 0, $mixIdx, 0;
}  
