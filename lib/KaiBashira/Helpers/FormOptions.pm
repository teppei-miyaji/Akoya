package KaiBashira::Helpers::FormOptions;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    options_for_select => sub {
      my ( $c , $selected , @container ) = @_;

      return @container unless @container;
      @container = $c->h_to_a( $container[0] ) if ref( $container[0] ) eq 'HASH';
      my $disabled;
      ( $selected, $disabled ) = $c->extract_selected_and_disabled( $selected );

      my @options = ();
      foreach my $element( @container ){
        my ( $text , $value ) = $c->option_text_and_value( $element );

        my @result;
        push @result , $text , $value;

        if( $c->is_option_value_selected( $value, $selected ) ){
          push @result , selected => 'selected';
        }
        if( $disabled && $c->is_option_value_selected( $value, $disabled ) ){
          push @result , disabled => 'disabled';
        }

        push @options , [@result];
      }
      my @options_for_select = @options;

      \@options_for_select;
    }
  );

  #private
  $app->helper(
    option_text_and_value => sub {
      my ( $c , $option ) = @_;
      # Options are (text, value) pairs or strings used for both.
      if( ref( $option ) eq 'ARRAY' ){
        my $first = shift( @{ $option } );
        my $last = pop( @{ $option } );
        return ( $first, $last );
      }else{
        return ( $option, $option );
      }
    }
  );

  $app->helper(
    is_option_value_selected => sub {
      my ( $c , $value, $selected) = @_;
      given( ref( $selected ) ) {
        when( 'HASH' ){
          return defined( $selected->{ $value } );
        }
        when( 'ARRAY' ){
          return $c->a_is_include( $value , @{ $selected } );
        }
        default {
          return $value eq $selected;
        }
      }
    }
  );

  $app->helper(
    extract_selected_and_disabled => sub {
      my ( $c, $selected ) = @_;
      if( ref( $selected ) eq 'HASH' ){
        return ( $selected->{selected}, $selected->{disabled} );
      }
      else {
        return ( $selected, undef );
      }
    }
  );

}

1;