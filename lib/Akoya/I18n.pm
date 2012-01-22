package Akoya::I18N;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

use Data::Dumper;

use I18N::LangTags;
use I18N::LangTags::Detect;
use Date::Manip::Date;
use YAML::Syck;

sub register {
  my ($self, $app, $conf) = @_;
  $conf ||= {};

  my $valid_languages;

  # Initialize
  my $namespace = $conf->{namespace} || ((ref $app) . "::I18N");

  my $locales_dir = $app->home->rel_dir("/config/locales");
  opendir my $dh, $locales_dir or die "$!:$locales_dir";
  while (my $dir = readdir $dh) {
    next unless $dir =~ m|\.yml$|;
    my $fullpath = "$locales_dir/$dir";
    next unless -f $fullpath;

    my $locales_def = LoadFile( $fullpath );
    my ( $lang , $defs ) = each( %{ $locales_def } );
    
    push @{ $valid_languages } , { $lang => $defs->{general_lang_name} };

    my $evalize_defs = $app->dumper( $defs );
    $lang = $app->underscore( $lang ) if $lang =~ m|\-|;
    eval "package ${namespace}::${lang}; use Mojo::Base '$namespace'; our %Lexicon = %{ ${evalize_defs} }; 1;";
    die qq/Couldn't initialize I18N class "${namespace}::${lang}" file is $dir: $@/ if $@;
  }
  closedir $dh;

  my $default   = $conf->{default}   || 'en';
  eval "package $namespace; use base 'Locale::Maketext'; 1;";
  eval "require ${namespace}::${default};";
  unless (eval "\%${namespace}::${default}::Lexicon") {
    eval "package ${namespace}::$default; use base '$namespace';"
      . 'our %Lexicon = (_AUTO => 1); 1;';
    die qq/Couldn't initialize I18N class "$namespace": $@/ if $@;
  }

  # Add hook
  $app->hook(
    before_dispatch => sub {
      my $self = shift;

      # Header detection
      my @languages = I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
          $self->req->headers->accept_language
        )
      );

      # Handler
      $self->stash->{i18n} =
        Akoya::I18n::_Handler->new(namespace => $namespace);

      # Languages
      $self->stash->{i18n}->languages(@languages, $default);
    }
  );

  my $date_manip = Date::Manip::Date->new;
  $app->helper( date_manip => sub { $date_manip; } );

  # Add "languages" helper
  $app->helper(languages => sub { shift->stash->{i18n}->languages(@_) });

  # Add "l" helper
  $app->helper(l => sub { b( shift->stash->{i18n}->localize(@_) )->decode('UTF8')->to_string } );

  $app->helper( l_or_humanize => sub {
    my ( $c , $s , $options ) = @_;
    my $k = $options->{prefix} . $s;
    my $r = $c->l( $k );
    $r ne $k ? $r : $c->humanize( $s );
  } );

  $app->helper( format_date => sub {
    my ( $c , $date ) = @_;
    $c->date_manip->parse($date);
    if( $c->setting->date_format ){
      $c->date_manip->printf( $c->setting->date_format );
    }
    else{
      $c->date_manip->printf( $c->l( 'date' , formats => 'default' ) );
    }
  } );

  $app->helper( format_time => sub {
    my ( $c , $date ) = @_;
    $c->date_manip->parse($date);
    if( $c->setting->time_format ){
      $c->date_manip->printf( $c->setting->time_format );
    }
    else{
      $c->date_manip->printf( $c->l( 'time' , formats => 'default' ) );
    }
  } );

  $app->helper( valid_languages =>sub { $valid_languages } );

  $app->helper( current_language => sub {
      $_[0]->languages;
  } );
}

package Akoya::I18n::_Handler;
use Mojo::Base -base;
use Data::Dumper;

# "Robot 1-X, save my friends! And Zoidberg!"
sub languages {
  my ($self, @languages) = @_;
  return $self->{language} unless @languages;

  # Handle
  my $namespace = $self->{namespace};
  if (my $handle = $namespace->get_handle(@languages)) {
    $handle->fail_with(sub { $_[1] });
    $self->{handle}   = $handle;
    $self->{language} = $handle->language_tag;
  }

  return $self;
}

sub localize {
  my ($self, $key ) = ( shift , shift );
  my %options = @_;
  my $use_key;
  $use_key = delete ( $options{formats} ) if $options{formats};
  my $distance_in_words;
  $distance_in_words = delete ( $options{distance_in_words} ) if $options{distance_in_words};

  my $handle = $self->{handle};
  return $key unless $handle;

  my $output = "";

  my $result = $handle->maketext($key, @_);
  if( ref( $result ) eq q|HASH| ){
    if( $key eq 'datetime' ){
      if( ref( $result->{distance_in_words}->{$distance_in_words} ) eq 'HASH' ){
        $output = $result->{distance_in_words}->{$distance_in_words}->{other};
      }
      else {
        $output = $result->{distance_in_words}->{$distance_in_words};
      }
    }
    elsif( $use_key ){
      $output = $result->{formats}->{$use_key};
    }
    else{
      my $format = ( keys %{ $result } )[0];
      $output = $result->{$format};
    }
  }
  else{
    $output = $result;
  }

  if( %options ){
    my %options = @_;
    while( my ( $key , $value ) = each( %options ) ){
      $output =~ s/\%\{${key}\}/${value}/g;
    }
  }

  $output;
}

1;
