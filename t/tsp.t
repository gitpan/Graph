use Graph::Undirected;

print "1..2\n";

sub Graph::add_XY_vertex {
    my ( $g, $v, $x, $y ) = @_;
    
    $g->add_vertex( $v );
    $v = $g->vertices( $v );
    $v->X( $x );
    $v->Y( $y );
}

my $g1 = Graph::Undirected->new;

$g1->add_XY_vertex(qw(a 2 0));
$g1->add_XY_vertex(qw(b 0 1));
$g1->add_XY_vertex(qw(c 1 2));
$g1->add_XY_vertex(qw(d 3 3));
$g1->add_XY_vertex(qw(e 4 4));

print "not " unless $g1->TSP_approx_prim eq
                    "a-c,a-e,b-d,c-b,d-e";

print "ok 1\n";

my $g2 = Graph::Undirected->new;

$g2->add_XY_vertex(qw(a 1 0));
$g2->add_XY_vertex(qw(b 3 0));
$g2->add_XY_vertex(qw(c 5 0));
$g2->add_XY_vertex(qw(d 2 1));
$g2->add_XY_vertex(qw(e 4 2));
$g2->add_XY_vertex(qw(f 1 3));
$g2->add_XY_vertex(qw(g 3 3));
$g2->add_XY_vertex(qw(h 0 4));
$g2->add_XY_vertex(qw(i 4 4));
$g2->add_XY_vertex(qw(j 3 5));

print "not " unless $g2->TSP_approx_prim eq
                    "a-f,a-j,b-e,c-g,d-i,e-c,f-h,g-d,h-b,i-j";

print "ok 2\n";

