package Akoya::Data::News;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

use Data::Dumper;

pub 'columns';

has [qw/id project_id title summary description author_id created_on comments_count/];

pub table => "news";

belongs_to name => 'project';
belongs_to name => 'author' , class_name => 'User' , foreign_key => 'author_id';
has_many name => 'comments', as => 'commented', dependent => 'delete_all', order => "created_on";

sub new {
  my $self = shift->SUPER::new( @_ );
  if( $self->{id} && $self->parent->dbi->count( table => $self->table , where => { id => $self->id } ) ){
    my $result = $self->parent->dbi->select( table => $self->table , where => { id => $self->id } )->one;
    while( my ( $attr , $value ) = each %{ $result } ){
      $self->{ "${attr}" } = $value;
    }
  }
  $self;
}

sub latest {
  my ( $self , $user, $count ) = @_;
  $user ||= $self->parent->user->current;
  $count ||= 5;

  my @news = ();

  foreach my $row ( $self->select( column => 'id' , append => "order by created_on desc limit ${count}" ) ) {
    push @news , __PACKAGE__->new( id => $row->{id} , parent => $self->parent );
  }

  @news;
}

sub path {
   my ( $self, $news ) = @_;
   $news ||= $self;
   $self->parent->url_for( "news/" . $news->id );
}

1;


