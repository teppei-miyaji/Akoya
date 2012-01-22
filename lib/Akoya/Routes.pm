package Akoya::Routes;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;
  my $r = $app->routes;
  $r->namespace( 'Controllers' );
  
  $r->route('')->name('home')->to( controller => 'welcome' , action => 'index' );

  $r->route('login')->name('signin')->to( controller => 'account', action => 'login' );
  $r->route('logout')->name('signout')->to( controller => 'account', action => 'logout' );

  $r->route('roles/workflow/:id/:role_id/:tracker_id')->to( controller => 'roles', action => 'workflow' );
  $r->route('help/:ctrl/:page')->to( controller => 'help' );

  my $time_report = $r->to( controller => 'time_entry_reports', action => 'report' );
  $time_report->get( 'projects/:project_id/issues/:issue_id/time_entries/report' );
  $time_report->get( 'projects/:project_id/issues/:issue_id/time_entries/report.:format' );
  $time_report->get( 'projects/:project_id/time_entries/report' );
  $time_report->get( 'projects/:project_id/time_entries/report.:format' );
  $time_report->get( 'time_entries/report' );
  $time_report->get( 'time_entries/report.:format' );

  $r->get( 'time_entries/bulk_edit' )->name('bulk_edit_time_entry')->to( controller => 'timelog', action => 'bulk_edit' );
  $r->post( 'time_entries/bulk_edit' )->name('bulk_update_time_entry')->to( controller => 'timelog', action => 'bulk_update' );
  $r->route( 'time_entries/context_menu' )->name('time_entries_context_menu')->to( controller => 'context_menus', action => 'time_entries' );

  $self->resources( $app , 'time_entries' , { controller => 'timelog' , suffix => '.:format' } );

  $r->post( 'projects/:id/wiki' )->to( controller => 'wikis', action => 'edit' );
  $r->get( 'projects/:id/wiki/destroy' )->to( controller => 'wikis', action => 'destroy' );
  $r->post( 'projects/:id/wiki/destroy' )->to( controller => 'wikis', action => 'destroy' );

  my $messages_views = $r->to( controller => 'messages' );
  $messages_views->get( 'boards/:board_id/topics/new' )->to( action => 'new' );
  $messages_views->get( 'boards/:board_id/topics/:id' )->to( action => 'show' );
  $messages_views->get( 'boards/:board_id/topics/:id/edit' )->to( action => 'edit' );
  my $messages_actions = $r->to( controller => 'messages' );
  $messages_actions->post( 'boards/:board_id/topics/new' )->to( action => 'new' );
  $messages_actions->post( 'boards/:board_id/topics/:id/replies' )->to( action => 'reply' );
  $messages_actions->post( 'boards/:board_id/topics/:id/:action' )->to( action => qr/edit|destroy/ );

  my $board_views = $r->to( controller => 'boards' );
  $board_views->get( 'projects/:project_id/boards' )->to( action => 'index' );
  $board_views->get( 'projects/:project_id/boards/new' )->to( action => 'new' );
  $board_views->get( 'projects/:project_id/boards/:id' )->to( action => 'show' );
  $board_views->get( 'projects/:project_id/boards/:id.:format' )->to( action => 'show' );
  $board_views->get( 'projects/:project_id/boards/:id/edit' )->to( action => 'edit' );
  my $board_actions = $r->to( controller => 'boards' );
  $board_actions->post( 'projects/:project_id/boards' )->to( action => 'new' );
  $board_actions->post( 'projects/:project_id/boards/:id/:action' )->to( action => qr/edit|destroy/ );

  my $document_views = $r->to( controller => 'documents' );
  $document_views->get( 'projects/:project_id/documents' )->to( action => 'index' );
  $document_views->get( 'projects/:project_id/documents/new' )->to( action => 'new' );
  $document_views->get( 'documents/:id' )->to( action => 'show' );
  $document_views->get( 'documents/:id/edit' )->to( action => 'edit' );
  my $document_actions = $r->to( controller => 'documents' );
  $document_actions->post( 'projects/:project_id/documents' )->to( action => 'new' );
  $document_actions->post( 'documents/:id/:action' )->to( action => qr/destroy|edit/ );

  $self->resources( $app , 'issue_moves' , { only => [qw/new create/] , path_prefix => '/issues' , as => 'move' , suffix => '.:format' } );
  $self->resources( $app , 'queries' , { except => [qw/show/] } );

  $r->get( '/issues/auto_complete' )->name("auto_complete_issues")->to( controller => 'auto_completes', action => 'issues' );
  $r->route( '/issues/preview/:id' )->name( "preview_issue" )->to( controller => 'previews', action => 'issue' );
  $r->route( '/issues/context_menu' )->name( "issues_context_menu" )->to( controller => 'context_menus', action => 'issues' );
  $r->route( '/issues/changes' )->name( "issue_changes" )->to( controller => 'journals', action => 'index' );
  $r->get( 'issues/bulk_edit' )->name( "bulk_edit_issue" )->to( controller => 'issues', action => 'bulk_edit' );
  $r->post( 'issues/bulk_edit' )->name( "bulk_update_issue" )->to( controller => 'issues', action => 'bulk_update' );
  $r->post( '/issues/:id/quoted' )->name( "quoted_issue" )->to( controller => 'journals', action => 'new', id => qr/\d+/ );
  $r->post( '/issues/:id/destroy' )->to( controller => 'issues', action => 'destroy' );
 
  my $gantts_routes = $r->to( controller => 'gantts', action => 'show' );
    $gantts_routes->route( '/projects/:project_id/issues/gantt' );
    $gantts_routes->route( '/projects/:project_id/issues/gantt.:format' );
    $gantts_routes->route( '/issues/gantt.:format' );

  my $calendars_routes = $r->to( controller => 'calendars', action => 'show' );
    $calendars_routes->route( '/projects/:project_id/issues/calendar' );
    $calendars_routes->route( '/issues/calendar' );

  my $reports = $r->to( controller => 'reports' );
    $reports->get( 'projects/:id/issues/report' )->to( action => 'issue_report' );
    $reports->get( 'projects/:id/issues/report/:detail' )->to( action => 'issue_report_details' );

  $r->post( '/issues' )->to( controller => 'issues', action => 'index' );
  $r->post( '/issues/create' )->to( controller => 'issues', action => 'index' );

