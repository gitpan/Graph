# Test basic parts.

use Graph::Directed;
use Graph::Undirected;

print "1..44\n";

my $test = 1;

my @v;
my @e;

my $g1 = Graph::Directed->new;

print "not " unless @v == 0;
print "ok ", $test++, "\n";

$g1->add_vertex(qw(a b)); # should ignore b

@v = $g1->vertices;

print "not " unless @v == 1 and $v[0] eq "a";
print "ok ", $test++, "\n";

$g1->add_vertices(qw(b c)); # should not ignore b nor c

@v = sort $g1->vertices;

print "not " unless @v == 3 and "@v" eq "a b c";
print "ok ", $test++, "\n";

$g1->delete_vertex(qw(b c)); # should ignore c

@v = sort $g1->vertices;

print "not " unless @v == 2 and "@v" eq "a c";
print "ok ", $test++, "\n";

$g1->delete_vertices(qw(a c));

@v = sort $g1->vertices;

print "not " unless @v == 0;
print "ok ", $test++, "\n";

$g1->add_edge(qw(a b));

@v = sort $g1->vertices;

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

$g1->add_edge(qw(b c));
$g1->add_edge(qw(a c));
$g1->add_edge(qw(a d));

@v = sort $g1->vertices;
@e = sort $g1->edges;

print "not " unless @v == 4 and "@v" eq "a b c d";
print "ok ", $test++, "\n";

print "not " unless @e == 4 and "@e" eq "a-b a-c a-d b-c";
print "ok ", $test++, "\n";

my $e1 = $g1->edge(qw(a b));

@v = sort $e1->vertices;

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

print "not " unless "@{[$e1->start]}" eq "a";
print "ok ", $test++, "\n";

print "not " unless "@{[$e1->stop]}"  eq "b";
print "ok ", $test++, "\n";

$g1->delete_vertex(qw(b));

@v = sort $g1->vertices;
@e = sort $g1->edges;

print "not " unless @v == 3 and "@v" eq "a c d";
print "ok ", $test++, "\n";

print "not " unless @e == 2 and "@e" eq "a-c a-d";
print "ok ", $test++, "\n";

$g1->delete_edge(qw(a d));

@v = sort $g1->vertices;
@e = sort $g1->edges;

print "not " unless @v == 3 and "@v" eq "a c d";
print "ok ", $test++, "\n";

print "not " unless @e == 1 and "@e" eq "a-c";
print "ok ", $test++, "\n";

$g1->add_edges(qw(a b b c b d));

@v = sort $g1->vertex_successors("a");

print "not " unless @v == 2 and "@v" eq "b c";
print "ok ", $test++, "\n";

@v = sort $g1->vertex_predecessors("c");

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

@v = sort $g1->vertex_successors("d");

print "not " unless @v == 0;
print "ok ", $test++, "\n";

@v = sort $g1->vertex_predecessors("a");

print "not " unless @v == 0;
print "ok ", $test++, "\n";

$g1->delete_edge(qw(a c));

@v = sort $g1->vertex_successors("a");

print "not " unless @v == 1 and "@v" eq "b";
print "ok ", $test++, "\n";

@v = sort $g1->vertex_predecessors("c");

print "not " unless @v == 1 and "@v" eq "b";
print "ok ", $test++, "\n";

@v = sort $g1->connected_vertices;

print "not " unless @v == 4 and "@v" eq "a b c d";
print "ok ", $test++, "\n";

@v = sort $g1->unconnected_vertices;

print "not " unless @v == 0;
print "ok ", $test++, "\n";

$g1->add_vertex(qw(e));

@v = sort $g1->connected_vertices;

print "not " unless @v == 4 and "@v" eq "a b c d";
print "ok ", $test++, "\n";

@v = sort $g1->unconnected_vertices;

print "not " unless @v == 1 and "@v" eq "e";
print "ok ", $test++, "\n";

@v = sort $g1->sink_vertices;

print "not " unless @v == 2 and "@v" eq "c d";
print "ok ", $test++, "\n";

@v = sort $g1->source_vertices;

print "not " unless @v == 1 and "@v" eq "a";
print "ok ", $test++, "\n";

@v = sort $g1->interior_vertices;

print "not " unless @v == 1 and "@v" eq "b";
print "ok ", $test++, "\n";

@v = sort $g1->exterior_vertices;

print "not " unless @v == 3 and "@v" eq "a c d";
print "ok ", $test++, "\n";

$g1->add_edge(qw(f f));

@v = sort $g1->selfloop_vertices;

print "not " unless @v == 1 and "@v" eq "f";
print "ok ", $test++, "\n";

my $g2 = Graph::Undirected->new;

$g2->add_edges(qw(a b b c b d a c));

@v = sort $g2->vertices;
@e = sort $g2->edges;

print "not " unless @v == 4 and "@v" eq "a b c d";
print "ok ", $test++, "\n";

print "not " unless @e == 8 and "@e" eq "a-b a-c b-a b-c b-d c-a c-b d-b";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("a");

print "not " unless @v == 2 and "@v" eq "b c";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("b");

print "not " unless @v == 3 and "@v" eq "a c d";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("c");

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbors("d");

print "not " unless @v == 1 and "@v" eq "b";
print "ok ", $test++, "\n";

$g2->directed(1);

print "not " unless "$g2" eq "a-b,a-c,b-a,b-c,b-d,c-a,c-b,d-b";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("a");

print "not " unless @v == 2 and "@v" eq "b c";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("b");

print "not " unless @v == 3 and "@v" eq "a c d";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbours("c");

print "not " unless @v == 2 and "@v" eq "a b";
print "ok ", $test++, "\n";

@v = sort $g2->vertex_neighbors("d");

print "not " unless @v == 1 and "@v" eq "b";
print "ok ", $test++, "\n";

$g2->directed(0);

print "not " unless "$g2" eq "a=b,a=c,b=c,b=d";
print "ok ", $test++, "\n";

$g2->delete_edge(qw(c a));

print "not " unless "$g2" eq "a=b,b=c,b=d";
print "ok ", $test++, "\n";

$g2->add_edge(qw(c a));

print "not " unless "$g2" eq "a=b,a=c,b=c,b=d";
print "ok ", $test++, "\n";
