package Akoya::Themes;
use Mojo::Base 'Mojolicious::Plugin';

our %installed_themes;
our %themes;
our $theme_path;

sub register {
  my ( $self , $app ) = @_;

  $theme_path = $app->home->rel_file('public/themes');

  my $theme = __PACKAGE__->new;
  $app->helper( theme => sub { $theme } );

  $app->helper(
    current_theme => sub {
      my ( $c ) = @_;
      unless( $c->stash( 'current_theme' ) ){
        $c->stash( current_theme => Akoya::Themes->theme( $c->setting->ui_theme ) );
      }
      $c->stash( 'current_theme' );
    }
  );

  $app->helper(
    path_to_stylesheet => sub {
      my ( $c, $source ) = @_;
      $c->stylesheet_path( $source );
    }
  );

  $app->helper(
    heads_for_theme => sub {
      my ( $c ) = @_;
      if( $c->current_theme && $c->current_theme->javascripts->is_include('theme') ){
        $c->javascript_include_tag( $c->current_theme->javascript_path('theme') );
      }
    }
  );
}

sub themes {
  my ( $self ) = @_;
  unless( %installed_themes ){
    %installed_themes = $self->scan_themes;
  }
  %installed_themes;
}

sub rescan {
  my ( $self ) = @_;
  %installed_themes = $self->scan_themes;
}

sub theme {
  my ( $class , $id , $options ) = @_;

  return undef unless $id;

  my $self;
  
  if( ref( $class ) eq __PACKAGE__ ){
    $self = $class;
  }
  else {
    $self = bless {}, $class;
  }

  my $found = $themes{ $id };
  if( ! $found && $options->{rescan} ne 0 ){
    $self->rescan;
    $found = $self->theme( $id, { rescan => 0 } );
  }
  $found;
}

sub scan_themes {
  my ( $self ) = @_;
  my %dirs = ();
  opendir my $dh, $theme_path or die "$!:$theme_path";
  while (my $dir = readdir $dh) {
    my $f = "$theme_path/$dir";
    if( -d $f && -f $f . "/stylesheets/application.css" ) {
      $dirs{ $dir } = Akoya::Themes::Theme->new( $dir );
    }
  }
  closedir $dh;
  %dirs;
}

1;