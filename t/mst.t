use Graph::Undirected;

print "1..4\n";

my $g1 = Graph::Undirected->new;

$g1->add_Weight_path(qw(a 4 b 1 c 2 f 3 i 2 h 1 g 2 d 1 a));
$g1->add_Weight_path(qw(a 3 e 6 i));
$g1->add_Weight_path(qw(d 1 e 2 f));
$g1->add_Weight_path(qw(b 2 e 5 h));
$g1->add_Weight_path(qw(e 1 g));
$g1->add_Weight_path(qw(b 1 f));

# These Prim MST orderings come from Heap::Fibonacci.
# Some other heap might order the edges differently.

print "not " unless $g1->MST_kruskal eq
                    "a=d,b=c,b=e,b=f,d=e,e=g,g=h,h=i";

print "ok 1\n";

print "not " unless $g1->MST_prim("a") eq
                    "a=d,b=c,b=c,b=f,d=e,e=g,g=h,h=i";

print "ok 2\n";

$g1->delete_path(qw(e i));
$g1->add_Weight_path(qw(e 2 i));

print "not " unless $g1->MST_kruskal eq
                    "a=d,b=c,b=f,d=e,e=f,e=g,g=h,h=i";

print "ok 3\n";

print "not " unless $g1->MST_prim("a") eq
                    "a=d,b=c,b=c,b=f,d=e,e=g,e=i,g=h";

print "ok 4\n";

