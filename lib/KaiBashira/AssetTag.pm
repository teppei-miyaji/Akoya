package KaiBashira::AssetTag;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Types;

use constant {
  ASSETS_DIR => '/',
  JAVASCRIPTS_DIR => "/javascripts" ,
  STYLESHEETS_DIR => "/stylesheets" ,
  JAVASCRIPT_DEFAULT_SOURCES => ['prototype', 'effects', 'dragdrop', 'controls']
};

our $javascript_expansions = { defaults => JAVASCRIPT_DEFAULT_SOURCES };

sub register {
  my ( $self , $app ) = @_;
  
  $app->helper(
    auto_discovery_link_tag => sub {
      my ( $c , $type, $url_options, $tag_options ) = @_;
      $type ||= 'rss';
      my $types = Mojolicious::Types->new;
      $c->tag(
        "link",
        rel   => $tag_options->{rel} || "alternate",
        type  => $tag_options->{type} || $types->type( $type ),
        title => $tag_options->{title} || uc( $type ),
        href  => ref( $url_options ) eq 'HASH' ? $c->url_for( $url_options ) : $url_options
      )
    }
  );

  $app->helper(
    javascript_path => sub {
      my ( $c , $value ) = @_;
      join( '/' , 'javascripts' , $value );
    }
  );

  $app->helper(
    javascript_include_tag => sub {
      my ( $c , $sources , $options ) = @_;
      my @sources = ();
      if( ref( $sources ) eq 'ARRAY' ){
        @sources = @{ $sources };
      }
      else {
        push @sources , $sources;
      }
      my $concat = delete( $options->{concat} );
      my $cache = $concat || delete( $options->{cache} );
      my $recursive = delete( $options->{recursive} );
      if( $cache || $cache ){
      }
      else {
        my @results = $c->expand_javascript_sources( \@sources , $recursive);
        map { $_ = $c->javascript( join( '/' , JAVASCRIPTS_DIR , $_ . '.js' ) ) } @results;
        @results;
      }
    }
  );

  $app->helper(
    expand_javascript_sources => sub {
      my ( $c, $sources , $recursive ) = @_;
      $recursive ||= 0;
      my @expanded_sources = ();
      if( @{ $sources } ~~ 'all' ){
        my @all_javascript_files = $c->collect_asset_files( JAVASCRIPTS_DIR , ( $recursive ? '**' : undef ), '*.js' );
        $c->a_uniq( $c->a_and( $c->determine_source('defaults', $c->javascript_expansions) , \@all_javascript_files ) , @all_javascript_files);
      }
      else {
        foreach my $source( @{ $sources } ){
          push @expanded_sources , $c->a_flatten( $c->determine_source( $source , $javascript_expansions ) );
        }
        push @expanded_sources , "application" if $c->a_is_include( 'defaults' , $sources ) && -f $c->app->home->rel_file( join( q|/| , 'public' , JAVASCRIPTS_DIR , "application.js" ) );
        @expanded_sources;
      }
    }
  );

  $app->helper(
    determine_source => sub {
      my ( $c , $source, $collection) = @_;
      given( ref( $collection ) ){
        when( 'HASH' ){
          $collection->{ $source };
        }
        default {
          $source;
        }
      }
    }
  );

  $app->helper(
    stylesheet_path => sub {
      my ( $c , $value ) = @_;
      join( '/' , 'stylesheets' , $value );
    }
  );

  $app->helper(
    image_path => sub {
      my ( $c , $value ) = @_;
      join( '/' , 'images' , $value );
    }
  );
}

1;