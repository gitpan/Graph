use Graph;

print "1..6\n";

my $g1 = Graph->new;

$g1->add_Weight_path(qw(a 9 b 1 e));
$g1->add_Weight_path(qw(a 1 d 2 g 2 e));
$g1->add_Weight_path(qw(a 3 c 1 f 2 d 2 b));
$g1->add_Weight_path(qw(g 3 f));

my $w1 = $g1->SSSP_dijkstra("a");

print "not " unless $w1 eq
	            "a-c,a-d,b-e,c-f,d-b,d-g";

print "ok 1\n";

my $w2 = $g1->SSSP_dijkstra("c");

print "not " unless $w2 eq "b-e,c-f,d-b,d-g,f-d"
                and $w2->edges(qw(b e))->Weight == 6;

print "ok 2\n";

my $g3 = Graph->new;

$g3->add_Weight_path(qw(a 9 b 1 e));
$g3->add_Weight_path(qw(a 1 d 2 g 2 e));
$g3->add_Weight_path(qw(a 3 c 1 f 2 d 2 b));
$g3->add_Weight_path(qw(g -3 f));

my $w3 = $g3->SSSP_bellman_ford("a");

print "not " unless $w3 eq
	            "a-c,a-d,b-e,d-b,d-g,g-f";

print "ok 3\n";

my $w4 = $g3->SSSP_bellman_ford("c");

print "not " unless $w4 eq "b-e,c-f,d-b,d-g,f-d"
                and $w4->edges(qw(b e))->Weight == 6;

print "ok 4\n";

my $g5 = Graph->new;

$g5->add_Weight_path(qw(a 3 b 2 e -1 f 3 h));
$g5->add_Weight_path(qw(b 1 d 2 f));
$g5->add_Weight_path(qw(d 4 g 2 h));
$g5->add_Weight_path(qw(a 1 c -2 d));
$g5->add_Weight_path(qw(c 3 g));

print "not " unless $g5->SSSP_dag("a") eq "a-b,a-c,b-e,c-d,d-f,d-g,f-h";

print "ok 5\n";

print "not " unless $g5->SSSP_dag("c") eq "c-d,d-f,d-g,f-h";

print "ok 6\n";
