use Test::More tests => 10;

use Graph;

my $g0 = Graph->new(directed => 1);
my $g1 = Graph->new(directed => 0);
my $g2 = Graph->new(directed => 1);

$g0->add_edge('a', 'b');
$g1->add_edge('a', 'b');
$g2->add_edge('a', 'a');

eval '$g0->expect_undirected';
like($@, qr/expected undirected graph, got directed/);

eval '$g1->expect_undirected';
is($@, '');

eval '$g0->expect_directed';
is($@, '');

eval '$g1->expect_directed';
like($@, qr/expected directed graph, got undirected/);

eval '$g0->expect_acyclic';
is($@, '');

eval '$g1->expect_acyclic';
is($@, '');

eval '$g2->expect_acyclic';
like($@, qr/expected acyclic graph, got cyclic/);

eval '$g0->expect_dag';
is($@, '');

eval '$g1->expect_dag';
like($@, qr/expected directed acyclic graph, got undirected/);

eval '$g2->expect_dag';
like($@, qr/expected directed acyclic graph, got cyclic/);

