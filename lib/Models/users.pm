package Models::users;
use lib qw|/Users/tripper/akoya/lib|;
use Models -base;

1;
__DATA__
use Data::Dumper;
use Akoya::Project;

has this_table => 'users';

has relation => sub{{
  has_and_belongs_to_many => {
    groups => {
      after_add => 1 ,
      after_remove => 1
    }
  },
  has_many => {
    changesets => {
      dependent => 'nullify'
    } ,
    members => {
      foreign_key => 'user_id' ,
      dependent => 'destroy'
    } ,
    memberships => {
      class_name => 'Member',
      foreign_key => 'user_id', 
      include => [qw/project roles/],
      conditions => "projects.status=" . $Akoya::Project::STATUS_ACTIVE,
      order => "projects.name"
    } ,
    projects => {
      through => 'memberships'
    } ,
    issue_categories => {
      foreign_key => 'assigned_to_id',
      dependent => 'nullify'
    }
  } ,
  has_one => {
    preference => {
      dependent => 'destroy' ,
      class_name => 'UserPreference'
    } ,
    rss_token => {
      class_name => 'Token' ,
      conditions => { action => 'feeds' }
    } ,
    api_token => {
      class_name => 'Token' ,
      conditions => { action => 'api' }
    } ,
  },
  belongs_to => {
    auth_source => 1 ,
  }
}};

has join => sub {
  ['left outer join user_preferences on users.id = user_preferences.user_id'];
};

1;
