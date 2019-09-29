#!/usr/bin/perl
use warnings;
use strict;
use Cwd qw(getcwd);
use Test::More;
use IkiWiki;

my $installed = $ENV{INSTALLED_TESTS};

my @command;
if ($installed) {
	@command = qw(ikiwiki);
}
else {
	ok(! system("make -s ikiwiki.out"));
	@command = ("perl", "-I".getcwd, qw(./ikiwiki.out
		--underlaydir=underlays/basewiki
		--set underlaydirbase=underlays
		--templatedir=templates));
}

push @command, qw(--set usedirs=0 --plugin table
	--url=http://example.com --cgiurl=http://example.com/ikiwiki.cgi
	t/tmp/in t/tmp/out --verbose);

my $blob;

ok(! system("rm -rf t/tmp"));
ok(! system("mkdir t/tmp"));

sub write_old_file {
	my $name = shift;
	my $content = shift;

	writefile($name, "t/tmp/in", $content);
	ok(utime(333333333, 333333333, "t/tmp/in/$name"));
}

write_old_file("csv.mdwn",
'[[!table format="csv" data="""
Key,Value
"ASCII","hello"
"Not ASCII","¬"
"""]]');
write_old_file("dsv.mdwn",
'[[!table format="dsv" data="""
Key       | Value
ASCII     | hello
Not ASCII | ¬
"""]]');
write_old_file("jon.mdwn",
'(See doc/bugs/table_can_not_deal_with_Chinese.mdwn)

[[!table class=fullwidth_table delimiter="	" data="""
Number	Title	Own?	Read?
I (HB1), 70 (PB1), 5 (PB50)	Dune	O	✓"""]]');

ok(! system(@command));
ok(! system(@command, "--refresh"));

$blob = readfile("t/tmp/out/dsv.html");
like($blob, qr{<th>\s*Key\s*</th>.*<th>\s*Value\s*</th>}s);
like($blob, qr{<td>\s*ASCII\s*</td>.*<td>\s*hello\s*</td>}s);
like($blob, qr{<td>\s*Not ASCII\s*</td>.*<td>\s*¬\s*</td>}s);

SKIP: {
	skip "Text::CSV unavailable", 0 unless eval q{use Text::CSV; 1};

	$blob = readfile("t/tmp/out/jon.html");
	like($blob, qr{<th>\s*Number\s*</th>\s*<th>\s*Title\s*</th>\s*<th>\s*Own\?\s*</th>\s*<th>\s*Read\?\s*</th>}s);
	like($blob, qr{<td>\s*I \(HB1\), 70 \(PB1\), 5 \(PB50\)\s*</td>\s*<td>\s*Dune\s*</td>\s*<td>\s*O\s*</td>\s*<td>\s*✓\s*</td>}s);

	$blob = readfile("t/tmp/out/csv.html");
	like($blob, qr{<th>\s*Key\s*</th>.*<th>\s*Value\s*</th>}s);
	like($blob, qr{<td>\s*ASCII\s*</td>.*<td>\s*hello\s*</td>}s);
	like($blob, qr{<td>\s*Not ASCII\s*</td>.*<td>\s*¬\s*</td>}s);
}

done_testing;
