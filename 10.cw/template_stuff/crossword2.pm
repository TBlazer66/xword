package crossword2;
require Exporter;
use utf8;

our @ISA    = qw(Exporter);
our @EXPORT = qw(  getsubset
  rangeparse print_aoa_utf8
  make_russian_crossword get_тайный);

sub print_aoa {
  use warnings;
  use 5.011;

  my $a     = shift;
  my @array = @$a;
  for my $row (@array) {
    print join( "  ", @{$row} ), "\n";
  }
  return $a;
}

sub print_aoa_utf8 {
  use warnings;
  use 5.011;
  use utf8;   
  use open OUT => ':encoding(utf8)';
  
  my $a     = shift;
  my @array = @$a;
  for my $row (@array) {
    print join( "", @{$row} ), "\n";
  }
  return $a;
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
  use utf8;

  my $rvars = shift;
  my %vars  = %$rvars;

  say "in make russian xword------";

  my $munge = strftime( "p%d-%m-%Y-%H-%M-%S\.txt", localtime );
  my $in_path = path( $vars{translations}, $munge )->touchpath;

  # Let mother know that you created a logfile:
  $vars{log_file} = $in_path;

  ## input use Path::Tiny methods
  my @lines = $vars{подписи}->lines_utf8;
  my $width = 10;
  my $ref_lines = \@lines;

  ####  what lies between these matching hash marks is shit
  #print_aoa_utf8($ref_lines);
  say Dumper $ref_lines;
  print_aoa $ref_lines;
  say "rectangularization------";
  my @new_array;
  # truncate if necessary
  for (@lines){
  say "default is $_";
  $_ = substr( $_, 0, $width );
  my @vector = $_;
  say "vector is @vector";
  #push @new_array, @vector;
  my $scalar = scalar @vector;
  say "scalar is $scalar";
  say "default2 is $_";
}
  #my $ref_new_array = \@new_array;
  say "lines are";
  say "@lines";
  #print_aoa_utf8($ref_lines);
  #$vars{data} = $ref_new_array;
  
  ####  ^^^ none of this works

  ## try rangeparse test 

#use Carp;
#use Data::Alias 'alias';

# from haukex pm nodeid = 1224734

use Test::More tests => 1;

{
  say "inside first anonymous block";
  my $subset = getsubset( $ref_lines, "R1C1:R6C1" );
  print_aoa $subset;
  is_deeply $subset, [ л о к л ё п];
  print_aoa $subset;

  $subset->[0][0] = "д";
  print_aoa $subset;
  say "exiting first anonymous block";
}

say "----------";


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

