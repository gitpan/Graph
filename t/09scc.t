use Graph::Directed;
my $g = Graph::Directed->new();

print "1..5\n";

my @scc;

$g->add_edges( qw|a b|);

@scc = sort $g->strongly_connected_graph;
print "ok 1\n" if @scc == 1 && $scc[0] eq 'a-b';

$g->add_edges( qw|b a|);
@scc = sort $g->strongly_connected_graph;
print "ok 2\n" if @scc == 1 && $scc[0] eq 'a+b';

$g = new Graph::Directed;
$g->add_vertex("a");
$g->add_vertex("b");
$g->add_vertex("c");
$g->add_edge("a","c");
$g->add_edge("b","c");
$g->add_edge("c","a");
@scc = $g->strongly_connected_components;
print "ok 3\n" if @scc == 2;

$g = new Graph::Directed;
$g->add_edge(qw(g c));
$g->add_edge(qw(e b));
$g->add_edge(qw(a d));
$g->add_path(qw(b c f));
$g->add_path(qw(c b h));

@scc = $g->strongly_connected_components();
print "ok 4\n" if @scc == 7;

my @sccv = $g->strongly_connected_graph->vertices;
print "ok 5\n" if grep { $_ eq 'b+c' || $_ eq 'c+b' } @sccv;







