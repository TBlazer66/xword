package html_utils1;
require Exporter;
use utf8;

our @ISA    = qw(Exporter);
our @EXPORT = qw( invert_aoa 
  highest_number   
  );

sub invert_aoa {
  use strict;
  use warnings;
  use 5.011;

  my $a   = shift;
  my @AoA = @$a;
  my $k   = $#AoA;

  #say "k is $k";
  my @BoB;
  for my $i ( 0 .. $#AoA ) {
    my $aref = $AoA[$i];
    my $x    = $#{$aref};

    #say "x is $x";
    for my $j ( 0 .. $#{$aref} ) {
      $BoB[$j][$i] = $AoA[$i][$j];
    }
  }
  my $b = \@BoB;
  return $b;
}

sub print_aoa_utf8 {
  use warnings;
  use 5.011;
  use utf8;    # a la François
  use open OUT => ':encoding(utf8)';
  use open ':std';

  my $a   = shift;
  my @AoA = @$a;

  for my $i ( 0 .. $#AoA ) {
    my $aref = $AoA[$i];
    for my $j ( 0 .. $#{$aref} ) {
      print "elt $i $j is $AoA[$i][$j]\n";
    }
  }
  return $a;
}

sub print_aoa {
  use warnings;
  use 5.011;

  my $a   = shift;
  my @AoA = @$a;
  for my $i ( 0 .. $#AoA ) {
    my $aref = $AoA[$i];
    for my $j ( 0 .. $#{$aref} ) {
      print "elt $i $j is $AoA[$i][$j]\n";
    }
  }
  return $a;
}

sub highest_number {
  use 5.011;

  my ( $aref, $filetype, $word ) = @_;
  my $number;
  my @matching;
  my $ext = "." . $filetype;
  push( @matching, 0 );    #min returned value
  for my $file ( @{$aref} ) {

    #print "file is $file\n";
    if ( $file =~ /^$word(\d+)$ext$/ ) {
      print "matching is $file\n";
      push( @matching, $1 );
    }
  }
  @matching = sort { $a <=> $b } @matching;
  my $winner = pop @matching;
  return $winner;
}

sub rangeparse {
  use Carp;
  local $_ = shift;
  my @o;    # [ row1,col1, row2,col2 ] (-1 = last row/col)
  if ( @o = /\AR([0-9]+|n)C([0-9]+|n):R([0-9]+|n)C([0-9]+|n)\z/ ) { }
  elsif (/\AR([0-9]+|n):R([0-9]+|n)\z/) { @o = ( $1, 1, $2, -1 ) }
  elsif (/\AC([0-9]+|n):C([0-9]+|n)\z/) { @o = ( 1, $1, -1, $2 ) }
  elsif (/\AR([0-9]+|n)C([0-9]+|n)\z/) { @o = ( $1, $2, $1, $2 ) }
  elsif (/\AR([0-9]+|n)\z/) { @o = ( $1, 1, $1, -1 ) }
  elsif (/\AC([0-9]+|n)\z/) { @o = ( 1, $1, -1, $1 ) }
  else                      { croak "failed to parse '$_'" }
  $_ eq 'n' and $_ = -1 for @o;
  return \@o;
}

sub getsubset {
  use Carp;
  my ( $data, $range ) = @_;
  my $cols = @{ $$data[0] };
  @$_ == $cols or croak "data not rectangular" for @$data;
  $range = rangeparse($range) unless ref $range eq 'ARRAY';
  @$range == 4 or croak "bad size of range";
  my @max = ( 0 + @$data, $cols ) x 2;
  for my $i ( 0 .. 3 ) {
    $$range[$i] = $max[$i] if $$range[$i] < 0;
    croak "index $i out of range"
      if $$range[$i] < 1 || $$range[$i] > $max[$i];
  }
  croak "bad rows $$range[0]-$$range[2]" if $$range[0] > $$range[2];
  croak "bad cols $$range[1]-$$range[3]" if $$range[1] > $$range[3];
  my @cis = $$range[1] - 1 .. $$range[3] - 1;
  return [
    map {
      sub { \@_ }
        ->( @{ $$data[$_] }[@cis] )
    } $$range[0] - 1 .. $$range[2] - 1
  ];
}

sub make_russian_crossword {
  use 5.011;
  use warnings;
  use POSIX qw(strftime);
  use Path::Tiny;
  use Encode;
  use open OUT => ':encoding(UTF-8)', ':std';
  use Data::Dumper;

  my $rvars = shift;
  my %vars  = %$rvars;

  my $munge = strftime( "p%d-%m-%Y-%H-%M-%S\.txt", localtime );
  my $in_path = path( $vars{rus_captions}, $munge )->touchpath;

  say "in make russian xword------";

  ##Let mother know that you created a file, *verb* a reference:
  $vars{log_file} = $in_path;
  my @images;
  for ( $vars{изображение}->children ) {
    say "default is $_";
    my $push_path = path( $_ );
    push( @images, $push_path );

  }
  @images = sort @images;
  my $pic = shift(@images);
  say "pic is $pic";

  my @captions;
  for ( $vars{подписи}->children ) {
    say "default is $_";
    my $push_path = path( $_ );
    push( @captions, $push_path );

  }
  @captions = sort @captions;

  my $caps = shift(@captions);
  say "caps is $caps";

  return $rvars;
}

sub get_тайный {

  use 5.011;
  use warnings;
  use utf8;
  use Net::SFTP::Foreign;
  use Config::Tiny;
  use Path::Tiny;
  use Data::Dumper;
  use open OUT => ':encoding(utf8)';
  use open ':std';

  my $rvars = shift;
  my %vars  = %$rvars;

  my $ini_path = $vars{ini_path};

  #say "ini path is $ini_path";

  my $sub_hash = "my_sftp";
  my $Config   = Config::Tiny->new;
  $Config = Config::Tiny->read( $ini_path, 'utf8' );

  #say Dumper $Config;

  # -> is optional between brackets
  my $domain   = $Config->{$sub_hash}{'domain'};
  my $username = $Config->{$sub_hash}{'username'};

  #my $password = $Config->{$sub_hash}{'password'};
  my $port     = $Config->{$sub_hash}{'port'};
  my $key_path = $Config->{$sub_hash}{'key_path'};

  #dial up the server

  #say "values are $domain $username $port";
  my $sftp = Net::SFTP::Foreign->new(
    $domain,

    #more     => '-v',
    user => $username,
    port => $port,

    #password => $password,
    key_path => $key_path,
  ) or die "Can't connect: $!\n";
  return $sftp;
}

1;

