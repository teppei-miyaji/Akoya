package Controllers::My;
use Mojo::Base 'Mojolicious::Controller';
use lib qw|/Users/tripper/akoya/lib|;

has 'handler';

our $BLOCKS = {
  issuesassignedtome => 'label_assigned_to_me_issues',
  issuesreportedbyme => 'label_reported_issues',
  issueswatched => 'label_watched_issues',
  news => 'label_news_latest',
  calendar => 'label_calendar',
  documents => 'label_document_plural',
  timelog => 'label_spent_time'
};

our $DEFAULT_LAYOUT = {
  left => ['issuesassignedtome'],
  right => ['issuesreportedbyme']
};

sub page {
  my ( $self ) = @_;
  my $user = $self->user->current;
  $self->stash(
    user =>  $user ,
    blocks => $user->pref->my_page_layout || $DEFAULT_LAYOUT
  );
}

# Edit user's account
sub account {
  my ( $self ) = @_;
  my $user = $self->user->current;
  my $pref = $user->pref;
  if( $self->req->method eq 'POST' ){
    $user->safe_attributes( $self->param('user') );
    $user->pref->attributes( $self->param('pref') );
    $user->pref->no_self_notified( ( $self->params('no_self_notified') eq '1') );
    if( $user->save ){
      $user->pref->save;
      $user->notified_project_ids( $user->mail_notification eq 'selected' ? $self->param( 'notified_project_ids' ) : [] );
      $self->set_language_if_valid( $user->language );
      $self->stash( flash => { notice => $self->l('notice_account_updated') } );
      $self->redirect_to( '/my/account' );
    }
  }
  $self->stash(
    user => $user ,
    pref => $pref
  );
}

1;