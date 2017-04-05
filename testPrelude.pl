#!/usr/bin/perl
use strict;
use Prelude;
use Scalar::Util 'blessed';
$\ = "\n";

my ($procs, $list, $names);
for(@ARGV) {
	match $_
	, -l => sub { $list = 1 }
	, -n => sub { $names = 1 }
	, '' => sub { $procs = $_[0] . ($procs? "|$procs" : ')$') }
}
$procs = '^(' . $procs if $procs;

sub paragraph { "=====================================================================================================\n" }
sub delim { '-----------------------------------------------------------------------------------------------------' }
my $once = 1;
sub demo {
	if($names or $procs) {
		my $procName = $_[0];
		$procName =~ s/ .*//s;
		return if $procs and $procName !~ /$procs/o or $names and print $procName;
	}
	print paragraph unless $once;
	print $_[0] and return if $list;
	print shift, "\n";
	for my $demo (@_) {
		print delim;
		print "> $_" for split /\n/, $demo;
		print '===';
		print "===> " . show eval $demo;
		print $@ if $@
	}
	undef $once
}

demo 'truth EXPR', map "truth $_", qw(undef 0 1), "'abc'", "''", '';
demo 'nil', 'nil', 'scalar nil';
demo 'identity LIST', map(($_, "scalar $_"), map "identity $_", '', '()', 1, 'qw(a b c)');
demo 'unfold BLOCK LIST', <<'UNFOLD';
unfold {
	my $val = $_[0];
	$val * 2 + 2, $val * 4 if $val < 40
} 9
UNFOLD
demo 'match EXPR, EXPR => PROC, ...', map(($_, "scalar $_")
	, 'match 42, 0 => sub { \'Zero\' }, 1 => sub { \'The One\' }'
	, 'match 42, 0 => sub { \'Zero\' }, 1 => sub { \'The One\' }, 42 => sub { \'The\', \'Answer\' }'
	, 'match 42, 0 => sub { \'Zero\' }, 1 => sub { \'The One\' }, \'\' => sub { \'I don\\\'t know\', \'the Answer\', \'but it is\', $_[0] }');
demo 'match1 EXPR, HASHREF, LIST', map(($_, "scalar $_")
	, 'match1 42, %{{0 => sub { "Zero$_[1] ($_[0])" }, 1 => sub { "The Only$_[1] ($_[0])" } }}, \', like\', \', you know\''
	, 'match1 42, %{{0 => sub { "Zero$_[1] ($_[0])" }, 1 => sub { "The Only$_[1] ($_[0])" }, 42 => sub { "The$_[1]", "Answer $_[2] ($_[0])" } }}, \', like\', \', you know\''
	, 'match1 42, %{{0 => sub { "Zero$_[1] ($_[0])" }, 1 => sub { "The Only$_[1] ($_[0])" }, \'\' => sub { "I don\'t know $_[1]", "the Answer$_[2] ($_[0])" } }}, \', like\', \', you know\'');
