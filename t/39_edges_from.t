use Test::More tests => 9;

use Graph;
my $g = Graph->new;

$g->add_edge("a", "b");
$g->add_edge("b", "c");
$g->add_edge("c", "d");
$g->add_edge("d", "d");
$g->add_edge("e", "b");
$g->add_edge("c", "f");
$g->add_edge("c", "g");
$g->add_edge("g", "h");
$g->add_edge("h", "g");

sub from {
    join(" ", sort map { "[" . join(" ", map { ref $_ ? "[@$_]" : $_ } @$_) . "]" } $g->edges_from(@_));
}

is( from("a"), "[a b]");
is( from("b"), "[b c]");
is( from("c"), "[c d] [c f] [c g]");
is( from("d"), "[d d]");
is( from("e"), "[e b]");
is( from("f"), "");
is( from("g"), "[g h]");
is( from("h"), "[h g]");
is( from("x"), "");

