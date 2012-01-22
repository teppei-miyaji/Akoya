package KaiBashira::Helpers::Date;
use Mojo::Base 'Mojolicious::Plugin';
use Date::Manip::Date;
use Mojo::ByteStream 'b';

use Data::Dumper;

sub register {
  my ( $self , $app ) = @_;

  $app->helper(
    distance_of_time_in_words => sub {
      my ( $c , $from_date , $to_date ) = @_;
      
      #$from_date = 'epoch ' . $from_date if $from_date =~ /^¥d+$/;
      my $from_date_oo = Date::Manip::Date->new;
      $from_date_oo->parse( $from_date  );
      
      my $to_date_oo = Date::Manip::Date->new;
      $to_date_oo->parse( $to_date );

      my $d = $to_date_oo->calc( $from_date_oo );
 
      my( $years, $months, $weeks, $days, $hours, $minutes, $seconds ) = $d->value;
  
      my $r = "";
  
      if   ( $years > 1    ){ $r = $c->l( 'datetime' , distance_in_words => 'over_x_years'       , count => $years   ); }
      elsif( $years == 1   ){ $r = $c->l( 'datetime' , distance_in_words => 'about_x_years'      , count => $years   ); }
      elsif( $months > 1   ){ $r = $c->l( 'datetime' , distance_in_words => 'x_months'           , count => $months  ); }
      elsif( $months == 1  ){ $r = $c->l( 'datetime' , distance_in_words => 'about_x_months'     , count => $months  ); }
      elsif( $days > 1     ){ $r = $c->l( 'datetime' , distance_in_words => 'x_days'             , count => $days    ); }
      elsif( $days == 1    ){ $r = $c->l( 'datetime' , distance_in_words => 'x_days'             , count => $days    ); }
      elsif( $hours > 1    ){ $r = $c->l( 'datetime' , distance_in_words => 'about_x_hours'      , count => $hours   ); }
      elsif( $hours == 1   ){ $r = $c->l( 'datetime' , distance_in_words => 'about_x_hours'      , count => $hours   ); }
      elsif( $minutes > 1  ){ $r = $c->l( 'datetime' , distance_in_words => 'x_minutes'          , count => $minutes ); }
      elsif( $minutes == 1 ){ $r = $c->l( 'datetime' , distance_in_words => 'x_minutes'          , count => $minutes ); }
      elsif( $seconds > 1  ){ $r = $c->l( 'datetime' , distance_in_words => 'less_than_x_seconds', count => $seconds ); }
      elsif( $seconds == 1 ){ $r = $c->l( 'datetime' , distance_in_words => 'less_than_x_seconds', count => $seconds ); }
      else{   $r = 'error'   }
      
      b( $r )->encode('UTF8')->to_string;
    }
  );

}
1;