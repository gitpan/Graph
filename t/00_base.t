# Test basic graph creation.

use Graph;
use Graph::Directed;
use Graph::Undirected;

print "1..14\n";

my $test = 1;

my $g1 = new Graph;

print "not " unless ref $g1 eq 'Graph';
print "ok ", $test++, "\n";

print "not " unless $g1->directed;
print "ok ", $test++, "\n";

print "not " if $g1->undirected;
print "ok ", $test++, "\n";

my $g2 = new Graph::Directed;

print "not " unless ref $g2 eq 'Graph::Directed';
print "ok ", $test++, "\n";

print "not " unless $g2->directed;
print "ok ", $test++, "\n";

print "not " if $g2->undirected;
print "ok ", $test++, "\n";

my $g3 = new Graph::Undirected;

print "not " unless ref $g3 eq 'Graph::Undirected';
print "ok ", $test++, "\n";

print "not " if $g3->directed;
print "ok ", $test++, "\n";

print "not " unless $g3->undirected;
print "ok ", $test++, "\n";

use Math::Complex;

print "not " if $g1->has_attribute('Complex');
print "ok ", $test++, "\n";

$g1->Complex(cplx(2,3));

print "not " unless $g1->Complex->stringify_cartesian eq "2+3i";
print "ok ", $test++, "\n";

print "not " unless $g1->has_attribute('Complex');
print "ok ", $test++, "\n";

$g1->delete_attribute('Complex');

print "not " if $g1->has_attribute('Complex');
print "ok ", $test++, "\n";

eval { $g1->should_fail(42) };

print "not " unless $@ =~ /must have uppercase letters/;
print "ok ", $test++, "\n";
