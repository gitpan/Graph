use Test::More tests => 18;

use Graph;
use Graph::Directed;
use Graph::Undirected;

my $g = Graph::Directed->new;

$g->add_weighted_path("b", 1, "f", 2, "c", 3, "d", 3,
		      "f", 2, "g", 2, "e");
$g->add_weighted_edges("d", "e", 3,
		       "g", "a", 3,
		       "g", "f", 2,
		       "b", "a", 3,
		       "h", "b", 1,
		       "h", "c", 1);

my $u = Graph::Undirected->new;

$u->add_weighted_path("b", 1, "f",
		           2, "c",
		           3, "d",
		           3, "f",
		           2, "g",
		           2, "e");
$u->add_weighted_edges("d", "e", 3,
		       "g", "a", 3,
		       "g", "f", 2,
		       "b", "a", 3,
		       "h", "b", 1,
		       "h", "c", 1);

my $sgb_d = $g->SPT_Dijkstra(first_root => "b");

is( $sgb_d, "b-a,b-f,c-d,f-c,f-g,g-e" );

my $sgb_bf = $g->SPT_Bellman_Ford(first_root => "b");

is( $sgb_bf, "b-a,b-f,c-d,f-c,f-g,g-e" );

my $sgh_d = $g->SPT_Dijkstra(first_root => "h");

is( $sgh_d, "b-a,b-f,c-d,f-g,g-e,h-b,h-c" );

my $sga_d = $g->SPT_Dijkstra(first_root => "a", next_root => undef);

is( $sga_d, '' );

my $sub = $u->SPT_Dijkstra(first_root => "b");

is( $sub, "a=b,b=f,b=h,c=h,d=f,e=g,f=g" );

my $suh = $u->SPT_Dijkstra(first_root => "h");

is( $suh, "a=b,b=f,b=h,c=d,c=h,e=g,f=g" );

my $sua = $u->SPT_Dijkstra(first_root => "a");

print "# sua = $sua\n";

ok( $sua eq "a=b,a=g,b=f,b=h,c=h,d=e,e=g" ||
    $sua eq "a=b,a=g,b=f,b=h,c=h,d=f,e=g" ||
    $sua eq "a=b,a=g,c=f,c=h,d=e,e=g,f=g" ||
    $sua eq "a=b,a=g,c=f,c=h,d=f,e=g,f=g" );

# Sedgewick, Algorithms in C, Third Edition
# Chapter 21, "Shortest Paths", Figure 21.10 (p 282)
my $g2 = Graph::Directed->new;

$g2->add_weighted_edge(qw(0 1 0.41));
$g2->add_weighted_edge(qw(1 2 0.51));
$g2->add_weighted_edge(qw(2 3 0.50));
$g2->add_weighted_edge(qw(4 3 0.36));
$g2->add_weighted_edge(qw(3 5 0.38));
$g2->add_weighted_edge(qw(3 0 0.45));
$g2->add_weighted_edge(qw(0 5 0.29));
$g2->add_weighted_edge(qw(5 4 0.21));
$g2->add_weighted_edge(qw(1 4 0.32));
$g2->add_weighted_edge(qw(4 2 0.22));
$g2->add_weighted_edge(qw(5 1 0.29));

my $s2 = $g2->SPT_Dijkstra(first_root => "0");

is( $s2, "0-1,0-5,4-2,4-3,5-4" );

my $s2_bf = $g2->SPT_Bellman_Ford(first_root => "0");

is( $s2_bf, "0-1,0-5,4-2,4-3,5-4" );

my $g3 = Graph::Directed->new;

$g3->add_weighted_path(qw(a 1 b 2 c 3 d -1 e 4 f));

my $s3_d;

eval '$s3_d = $g3->SPT_Dijkstra(first_root => "a")';

like($@, qr/Graph::SPT_Dijkstra: edge d-e is negative \(-1\)/);

is( $s3_d, undef );

my $s3_bf;

eval '$s3_bf = $g3->SPT_Bellman_Ford(first_root => "a")';

is($@, '');

is( $s3_bf, "a-b,b-c,c-d,d-e,e-f");

$g3->add_weighted_path(qw(b -2 a));

undef $s3_bf;

eval '$s3_bf = $g3->SPT_Bellman_Ford(first_root => "a")';

like($@, qr/Graph::SPT_Bellman_Ford: negative cycle exists/);

is( $s3_bf, undef );

# http://rt.cpan.org/NoAuth/Bug.html?id=516
my $g4 = new Graph::Undirected;

$g4->add_weighted_edge("r1", "l1", 1);

my $d4 = $g4->SSSP_Dijkstra("r1");

is($g4, "l1=r1");
is($d4, "l1=r1");

# Nathan Goodman
my $g5 = Graph::Directed->new;
$g5->add_edge(qw(0 1));
$g5->add_edge(qw(1 2));
my $sg5 = $g5->SPT_Dijkstra(first_root => "0");
is($sg5, "0-1,1-2");

