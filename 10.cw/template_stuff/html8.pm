package html8;
require Exporter;

use html_utils1;

our @ISA    = qw(Exporter);
our @EXPORT = qw(
  get_content
  write_body
  get_html_filename
  create_html_file
  write_script
  write_bottom
  write_header
  write_footer
  write_module
  get_tiny
  create_page
  put_page
  init_values
);

sub init_values {

  use strict;
  use warnings;
  use 5.011;
  use Path::Tiny;
  use utf8;
  use Data::Dumper;

  # initializations that must precede main data structure

  my $images   = "images";
  my $captions = "hints";

  my ( $title, $path2, $abs ) = (@_);

  # page params
  my %vars2 = (
    title        => $title,
    headline     => undef,
    place        => 'Vancouver',
    base_url     => 'http://www.merrillpjensen.com',
    css_file     => "${title}1.css",
    header       => path( $path2, "hc_input2.txt" ),
    footer       => path( $path2, "footer_center3.txt" ),
    body         => path( $path2, "rebus5.tmpl" ),
    print_script => "1",
    code_tmpl    => path( $path2, "code2.tmpl" ),
    oitop        => path( $path2, "oitop.txt" ),
    oibottom     => path( $path2, "oibottom.txt" ),
    to_images    => path( $path2, $images ),
    eng_captions => path( $path2, $captions ),
    translations => path( $path2, 'translations' ),
    bottom       => path( $path2, "bottom1.txt" ),
    book         => 'Crosswords: ',
    chapter      => 'Кроссворды',
    make_puzzle  => 1,
    print_module => 1,
    script_file  => $abs,
    module_tmpl  => path( $path2, "code3.tmpl" ),
    server_dir   => 'perlmonks',
    image_dir    => 'pmimage',
    ts           => 'template_system',
    css_path     => $path2,
    ini_path => path('/home/bob/Documents/html_template_data/3.ценности.ini'),

  );

  my $rvars2 = \%vars2;

  #say "hash returned from init";
  #say Dumper $rvars2;
  return $rvars2;

}

sub create_page {

  use 5.011;
  use Net::SFTP::Foreign;
  use POSIX;
  use Encode;
  use open OUT => ':utf8';
  use crossword3;

  #create html page
  my $rvars = shift;
  my %vars  = %$rvars;

  my $sftp = get_tiny();
  say "object created, back with caller";
  my $html_file = get_html_filename( $sftp, $rvars );
  $vars{html_file} = $html_file;
  print "Make unique captions(y/n)?: ";
  my $prompt1 = <STDIN>;
  chomp $prompt1;
  if ( $prompt1 eq ( "y" | "Y" ) ) {
    ## delete existing files

    foreach my $child ( $vars{eng_captions}->children ) {

      my $success = $child->remove;
      say "success deleting was $success";
    }

  }
  my $fh         = create_html_file($html_file);
  my $remote_dir = $html_file;
  $remote_dir =~ s/\.html$//;
  say "remote_dir is $remote_dir";
  $vars{remote_dir} = $remote_dir;

  # create header
  my $rhdr = write_header($rvars);
  print $fh $$rhdr;

  if ( $vars{"make_puzzle"} ) {
    my $return = make_russian_crossword($rvars);
    say "return is $return";
  }
  $vars{refc} = get_content($rvars);
  $rvars = \%vars;    ## will same trick work?
  ## will this survive after ref dies?

  my $body = write_body( $rvars, $vars{refc} );
  print $fh $$body;
  say "------------body";
  say $$body;

  #say Dumper $rvars;

  my $rftr = write_footer($rvars);
  print $fh $$rftr;
  if ( $vars{"print_script"} ) {
    my $script = write_script($rvars);
    print $fh $$script;
  }
  if ( $vars{"print_module"} ) {
    my $module = write_module($rvars);
    print $fh $$module;
  }
  my $rhbt = write_bottom($rvars);
  print $fh $$rhbt;
  close $fh;

  print "Put file to server(y/n)?: ";
  my $prompt2 = <STDIN>;
  chomp $prompt2;
  if ( $prompt2 eq ( "y" | "Y" ) ) {
    put_page( $sftp, $rvars );
  }
  return $html_file;
}

