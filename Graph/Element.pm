package Graph::Element;

# $Id: Element.pm,v 1.1 1998/06/30 07:16:56 jhi Exp jhi $

=pod

=head1 NAME

Graph::Element - a base class for all things graph

=head1 SYNOPSIS

B<Not to be used directly>.

=head1 DESCRIPTION

This class is a base class for all the graph elements: vertices,
edges, and the graphs themselves.

Though largely this class is for internal use only and will bite
viciously if approached by strangers it does provide some public
methods.

=cut

use strict;
local $^W = 1;

use vars qw($AUTOLOAD %_BY_SELF %_BY_NAME $debug @EXPORT_OK);

@EXPORT_OK = qw(debug);

use Carp 'confess';

=pod

=head1 METHODS

	$name = $element->name;

Get the current name of the element.  Vertices always have names
(they are I<defined> by their names), edges and graphs not necessarily.

	$element->name($new_name);

Set the name of the element.

=cut

sub name ($;$) {
    if ( @_ == 1 ) {
	return $_BY_SELF{ $_[0]->_id };
    } elsif ( @_ == 2 ) {
	if ( exists $_BY_NAME{ $_[1] }->{ $_[0]->_id } ) {
	    warn "$_[0] already named '$_BY_SELF{ $_[1] }->{ $_[0]->_id }'.\n";
	} else {
	    $_BY_SELF{ $_[0]->_id } = $_[1];
	    $_BY_NAME{ $_[1] }->{ $_[0]->_id } = $_[1];
	}
    } 
}

my $debug = 0;

sub debug (@) {
    if ( @_ ) {
	if ( $_[0] =~ /^[01]$/ ) {
	    $debug = shift;
	} elsif ( $debug ) {
	    print @_, "\n";
	}
    } else {
	return $debug;
    }
}

sub _new ($;$) {
    my $class = shift;
    my $name  = shift;

    my $new = { };

    my $id = "$new"; # Before the bless(), before the "" overload.

    debug "_new Element $class=$new, ID = $id, NAME = ",
          defined $name ? $name : '*UNDEF*';

    bless $new, $class;

    $new->_id( $id );

    if ( defined $name ) {
	$_BY_SELF{ $new->_id  } = $name;
	$_BY_NAME{ $name }->{ $new->_id } = $new;
    }

    return $new;
}

sub _delete {
    my $self = shift;

    debug "_delete Element $self";

    if ( exists $_BY_SELF{ $self->_id } ) {
	delete $_BY_NAME{ $_BY_SELF{ $self->_id } }->{ $self->_id };
	delete $_BY_SELF{ $self->_id };
    }

    my %a = $self->_attributes;

    foreach my $a ( keys %a ) {
       $self->delete_attribute( $a )
	   unless $a eq '_id'; # Leave this for later.
    }
}

sub _add_to_graph ($$$;$) {
    my ( $self, $graph, $element, $name ) = @_;

    $graph->{ $element }->{ $self->_id } = $self;

    $graph->{ _BY_NAME }->{ $element }->{ $name } = $self if defined $name;
}

sub _delete_from_graph ($$$;$) {
    my ( $graph, $self, $element ) = @_;

    my $existed = exists $graph->{ $element }->{ $self->_id };

    delete $graph->{ $element }->{ $self->_id };

    delete $graph->{ _BY_NAME }->{ $element }->{ $self->name }
        if defined $self->name;

    return $existed;
}

=pod

=head1 VIRTUAL METHODS

This class also implements a L<virtual method> for all the graph
elements: if an unknown method is invoked on an element, it is assumed
to be an attribute get/set method from then onwards.  For example:

	$graph->yabadabadoo('fred');
	$flintstone = $graph->yabadabadoo;
	
C<$flintstone> will be now C<'fred'>.  This feature is both very
comfortable and very uncomfortable: no need to separately
define methods -- and a pain in nether parts if you are prone to
typos.

=head1 ATTRIBUTE METHODS

If you want to play safe with the attributes (as opposed to the
virtual attribute methods), you must use explicit language:

	$attribute_value = $element->attribute($attribute_name);

Get the attribute of the element.

	$element->attribute($attribute_name, $attribute_value);

Set the attribute of the element.

=cut

sub attribute ($$;@) {
    my $self = shift;

    if ( @_ == 2 ) {		# Set attribute.
	$self->{ _ATTRIBUTE }->{ $_[0] } = $_[1];
    } elsif ( @_ == 1 ) {	# Get attribute.
	return $self->{ _ATTRIBUTE }->{ $_[0] };
    } else {			# Unknown operation.
	die "$self->attribute: called with ",
	    scalar @_, " arguments, wants 1 or 2.\n";
    }
}

sub _attributes {
    my $self = shift;

    return %{ $self->{ _ATTRIBUTE } };
}

=pod

	$element->delete_attribute($attribute_name);

Delete the attribute of the element.  You can also

	$element->attribute($attribute_name, undef)

but that doesn't really get rid of the attribute, the C<has_attribute>
method will still find the attribute, but after C<delete_attribute>
even that will fail.

=cut

sub delete_attribute ($$) {
    delete $_[0]->{ _ATTRIBUTE }->{ $_[1] };
}

=pod
	$element->delete_attribute($attribute_name);

Tests whether the element has the attribute, regardless of the value
of the attribute.

=cut

sub has_attribute ($$) {
    return exists $_[0]->{ _ATTRIBUTE }->{ $_[1] };
}

# This implements the virtual attribute methods.

sub _virtualise {
    my $attribute_name = shift;

    no strict 'refs';
    
    *$AUTOLOAD = sub ($;@) {
	my $self = shift;
	$self->attribute( $attribute_name, @_ )
    };
    
    goto &$AUTOLOAD; # Rewire.
}

sub AUTOLOAD ($;@) {
    my ( $method ) = ( $AUTOLOAD =~ /::(\w+)$/ );

    # Do not try to print @_ here unles you like deep recursion.
    debug "AUTOLOAD Element ", ref $_[0], " ", $method;

    if ( $method eq 'DESTROY' ) {
	return;
    } else {
	# Either the name has to have uppercase in it in which case it
	# is user code or
	# there must be 'Graph' in the caller stack right above us.
	if ( $method =~ /[A-Z]/
	     or
	     (caller())[0] =~ /^Graph(::(?:Element|Edge))?$/
	     ) {

	    # Temporary assertion.
	    confess "OBSOLETE: $method" if $method =~ /^(edges|successors)$/;

	    _virtualise( $method, @_ );
	} else {
	    confess <<EOW;
AUTOLOAD failed:
user attribute get/set methods must have uppercase letters in
their names: method '$method' does not.  Aborting at
EOW
	}
    }
}

sub DESTROY {
    my $self = shift;

    debug "DESTROY Element $self";
}

=pod

=head1 SEE ALSO

L<Graph>, L<Graph::Directed>, L<Graph::Undirected>.

=head1 VERSION

See L<Graph>.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

1;
