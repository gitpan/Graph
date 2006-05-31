use Test::More tests => 5;

use Graph;
my $g = Graph->new;

ok( $g->add_vertex("a") );
ok( $g->add_vertex("b") );

is( $g->add_vertex("c"), $g );

eval '$g->add_vertex("c", "d")';
like($@,
     qr/Graph::add_vertex: use add_vertices for more than one vertex/);

eval '$g->add_vertex(undef)';
like($@,
     qr/Graph::add_vertex: undef vertex/);