sub put_page {

  use 5.011;
  use Net::SFTP::Foreign;
  use Encode;
  use open OUT => ':encoding(UTF-8)';
  use Data::Dumper;

  my ( $sftp, $rvars ) = (@_);
  my %vars = %$rvars;

  #load html file to server
  my $server_dir = $vars{"server_dir"};
  say "server dir is $server_dir";
  $sftp->mkdir("/$server_dir")   or warn "mkdir1 failed $!\n";
  $sftp->setcwd("/$server_dir")  or warn "setcwd1 failed $!\n";
  $sftp->put( $vars{html_file} ) or die "html put failed $!\n";

  #load css file to server
  $sftp->setcwd("/css") or warn "setcwd2 failed $@\n";
  my $path3 = path( $vars{css_path}, $vars{"css_file"} );
  say "path3 is $path3";
  my $remote_css = $vars{"css_file"};
  $sftp->put( "$path3", $remote_css ) or warn "css put failed $@\n";

  # upload images
  my $image_dir = $vars{"image_dir"};
  $sftp->mkdir("/$image_dir")        or warn "mkdir2 failed $!\n";
  $sftp->setcwd("/$image_dir")       or warn "setcwd2 failed $!\n";
  $sftp->mkdir( $vars{remote_dir} )  or warn "mkdir3 failed $!\n";
  $sftp->setcwd( $vars{remote_dir} ) or warn "setcwd3 failed $!\n";
  print $sftp->cwd(), "\n";

  my $ref_content = $vars{refc};
  my @AoA         = @$ref_content;
  say "content----------";

  #print Dumper $ref_content;

  for my $i ( 0 .. $#AoA ) {

    #say "first value is $vars{to_images} ";
    #say "array part is $AoA[$i][0]";
    if ( !defined $AoA[$i][0] ) {
      say "undefined!...initializing:";
      $AoA[$i][0] = 'quux';
    }
    my $a = path( $vars{to_images}, $AoA[$i][0] );
    say "a is $a";
    my $b = $a->basename;
    say "b is $b";
    $sftp->put( $a, $b ) or warn "AoA put failed $@\n";
  }
  undef $sftp;

  return "nothing";

}

sub get_content {
  use 5.010;

  my $rvars   = shift;
  my %vars    = %$rvars;
  my $refimg  = get_images($rvars);
  my $refcaps = get_utf8_text( $rvars, $vars{"eng_captions"} );

  my $aoa = [ $refimg, $refcaps ];
  my $b = invert_aoa($aoa);
  return ($b);
}

sub get_images {
  use 5.011;
  use Data::Dumper;

  my $rvars = shift;
  my %vars  = %$rvars;

  #print Dumper $rvars;

  my @filetypes = qw/jpg gif png jpeg GIF/;
  my $pattern = join '|', map "($_)", @filetypes;
  my @matching2;

  #say "value is $vars{to_images}";
  opendir my $hh, $vars{to_images} or warn "warn  $!\n";
  while ( defined( $_ = readdir($hh) ) ) {
    if ( $_ =~ /($pattern)$/i ) {
      push( @matching2, $_ );
    }
  }

  #important to sort
  @matching2 = sort @matching2;
  return \@matching2;
}

sub get_utf8_text {
  use 5.010;
  use HTML::FromText;
  use Path::Tiny;
  use utf8;
  use open OUT => ':utf8';

### Passing in
  #reference to main data structure and directory for captions
  my ( $rvars, $dir ) = (@_);
  my %vars = %$rvars;

  say "dir is $dir";
  opendir my $eh, $dir or warn "can't open dir for utf8 captions  $!\n";
  while ( defined( $_ = readdir($eh) ) ) {
    next if m/~$/;
    next if -d;
    if (m/txt$/) {
      my $file = path( $dir, $_ );

      my $guts = $file->slurp_utf8;
      my $temp = text2html(
        $guts,
        lines => 1,
        paras => 1,
      );

      # surround by divs

      my $oitop    = $vars{"oitop"};
      my $oben     = $oitop->slurp_utf8;
      my $oibottom = $vars{"oibottom"};
      my $unten    = $oibottom->slurp_utf8;
      my $text     = $oben . $temp . $unten;

      say "text is $text";
      $content{$_} = $text;
    }
  }
  closedir $eh;

  #important to sort
  my @return;
  foreach my $key ( sort keys %content ) {

    #print $content{$key} . "\n";
    push @return, $content{$key};
  }
  return \@return;
}

sub write_body {
  use warnings;
  use 5.011;
  use Text::Template;
  use Encode;

  my $rvars    = shift;
  my $reftoAoA = shift;
  my %vars     = %$rvars;
  my @AoA      = @$reftoAoA;
  my $body     = $vars{"body"};
  my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE   => $body
  ) or die "Couldn't construct template: $!";
  my $return;

  for my $i ( 0 .. $#AoA ) {
    $vars{"file"}    = $AoA[$i][0];
    $vars{"english"} = $AoA[$i][1];

    my $result = $template->fill_in( HASH => \%vars );
    $return = $return . $result;
  }
  return \$return;
}

