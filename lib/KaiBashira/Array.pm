package KaiBashira::Array;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    a_and => sub {
      my ( $c , $array1 , $array2 ) = @_;
      my @result = ();
      foreach my $elem1 ( @{ $array1 } ){
        foreach my $elem2 ( @{ $array2 } ){
          if( $elem1 ~~ $elem2 ){
            push @result , $elem1;
            last;
          }
        }
      }
      @result;
    }
  );

  $app->helper(
    a_uniq => sub {
      my ( $c , $array1 , $array2 ) = @_;
      my %result;
      foreach my $elem ( @{ $array1 } , @{ $array2 } ){
        $result{ $elem } = 1;
      }
      keys %result;
    }
  );

  $app->helper(
    a_is_include => sub {
      my ( $c , $value , @array ) = @_;
      if( ref( $array[0] ) eq 'ARRAY' ){
        return $value ~~ @{ $array[0] } ? 1 : 0;
      }
      else {
        return $value ~~ @array ? 1 : 0;
      }
    }
  );

  $app->helper(
    a_flatten => sub {
      my ( $c , @arrays ) = @_;
      my @result = ();
      foreach my $array( @arrays ){
        given( ref( $array ) ){
          when( 'ARRAY' ){
            push @result , $c->a_flatten( @{ $array } );
          }
          default {
            push @result , $array;
          }
        }
      }
      @result;
    }
  );

}  

1;