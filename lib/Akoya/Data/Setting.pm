package Akoya::Data::Setting;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

pub table => "settings";

sub AUTOLOAD{
  our $AUTOLOAD;
  my @call_func = split( /::/ , $AUTOLOAD );
  my $name = pop @call_func;
  my ( $self , $value ) = @_;

  my $is_mode = 0;
  
  if( $name =~ m|^is_| ){
    $name =~ s|^is_||;
    $is_mode = 1;
  }

  if( $value ){
    #$self->parent->dbi->model('settings')->update_or_insert({ name => $value });
  }
  else {
    my $result = $self->parent->dbi->select(
      table => $self->table ,
      column => 'value' ,
      where => { name => $name }
    );
    if( $result ){
      my $hash = $result->one;
      $value = $hash->{value};
    }
    
    $value = $self->parent->stash('setting')->{ $name }->{default} unless $value;
    $value = $self->parent->app->defaults->{ $name }->{default} unless $value;
    if( ( $value || ' ' ) =~ /^:/ ){
      $value =~ s/^://;
    }
  }

  if( $is_mode ){
    given( $value ){
      when( [qw/Yes yes YES y 1 t True true TRUE/] ){
        $value = 1;
      }
      when( [qw/No no NO n 0 False false FALSE nil undef/] ){
        $value = 0;
      }
      when( ( $value || 0 ) > 0 ) {
        $value = 1;
      }
      default {
        $value = 0;
      }
    }
  }

  $value;
}


1;