#  map.resources :issues, :member => { :edit => :post }, :collection => {} do |issues|
#    issues.resources :time_entries, :controller => 'timelog'
#    issues.resources :relations, :shallow => true, :controller => 'issue_relations', :only => [:index, :show, :create, :destroy]
#  end

#  map.resources :issues, :path_prefix => '/projects/:project_id', :collection => { :create => :post } do |issues|
#    issues.resources :time_entries, :controller => 'timelog'
#  end

  $r->route( 'projects/:id/members/new' )->to( controller => 'members', action => 'new' );

  my $users = $r->to( controller => 'users' );
  $users->get( 'users/:id/edit/:tab' )->to( action => 'edit', tab => undef );
  my $user_actions = $users;
  $user_actions->post( 'users/:id/memberships' )->to( action => 'edit_membership' );
  $user_actions->post( 'users/:id/memberships/:membership_id' )->to( action => 'edit_membership' );
  $user_actions->post( 'users/:id/memberships/:membership_id/destroy' )->to( action => 'destroy_membership' );

  $self->resources( $app , 'users' , { member => { 
    edit_membership => 'post' , 
    destroy_membership => 'post'
  } } );
 
# #   map.resources :users, :member => {
    # :edit_membership => :post,
    # :destroy_membership => :post
  # }

  # For nice "roadmap" in the url for the index action
  $r->route( 'projects/:project_id/roadmap' )->to( controller => 'versions', action => 'index' );

  $r->route( 'news' )->name( 'all_news' )->to( controller => 'news', action => 'index' );
  $r->route( 'news.:format' )->name( 'formatted_all_news' )->to( controller => 'news', action => 'index' );
  $r->route( '/news/preview' )->name( 'preview_news' )->to( controller => 'previews', action => 'news' );
  $r->post( 'news/:id/comments' )->to( controller => 'comments', action => 'create' );
  $r->delete( 'news/:id/comments/:comment_id' )->to( controller => 'comments', action => 'destroy' );

# #   map.resources :projects, :member => {
    # :copy => [:get, :post],
    # :settings => :get,
    # :modules => :post,
    # :archive => :post,
    # :unarchive => :post
  # } do |project|
    # project.resource :project_enumerations, :as => 'enumerations', :only => [:update, :destroy]
    # project.resources :files, :only => [:index, :new, :create]
    # project.resources :versions, :shallow => true, :collection => {:close_completed => :put}, :member => {:status_by => :post}
    # project.resources :news, :shallow => true
    # project.resources :time_entries, :controller => 'timelog', :path_prefix => 'projects/:project_id'
    # project.resources :queries, :only => [:new, :create]
    # project.resources :issue_categories, :shallow => true

