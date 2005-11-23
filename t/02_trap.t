use Test::More tests => 2;

use Graph;

isnt($SIG{__DIE__},  \&Graph::CarpConfess, '$SIG{__DIE__}' );
isnt($SIG{__WARN__}, \&Graph::CarpConfess, '$SIG{__WARN__}');




