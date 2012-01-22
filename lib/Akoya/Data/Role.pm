package Akoya::Data::Role;
use lib qw|/Users/tripper/akoya/lib|;
use KaiBashira::Base -base;
use KaiBashira::Data -base;

our $BUILTIN_NON_MEMBER = 1;
our $BUILTIN_ANONYMOUS  = 2;

our $ISSUES_VISIBILITY_OPTIONS = [
    ['all', 'label_issues_visibility_all'],
    ['default', 'label_issues_visibility_public'],
    ['own', 'label_issues_visibility_own']
];

1;
