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

sub to {
    join(" ", sort map { "[" . join(" ", map { ref $_ ? "[@$_]" : $_ } @$_) . "]" } $g->edges_to(@_));
}

is( to("a"), "");
is( to("b"), "[a b] [e b]");
is( to("c"), "[b c]");
is( to("d"), "[c d] [d d]");
is( to("e"), "");
is( to("f"), "[c f]");
is( to("g"), "[c g] [h g]");
is( to("h"), "[g h]");
is( to("x"), "");

