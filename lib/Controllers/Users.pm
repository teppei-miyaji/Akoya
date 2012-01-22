package Controllers::Users;
use Mojo::Base 'Mojolicious::Controller';
use lib qw|/Users/tripper/akoya/lib|;

has 'handler';

sub show {
  my ( $self ) = @_;
  my $user = Akoya::Data::User->new( id => $self->param('id') , parent => $self );
  # show projects based on current user visibility
  my @memberships = $self->user->memberships->all( conditions => $self->project->visible_condition( $self->user->current ) );

  my $events = Akoya::Activity::Fetcher->new( $self->user->current, author => $user )->events( undef , undef , { limit => 10} );
  my @events_by_day = $events->group_by( 'event_date' );

  unless( $user->current->is_admin ){
    if( ! $user->is_active || ( $user != $self->user->current && @memberships && $events ) ){
      $self->render_not_found;
    }
  }

  $self->respond_to( sub { my $format = @_;
     $format->html( $self->render( layout => 'base' ) );
     $format->api;
   } );
}

1;