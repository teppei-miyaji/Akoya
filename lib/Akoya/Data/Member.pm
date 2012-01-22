package Akoya::Data::Member;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

has [qw/id user_id project_id created_on mail_notification/];

1;
