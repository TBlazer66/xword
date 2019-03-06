package utils2;
require Exporter;

use utf8;
use open qw/:std :utf8/;
use Data::Dumper;

our @ISA    = qw(Exporter);
our @EXPORT = qw( archive1 );

sub archive1 {
  use warnings;
  use 5.011;
  use Path::Tiny;

  my $rvars = shift;
  my %vars  = %$rvars;
  say Dumper $rvars;

  $vars{"grandfather"} = $vars{"init_dir"}->parent();
  my $file1 = "1.manifest";
  my $from = path( $vars{"grandfather"}, $file1 );
  say "from is $from";
  my @files = $from->lines_utf8( { chomp => 1 } );
  say Dumper $rvars;
  say "files are @files";

  my $tempdir = Path::Tiny->tempdir('backup_XXXXXX');
  say "temp dir is $tempdir";
  my $readme = $tempdir->child( 'grandmother', 'README.txt' )->touchpath;
  say "read me is $readme";
  my $grand_dir = $readme->parent;

  foreach my $item (@files) {
    say "item is <<$item>>";
    next if ( $item eq "" );
    my $abs = path( $vars{"grandfather"},  $item );
    say "abs is <$abs>";
    if ( -d $abs ) {
      say "$abs is a directory";

      #create copy to directory
      my $mother_dir = path( $grand_dir, $item )->mkpath;
      say "mother dir is $mother_dir";
      $from = path( $vars{"grandfather"}, $item, $file1 );
      say "from is $from";
      my @files2 = $from->lines_utf8( { chomp => 1 } );
      say "files2 are @files2";
      foreach my $item2 (@files2) {
        say "item2 is <<<$item2>>>";
        my $father_path = path( $vars{"grandfather"}, $item, $item2);
        say "father path is $father_path";
        if ( $father_path->is_file ) {
          say "$father_path is a  file";
          next if ( $item2 eq "" );

          #syntax is from -> to
          my $return = path($abs)->copy( $mother_dir, $item2 );
          if ( $item2 =~ m/\.(pl|sh)$/ ) {
            $return->chmod(0755);
          }
        }
      }

    }

    if ( -f $abs ) {
      say "$item is a plain file";

      #syntax is from -> to
      my $return = path($abs)->copy( $grand_dir, $item );
      if ( $item =~ m/\.(pl|sh)$/ ) {
        $return->chmod(0755);
      }
      say "return is $return";
    }

  }

  my $b = $tempdir;
  return $b;
}

sub archive2 {
  use warnings;
  use 5.011;
  use Path::Tiny;


use Data::Dumper;

my $path1 = Path::Tiny->cwd;
say "path1 is $path1";
my $title = $path1->basename;
say "base is $title";

# script parameters
my %vars = (
  init_dir    => $path1,
  title       => $title,
);

$vars{"grandfather"} = $vars{"init_dir"}->parent();
print Dumper(\%vars);

print "vars-grandfather : ", $vars{"grandfather"}->basename, "\n";
print "vars-grandfather : ", $vars{"grandfather"};


}

1;

