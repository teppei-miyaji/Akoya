package Akoya;
use Mojo::Base 'Mojolicious';
use Data::Dumper;
use KaiBashira::TimeZone;

use Akoya::Activity;
use Akoya::Activity::Fetcher;

our $CODENAME = 'Akoya Gai';
our $VERSION  = '0.001';

# This method will run once at server start
sub startup {
  my $self = shift;

  #$self->plugins( [ 'Mojolicious' , 'Akoya' ] );

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # KaiBashira base support plugins;
  $self->plugin('KaiBashira::Array');
  $self->plugin('KaiBashira::AssetTag');
  $self->plugin('KaiBashira::Config');
  $self->plugin('KaiBashira::Failsafe');
  $self->plugin('KaiBashira::Hash');
  $self->plugin('KaiBashira::Helpers::Date');
  $self->plugin('KaiBashira::Helpers::DBIx');
  $self->plugin('KaiBashira::Helpers::FormBuilder');
  $self->plugin('KaiBashira::Helpers::FormOptions');

  # Akoya application plugins;
  $self->plugin('Akoya::Inflector');

  $self->plugin('Akoya::AccessControl');
  $self->plugin('Akoya::AccessKeys');
#  $self->plugin('Akoya::Activity');
  $self->plugin('Akoya::CustomFieldFormat');
  $self->plugin('Akoya::Helpers');
  $self->plugin('Akoya::Hook');
  $self->plugin('Akoya::I18N');
  $self->plugin('Akoya::Info');
  $self->plugin('Akoya::MenuManager');
  $self->plugin('Akoya::Model');
  $self->plugin('Akoya::Routes');
#  $self->plugin('Akoya::Setting');
  $self->plugin('Akoya::Themes');

  $self->custom_field_format->map( sub { my ( $fields ) = @_;
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'string', options => { label => 'label_string' , order => 1 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'text', options => { label => 'label_text' , order => 2 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'int', options => { label => 'label_integer' , order => 3 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'float', options => { label => 'label_float' , order => 4 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'list', options => { label => 'label_list' , order => 5 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'date', options => { label => 'label_date' , order => 6 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'bool', options => { label => 'label_boolean' , order => 7 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'user', options => { label => 'label_user' , only => [qw/Issue TimeEntry Version Project/], edit_as => 'list', order => 8 } ) );
    $fields->entry( Akoya::CustomFieldFormat->new( name => 'version', options => { label => 'label_version' , only => [qw/Issue TimeEntry Version Project/], edit_as => 'list', order => 9 } ) );
  } );

  # Permissions
  $self->access_control->map( sub { my ( $map ) = @_;
    $map->permission( 'view_project', {projects => [qw/show/], activities => [qw/index/]}, { public => 1 } );
    $map->permission( 'search_project', {search => 'index'}, { public => 1 } );
    $map->permission( 'add_project', {projects => [qw/new create/]}, { require => 'loggedin' } );
    $map->permission( 'edit_project', {projects => [qw/settings edit update/]}, { require => 'member' } );
    $map->permission( 'select_project_modules', {projects => 'modules'}, { require => 'member' } );
    $map->permission( 'manage_members', {projects => 'settings', members => [qw/new edit destroy autocomplete_for_member/]}, { require => 'member' } );
    $map->permission( 'manage_versions', {projects => 'settings', versions => [qw/new create edit update close_completed destroy/]}, { require => 'member' } );
    $map->permission( 'add_subprojects', {projects => [qw/new create/]}, { require => 'member' } );
  
    $map->project_module( 'issue_tracking', sub { my ( $map ) = @_;
      # Issue categories
      $map->permission( 'manage_categories', {projects => 'settings', issue_categories => [qw/index show new create edit update destroy/]}, { require => 'member' } );

      # Issues
      $map->permission( 'view_issues', {issues => [qw/index show/],
                                        auto_complete => [qw/issues/],
                                        context_menus => [qw/issues/],
                                        versions => [qw/index show status_by/],
                                        journals => [qw/index diff/],
                                        queries => 'index',
                                        reports => [qw/issue_report issue_report_details/]} );
      $map->permission( 'add_issues', {issues => [qw/new create update_form/]} );
      $map->permission( 'edit_issues', {issues => [qw/edit update bulk_edit bulk_update update_form/], journals => [qw/new/]} );
      $map->permission( 'manage_issue_relations', {issue_relations => [qw/index show create destroy/]} );
      $map->permission( 'manage_subtasks', {} );
      $map->permission( 'set_issues_private', {} );
      $map->permission( 'set_own_issues_private', {}, { require => 'loggedin' } );
      $map->permission( 'add_issue_notes', {issues => [qw/edit update/], journals => [qw/new/]} );
      $map->permission( 'edit_issue_notes', {journals => 'edit'}, { require => 'loggedin' } );
      $map->permission( 'edit_own_issue_notes', {journals => 'edit'}, { require => 'loggedin' } );
      $map->permission( 'move_issues', {issue_moves => [qw/new create/]}, { require => 'loggedin' } );
      $map->permission( 'delete_issues', {issues => 'destroy'}, { require => 'member' } );
      # Queries
      $map->permission( 'manage_public_queries', {queries => [qw/new create edit update destroy/]}, { require => 'member' } );
      $map->permission( 'save_queries', {queries => [qw/new create edit update destroy/]}, { require => 'loggedin' } );
      # Watchers
      $map->permission( 'view_issue_watchers' , {} );
      $map->permission( 'add_issue_watchers' , {watchers => 'new'} );
      $map->permission( 'delete_issue_watchers' , {watchers => 'destroy'} );
    } );

    $map->project_module( 'time_tracking' , sub { my ( $map ) = @_;
      $map->permission( 'log_time', {timelog => [qw/new create/]}, { require => 'loggedin' } );
      $map->permission( 'view_time_entries', {timelog => [qw/index show/], time_entry_reports => [qw/report/] } );
      $map->permission( 'edit_time_entries', {timelog => [qw/edit update destroy bulk_edit bulk_update/]}, { require => 'member' } );
      $map->permission( 'edit_own_time_entries', {timelog => [qw/edit update destroy bulk_edit bulk_update/]}, { require => 'loggedin' } );
      $map->permission( 'manage_project_activities', {project_enumerations => [qw/update destroy/]}, { require => 'member' } );
    } );

    $map->project_module( 'news' , sub { my ( $map ) = @_;
      $map->permission( 'manage_news', {news => [qw/new create edit update destroy/], comments => [qw/destroy/]}, { require => 'member' } );
      $map->permission( 'view_news', {news => [qw/index show/]}, { public => 1 } );
      $map->permission( 'comment_news', {comments => 'create'} );
    } );

    $map->project_module( 'documents' , sub { my ( $map ) = @_;
      $map->permission( 'manage_documents', {documents => [qw/new edit destroy add_attachment/]}, { require => 'loggedin' } );
      $map->permission( 'view_documents', {documents => [qw/index show download/] } );
    } );

    $map->project_module( 'files' , sub { my ( $map ) = @_;
      $map->permission( 'manage_files', {files => [qw/new create/]}, { require => 'loggedin' } );
      $map->permission( 'view_files', {files => 'index', versions => 'download'} );
    } );

    $map->project_module( 'wiki' , sub { my ( $map ) = @_;
      $map->permission( 'manage_wiki', {wikis => [qw/edit destroy/]}, { require => 'member' } );
      $map->permission( 'rename_wiki_pages', {wiki => 'rename'}, { require => 'member' } );
      $map->permission( 'delete_wiki_pages', {wiki => 'destroy'}, { require => 'member' } );
      $map->permission( 'view_wiki_pages', {wiki => [qw/index show special date_index/] } );
      $map->permission( 'export_wiki_pages', {wiki => [qw/export/] } );
      $map->permission( 'view_wiki_edits', {wiki => [qw/history diff annotate/] } );
      $map->permission( 'edit_wiki_pages', {wiki => [qw/edit update preview add_attachment/] } );
      $map->permission( 'delete_wiki_pages_attachments', {} );
      $map->permission( 'protect_wiki_pages', {wiki => 'protect'}, { require => 'member' } );
    } );

    $map->project_module( 'repository' , sub { my ( $map ) = @_;
      $map->permission( 'manage_repository', {repositories => [qw/edit committers destroy/]}, { require => 'member' } );
      $map->permission( 'browse_repository', {repositories => [qw/show browse entry annotate changes diff stats graph/]} );
      $map->permission( 'view_changesets', {repositories => [qw/show revisions revision/]} );
      $map->permission( 'commit_access', {} );
    } );

    $map->project_module( 'boards' , sub { my ( $map ) = @_;
      $map->permission( 'manage_boards', {boards => [qw/new edit destroy/]}, { require => 'member' } );
      $map->permission( 'view_messages', {boards => [qw/index show/], messages => [qw/show/]}, { public => 1 } );
      $map->permission( 'add_messages', {messages => [qw/new reply quote/]} );
      $map->permission( 'edit_messages', {messages => 'edit'}, { require => 'member' } );
      $map->permission( 'edit_own_messages', {messages => 'edit'}, { require => 'loggedin' } );
      $map->permission( 'delete_messages', {messages => 'destroy'}, { require => 'member' } );
      $map->permission( 'delete_own_messages', {messages => 'destroy'}, { require => 'loggedin' } );
    } );

    $map->project_module( 'calendar' , sub { my ( $map ) = @_;
      $map->permission( 'view_calendar', { calendars => [qw/show update/] } );
    } );

    $map->project_module( 'gantt' , sub { my ( $map ) = @_;
      $map->permission( 'view_gantt', { gantts => [qw/show update/] } );
    } );

  } );

  $self->menu_manager->map( 'top_menu' , sub { my ( $menu) = @_;
    $menu->push( 'home' , $self->url_for( 'home' ) );
    $menu->push( 'my_page' , { controller => 'my', action => 'page' } , { if => sub { shift->user->current->is_logged } } );
    $menu->push( 'projects' , { controller => 'projects', action => 'index' }, { caption => 'label_project_plural' } );
    $menu->push( 'administration' , $self->url_for( '/admin' ) , { if => sub { shift->user->current->is_admin }, last => 1 } );
    $menu->push( 'help' , Akoya::Info->help_url , { last => 1 } );
  } );

  $self->menu_manager->map( 'account_menu' , sub { my ( $menu ) = @_;
    $menu->push( 'login', $self->url_for( 'signin' ) , { if => sub { ! shift->user->current->is_logged } } );
    $menu->push( 'register', { controller => 'account', action => 'register' }, { if => sub { my ( $c ) = @_; !$c->user->current->is_logged && $c->setting->is_self_registration ? 1 : 0 } } );
    $menu->push( 'my_account', $self->url_for( '/my/account' ) , { if => sub { shift->user->current->is_logged } } );
    $menu->push( 'logout', $self->url_for( 'signout' ) , { if => sub { shift->user->current->is_logged } } );
  } );

  $self->menu_manager->map( 'application_menu' , sub { my ( $menu ) = @_;
    # Empty
  } );

  $self->menu_manager->map( 'admin_menu' , sub { my ( $menu ) = @_;
    $menu->push( 'projects', { controller => 'admin', action => 'projects' }, { caption => 'label_project_plural' } );
    $menu->push( 'users', { controller => 'users'}, { caption => 'label_user_plural' } );
    $menu->push( 'groups', { controller => 'groups'}, { caption => 'label_group_plural' } );
    $menu->push( 'roles', { controller => 'roles'}, { caption => 'label_role_and_permissions' } );
    $menu->push( 'trackers', { controller => 'trackers' }, { caption => 'label_tracker_plural' } );
    $menu->push( 'issue_statuses', { controller => 'issue_statuses' }, { caption => 'label_issue_status_plural',
            html => { class => 'issue_statuses' } } );
    $menu->push( 'workflows', { controller => 'workflows', action => 'edit' }, { caption => 'label_workflow' } );
    $menu->push( 'custom_fields', { controller => 'custom_fields' },  { caption => 'label_custom_field_plural',
            html => { class => 'custom_fields' } } );
    $menu->push( 'enumerations', { controller => 'enumerations' } );
    $menu->push( 'settings', { controller => 'settings' } );
    $menu->push( 'ldap_authentication', { controller => 'ldap_auth_sources', action => 'index'}, {
            html => { class => 'server_authentication' } } );
    $menu->push( 'plugins', { controller => 'admin', action => 'plugins' }, { last => 1 } );
    $menu->push( 'info', { controller => 'admin', action => 'info' }, { caption => 'label_information_plural', last => 1 } );
  } );

  $self->menu_manager->map( 'project_menu' , sub { my ( $menu ) = @_;
    $menu->push( 'overview', { controller => 'projects', action => 'show' } );
    $menu->push( 'activity', { controller => 'activities', action => 'index' } );
    $menu->push( 'roadmap', { controller => 'versions', action => 'index' }, { param => 'project_id',
            if => sub { foreach my $p ( shift->project ){ $p->shared_versions->is_any } } } );
    $menu->push( 'issues', { controller => 'issues', action => 'index' }, { param => 'project_id', caption => 'label_issue_plural' } );
    $menu->push( 'new_issue', { controller => 'issues', action => 'new' }, { param => 'project_id', caption => 'label_issue_new',
            html => { accesskey => Akoya::AccessKeys->key_for( 'new_issue' ) } } );
    $menu->push( 'gantt', { controller => 'gantts', action => 'show' }, { param => 'project_id', caption => 'label_gantt' } );
    $menu->push( 'calendar', { controller => 'calendars', action => 'show' }, { param => 'project_id', caption => 'label_calendar' } );
    $menu->push( 'news', { controller => 'news', action => 'index' }, { param => 'project_id', caption => 'label_news_plural' } );
    $menu->push( 'documents', { controller => 'documents', action => 'index' }, { param => 'project_id', caption => 'label_document_plural' } );
    $menu->push( 'wiki', { controller => 'wiki', action => 'show', id => 0 }, { param => 'project_id',
            if => sub { foreach my $p ( shift->project ){ $p->wiki && $p->wiki->is_new_record ? 0 : 1 } } } );
    $menu->push( 'boards', { controller => 'boards', action => 'index', id => 0 }, { param => 'project_id',
            if => sub { foreach my $p ( shift->project ){ $p->boards->is_any } }, caption => 'label_board_plural' } );
    $menu->push( 'files', { controller => 'files', action => 'index' }, { caption => 'label_file_plural', param => 'project_id' } );
    $menu->push( 'repository', { controller => 'repositories', action => 'show' }, {
            if => sub { foreach my $p ( shift->project ){ $p->repository && $p->repository->is_new_record ? 0 : 1 } } } );
    $menu->push( 'settings', { controller => 'projects', action => 'settings' }, { last => 1 } );
  } );

  Akoya::Activity->map( sub { my ( $activity ) = @_;
    Akoya::Activity->entry( 'issues', { class_name => [qw/Issue Journal/] } );
    Akoya::Activity->entry( 'changesets' );
    Akoya::Activity->entry( 'news' );
    Akoya::Activity->entry( 'documents', { class_name => [qw/Document Attachment/] } );
    Akoya::Activity->entry( 'files', { class_name => 'Attachment' } );
    Akoya::Activity->entry( 'wiki_edits', { class_name => 'WikiContent::Version', default => 0 } );
    Akoya::Activity->entry( 'messages', { default => 0 } );
    Akoya::Activity->entry( 'time_entries', { default => 0 } );
  } );

  # Routes
  my $r = $self->routes;

  # Normal route to controller
  $r->route('/welcome')->to('example#welcome');
}

1;
