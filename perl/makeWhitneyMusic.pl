#!/usr/bin/perl

#
# makeWhitneyMusic.pl - Jim Bumgardner
#
# This Perl script will produce standard MIDI files containing Whitney Music Box sequences.
#
# NOTE: Most of the variations on the Whitney Music Box were not
# made using MIDI. Some of them, such as the ones based on harmonics
# or on microtones, cannot be made using a MIDI instrument because of
# the precise tunings involved. Instead, I generated the audio directly
# using my software synthesizer "Syd".  PD (Puredata) is also a good choice.
#
# I did use MIDI for some of the later variations which use Piano sounds 
# (particularly #12 and #13.  For #11, which uses a different piano sound,
# I used a more elegant Nyquist script.
#
# This is the script I used for #12.
#
# - Jim Bumgardner

# use Data::Dumper;  # for debugging
use MIDI;

$syntax = <<EOT;

makeWhitneyMidi [options]

-o outfile           name of output file (default=o.mid)
-tines n             nbr tines
-len l               length of piece (in minutes, default=3)
-amp a               max-amplitude (default=300)
-rev                 reverse pitches
-rise                rising pitches (k*n % tines)
-primes              prime numbers
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
$primes = 0;

@ptab = (   2,   3,   5,   7,  11,  13,  17,  19,  23,  29,
           31,  37,  41,  43,  47,  53,  59,  61,  67,  71,
           73,  79,  83,  89,  97, 101, 103, 107, 109, 113, 
          127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
          179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 
          233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
          283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
          353, 359, 367, 373, 379, 383);

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
    $primes = 1;
  }
  elsif (/^-o$/)
  {
    $ofile = shift;
  }
  else {
    print $syntax;
    exit;
  }
}

sub kToPitch($$)
{
  my ($k,$n) = @_;
  
  my $fPitch = int(64-$nbrTines/2);
  $fPitch = 21 if $fPitch < 21;

  $k = $k ^ 0x02A if ($xor);
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
  return $ptab[$k] if $primes;
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