demo 'pick EXPR, EXPR => EXPR, ...'
, 'pick 42, 0 => \'Zero\', 1 => \'The One\''
, 'scalar pick 42, 0 => \'Zero\', 1 => \'The One\''
, 'pick 42, 0 => \'Zero\', 1 => \'The One\', 42 => \'The Answer\''
, 'pick 42, 0 => \'Zero\', 1 => \'The One\', \'\' => \'I don\\\'t know the Answer\'';
demo 'pick1 EXPR, HASHREF'
, 'pick1 42, %{{0 => \'Zero\', 1 => \'The One\'}}'
, 'scalar pick1 42, %{{0 => \'Zero\', 1 => \'The One\'}}'
, 'pick1 42, %{{0 => \'Zero\', 1 => \'The One\', 42 => \'The Answer\'}}'
, 'pick1 42, %{{0 => \'Zero\', 1 => \'The One\', \'\' => \'I don\\\'t know the Answer\'}}';
demo 'case EXPR, EXPR => EXPR, ...'
, 'case 42, 0 => \'Zero\', 1 => sub { \'The One\' }'
, 'scalar case 42, 0 => \'Zero\', 1 => sub { \'The One\' }'
, 'case 42, 0 => \'Zero\', 1 => \'The One\', 42 => \'The Answer\''
, 'case 42, 0 => \'Zero\', 1 => \'The One\', \'\' => sub { print "Out of range!"; \'I don\\\'t know the Answer\' }';
demo 'case1 EXPR, HASHREF'
, 'case1 42, %{{0 => \'Zero\', 1 => sub { \'The One\' }}}'
, 'scalar case1 42, %{{0 => \'Zero\', 1 => sub { \'The One\' }}}'
, 'case1 42, %{{0 => \'Zero\', 1 => \'The One\', 42 => \'The Answer\'}}'
, 'case1 42, %{{0 => \'Zero\', 1 => \'The One\', \'\' => sub { print "Out of range!"; \'I don\\\'t know the Answer\' }}}';
demo 'lazy BLOCK LIST', <<'LAZY';
my $x = lazy { print "Hello, $_[0]!"; $_[1] + 2 } world => 40;
my $y = lazy { print 'Using $x for $y...'; $x };
print '$x, $y: ' . show $x, $y;
print '--- Now forcing $y';
print '$y: ' . $y->val;
print '$y: ' . $y->val;
print '$x, $y: ' . show $x, $y;
print '--- Now forcing $x';
print '$x: ' . $x->val;
print '$x: ' . $x->val;
print '$x, $y: ' . show $x, $y
LAZY
demo "cond EXPR => PROC\ncond EXPR => PROC, ..., PROC"
, <<'COND'
cond lazy(sub { print 'Zero'; 0 }) => sub { print 'Zero!' }
, lazy(sub { print '42'; 42 }) => sub { print 'The Answer' }
, lazy(sub { print 'This is not printed'; '' }) => sub { print 'This could not happen' }
COND
, <<'COND';
cond 0 => sub { print 'Zero!' }
, lazy(sub { print 'It\'s not 42'; undef }) => sub { print 'There\'s no Answer' }
, lazy(sub { print 'Now this is printed'; '' }) => sub { print 'This could not happen' }
, sub { 'So that is all' }
COND
demo 'zipFor BLOCK EXPR, LIST', 'zipFor { print "$_[0] $_[1]!"; $_[2] } 3, qw(Hello, world 3.141592), \'Here is\', \'the Answer\', 42';
demo 'zipMap BLOCK EXPR, LIST', 'zipMap { "$_[0] $_[1]!", $_[2] } 3, qw(Hello, world 3.141592), \'Here is\', \'the Answer\', 42, qw(OMG LOL)';
demo 'show LIST', 'print show undef, \'\', 1, qw(a b c), [], {}, [qw(a b c)], {a => undef, b => \'\', c => 42, 42 => \'c\'}, \*STDIN', 'show';
demo 'foldl BLOCK EXPR, LIST', <<'FOLDL';
foldl {
	print 'ARGS: ' . show @_;
	my $key = $_[1];
	if($key < 42) {
		print "$key is too small";
		"$_[0] $_[2]"
	}
	else {
		print "I like $key";
		"$_[0] $_[2]", $key
	}
} 3, 0, 1, 2, 3, 4, 42, 43, 44
FOLDL
demo 'foldr BLOCK EXPR, LIST', <<'FOLDR';
foldr {
	print 'ARGS: ' . show @_;
	my $key = $_[1];
	if($key < 42) {
		print "$key is too small";
		"$_[0] $_[2]"
	}
	else {
		print "I like $key";
		$key, "$_[0] $_[2]"
	}
} 3, 44, 43, 42, 4, 3, 2, 1, 0
FOLDR
demo 'shortFoldl BLOCK EXPR, LIST', <<'SHORT_FOLDL';
shortFoldl {
	print 'ARGS: ' . show @_;
	my $key = $_[1];
	if($key =~ /42/) {
		print 'Now I\'ve found the Answer, so I\'m leaving for good.';
		()
	}
	else { $_[0], "and $_[2]" }
} 3, 0, 1, 2, 3, 4, 42, 43, 44
SHORT_FOLDL
demo 'shortFoldr BLOCK EXPR, LIST', <<'SHORT_FOLDR';
shortFoldr {
	print 'ARGS: ' . show @_;
	my $key = $_[1];
	if($key =~ /42/) {
		print 'Now I\'ve found the Answer, so I\'m leaving for good.';
		''
	}
	else { $_[0], "and $_[2]" }
} 3, 44, 43, 42, 4, 3, 2, 1, 0
SHORT_FOLDR
demo 'hash LIST', 'hash a => 1, b => 2';
demo 'array LIST', 'array qw(a b c)';
demo 'mkSet LIST', 'hash mkSet qw(a b c)';
demo 'mkDefSet LIST', 'hash mkDefSet qw(42 a b c)';
demo 'List::nil', 'List::nil';
demo 'List::lazy', <<'LIST_LAZY';
{
	my $l = List::lazy { List::cons lazy{0}, List::lazy {List::cons 1, List::nil}};
	print 'l: ' . show $l;
	print 'head l: ' . show $l->head;
	print 'l: ' . show $l;
}
print '--- Now for the tail';
{
	my $l = List::lazy { List::cons lazy{0}, List::lazy {List::cons 1, List::nil}};
	print 'l: ' . show $l;
	print 'tail l: ' . show $l->tail;
	print 'l: ' . show $l;
	print 'l\'s second element: ' . show $l->tail->head;
	print 'l: ' . show $l;
}
LIST_LAZY
demo 'List::cons', 'List::cons 0, List::nil';
demo 'List::isList', 'List::isList List::nil', 'List::isList 42';
demo 'List::notList', 'List::notList List::nil', 'List::notList 42';
demo 'List::filter'
, '(List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}})->filter(sub { $_[0] % 2 })'
, '(List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}})->filter(sub { $_[0] % 2 })->realize';
demo 'List::map'
, '(List::lazy { List::list 0, List::lazy { List::list 1, 2, 3, 4, 5, 6 } })->map(sub { print "Arg: $_[0]"; $_[0] + 1 })'
, '(List::lazy { List::list 0, List::lazy { List::list 1, 2, 3, 4, 5, 6 } })->map(sub { print "Arg: $_[0]"; $_[0] + 1 })->realize';
demo 'List::concatMap'
, <<'LIST_CONCAT_MAP'
(List::lazy { List::list 0, List::lazy { List::list 1, 2, 3, 4, 5, 6 } })->concatMap(sub {
		my $x = $_[0];
		$x == 2? List::lazy { List::list $x * 100, $x * 10 }
		: $x == 3? List::singleton List::list $x * 1000, $x * 100, $x * 10
		: $x * 0.1 })