sub write_bottom {
  use strict;
  use Text::Template;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $footer  = $vars{"bottom"};
  my $template = Text::Template->new( SOURCE => $footer )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => $rvars );
  return \$result;
}

sub get_html_filename {
  use Net::SFTP::Foreign;
  use warnings;
  use 5.011;
  binmode STDOUT, ":utf8";

  my ( $sftp, $rvars ) = (@_);
  my %vars = %$rvars;

  # get working directory
  my $word = $vars{"title"};
  say "word is $word";

  # get files from /pages
  my $dir2 = $vars{"server_dir"};
  say "dir2 is $dir2";
  my $ls = $sftp->ls( "/$dir2", wanted => qr/$word/ )
    or warn "unable to retrieve " . $sftp->error;
  print "$_->{filename}\n" for (@$ls);

  my @remote_files = map { $_->{filename} } @$ls;
  say "files are @remote_files";
  my $rref     = \@remote_files;
  my $filetype = "html";
  my $old_num  = highest_number( $rref, $filetype, $word );
  print "old num is $old_num\n";
  my $new_num   = $old_num + 1;
  my $html_file = $word . $new_num . '.' . $filetype;
  return $html_file;
}

sub create_html_file {
  my $html_file = shift;
  open( my $fh, ">>:encoding(UTF-8)", $html_file )
    or die("Can't open $html_file for writing: $!");
  return $fh;
}

sub write_header {
  use Text::Template;
  use 5.011;
  use warnings;
  my $rvars = shift;
  my %vars  = %$rvars;

  # get time
  my $now_string = localtime;
  $vars{"date"} = $now_string;

  my $headline = join( ' ', $vars{"book"}, $vars{"chapter"} );
  $vars{"headline"} = $headline;
  my $header   = $vars{"header"};
  my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE   => $header,
  ) or die "Couldn't construct template: $!";

  my $result = $template->fill_in( HASH => \%vars );
  say "result is $result";
  return \$result;
}

sub write_footer {
  use Text::Template;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $footer  = $vars{"footer"};
  my $template = Text::Template->new( SOURCE => $footer )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => $rvars );
  return \$result;
}

sub write_script {
  use Text::Template;
  use 5.010;
  use utf8;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $tmpl    = $vars{"code_tmpl"};
  say "tmpl is $tmpl";
  my $file = $vars{"script_file"};
  my $text = do {
    open my $fh, '<:raw:encoding(UTF-8)', $file
      or die "$file: $!";
    local $/;
    <$fh>;
  };
  my %data = ( 'script', $text );
  my $template = Text::Template->new( SOURCE => $tmpl )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => \%data );
  return \$result;
}

sub write_module {
  use 5.010;
  use File::Spec;
  use Text::Template;
  use utf8;

  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $tmpl    = $vars{"module_tmpl"};
  say "tmpl is $tmpl";
  my $file = File::Spec->rel2abs(__FILE__);
  my $text = do {
    open my $fh, '<:raw:encoding(UTF-8)', $file
      or die "$file: $!";
    local $/;
    <$fh>;
  };
  my %data = ( 'module', $text );
  my $template = Text::Template->new( SOURCE => $tmpl )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => \%data );
  return \$result;
}

sub get_tiny {

  use 5.011;
  use warnings;
  use Net::SFTP::Foreign;
  use Config::Tiny;
  use Data::Dumper;

  my $ini_path = qw( /home/bob/Documents/html_template_data/3.values.ini );
  say "ini path is $ini_path";

  my $sub_hash = "my_sftp";
  my $Config   = Config::Tiny->new;
  $Config = Config::Tiny->read( $ini_path, 'utf8' );
  say Dumper $Config;

  # -> is optional between brackets
  my $domain   = $Config->{$sub_hash}{'domain'};
  my $username = $Config->{$sub_hash}{'username'};
  my $password = $Config->{$sub_hash}{'password'};
  my $port     = $Config->{$sub_hash}{'port'};

  #dial up the server

  say "values are $domain $username $password $port";
  my $sftp = Net::SFTP::Foreign->new(
    $domain,

    #more     => '-v',
    user     => $username,
    port     => $port,
    password => $password
  ) or die "Can't connect: $!\n";
  return $sftp;
}

1;
