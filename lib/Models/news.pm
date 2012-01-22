package Models::news;
use lib qw|/Users/tripper/akoya/lib|;
use Models -base;

has this_table => 'news';

has relation => sub{{
  belongs_to => {
    project => 1 ,
    author => {
      class_name => 'User',
      foreign_key => 'author_id'
    } ,
  } ,
  has_many => {
    comments => {
      as => 'commented',
      dependent => 'delete_all',
      order => 'created_on'
    }
  }
}};

1;