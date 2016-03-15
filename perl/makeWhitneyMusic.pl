#!/usr/bin/perl

#
# makeWhitneyMusic - Jim Bumgardner
#

# use Data::Dumper;  # for debugging
use MIDI;

$syntax = <<EOT;

makeWhitneyMidi [options - please include at least one]

-o outfile           name of output file (default=o.mid)
-tines n             nbr tines
-len l               length of piece (in minutes, default=3)
-amp a               max-amplitude (default=300)
-rev                 reverse pitches
-rise                rising pitches (k*n % tines)
-primes              prime numbers
-nonprimes           non primes
-scale scale         choice of chromatic blues blues2 major minor minorh (default=chromatic)
EOT

$ofile = 'o.mid';
$tempo = 60;           # beats per minute
$ticksPerBeat = 960;   # ticks per beat

$mEventList = [];  # midi event lists for each voice
push @{$mEventList},['raw_meta_event', 0, 33, "\x00"];  # select piano patch (0)
push @{$mEventList},['control_change', 0, 0, 7, 64];    # default volume = 64

$nbrTines = 88;
$lenPiece = 3*60;
$maxAmp = 300;
$rev = 0;
$xor = 0;
$rise = 0;
$usePrimes = 0;
$useNonPrimes = 0;
$useScale = 0;

%scales = (blues => [0,3,4,5,6,7,10],
           blues2 => [0,2,3,4,5,6,7,10],
           major => [0,2,4,5,7,9,11],
           lydian => [0,2,4,6,7,9,11],
           minor => [0,2,3,5,7,8,10],
           minorh => [0,2,3,5,7,8,11]);


@primes = (   2,   3,   5,   7,  11,  13,  17,  19,  23,  29,
           31,  37,  41,  43,  47,  53,  59,  61,  67,  71,
           73,  79,  83,  89,  97, 101, 103, 107, 109, 113, 
          127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
          179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 
          233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
          283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
          353, 359, 367, 373, 379, 383);

@nonprimes = (   1,   4,   6,   8,   9,  10,  12,  14,  15,  16,
           18,  20,  21,  22,  24,  25,  26,  27,  28,  30,
           32,  33,  34,  35,  36,  38,  39,  40,  42,  44, 
           45,  46,  48,  49,  50,  51,  52,  54,  55,  56,
           57,  58,  60,  62,  63,  64,  65,  66,  68,  69, 
           70,  72,  74,  75,  76,  77,  78,  80,  81,  82,
           84,  85,  86,  87,  88,  90,  91,  92,  93,  94,
           95,  96,  98,  99, 100, 102);

if (scalar(@ARGV) == 0)
{
  print $syntax;
  exit;
}

while ($_ = shift)
{
  if (/^-tines/)
  {
    $nbrTines = shift;
  }
  elsif (/^-len/)
  {
    $lenPiece = (shift) * 60;
  }
  elsif (/^-amp/)
  {
    $maxAmp = shift;
  }
  elsif (/^-rev/)
  {
    $rev = 1;
  }
  elsif (/^-xor/)
  {
    $xor = 1;
  }
  elsif (/^-rise/)
  {
    $rise = 1;
  }
  elsif (/^-primes?$/)
  {
    $usePrimes = 1;
  }
  elsif (/^-scale$/)
  {
    $useScale = lc(shift);
    undef $useScale if $useScale eq 'chromatic';
    die ("Unknown scale: $useScale\n") if !(defined $scales{$useScale});
  }
  elsif (/^-nonprimes?$/)
  {
    $useNonPrimes = 1;
  }
  elsif (/^-o$/)
  {
    $ofile = shift;
  }
  else {
    print "Unknown: $_" . "\n\n";
    print $syntax;
    exit;
  }
}


my $fPitch = int(64-$nbrTines/2);
my $lenScale = 12;
if ($useScale) {
    $lenScale = scalar(@{$scales{$useScale}});
    $fPitch = int(64-($nbrTines*12/$lenScale)/2);
}

sub kToPitch($$)  # n has no effect if rise is not in effect
{
  my ($k,$n) = @_;

  if ($useScale) {
    $k = $scales{$useScale}->[$k % $lenScale] + 12*int($k/$lenScale);
  }
  else {
    $k = $k ^ 0x02A if ($xor);
  }
  if ($rev)
  {
     return ($fPitch+$nbrTines) - $k;
  }
  if ($rise) {
    return $fPitch + ($k + $k*$n)%$nbrTines;
  }
  else {
    return $fPitch + $k;
  }
}

sub kToTime($$)
{
  my ($k, $i) = @_;
  return ($i * $lenPiece/kToCount($k))*$ticksPerBeat;
}

sub kToDuration($$)
{
  my ($k, $i) = @_;
  my $d = $lenPiece/kToCount($k);

  $d *= .5;
  # $d = 10 if ($d > 10);

  return $d * $ticksPerBeat;
}

sub kToVelocity($$)
{
  my ($k, $i) = @_;
  return 64;
}

sub kToCount($)
{
  my ($k) = @_;
  return $primes[$k] if $usePrimes;
  return $nonprimes[$k] if $useNonPrimes;
  return ($k+1);
}


@myEList = ();

foreach $k (0..$nbrTines-1)
{
  foreach $n (0..kToCount($k)-1)
  {
    push @myEList, {   t=>kToTime($k,$n),
                       pitch=>kToPitch($k,$n),
                       vel=>kToVelocity($k,$n)};
    push @myEList, {   t=>kToTime($k,$n)+kToDuration($k,$n),
                       pitch=>kToPitch($k,$n),
                       vel=>0};
  }
}

# print Dumper(\@myEList);


$lTicks = 0;
foreach $e (sort {$a->{t} <=> $b->{t}} @myEList)
{
  $offset = int($e->{t} - $lTicks);
  push @{$mEventList}, ['note_on', $offset, 0, int($e->{pitch}), int($e->{vel})];
  $lTicks += $offset;
}

# print Dumper($mEventList);

my $op = MIDI::Opus->new({
'format' => 1,
'ticks'  => $ticksPerBeat,  # ticks per quarternote
'tracks' => [   # 2 tracks...

# Track #0 ...
MIDI::Track->new({
  'type' => 'MTrk',
  'events' => [  # 3 events.
    ['time_signature', 0, 4, 2, 24, 8],
    ['key_signature', 0, 0, 0],
    ['set_tempo', 0, int(1000000*60/$tempo)],  # microseconds per quarter note
  ]
}),

# Track #1 ...
MIDI::Track->new({
  'type' => 'MTrk',
  'events' => $mEventList
  }),

]
});
$op->write_to_file("$ofile");  
