use Test::More tests => 22;

use Graph;
use Graph::AdjacencyMap::Heavy;

sub _REF () { Graph::AdjacencyMap::Heavy::_REF }

use Math::Complex;

my $t = [1, 2];
my $u = bless { 3, 4 }, "Ubu";
my $v = cplx(3, 4);
my $z = cplx(4, 5);

my $m1 = Graph::AdjacencyMap::Heavy->_new(_REF, 1);
my $m2 = Graph::AdjacencyMap::Heavy->_new(_REF, 2);

ok( $m1->set_path($t) );
my @m1 = $m1->_get_id_path( $m1->_get_path_id($t) );
is( $m1[0], $t );

ok( $m2->set_path($u, $v) );
my @m2 = $m2->_get_id_path( $m2->_get_path_id($u, $v) );
is( $m2[0], $u );
ok( $m2[1] == $v );		# is() doesn't work.
ok( $m2[1] ** 2 == $v ** 2 );	# is() doesn't work.

my $g = Graph->new(refvertexed => 1);

$g->add_vertex($v);
$g->add_edge($v, $z);

my @V = sort { $a->sqrt <=> $b->sqrt } $g->vertices;

is($V[0]->Re, 3);
is($V[0]->Im, 4);
is($V[1]->Re, 4);
is($V[1]->Im, 5);

ok($g->has_vertex($v));
ok($g->has_vertex($z));
ok($g->has_edge($v, $z));

$v->Re(7);
$z->Im(8);

ok($g->has_vertex($v));
ok($g->has_vertex($z));

@V = sort { $a->sqrt <=> $b->sqrt } $g->vertices;

is($V[0]->Re, 4);
is($V[0]->Im, 8);
is($V[1]->Re, 7);
is($V[1]->Im, 4);

my $x = cplx(1,2);
my $y = cplx(3,4);
$g = Graph->new(refvertexed => 1);
$g->add_edge($x,$y);
my @e = $g->edges;
is("@{$e[0]}", "1+2i 3+4i");
$x->Im(5);
is("@{$e[0]}", "1+5i 3+4i");
$e[0]->[1]->Im(6);
is("$y", "3+6i");
