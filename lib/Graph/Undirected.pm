package Graph::Undirected;

use Graph;
use base 'Graph';

sub new {
    my $class = shift;
    bless Graph->new(undirected => 1, @_), ref $class || $class;
}

1;
