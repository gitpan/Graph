use Graph;

print "1..2\n";

my $test = 1;

my $g = Graph->new;

$g->add_edges(qw(a b b c b d d e));

my $w = Graph::DFS->new;

$w->( $g );

my @w;

foreach my $v ( sort $g->vertices ) {
    push @w, join " ", $v, $v->Seen, $v->Done, $v->SeenG, $v->DoneG;
}

print "not " unless @w == 5 and
                    $w[0] eq "a 0 4 0 9" and
                    $w[1] eq "b 1 3 1 8" and
                    $w[2] eq "c 2 0 2 3" and
                    $w[3] eq "d 3 2 4 7" and
                    $w[4] eq "e 4 1 5 6";
print "ok ", $test++, "\n";

my $h = Graph->new;

$h->add_path(qw(a b c a));

$w->( $h );

@w = ();

foreach my $v ( sort $h->vertices ) {
    push @w, join " ", $v, $v->Seen, $v->Done, $v->SeenG, $v->DoneG;
}

print "not " unless @w == 3 and
                    $w[0] eq "a 0 1 0 3" and
                    $w[1] eq "b 1 0 1 2" and
                    $w[2] eq "c 2 2 4 5";
print "ok ", $test++, "\n";
