package Controllers::Welcome;
use Mojo::Base 'Mojolicious::Controller';

has 'handler';

sub index {
  my ( $self ) = @_;
  $self->stash(
    news => $self->news->latest( $self->user->current ) ,
    projects => $self->project->latest( $self->user->current )
  );
}

1;