package Models::projects;
use lib qw|/Users/tripper/akoya/lib|;
use Models -base;

has this_table => 'projects';

has relation => sub{{
  has_and_belongs_to_many => {
    trackers => { order => "#{Tracker.table_name}.position" }
  } ,
  has_many => {
    time_entry_activities => 1 ,
    members => {
      include => [qw/user roles/], 
      conditions => "#{User.table_name}.type='User' AND #{User.table_name}.status=#{User::STATUS_ACTIVE}"
    } ,
    memberships => {
      class_name => 'Member'
    } ,
    member_principals => {
      class_name => 'Member',
      include => 'principal',
      conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND #{Principal.table_name}.status=#{User::STATUS_ACTIVE})"
    } ,
    users => {
      through => 'members'
    } ,
    principals => {
      through => 'member_principals' ,
      source => 'principal'
    } ,
    enabled_modules => {
      dependent => 'delete_all'
    } ,
    issues => {
      dependent => 'destroy',
      order => "#{Issue.table_name}.created_on DESC",
      include => [qw/status tracker/]
    } ,
    issue_changes => {
      through => 'issues',
      source => 'journals'
    } ,
	versions => {
	  dependent => 'destroy',
	  order => "#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC"
	} ,
    time_entries => {
      dependent => 'delete_all'
    } ,
    queries => {
      dependent => 'delete_all'
    } ,
    documents => {
      dependent => 'destroy'
    } ,
    news => {
      dependent => 'destroy',
      include => 'author'
    } ,
    issue_categories => { 
      dependent => 'delete_all',
      order => "#{IssueCategory.table_name}.name"
    } ,
    boards => {
      dependent => 'destroy',
      order => "position ASC"
    } ,
    changesets => {
      through => 'repository'
    }
  } ,
  has_one => {
    repository => {
      dependent => 'destroy'
    } ,
    wiki => {
      dependent => 'destroy'
    }
  }
}};

1;
