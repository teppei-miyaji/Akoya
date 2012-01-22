package TreeNodePatch;
use Mojo::Base 'KaiBashira::Tree';
use Carp;

has last_items_count => 0;

sub new {
  my $self = shift->SUPER::new( @_ );
  $self; 
}

sub prepend {
  my ( $self , $child ) = @_;
  croak "Child already added" if $self->{children_hash}->{ $child->name };

  $self->{children_hash}->{ $child->name } = $child;
  @{ $self->{children} } = ( $child , @{ $self->{children} } );
  $child->parent( $self );
  $child;

}

sub add_at {
  my ( $self , $child , $position ) = @_;
  croak "Child already added" if $self->{children_hash}->{ $child->name };

  $self->{children_hash}->{ $child->name } = $child;
  splice @{ $self->{children} } , $position , 0 , $child;
  $child->parent( $self );
  $child;

}

sub add_last {
  my ( $self , $child ) = @_;
  croak "Child already added" if $self->{children_hash}->{ $child->name };

  $self->{children_hash}->{ $child->name } = $child;
  push @{ $self->{children} } , $child;
  $self->{last_items_count} += 1;
  $child->parent( $self );
  $child;

}

sub add {
  my ( $self , $child ) = @_;
  croak "Child already added" if $self->{children_hash}->{ $child->name };

  $self->{children_hash}->{ $child->name } = $child;
  my $size = @{ $self->{children} } ;
  my $position = $size - $self->last_items_count;
  splice @{ $self->{children} } , $position , 0 , $child;
  $child->parent( $self );
  $child;

}

sub remove {
  my ( $self , $child ) = @_;
  
  my $last = @{ $child->{children} };
  $self->{last_items_count} -= 1 if $child && $last;
  $self->SUPER::remove( $child );
}

sub position {
  my ( $self ) = @_;
  my $index = 0;
  foreach my $item ( @{ $self->parent->{children} } ){
    return $index if $item ~~ $self;
    $index++;
  }
  undef;
}

package Akoya::MenuManager;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $self , $app ) = @_;
  my $menu_manager = __PACKAGE__->new;
  $app->helper( menu_manager => sub{ $menu_manager; } );
  $app->plugin('Akoya::MenuManager::MenuHelper');
}

sub map {
  my ( $self , $menu_name , $code ) = @_;
  $self->{items} = {} unless defined $self->{items};
  my $mapper = Akoya::MenuManager::Mapper->new( name => $menu_name , items => $self->{items} );
  if( ref( $code ) eq q|CODE| ){
    $code->( $mapper );
  }
  else {
    $mapper;
  }
}

sub items {
  my ( $self , $menu_name ) = @_;
  no strict 'refs';
  $self->{items}->{ $menu_name } || TreeNodePatch->new( 'root' , {} );
}

package Akoya::MenuManager::Mapper;
use Mojo::Base -base;
use Data::Dumper;

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->{items}->{ $self->{name} } = TreeNodePatch->new( 'root' , {} ) unless $self->{items}->{ $self->{name} };
  $self->{menu_items} = $self->{items}->{ $self->{name} };
  $self->{last_items_count} = 0;
  $self;
}

sub push {
  my ( $self , $name , $url , $options ) = @_;
  my $options_dup = $options;

  my $target_root;
  if( $options->{parent} ){
    my $subtree = $self->find( $options->{parent} );
    if( $subtree ){
      $target_root = $subtree;
    }
    else {
      $target_root = $self->{menu_items}->root;
    }
  }
  else {
    $target_root = $self->{menu_items}->root;
  }

  # menu item position
  if( my $first = delete( $options->{first} ) ){
    $target_root->prepend( Akoya::MenuManager::MenuItem->new( name => $name , url => $url, options => $options ) );
  }
  elsif( my $before = delete( $options->{before} ) ){

    if( $self->is_exists( $before ) ){
      $target_root->add_at( Akoya::MenuManager::MenuItem->new( name => $name , url => $url, options => $options ) , $self->position_of( $before ) );
    }
    else {
      $target_root->add( Akoya::MenuManager::MenuItem->new( name => $name , url => $url , options => $options ) );
    }
  }
  elsif( my $after = delete( $options->{after} ) ){

    if( $self->is_exists( $after ) ){
      $target_root->add_at( Akoya::MenuManager::MenuItem->new( name => $name , url => $url , options => $options ), $self->position_of( $after ) + 1 );
    }
    else {
      $target_root->add( Akoya::MenuManager::MenuItem->new( name => $name , url => $url , options => $options ) );
    }
  }
  elsif( $options->{last} ){ # don't delete, needs to be stored
    $target_root->add_last( Akoya::MenuManager::MenuItem->new( name => $name , url => $url , options => $options ) );
  }
  else {
    $target_root->add( Akoya::MenuManager::MenuItem->new( name => $name , url => $url , options => $options ) );
  }
}

