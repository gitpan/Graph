use Test::More tests => 12;

use Graph;
my $g = Graph->new(hyperedged => 1, hypervertexed => 1);

$g->add_edge("a", "b");
$g->add_edge("b", "a");
$g->add_edge("a", ["b", "c"]);
$g->add_edge(["a", "b"], "c");
$g->add_edge(["c", "d"], "e");
$g->add_edge("d" ,"e");
$g->add_edge(["a", "b", "c"], "d");
$g->add_edge("a", "b", "c");

sub deref {
    my $r = shift;
    ref $r ? "[" . join(" ", map { deref($_) } @$r) . "]" : $_;
}

sub at {
    join(" ", sort map { deref($_) } $g->edges_at(@_));
}

is( at("a"), "[[a b c] d] [[a b] c] [a [b c]] [a b c] [a b] [b a]");
is( at("b"), "[[a b c] d] [[a b] c] [a [b c]] [a b c] [a b] [b a]");
is( at("c"), "[[a b c] d] [[a b] c] [[c d] e] [a [b c]] [a b c]");
is( at("d"), "[[a b c] d] [[c d] e] [d e]");
is( at("e"), "[[c d] e] [d e]");
is( at("x"), "");

is( at("a", "b"), "[[a b c] d] [[a b] c]");
is( at("b", "a"), "[[a b c] d] [[a b] c]");
is( at("a", "c"), "[[a b c] d]");
is( at("a", "d"), "");

is( at("a", "b", "c"), "[[a b c] d]");
is( at("a", "b", "d"), "");

