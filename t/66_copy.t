use Test::More tests => 92;

use Graph::Directed;
use Graph::Undirected;

my $g0 = Graph::Directed->new;
my $g1 = Graph::Undirected->new;
my $g2 = Graph::Directed->new;
my $g3 = Graph::Undirected->new;
my $g4 = Graph::Directed->new;
my $g5 = Graph::Undirected->new;

$g0->add_path(qw(a b c));
$g0->add_path(qw(d b e));

$g1->add_path(qw(a b c));
$g1->add_path(qw(d b e));

$g2->add_path(qw(a b c d));
$g2->add_path(qw(c a));

$g3->add_path(qw(a b c d));
$g3->add_path(qw(c a));

$g4->add_path(qw(a b c));
$g4->add_path(qw(b a));

$g5->add_path(qw(a b c));
$g5->add_path(qw(b a));

my $g0c = $g0->copy;
my $g1c = $g1->copy;
my $g2c = $g2->copy;
my $g3c = $g3->copy;
my $g4c = $g4->copy;
my $g5c = $g5->copy;

is("@{[sort $g0c->successors('a')]}", "b");
is("@{[sort $g0c->successors('b')]}", "c e");
is("@{[sort $g0c->successors('c')]}", "");
is("@{[sort $g0c->successors('d')]}", "b");
is("@{[sort $g0c->successors('e')]}", "");

is("@{[sort $g0c->predecessors('a')]}", "");
is("@{[sort $g0c->predecessors('b')]}", "a d");
is("@{[sort $g0c->predecessors('c')]}", "b");
is("@{[sort $g0c->predecessors('d')]}", "");
is("@{[sort $g0c->predecessors('e')]}", "b");

is("@{[sort $g1c->successors('a')]}", "b");
is("@{[sort $g1c->successors('b')]}", "a c d e");
is("@{[sort $g1c->successors('c')]}", "b");
is("@{[sort $g1c->successors('d')]}", "b");
is("@{[sort $g1c->successors('e')]}", "b");

is("@{[sort $g1c->predecessors('a')]}", "b");
is("@{[sort $g1c->predecessors('b')]}", "a c d e");
is("@{[sort $g1c->predecessors('c')]}", "b");
is("@{[sort $g1c->predecessors('d')]}", "b");
is("@{[sort $g1c->predecessors('e')]}", "b");

is("@{[sort $g2c->successors('a')]}", "b");
is("@{[sort $g2c->successors('b')]}", "c");
is("@{[sort $g2c->successors('c')]}", "a d");
is("@{[sort $g2c->successors('d')]}", "");

is("@{[sort $g2c->predecessors('a')]}", "c");
is("@{[sort $g2c->predecessors('b')]}", "a");
is("@{[sort $g2c->predecessors('c')]}", "b");
is("@{[sort $g2c->predecessors('d')]}", "c");

is("@{[sort $g3c->successors('a')]}", "b c");
is("@{[sort $g3c->successors('b')]}", "a c");
is("@{[sort $g3c->successors('c')]}", "a b d");
is("@{[sort $g3c->successors('d')]}", "c");

is("@{[sort $g3c->predecessors('a')]}", "b c");
is("@{[sort $g3c->predecessors('b')]}", "a c");
is("@{[sort $g3c->predecessors('c')]}", "a b d");
is("@{[sort $g3c->predecessors('d')]}", "c");

is("@{[sort $g4c->successors('a')]}", "b");
is("@{[sort $g4c->successors('b')]}", "a c");
is("@{[sort $g4c->successors('c')]}", "");

is("@{[sort $g4c->predecessors('a')]}", "b");
is("@{[sort $g4c->predecessors('b')]}", "a");
is("@{[sort $g4c->predecessors('c')]}", "b");

is("@{[sort $g5c->successors('a')]}", "b");
is("@{[sort $g5c->successors('b')]}", "a c");
is("@{[sort $g5c->successors('c')]}", "b");

is("@{[sort $g5c->predecessors('a')]}", "b");
is("@{[sort $g5c->predecessors('b')]}", "a c");
is("@{[sort $g5c->predecessors('c')]}", "b");

my $g0u = $g0->undirected_copy;
my $g2u = $g2->undirected_copy;
my $g4u = $g4->undirected_copy;

is($g0u, $g1);
is($g2u, $g3);
is($g4u, $g5);

my $g1d = $g1->directed_copy;
my $g3d = $g3->directed_copy;
my $g5d = $g5->directed_copy;

for my $i ([$g1d, $g1],
	   [$g3d, $g3],
	   [$g5d, $g5]) {
    my ($d, $u) = @$i;
    for my $e ($u->edges) {
	my @e = @$e;
	ok($d->has_edge(@e));
	ok($d->has_edge(reverse @e));
    }
    for my $v ($u->vertices) {
	ok($d->has_vertex($v));
    }
}

{
    my $g = Graph->new;
    $g->set_graph_attribute('color' => 'deep_purple');
    my $c = $g->deep_copy;
    is($c->get_graph_attribute('color'), 'deep_purple');
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->add_graph($h);
    is($g, "0-1,0-2,0-3,2-4,2-5,6,7,8");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->add_graph($h, vertices => 0);
    is($g, "0-1,0-2,0-3,2-4,2-5,6,7");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->add_graph($h, resolve =>
		  sub {
		      my ($g, $h, $u, $v) = @_;
		      @_ == 4 && ($u eq '0') || @_ == 3 ? 1 : 0
		  });
    is($g, "0-1,0-2,0-3,6,7");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->add_graph($h, edges => 0);
    is($g, "0-1,0-2,0-3,4,5,6,7,8");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $g->add_edge(qw(10 11));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->delete_graph($h);
    is($g, "10-11,3,6");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $g->add_edge(qw(10 11));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->delete_graph($h, vertices => 0);
    is($g, "0-2,0-3,10-11,1,6,7");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $g->add_edge(qw(10 11));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->delete_graph($h, edges => 0);
    is($g, "10-11,3,6");
}

{
    my $g = Graph->new;
    my $h = Graph->new;
    $g->add_edges(qw(0 1 0 2 0 3));
    $g->add_vertices(qw(6 7));
    $g->add_edge(qw(10 11));
    $h->add_edges(qw(0 1 2 4 2 5));
    $h->add_vertices(qw(7 8));
    $g->delete_graph($h, resolve =>
		    sub {
		      my ($g, $h, $u, $v) = @_;
		      return @_ == 3 && ($u ne '7') || @_ == 4 ? 1 : 0;
		    } );
    is($g, "10-11,3,6,7");
}