LIST_CONCAT_MAP
, <<'LIST_CONCAT_MAP';
(List::lazy { List::list 0, List::lazy { List::list 1, 2, 3, 4, 5, 6 } })->concatMap(sub {
		my $x = $_[0];
		$x == 2? List::lazy { List::list $x * 100, $x * 10 }
		: $x == 3? List::singleton List::list $x * 1000, $x * 100, $x * 10
		: $x * 0.1 })->realize
LIST_CONCAT_MAP
demo 'List::realize', <<'LIST_REALIZE';
print 'The original lazy list: ' . show List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}}};
print 'The same but forced: ' . show((List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}}})->force);
print 'The same but realized: ' . show((List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}}})->realize);
print 'The same but partially realized: ' . show((List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}}})->realize(2));
print 'The same but excessively realized: ' . show((List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::nil }}}})->realize(42));
LIST_REALIZE
demo 'List::list', map(($_, "($_)->realize"), '((List::lazy { List::list qw(a b c) })->list(List::singleton(42), undef, List::nil, \'Hello, world!\', List::list(1, 2, 3)))', map "List::list$_", '', map " $_", 'undef', 42, 'List::list(qw(a b c))', 'lazy { 42 }, List::list(qw(a b c))', 'List::list(qw(a b c)), List::list((lazy { 3.141592 }), 42), List::list');
demo 'List::ref', <<'LIST_REF';
my $list = List::lazy { List::cons 0, List::lazy { List::cons lazy{1}, List::lazy { List::list 2, lazy{3}, 4, 5, 6 }}};
print 'List: ' . show $list;
my $x = $list->ref(1);
print 'List\'s second element: ' . show $x;
print 'List: ' . show $list;
print 'List\'s second element: ' . show $x->val;
print 'List: ' . show $list;
print 'List\'s 43rd element: ' . show $list->ref(42);
print 'List: ' . show $list;
print 'List\'s 43rd element: ' . show $list->ref(42)->val;
print 'List: ' . show $list;
LIST_REF
demo 'List::content', '(List::lazy { List::list qw(a b c) })->content';
demo 'List::last', map(($_, "$_->val"), map "List::lazy { $_ }->last", 'List::list qw(a b c)', 'List::nil');
demo 'List::init', map(($_, "$_->realize"), map "List::lazy { $_ }->init", 'List::list qw(a b c)', 'List::nil');
demo 'List::length', <<'LIST_LENGTH';
my $l = List::lazy {List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons lazy{2}, List::lazy { List::cons 3, List::lazy { List::cons 4, List::nil }}}}};
print show $l;
print $l->length;
print show $l;
$l->length
LIST_LENGTH
demo 'List::repeat', <<'LIST_REPEAT';
my $l = List::repeat 42;
print 'List: ' . show $l;
print 'List\'s prefix: ' . show $l->take(7)->realize;
print 'List: ' . show $l;
my $m = List::repeat 'Hello,', 'world!';
print 'List: ' . show($m) . ' (' . show($m->realize(7)) . ')'
LIST_REPEAT
demo 'List::replicate', <<'LIST_REPLICATE';
my $l = List::replicate 7, 42;
print 'List: ' . show $l;
print 'Forced List: ' . show $l->realize;
my $m = List::replicate 142, 'Hello,', 'world!';
print 'List: ' . show($m) . ' (' . show($m->realize(7)) . ', length = ' . $m->length() . ')'
LIST_REPLICATE
demo 'List::take', <<'LIST_TAKE';
my $l = 
	List::cons 0, List::lazy {
		print 'Step 1';
		List::cons 1, List::lazy {
			print 'Step 2';
			List::cons 2, List::lazy {
				print 'Step 3';
				List::cons 3, List::lazy {
					print 'Step 4';
					List::cons 4, List::lazy {
						print 'Step 5';
						List::cons 5, List::lazy {
							print 'Step 6';
							List::cons 6, List::lazy {
								print 'Step 7';
								List::cons 7, List::lazy {
									print 'Step 8';
									List::cons 8, List::lazy {
										print 'Step 9';
										List::cons 9, List::lazy {
											print 'Step 10';
											List::cons 10, List::lazy {
												print 'Step 11';
												List::cons 11, List::nil
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
};
print 'List: ' . show $l;
print 'List\' first 3: ' . show $l->take(3);
print 'List head: ' . show $l->take(3)->head;
print 'List: ' . show $l;
print 'List content: ' . show $l->take(42);
print 'List: ' . show $l;
print 'List \'s first 3: ' . show $l->take(3)->realize;
print 'List: ' . show $l;
print 'List \'s first 6: ' . show $l->take(6);
print 'List: ' . show $l;
print 'List \'s first 6: ' . show $l->take(6)->realize;
print 'List: ' . show $l;
print 'List content: ' . show $l->take(42)->realize;
print 'List: ' . show $l;
LIST_TAKE
demo 'List::drop', <<'LIST_DROP';
my $l = List::lazy { List::list 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
print show $l;
print show $l->drop(4);
print show $l;
print show $l->drop(4)->realize;
print show $l;
print show $l->drop(42);
print show $l;
print show $l->drop(42)->realize;
print show $l;
LIST_DROP
demo 'List::splitAt', <<'LIST_SPLIT_AT';
my ($left, $right) = List::lazy { List::cons 0, List::lazy { List::cons 1, List::lazy { List::cons 2, List::lazy { List::cons 3, List::lazy { List::cons 4, List::lazy { List::cons 5, List::lazy { List::nil }}}}}}}->splitAt(3);
print show $left;
print show $right;
print show $left->realize;
print show $right;
print show $right->realize;
print show $left;
print show $right;
LIST_SPLIT_AT
demo 'List::takeWhile'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->takeWhile(sub { $_[0] < 10 })'
, 'my $l = List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->takeWhile(sub { $_[0] < 10 }); print $l->head; $l'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->takeWhile(sub { $_[0] < 10 })->realize'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->takeWhile(sub { $_[0] < 10 })->realize(3)';
demo 'List::dropWhile'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->dropWhile(sub { $_[0] < 10 })'
, 'my $l = List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->dropWhile(sub { $_[0] < 10 }); print $l->head; $l'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->dropWhile(sub { $_[0] < 10 })->realize'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->dropWhile(sub { $_[0] < 10 })->realize(3)';
demo 'List::foldl'
, 'List::lazy { List::nil }->foldl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))'
, 'force List::lazy { List::nil }->foldl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->filter(sub { not $_[0] % 2 })->foldl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))'
, 'force List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->filter(sub { not $_[0] % 2 })->foldl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))';
demo 'List::scanl'
, 'List::lazy { List::nil }->scanl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))'
, 'List::lazy { List::nil }->scanl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))->realize'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->filter(sub { not $_[0] % 2 })->scanl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))'
, 'List::lazy { List::list 0, 1, 2, 3, 42, 5, 6, 7 }->filter(sub { not $_[0] % 2 })->scanl(sub { "$_[0]:$_[1]", "$_[0]:$_[2]" }, qw(hello world))->realize';
demo 'List::iterate'
, 'List::lazy { List::iterate { \'inter\', \'seption\', map scalar(@_) . ":$_", @_ } }->realize(12)'
, 'List::lazy { List::iterate { \'inter\', \'seption\', map scalar(@_) . ":$_", @_ } 42 }->realize(12)'
, 'List::lazy { List::iterate { \'inter\', \'seption\', map scalar(@_) . ":$_", @_ } 42, 3.141592 }->realize(12)';
