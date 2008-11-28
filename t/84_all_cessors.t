use Test::More tests => 105;

use Graph::Directed;
use Graph::Undirected;

{
    my $d0  = Graph::Directed->new;
    my $d1  = Graph::Directed->new;
    my $d2a = Graph::Directed->new;
    my $d2b = Graph::Directed->new;
    my $d2c = Graph::Directed->new;
    my $d3  = Graph::Directed->new;
    $d1->add_vertex('a');
    $d2a->add_vertices('a', 'b');
    $d2b->add_edge('a', 'b');
    $d2c->add_edge('a', 'b');
    $d2c->add_edge('b', 'a');
    $d3->add_edge('a', 'b');
    $d3->add_edge('a', 'c');
    $d3->add_edge('b', 'd');
    $d3->add_edge('b', 'e');
    $d3->add_edge('c', 'f');
    $d3->add_edge('c', 'g');

    is("@{[sort $d0->successors('a')]}",    "");
    is("@{[sort $d1->successors('a')]}",    "");
    is("@{[sort $d2a->successors('a')]}",   "");
    is("@{[sort $d2a->successors('b')]}",   "");
    is("@{[sort $d2b->successors('a')]}",   "b");
    is("@{[sort $d2b->successors('b')]}",   "");
    is("@{[sort $d2c->successors('a')]}",   "b");
    is("@{[sort $d2c->successors('b')]}",   "a");
    is("@{[sort $d3->successors('a')]}",    "b c");
    is("@{[sort $d3->successors('b')]}",    "d e");
    is("@{[sort $d3->successors('c')]}",    "f g");
    is("@{[sort $d3->successors('d')]}",    "");
    is("@{[sort $d3->successors('e')]}",    "");
    is("@{[sort $d3->successors('f')]}",    "");
    is("@{[sort $d3->successors('g')]}",    "");

    is("@{[sort $d0->all_successors('a')]}",    "");
    is("@{[sort $d1->all_successors('a')]}",    "");
    is("@{[sort $d2a->all_successors('a')]}",   "");
    is("@{[sort $d2a->all_successors('b')]}",   "");
    is("@{[sort $d2b->all_successors('a')]}",   "b");
    is("@{[sort $d2b->all_successors('b')]}",   "");
    is("@{[sort $d2c->all_successors('a')]}",   "b");
    is("@{[sort $d2c->all_successors('b')]}",   "a");
    is("@{[sort $d3->all_successors('a')]}",    "b c d e f g");
    is("@{[sort $d3->all_successors('b')]}",    "d e");
    is("@{[sort $d3->all_successors('c')]}",    "f g");
    is("@{[sort $d3->all_successors('d')]}",    "");
    is("@{[sort $d3->all_successors('e')]}",    "");
    is("@{[sort $d3->all_successors('f')]}",    "");
    is("@{[sort $d3->all_successors('g')]}",    "");

    is("@{[sort $d0->predecessors('a')]}",    "");
    is("@{[sort $d1->predecessors('a')]}",    "");
    is("@{[sort $d2a->predecessors('a')]}",   "");
    is("@{[sort $d2a->predecessors('b')]}",   "");
    is("@{[sort $d2b->predecessors('a')]}",   "");
    is("@{[sort $d2b->predecessors('b')]}",   "a");
    is("@{[sort $d2c->predecessors('a')]}",   "b");
    is("@{[sort $d2c->predecessors('b')]}",   "a");
    is("@{[sort $d3->predecessors('a')]}",    "");
    is("@{[sort $d3->predecessors('b')]}",    "a");
    is("@{[sort $d3->predecessors('c')]}",    "a");
    is("@{[sort $d3->predecessors('d')]}",    "b");
    is("@{[sort $d3->predecessors('e')]}",    "b");
    is("@{[sort $d3->predecessors('f')]}",    "c");
    is("@{[sort $d3->predecessors('g')]}",    "c");

    is("@{[sort $d0->all_predecessors('a')]}",    "");
    is("@{[sort $d1->all_predecessors('a')]}",    "");
    is("@{[sort $d2a->all_predecessors('a')]}",   "");
    is("@{[sort $d2a->all_predecessors('b')]}",   "");
    is("@{[sort $d2b->all_predecessors('a')]}",   "");
    is("@{[sort $d2b->all_predecessors('b')]}",   "a");
    is("@{[sort $d2c->all_predecessors('a')]}",   "b");
    is("@{[sort $d2c->all_predecessors('b')]}",   "a");
    is("@{[sort $d3->all_predecessors('a')]}",    "");
    is("@{[sort $d3->all_predecessors('b')]}",    "a");
    is("@{[sort $d3->all_predecessors('c')]}",    "a");
    is("@{[sort $d3->all_predecessors('d')]}",    "a b");
    is("@{[sort $d3->all_predecessors('e')]}",    "a b");
    is("@{[sort $d3->all_predecessors('f')]}",    "a c");
    is("@{[sort $d3->all_predecessors('g')]}",    "a c");
}