sub delete {
  my ( $self , $name ) = @_;
  if( my $found = $self->find( $name ) ){
    $self->{menu_items}->remove( $found );
  }
}

sub is_exists {
  my ( $self , $name ) = @_;
  foreach my $node ( $self->{menu_items}->children ){
    return 1 if $node->name eq $name;
  }
  0;
}

sub find {
  my ( $self , $name ) = @_;
  foreach my $node ( $self->{menu_items}->children ){
    return $node if $node->name eq $name;
  }
  0;
}

sub position_of {
  my ( $self , $name ) = @_;
  foreach my $node ( $self->{menu_items}->children ){
    if( $node->name eq $name ){
      return $node->position;
    }
  }
}

package Akoya::MenuManager::MenuItem;
use Mojo::Base 'TreeNodePatch';
use Mojo::ByteStream 'b';
use Carp;
use Data::Dumper;

has [qw/name url param condition parent child_menus last/];

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->{options}->{parent} ||= "";
  croak "ArgumentError Invalid option if for menu item '$self->name'" if $self->{options}->{if} && ref( $self->{options}->{if} ) ne q|CODE|;
  croak "ArgumentError Invalid option html for menu item '$self->name'" if $self->{options}->{html} && ref( $self->{options}->{html} ) ne q|HASH|;
  croak "ArgumentError Cannot set the parent to be the same as this item" if $self->{options}->{parent} eq $self->name;
  croak "ArgumentError Invalid option children for menu item '$self->name'" if $self->{options}->{children} && ref( $self->{options}->{children} ) eq q|CODE|;
  $self->condition( $self->{options}->{if} );
  $self->param( $self->{options}->{param} || 'id' );
  $self->{caption} = $self->{options}->{caption};
  $self->{html_options} = $self->{options}->{html} || {};
  # Adds a unique class to each menu item based on its name
  $self->{html_options}->{class} = "" unless defined $self->{html_options}->{class};
  $self->{html_options}->{class} = join( ' ' , $self->{html_options}->{class} , b( $self->name )->decamelize->to_string );
  $self->parent( $self->{options}->{parent} );
  $self->child_menus( $self->{options}->{children} );
  $self->last( $self->{options}->{last} || 0 );
  $self;
}

sub caption {
  my ( $self , $controller , $project ) = @_;
  if( ref( $self->{caption} ) eq q|CODE| ){
    my $c = $self->{caption}->( $project );
    $c = $self->name if ! $c;
    return $c;
  }
  else {
    if( ! $self->{caption} ){
      $controller->l_or_humanize( $self->name, { prefix => 'label_' } );
    }
    else {
      #$self->{caption} eq 'SCALAR' ? $controller->l( $self->{caption} ) : $self->{caption};
      $controller->l( $self->{caption} );
    }
  }
}

sub html_options {
  my ( $self , $options ) = @_;
  if( $options->{selected} ){
    my $o = $self->{html_options};
    $o->{class} = ' selected';
    return $o;
  }
  else {
    $self->{html_options};
  }
}

package Akoya::MenuManager::MenuController;
use Mojo::Base -base;

has 'menu_items';

sub new {
  my $self = shift->SUPER::new( @_ );
  $self->{menu_items} = {};
  $self; 
}

sub menu_item {
  my ( $self , $id , $options ) = @_;
  if( push my @actions , $options->{only} ){
    foreach my $aa ( @actions ){
      $self->{menu_items}->{controller_name}->{actions}->{$aa} = $id;
    }
  }
  else{
    $self->{menu_items}->{controller_name}->{default} = $id;
  }
}

sub menu_items {
  shift->{menu_items};
}

sub current_menu_item {
  my ( $self ) = @_;
  $self->{current_menu_item} ||= $self->{menu_items}->{controller_name}->{actions}->{action_name} ||
                                 $self->{menu_items}->{controller_name}->{default};
  $self->{current_menu_item};
}

sub redirect_to_project_menu_item {
  my ( $self , $project , $name) = @_;
  my $item;
  foreach my $i ( Akoya::MenuManager->items('project_menu') ){
    if( $i->name eq $name ){ $item = $i; last; }
  }

  if( $item && user->current->is_allowed_to($item->url, $project ) && ( ! $item->condition || $item->condition->call( $project ) ) ) {
    $item->param( $project );
    redirect_to( $item );
    return 1;
  }
  0;
}

package Akoya::MenuManager::MenuHelper;
use feature 'switch';
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Carp;