# #     project.wiki_start_page 'wiki', :controller => 'wiki', :action => 'show', :conditions => {:method => :get}
    # project.wiki_index 'wiki/index', :controller => 'wiki', :action => 'index', :conditions => {:method => :get}
    # project.wiki_diff 'wiki/:id/diff/:version', :controller => 'wiki', :action => 'diff', :version => nil
    # project.wiki_diff 'wiki/:id/diff/:version/vs/:version_from', :controller => 'wiki', :action => 'diff'
    # project.wiki_annotate 'wiki/:id/annotate/:version', :controller => 'wiki', :action => 'annotate'
    # project.resources :wiki, :except => [:new, :create], :member => {
      # :rename => [:get, :post],
      # :history => :get,
      # :preview => :any,
      # :protect => :post,
      # :add_attachment => :post
    # }, :collection => {
      # :export => :get,
      # :date_index => :get
    # }

# #   end

# Destroy uses a get request to prompt the user before the actual DELETE request
  $r->get( 'projects/:id/destroy' )->name( 'project_destroy_confirm' )->to( controller => 'projects', action => 'destroy' );

  # TODO: port to be part of the resources route(s)
  my $project_mapper = $r->to( controller => 'projects' );
  my $project_views = $project_mapper;
  $project_views->get( 'projects/:id/settings/:tab' )->to( controller => 'projects', action => 'settings' );
  $project_views->get( 'projects/:project_id/issues/:copy_from/copy' )->to( controller => 'issues', action => 'new' );
  
  my $activity = $r->to( controller => 'activities', action => 'index' );
  $activity->get( 'projects/:id/activity' );
  $activity->get( 'projects/:id/activity.:format' );
  $activity->get( 'activity' )->to( id => undef  );
  $activity->get( 'activity.:format' )->to( id => undef  );

# #   map.with_options :controller => 'repositories' do |repositories|
    # repositories.with_options :conditions => {:method => :get} do |repository_views|
      # repository_views.connect 'projects/:id/repository', :action => 'show'
      # repository_views.connect 'projects/:id/repository/edit', :action => 'edit'
      # repository_views.connect 'projects/:id/repository/statistics', :action => 'stats'
      # repository_views.connect 'projects/:id/repository/revisions', :action => 'revisions'
      # repository_views.connect 'projects/:id/repository/revisions.:format', :action => 'revisions'
      # repository_views.connect 'projects/:id/repository/revisions/:rev', :action => 'revision'
      # repository_views.connect 'projects/:id/repository/revisions/:rev/diff', :action => 'diff'
      # repository_views.connect 'projects/:id/repository/revisions/:rev/diff.:format', :action => 'diff'
      # repository_views.connect 'projects/:id/repository/revisions/:rev/raw/*path', :action => 'entry', :format => 'raw', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      # repository_views.connect 'projects/:id/repository/revisions/:rev/:action/*path', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      # repository_views.connect 'projects/:id/repository/raw/*path', :action => 'entry', :format => 'raw'
      # # TODO: why the following route is required?
      # repository_views.connect 'projects/:id/repository/entry/*path', :action => 'entry'
      # repository_views.connect 'projects/:id/repository/:action/*path'
    # end

# #     repositories.connect 'projects/:id/repository/:action', :conditions => {:method => :post}
  # end
 
  $self->resources( $app , 'attachments' , { only => [qw/show destroy/] } );
  # additional routes for having the file name at the end of url
  $r->route( 'attachments/:id/:filename' )->to( controller => 'attachments', action => 'show', id => qr/\d+/, filename => qr/.*/ );
  $r->route( 'attachments/download/:id/:filename' )->to( controller => 'attachments', action => 'download', id => qr/\d+/, filename => qr/.*/ );

  # map.resources :groups, :member => {:autocomplete_for_user => :get}
  $r->post( 'groups/:id/users' )->name( 'group_users' )->to( controller => 'groups', action => 'add_users', id => qr/\d+/ );
  $r->delete( 'groups/:id/users/:user_id' )->name( 'group_user' )->to( controller => 'groups', action => 'remove_user', id => qr/\d+/ );

  $self->resources( $app , 'trackers' , { except => [qw/show/] } );
  # map.resources :issue_statuses, :except => :show, :collection => {:update_issue_done_ratio => :post}

