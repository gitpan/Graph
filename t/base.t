use Graph;
use Graph::Undirected;

# This should be split into smaller files.

print "1..57\n";

sub T {
    my ( $a, $b ) = @_;
    if ( ( @_ == 2 and defined $a and defined $b and $a . "" ne $b . "" ) or
         ( @_ == 1 and not $a ) or
         ( @_ <  1 or @_ > 2 ) ) {
        print "# got '$a', want '$b'\n" if @_ == 2;
        print "not ";
    }
    $testi = 1 unless defined $testi;
    print "ok ", $testi++;
    print "\n";
}

print "# Graph Creation\n";

my $g1 = Graph->new("z");
T(ref $g1, "Graph");
T($g1->Id, "z");

print "# Graph Attributes\n";

$g1->Id("foo");
T($g1->Id, "foo");

use Math::Complex;
$g1->Complex(cplx(2,3));
T($g1->Complex, "2+3i");

$g1->delete_attr("Complex");
T(not $g1->has_attr("Complex"));
T(not defined $g1->Complex);

T(not defined $g1->Xyzzyzy);

print "# Adding Vertices\n";

$g1->add_vertex("a", "b");
T($g1->has_vertex("b", "a"));
T(not $g1->has_vertex("c"));

print "# Graph Density\n";

$g1->add_edge("a", "b");
$g1->add_edge("a", "c");
$g1->add_edge("b", "c");

T($g1->vertices == 3);
T($g1->edges    == 3);

T($g1->sparse);
T($g1->density, 0.5);

$g1->undirected(1);
T($g1->edges == 3);
T($g1->density, 1);
$g1->directed(1);

print "# Graph Vertex Attributes\n";

$g1->vertices("a")->Size(3);
T($g1->vertices("a")->Size, 3);
T(not defined $g1->vertices("c")->Size);

print "# Graph Edge Attributes\n";

$g1->edges("a","b")->Capacity(7);
T($g1->edges("a","b")->Capacity, 7);
T(not defined $g1->edges("a","c")->Capacity);

print "# Graph Directedness\n";

T($g1, "a-b,a-c,b-c");
$g1->undirected(1);
T($g1, "a=b,a=c,b=c");
$g1->directed(1);

$g1->add_vertex("d");
T($g1, "a-b,a-c,b-c,d");

print "# Edge Deletion\n";

$g1->add_edge("a","d");
$g1->delete_vertex("b");
T($g1, "a-c,a-d");

$g1->delete_edge("a","d");
T($g1, "a-c,d");
$g1->add_edge("b","c");
$g1->add_edge("e","e");
T($g1, "a-c,b-c,d,e-e");

print "# Vertex Classification\n";

T("@{[$g1->source_vertices]}", "a b");
T("@{[$g1->sink_vertices]}",   "c");
T("@{[$g1->self_vertices]}",   "e");
T($g1->vertices("a")->Class, "source");
T($g1->vertices("c")->Class, "sink");

T("@{[$g1->unconnected_vertices]}", "d");
T("@{[$g1->  connected_vertices]}", "a b c e");

my $g2 = Graph->new;

$g2->add_path(qw(a b d));
$g2->add_path(qw(  b e));
$g2->add_path(qw(a c f));
$g2->add_path(qw(  c g));
T($g2, "a-b,a-c,b-d,b-e,c-f,c-g");

print "# Depth-first and Breadth-first\n";

T($g2->depth_first);
T($g2->breadth_first);

my $g3 = Graph->new;

$g3->add_path(qw(a b d e));
$g3->add_path(qw(b e));
$g3->add_path(qw(a e));
$g3->add_path(qw(a c f g c));
$g3->add_path(qw(h i c));
$g3->add_path(qw(h j));
$g3->add_path(qw(i j));
T($g3, "a-b,a-c,a-e,b-d,b-e,c-f,d-e,f-g,g-c,h-i,h-j,i-c,i-j");

T($g3->depth_first);
T($g3->breadth_first);

print "# Edge Classification\n";

# Note: depends a lot on the walk order (which is pseudorandom).
T("@{$g3->classify_edges->{ forward }}", "a-e b-e h-j");
T($g3->edges("b","d")->Class, "tree");
T($g3->edges("c","f")->Class, "tree");
T($g3->edges("g","c")->Class, "back");
# Either a-e or b-e must be a forward edge.
T($g3->edges("a","e")->Class, "forward");
T($g3->edges("i","c")->Class, "cross");

print "# Cyclicity\n";

T($g3->cyclic);

print "# Dagness\n";

T(    $g2->dag);
T(not $g3->dag);

my $g4 = Graph->new;

$g4->add_path("a","b");
$g4->add_path("a","c");

print "# Transpose Graph\n";

T($g4->transpose_graph,"b-a,c-a");
T($g4->transpose_graph->transpose_graph,$g4);

print "# Complete graph\n";

T($g4->complete_graph,"a-b,a-c,b-a,b-c,c-a,c-b");
T(scalar $g4->complete_graph->edges, $g4->vertices*($g4->vertices-1));

print "# Complement Graph\n";

T($g4->complement_graph,"b-a,b-c,c-a,c-b");
T($g4->complement_graph->complement_graph,$g4);

print "# Toposort\n";

T("@{[$g2->topo_sort]}", "a c g f b e d");

print "# Depth-first forest\n";

T($g3->depth_first_forest, "a-b,a-c,b-d,c-f,d-e,f-g,h-i,i-j");

print "# Edge classification\n";

my $g6 = Graph::Undirected->new;

$g6->add_path(qw(a b d e f h g e));
$g6->add_path(qw(a c d));
$g6->add_path(qw(h i));
T($g6,"a=b,a=c,b=d,c=d,d=e,e=f,e=g,f=h,g=h,h=i");

$g6->classify_edges;
T($g6->edges(qw(a b))->Class, "tree");
