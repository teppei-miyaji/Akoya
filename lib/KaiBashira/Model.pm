package KaiBashira::Model;
use feature 'switch';
use lib qw|/Users/tripper/akoya/lib|;
use Mojo::Base 'DBIx::Custom';
use KaiBashira::Inflector;

use Data::Dumper;

has [qw/app/];
has infrector => sub{ KaiBashira::Inflector->new };

sub connect {
  my $self = shift->SUPER::connect( @_ );

  my $tables_info = {};

  foreach my $column( @{ $self->get_column_info } ){
    $tables_info->{ $column->{table} }->{ $column->{column} } = $column->{info}->{TYPE_NAME} || 1;
  }

  foreach my $table( keys %{ $tables_info } ){
    my @options;
    foreach my $column( keys %{ $tables_info->{ $table } } ){

      given( $column ){
        when( 'id' )        { push @options , ( primary_key => 'id' ) }
        when( 'updated_on' ){ push @options , ( updated_at => 'updated_on' ) }
        when( 'updated_at' ){ push @options , ( updated_at => 'updated_at' ) }
        when( 'created_on' ){ push @options , ( created_at => 'created_on' ) }
        when( 'created_at' ){ push @options , ( created_at => 'created_at' ) }
      }

    }
    $self->create_model( table => $table , @options );
  }

  warn Dumper( caller(2) );

}

1;