# #   #left old routes at the bottom for backwards compat
  # map.connect 'projects/:project_id/issues/:action', :controller => 'issues'
  # map.connect 'projects/:project_id/documents/:action', :controller => 'documents'
  # map.connect 'projects/:project_id/boards/:action/:id', :controller => 'boards'
  # map.connect 'boards/:board_id/topics/:action/:id', :controller => 'messages'
  # map.connect 'wiki/:id/:page/:action', :page => nil, :controller => 'wiki'
  # map.connect 'projects/:project_id/news/:action', :controller => 'news'
  # map.connect 'projects/:project_id/timelog/:action/:id', :controller => 'timelog', :project_id => /.+/
  # map.with_options :controller => 'repositories' do |omap|
    # omap.repositories_show 'repositories/browse/:id/*path', :action => 'browse'
    # omap.repositories_changes 'repositories/changes/:id/*path', :action => 'changes'
    # omap.repositories_diff 'repositories/diff/:id/*path', :action => 'diff'
    # omap.repositories_entry 'repositories/entry/:id/*path', :action => 'entry'
    # omap.repositories_entry 'repositories/annotate/:id/*path', :action => 'annotate'
    # omap.connect 'repositories/revision/:id/:rev', :action => 'revision'
  # end

  my $sys = $r->to( controller => 'sys' );
  $sys->get( 'sys/projects.:format' )->to( action => 'projects' );
  $sys->post( 'sys/projects/:id/repository.:format' )->to( action => 'create_project_repository' );

  # Install the default route as the lowest priority.
  $r->route( ':controller/:action/:id' );
  $r->route( ':controller/:action' );

  $r->route( 'admin' )->to( controller => 'admin', action => 'index' );

  $r->route( 'welcome/robots' )->name( 'robots.txt' );
  # Used for OpenID
  $r->route( 'account/login' )->name( 'root' );

}

sub resources {
  my ( $self , $app , $name , $options ) = @_;
  my $verb = {
    index => q|get| ,
    new => q|get| ,
    create => q|post| ,
    show => q|get| ,
    edit => q|get| ,
    update => q|put| ,
    destroy => q|delete| ,
  };

  my $routes = $app->routes;
  my $controller = $options->{controller} || $name;
  my $suffix = $options->{suffix} || "";
  push my @path , $options->{path_prefix} || "$name";
  push @path , $options->{as} if defined $options->{as};
  if( $options->{only} ){
    foreach my $action( keys %{ $verb } ){
      delete $verb->{ $action } unless $action ~~ @{ $options->{only} };
    }
  }
  if( $options->{except} ){
    foreach my $action( keys %{ $verb } ){
      delete $verb->{ $action } if $action ~~ @{ $options->{only} };
    }
  }

  foreach my $action( keys %{ $verb } ){
    given( $action ){
      when( q|index| ){
        $routes->get( join( '/' , @path ) . $suffix )->name( $name )->to( controller=> $controller , action => q|index| );
      }
      when( q|new| ){
        my $route_name = $app->singularize( "new_$name" );
        $routes->get( join( '/' , @path , 'new' ) . $suffix )->name( $route_name )->to( controller=> $controller , action => 'new' );
      }
      when( q|create| ){
        $routes->post( join( '/' , @path ) . $suffix )->to( controller=> $controller , action => q|create| );
      }
      when( q|show| ){
        my $route_name = $app->singularize( "$name" );
        $routes->get( join( '/' , @path , ':id' ) . $suffix )->name( $route_name )->to( controller=> $controller , action => 'show' );
      }
      when( q|edit| ){
        my $route_name = $app->singularize( "edit_$name" );
        $routes->get( join( '/' , @path , ':id' , 'edit' ) . $suffix )->name( $route_name )->to( controller=> $controller , action => 'edit' );
      }
      when( q|update| ){
        $routes->put( join( '/' , @path , ':id' ) . $suffix )->to( controller=> $controller , action => 'update' );
      }
      when( q|destroy| ){
        $routes->delete( join( '/' , @path , ':id' ) . $suffix )->to( controller=> $controller , action => 'destroy' );
      }
    }
  }
  
}

1;