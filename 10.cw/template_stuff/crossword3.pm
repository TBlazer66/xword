package crossword3;
require Exporter;
use utf8;

our @ISA    = qw(Exporter);
our @EXPORT = qw(  getsubset make_rectangular
  rangeparse print_aoa_utf8 print_aoa
  make_russian_crossword get_тайный);

sub make_rectangular {
  my ( $lines, $maxrows, $maxlength ) = @_;
  my @out;
  my $rowcount = 1;
  for my $line (@$lines) {
    my $trimmed = substr $line, 0, $maxlength;

    #push @out, sprintf "%-*s", $maxlength, $trimmed;
    push @out, [ split //, sprintf "%-*s", $maxlength, $trimmed ];
    last if ++$rowcount > $maxrows;
  }
  return \@out;
}

sub print_aoa {
  use warnings;
  use 5.011;

  my $a     = shift;
  my @array = @$a;
  for my $row (@array) {
    print join( "", @{$row} ), "\n";
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
  use open OUT => ':encoding(UTF-8)';
  use Data::Dumper;
  use utf8;
  binmode STDOUT, 'utf8';

  my $rvars = shift;
  my %vars  = %$rvars;

  say "in make russian xword------";

  my $input = $vars{подписи}->slurp_utf8;
  my ( $rows, $columns ) = ( 15, 10 );
  $input =~ s/\t/ /g;
  my @lines = split /\n/, $input;
  my $out = make_rectangular( \@lines, $rows, $columns );
  print_aoa_utf8($out);

  # create filename unique to second
  my $munge = strftime( "p%d-%m-%Y-%H-%M-%S\.txt", localtime );
  my $path_to_output = path( $vars{eng_captions}, $munge );
  my $file_handle = $path_to_output->openw_utf8();
  for my $row (@$out) {
    my $line2 = join( "", @{$row}, "\n", );
    $file_handle->print($line2);
  }
  say "leaving make russian xword------";

  return $out;
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
