package Akoya::Data::Principal;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

pub talbe => "users";

has_many name => 'members' , foreign_key => 'user_id', dependent => 'destroy';
has_many name => 'memberships' , class_name => 'Member', foreign_key => 'user_id', 
         include => [qw/project roles/], 
         conditions => { Akoya::Data::Project->table . ".status" => $Akoya::Data::Project::STATUS_ACTIVE },
         order => Akoya::Data::Project->table . ".name";
has_many name => 'projects' , through => 'memberships';
has_many name => 'issue_categories' , foreign_key => 'assigned_to_id', dependent => 'nullify';

sub dummy {
  warn $Akoya::Data::Project::STATUS_ACTIVE;
}

1;