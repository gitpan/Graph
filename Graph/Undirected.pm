package Graph::Undirected;

=pod

=head1 NAME

Graph::Undirected - undirected graphs

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 VERSION

Version 0.01.

=head1 AUTHOR

Jarkko Hietaniemi, <F<jhi@iki.fi>>

=head1 COPYRIGHT

Copyright 1998, O'Reilly & Associates.

This code is distributed under the same copyright terms as perl itself.

=cut

# This class is syntactic sweetener.
#
# Everything except the constructor method is inherited from the
# Graph::_element and Graph classes.

use strict;
use Carp 'confess';
use vars qw(@ISA);

use Graph;

@ISA = qw(Graph::_element Graph);

# new($type, $id)
#   The constructor.
#   Otherwise identical to the Graph class except
#   all the resulting graphs are automatically undirected
#   (the default of Graph->new being a directed graph).
#

sub new {
    shift; # Throw away the 'Graph::Undirected'.

    my $new = Graph->new( @_ );

    $new->undirected( 1 );

    return $new;
}

1;
