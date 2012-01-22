package Akoya::Data::UserPreference;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;
use YAML::Syck;

use Data::Dumper;

pub table => "user_preferences";
has [qw/id user_id others hide_mail time_zone/];

sub new {
  my $self = shift->SUPER::new( @_ );
  my $columns;
  if( $self->id ){
    $columns = $self->parent->dbi->select( table => 'user_preferences' ,columns => '*' , primary_key => 'id' , id => $self->id )->one;
  }
  elsif( $self->user_id ){
    $columns = $self->parent->dbi->select( table => 'user_preferences' ,columns => '*' , where => { uesr_id => $self->id } )->one;
  }
  
  if( $columns ){
    while( my ( $key , $value ) = each %{ $columns } ){
      $self->{ $key } = $value;
    }
    my $others = delete $self->{others};
    my $yaml = Load( $others );
    while( my ( $key , $value ) = each %{ $yaml } ){
      $key =~ s/^://;
      $self->{others}->{ $key } = $value;
    }
  }
  $self->others({}) unless $self->others;
  $self;
}

sub warn_on_leaving_unsaved {
  my ( $self ) = @_;
  $self->others->{warn_on_leaving_unsaved} || '1';
}

sub my_page_layout {
  my ( $self , $value ) = @_;
  $self->others->{my_page_layout} = $value if $value;
  $self->others->{my_page_layout} || undef;
}

sub no_self_notified {
  my ( $self , $value ) = @_;
  $self->others->{no_self_notified} = $value if $value;
  $self->others->{no_self_notified} || undef;
}

1;
