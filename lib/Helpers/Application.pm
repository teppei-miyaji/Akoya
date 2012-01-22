package Helpers::Application;
use lib qw|/Users/tripper/akoya/lib|;
use Mojo::Base 'Mojolicious::Plugin';
use Text::Textile qw/textile/;
use Mojo::ByteStream 'b';

use Data::Dumper;

sub register {
  my ( $self , $app ) = @_;

  my $textile = Text::Textile->new;

  $app->helper(
    link_to_user => sub {
      my ( $c, $user, $options ) = @_;
      if( ref( $user ) eq 'Akoya::Data::User' ){
        my $name = $c->h( $user->name( $options->{format} ) );
        if( $user->is_active ){
          $c->link_to( $name => $c->url_for( '/users/' . $user->id ) );
        }
        else {
          $name;
        }
      }
      else {
        $c->h( $user );
      }
    }
  );

  $app->helper(
    link_to_project => sub {
      my ( $c , $project , $options , $html_options ) = @_;

      if( $project->is_active ){
        my $url = $c->url_for( 'projects/' . $project->identifier );
        b( $c->link_to( $c->h( $project->name ) => $url => ( %{ $html_options } ) ) )->html_unescape;
      }
      else {
        $c->h( $project->name );
      }
    }
  );

  $app->helper(
    authoring => sub {
      my ( $c, $created, $author, $options ) = @_;
      $c->l( $options->{label} || 'label_added_time_by' , author => $c->link_to_user( $author ), age => $c->time_tag( $created ) );
    }
  );

  $app->helper(
    time_tag => sub {
      my( $c , $time ) = @_;
      my $text = $c->distance_of_time_in_words( 'now' , $time );
      my $project = $c->stash('project');
      if( $project ){
        $c->link_to( $text => $c->url_for( "activities/index/" . $project->id => ( $c->tag( 'acronym' , title => $c->format_time( $time ) => $text ) ) ) );
      }
      else {
        $c->tag( 'acronym' , title => $c->format_time ( $time ) => $text );
      }
    }
  );

  $app->helper(
    is_email_delivery_enabled => sub {}
  );

  $app->helper( textile => sub{ $textile; } );
  $app->helper(
    textilizable => sub {
      my ( $c , $value ) = @_;
      b( $c->textile->process( $value ) )->html_unescape;
    }
  );

  $app->helper(
    render_flash_messages => sub {
      my ( $c ) = @_;
      my $s = '';
 
      return '' unless $c->stash->{flash};
 
      while( my ( $k , $v ) = each( %{ $c->stash->{flash} } ) ){
        $s .= $c->tag( div => ( class => "flash ${k}" ) => sub{ $v } );
      }
      $s;
    }
  );

  $app->helper(
    page_header_title => sub {
      my ( $c ) = @_;
      if( ! $c->project || $c->project->is_new_record ){
        return $c->h( $c->setting->app_title );
      }
      else {
        my @b = ();
#        my @ancestors = ( $c->stash('project')->is_root ? () : $c->stash('project')->ancestors->visible->all );
        my @ancestors;
        if( @ancestors ){
          my $root = shift( @ancestors );
          push @b, $c->link_to_project( $root, { jump => $c->current_menu_item }, class => 'root');
          if( @ancestors > 2 ){
            push @b, "\xe2\x80\xa6";
            @ancestors = @ancestors[-2, 2];
          }
          foreach my $p( @ancestors ){
            push @b, $c->link_to_project( $p, { jump => $c->current_menu_item }, class => 'ancestor' );
          }
        }
        push @b, $c->h( $c->stash('project') );
        return join(" \xc2\xbb " , @b );
      }
    }
  );

  $app->helper(
    html_title => sub {
      my ( $c , @args ) = @_;
      if( @args ){
        push @{ $c->stash->{html_title} } , @args;
      }
      else {
        my @title = $c->stash->{html_title} || ();
        push @title , $c->stash('project')->name if $c->stash('project');
        push @title , $c->setting->app_title unless $c->setting->app_title eq $title[$#title] || '';
        join(' - ' , $c->a_flatten( @title ) );
      }
    }
  );

  $app->helper(
   javascript_heads => sub {
     my ( $c ) = @_;
     my $tags = join( "\n" , $c->javascript_include_tag( 'defaults' ) );
#     unless( ( $c->user->current->pref->warn_on_leaving_unsaved || '' ) eq '0' ){
#       my $text = $c->l('text_warn_on_leaving_unsaved') ;
#       $tags .= "\n" . $c->javascript( sub{ "Event.observe(window, 'load', function(){ new WarnLeavingUnsaved('${text}'); });" } );
#     }
     $tags;
    }
  );

  $app->helper(
    body_css_classes => sub {
      my ( $c ) = @_;
      my @css = ();
      if( my $theme = Akoya::Themes->theme( $c->setting->ui_theme ) ){
        push @css , 'theme-' . $theme->name;
      }
      push @css, 'controller-' . $c->stash('controller');
      push @css, 'action-' . $c->stash('action');
      join( ' ', @css );
    }
  );

  $app->helper(
    render_project_jump_box => sub {
      my ( $c ) = @_;
      return unless $c->user->current->is_logged;
      my $projects = $c->user->current->memberships;
      $projects = undef unless $projects->id;
      my $s;
      if( $projects ){
        $s = '<select onchange="if (this.value != \'\') { window.location = this.value; }">' .
            "<option value=''> " . $c->l('label_jump_to_a_project') . " </option>" .
            '<option value="" disabled="disabled">---</option>';
        $s .= $c->project_tree_options_for_select( $projects, { selected => $c->stash('project') } , sub {
          my ( $c , $p , $tag_options ) = @_;
          $tag_options->{value} = url_for( controller => 'projects', action => 'show', id => $p, jump => $c->current_menu_item );
        } );
        $s .= '</select>';
      }
      $s;
    }
  );

  $app->helper(
    project_tree_options_for_select => sub {
      my ( $c , $projects, $options ) = @_;
      my $s = '';
      $c->project_tree( $projects , sub { my ( $project, $level ) = @_;
        my $name_prefix = ( $level > 0 ? ('&nbsp;' * 2 * $level + '&#187; ') : '');
        my $tag_options = { value => $project->{id} };
        if( $project == $options->{selected} || ( $options->{selected}->can('is_include') && $options->{selected}->is_include( $project ) ) ){
          $tag_options->{selected} = 'selected';
        }
        else {
          $tag_options->{selected} = undef;
        }
        #$tag_options.merge!(yield(project)) if block_given?
        $s .= $c->tag('option', $name_prefix . $c->h($project->name), $tag_options );
      } );
      $s;
    }
  );

  $app->helper(
    project_tree => sub{
      my ( $c, $projects, $sub ) = @_;
      $c->project->project_tree( $projects, $sub );
    }
  );

  $app->helper(
    favicon => sub {
      my ( $c ) = @_;
      "<link rel='shortcut icon' href='" . $c->image_path('favicon.ico') . "' />";
    }
  );

  $app->helper(
    lang_options_for_select => sub {
      my ( $c , $blank ) = @_;
      $c->valid_languages;
    }
  );

  $app->helper(
    back_url_hidden_field_tag => sub {
      my ( $c ) = @_;
      my $back_url = $c->param('back_url') || $c->req->headers->referrer;
      $back_url = b( $back_url )->url_unescape;
      $c->hidden_field('back_url', b( $back_url )->url_escape ) if $back_url;
    }
  );

}

1;
