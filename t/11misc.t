print "1..2\n";

use Graph vertices_unsorted => 1;

my $g = Graph->new;
$g->add_vertices(1..10);

# One in 3.6 million will fail this test...
print "ok 1\n" unless join(",",$g->vertices) eq "0,1,2,3,4,5,6,7,8,9";

eval 'use Graph foobar => 1';
print "ok 2\n" if $@ =~ /Unknown attributes: 'foobar'/;