{
    my $u0  = Graph::Undirected->new;
    my $u1  = Graph::Undirected->new;
    my $u2a = Graph::Undirected->new;
    my $u2b = Graph::Undirected->new;
    my $u2c = Graph::Undirected->new;
    my $u3  = Graph::Undirected->new;
    $u1->add_vertex('a');
    $u2a->add_vertices('a', 'b');
    $u2b->add_edge('a', 'b');
    $u2c->add_edge('a', 'b');
    $u2c->add_edge('b', 'a');
    $u3->add_edge('a', 'b');
    $u3->add_edge('a', 'c');
    $u3->add_edge('b', 'd');
    $u3->add_edge('b', 'e');
    $u3->add_edge('c', 'f');
    $u3->add_edge('c', 'g');

    is("@{[sort $u0->successors('a')]}",    "");
    is("@{[sort $u1->successors('a')]}",    "");
    is("@{[sort $u2a->successors('a')]}",   "");
    is("@{[sort $u2a->successors('b')]}",   "");
    is("@{[sort $u2b->successors('a')]}",   "b");
    is("@{[sort $u2b->successors('b')]}",   "a");
    is("@{[sort $u2c->successors('a')]}",   "b");
    is("@{[sort $u2c->successors('b')]}",   "a");
    is("@{[sort $u3->successors('a')]}",    "b c");
    is("@{[sort $u3->successors('b')]}",    "a d e");
    is("@{[sort $u3->successors('c')]}",    "a f g");
    is("@{[sort $u3->successors('d')]}",    "b");
    is("@{[sort $u3->successors('e')]}",    "b");
    is("@{[sort $u3->successors('f')]}",    "c");
    is("@{[sort $u3->successors('g')]}",    "c");

    is("@{[sort $u0->predecessors('a')]}",    "");
    is("@{[sort $u1->predecessors('a')]}",    "");
    is("@{[sort $u2a->predecessors('a')]}",   "");
    is("@{[sort $u2a->predecessors('b')]}",   "");
    is("@{[sort $u2b->predecessors('a')]}",   "b");
    is("@{[sort $u2b->predecessors('b')]}",   "a");
    is("@{[sort $u2c->predecessors('a')]}",   "b");
    is("@{[sort $u2c->predecessors('b')]}",   "a");
    is("@{[sort $u3->predecessors('a')]}",    "b c");
    is("@{[sort $u3->predecessors('b')]}",    "a d e");
    is("@{[sort $u3->predecessors('c')]}",    "a f g");
    is("@{[sort $u3->predecessors('d')]}",    "b");
    is("@{[sort $u3->predecessors('e')]}",    "b");
    is("@{[sort $u3->predecessors('f')]}",    "c");
    is("@{[sort $u3->predecessors('g')]}",    "c");

    is("@{[sort $u0->all_neighbours('a')]}",    "");
    is("@{[sort $u1->all_neighbours('a')]}",    "");
    is("@{[sort $u2a->all_neighbours('a')]}",   "");
    is("@{[sort $u2a->all_neighbours('b')]}",   "");
    is("@{[sort $u2b->all_neighbours('a')]}",   "b");
    is("@{[sort $u2b->all_neighbours('b')]}",   "a");
    is("@{[sort $u2c->all_neighbours('a')]}",   "b");
    is("@{[sort $u2c->all_neighbours('b')]}",   "a");
    is("@{[sort $u3->all_neighbours('a')]}",    "b c d e f g");
    is("@{[sort $u3->all_neighbours('b')]}",    "a c d e f g");
    is("@{[sort $u3->all_neighbours('c')]}",    "a b d e f g");
    is("@{[sort $u3->all_neighbours('d')]}",    "a b c e f g");
    is("@{[sort $u3->all_neighbours('e')]}",    "a b c d f g");
    is("@{[sort $u3->all_neighbours('f')]}",    "a b c d e g");
    is("@{[sort $u3->all_neighbours('g')]}",    "a b c d e f");
}

