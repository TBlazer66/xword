#!/usr/bin/perl -w
use 5.011;
use Path::Tiny;
use utf8;
use Encode;
use open OUT => ':encoding(UTF-8)';
use Net::SFTP::Foreign;
use Data::Dumper;

# these modules available on github (ask if interested)
use lib "template_stuff";
use html8;    # uses crossword module in turn

### initializations that must precede main data structure
## turning things to Path::Tiny
# decode paths

my $abs   = path(__FILE__)->absolute;
my $path1 = Path::Tiny->cwd;
my $title = $path1->basename;
$abs   = decode( 'UTF-8', $abs );
$path1 = decode( 'UTF-8', $path1 );
$title = decode( 'UTF-8', $title );
say "title is $title";
say "path1 is $path1";
say "abs is $abs";
my $ts = "template_stuff";
my $path2 = path( $path1, $ts );

# crossword params
my %vars = (

  cw          => path( $path2, 'crosswords' ),
  изображение => path( $path2, 'crosswords', 'изображение', "1.атаман.jpg" ),
  подписи     => path( $path2, 'crosswords', 'подписи', "1.кгосс.txt" ),

);

my $rvars           = \%vars;
my $ref_html_values = init_values( $title, $path2, $abs );
my %html_vars       = %$ref_html_values;

# append returned hash from init
@vars{ keys %html_vars } = values %html_vars;
my $new_page = create_page($rvars);
say "$new_page";

say "ultimate disposition of main hash-------";

#say Dumper $rvars;
__END__ 

