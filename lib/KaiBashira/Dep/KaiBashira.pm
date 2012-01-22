package KaiBashira;
use Data::Dumper;

use KaiBashira::Model;

our $config = {};
our $parent;
our $dbi;

sub init { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  $parent = $_[0];
  &setting;
  $dbi = KaiBashira::Model->connect( &database->{ $parent->mode } );
}

sub dbi { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  $dbi = $_[0] if $_[0];
  $dbi;
}

sub setting { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  unless( $config->{setting} ) {
    if( -f $parent->home->rel_file( 'config/config.conf' ) ){
      $config->{setting} = &_conf_load( $parent->home->rel_file( 'config/config.conf' ) );
    }
  }
  $config->{setting};
}

sub database { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  unless( $config->{database} ) {
    if( -f $parent->home->rel_file( 'config/config.conf' ) ){
      $config->{database} = &_conf_load( $parent->home->rel_file( 'config/database.conf' ) );
    }
  }
  $config->{database};
}

sub _conf_load { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $file ) = @_;
  open my $handle, "<:encoding(UTF-8)", $file
    or die qq/Couldn't open config file "$file": $!/;
  my $content = do { local $/; <$handle> };
  &_parse( $content );
}

sub _parse { shift if $_[0] eq __PACKAGE__; shift if ref( $_[0] ) eq __PACKAGE__;
  my ( $content ) = @_;
  no warnings;
  die qq/Couldn't parse config file "$file": $@/
    unless my $config = eval "sub app { \$parent } $content";
  $config;
}

BEGIN{
  use Mojo::Home;
  my $app_name = $ENV{MOJO_APP} || __PACKAGE__;
  $mojo_home = Mojo::Home->new;
  $mojo_home->detect( $app_name );

  $app_home = $mojo_home->to_string;
  $app_lib = $mojo_home->lib_dir;
}

1;