sub register {
  my ( $self , $app ) = @_;

  $app->helper( current_menu_item => sub{
    my ( $c ) = @_;
    $c->stash('current_menu_item'); #->current_menu_item;
  } );

  $app->helper( render_main_menu => sub{
    my ( $c  , $project ) = @_;
    $c->render_menu( ( $project && !$project->is_new_record ) ? 'project_menu' : ( 'application_menu' , $project) );
  } );

  $app->helper( is_display_main_menu => sub{
    my ( $c , $project ) = @_;
    my $menu_name = $project && !$project->is_new_record ? 'project_menu' : 'application_menu';
    $c->menu_manager->items( $menu_name ) > 1;
  } );

  $app->helper( render_menu => sub{
    my ( $c , $menu , $project ) = @_;
    my @links;
    foreach my $node ( $c->menu_items_for( $menu, $project ) ){
      push @links , $c->render_menu_node( $node, $project );
    }
#    ! @links ? undef : b( b( $c->tag( ul => join( '' , map { $c->link_to( $_ ) . "\n" } @links ) ) )->html_unescape )->html_unescape;
    ! @links ? undef : b( b( $c->tag( ul => join( '' , @links ) ) )->html_unescape )->html_unescape;
  } );

  $app->helper( render_menu_node => sub{
    my ( $c , $node , $project ) = @_;
    if( $node->has_children || ! $node->child_menus ){
      return $c->render_menu_node_with_children( $node, $project );
    }
    else{
      my( $caption , $url , $selected ) = $c->extract_node_details( $node , $project );
      return $c->tag( 'li', $c->render_single_menu_node( $node, $caption, $url, $selected) );
    }
  } );

  $app->helper( render_menu_node_with_children => sub{
    my ( $c , $node, $project ) = @_;
    my( $caption , $url , $selected ) = $c->extract_node_details( $node , $project );

    my $html = "";
    $html .= '<li>';
    $html .= $c->render_single_menu_node( $node, $caption, $url, $selected);
    my $standard_children_list = do {
      my $child_html;
      foreach my $child ( $node->children ){
        $child_html .= $c->render_menu_node( $child, $project );
      };
      $child_html;
    };

    $html .= $c->tag( ul => ( $standard_children_list ) => ( class => 'menu-children' ) ) if $standard_children_list;

    my $unattached_children_list = $c->render_unattached_children_menu( $node, $project );
    $html .= $c->tag( ul => ( $unattached_children_list ) => ( class => 'menu-children unattached' ) ) if $unattached_children_list;

    $html .= '</li>';

    return $html . "\n";
  } );

  $app->helper( render_unattached_children_menu => sub{
    my ( $c , $node , $project ) = @_;
    return undef unless $node->child_menus;

    my $child_html = "";
    my @unattached_children = $node->child_menus->call( $project );
    foreach my $child( @unattached_children ){
      $child_html .= $c->tag( li => $c->render_unattached_menu_item( $child, $project ) );
    }
    $child_html;
  } );

  $app->helper( render_single_menu_node => sub {
    my ( $c , $item , $caption , $url , $selected ) = @_;
    $item->{selected} = $selected if $selected;
    $c->link_to( "$caption" => $url => ( $item->html_options ) );
  } );

  $app->helper( render_unattached_menu_item => sub {
    my ( $c , $menu_item , $project ) = @_;
    croak "MenuError child_menus must be an array of Akoya::MenuManager::MenuItems" unless ref( $menu_item ) eq "Akoya::MenuManager::MenuItem";

    if( $c->user->current->is_allowed_to( $menu_item->url , $project ) ){
      $c->link_to( $menu_item->caption( $c , $project ) ,
               $menu_item->url,
               $menu_item->html_options );
    }
  } );

  $app->helper( menu_items_for => sub {
    my ( $c , $menu , $project ) = @_;
    my @items = ();
    my $allowed;
    foreach my $node ( $c->menu_manager->items( $menu )->root->children ){
      if( $allowed = $c->is_allowed_node( $node, $c->user->current , $project ) ){
        if( ref( $allowed ) eq q|CODE| ){
          push @items , $node if $allowed->( $node );
        }
        else{
          push @items , $node;
        }
      }
    }
    return @items;
  } );

  $app->helper( extract_node_details => sub {
    my ( $c , $node , $project ) = @_;
    my $item = $node;
    my $url;
    given( ref( $item->url ) ){
      when( q|HASH| ){
        if( $project ){
          $url = $item->{param} = $project . $item->url;
        }
        else {
          $url = $c->url_for( $item->url->{controller} . "/" . $item->url->{action} )->to_string;
        }
      }
      when( q|Mojo::URL| ){
        $url = $item->url->to_string;
      }
      when( q|CODE| ){
        $url = $item->url->( $c );
      }
      default {
        $url = $item->url;
      }
    }
    my $caption = $item->caption( $c , $project );
    return ( $caption , $url , ( $c->current_menu_item || '' ) eq $item->name );
  } );

  $app->helper( is_allowed_node => sub {
    my ( $c , $node , $user , $project ) = @_;
    if( $node->condition && ! $node->condition->( $c , $project ) ){
      return 0;
    }

    if( $project ){
      return $c->user && $user->is_allowed_to( $node->url , $project );
    }
    else {
      return 1;
    }
  } );

}
       
1;