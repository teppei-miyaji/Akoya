package Models::members;
use lib qw|/Users/tripper/akoya/lib|;
use Models -base;

has this_table => 'members';

has relation => sub{{
  has_many => {
    member_roles => {
      dependent => 'destroy'
    } ,
    roles => {
      through => 'member_roles'
    }
  } ,
  belongs_to => {
    user => 1 ,
    principal => {
      foreign_key => 'user_id'
    } ,
    project => 1
  }
}};

1;
