#!/usr/bin/perl -w

######
## USER: start here.
## The values you will need to populate to create a proper ini file are here. 
## Change the ones you need to. You shouldn't have to change any of the 
## lexical perl. The most these example data will be is irrelevant.
######
use 5.011;
use Data::Dumper;
use Path::Tiny;
use Config::Tiny;

use constant {
  ENCODING => 'utf8'
};

my %config = (
  my_sftp => {
    domain   => '202.123.43.17',
    username => 'netcool',
    password => 'Hello@123',

  },

);
1;
my $ini_file = "5.example.ini";
my $ref_config = \%config;
my $ini_path = path( "/home/bob/Documents/html_template_data", $ini_file );
## USER      make path here^^^^^appropriate for your machine
my $ini = bless $ref_config, 'Config::Tiny';
say Dumper $ref_config;
# this will clobber any previous file of same name
$ini->write( $ini_path, ENCODING );
say 'created ', $ini_path;

__END__ 
