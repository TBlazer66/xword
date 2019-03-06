package trans2;
require Exporter;

#use utils1;

our @ISA    = qw(Exporter);
our @EXPORT = qw(


  make_russian_captions

);


sub make_russian_captions {
  use 5.011;
  use warnings;
  use POSIX qw(strftime);
  use Path::Tiny;
  use Encode;
  use open OUT => ':encoding(UTF-8)', ':std';

  my $rvars = shift;
  my %vars  = %$rvars;

  my $munge = strftime( "%d-%m-%Y-%H-%M-%S\.txt", localtime );
  my $in_path = path( $vars{translations}, $munge )->touchpath;

  #system("pwd >$in_path"); works
  my @matching2;
  opendir( my $hh, $vars{eng_captions} ) or die "death  $!\n";
  while ( defined( $_ = readdir($hh) ) ) {
    if (m/txt$/) {
      push( @matching2, $_ );
    }
  }

  #important to sort
  @matching2 = sort @matching2;
  say "matching are @matching2";
  my $rus_munge = path( $vars{translations}, "trans." . $munge );
  say "rus_munge is $rus_munge";
  my $yandex=' -e yandex ';

  # open file for writing
  my $fh = path($in_path)->openw_utf8;
  foreach (@matching2) {
    my $eng_path = path( $vars{eng_captions}, $_ );
    say $fh "##$_##";
    my $rus_path = path( $vars{rus_captions}, $_ )->touchpath;
    say "rus_path is $rus_path";
    my $content = path($eng_path)->slurp_utf8;
    $content =~ s/^\s+|\s+$//g;
    say $fh "$content";
    system("trans :ru file://$eng_path >$rus_path");

  }

  ## use trans shell
  system("trans :ru file://$in_path >$rus_munge");

  return "nothing yet";
}


1;
