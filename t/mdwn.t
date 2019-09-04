#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Encode;

BEGIN { use_ok("IkiWiki"); }

%config=IkiWiki::defaultconfig();
$config{srcdir}=$config{destdir}="/dev/null";
$config{disable_plugins}=["htmlscrubber"];

foreach my $multimarkdown (qw(1 0)) {
	$config{multimarkdown} = $multimarkdown;
	undef $IkiWiki::Plugin::mdwn::markdown_sub
		if defined $IkiWiki::Plugin::mdwn::markdown_sub;
	IkiWiki::loadplugins();
	IkiWiki::checkconfig();

	is(IkiWiki::htmlize("foo", "foo", "mdwn",
		"C. S. Lewis wrote books\n"),
		"<p>C. S. Lewis wrote books</p>\n",
		"alphalist off by default for multimarkdown = $multimarkdown");

	like(IkiWiki::htmlize("foo", "foo", "mdwn",
		"This works[^1]\n\n[^1]: Sometimes it doesn't.\n"),
		qr{<p>This works.*fnref:1.*},
		"footnotes on by default for multimarkdown = $multimarkdown");

	$config{mdwn_footnotes} = 0;
	unlike(IkiWiki::htmlize("foo", "foo", "mdwn",
		"An unusual link label: [^1]\n\n[^1]: http://example.com/\n"),
		qr{<p>An unusual link label: .*fnref:1.*},
		"footnotes can be disabled for multimarkdown = $multimarkdown");

	$config{mdwn_footnotes} = 1;
	like(IkiWiki::htmlize("foo", "foo", "mdwn",
		"This works[^1]\n\n[^1]: Sometimes it doesn't.\n"),
		qr{<p>This works.*fnref:1.*},
		"footnotes can be enabled for multimarkdown = $multimarkdown");
}

$config{mdwn_alpha_lists} = 1;
like(IkiWiki::htmlize("foo", "foo", "mdwn",
	"A. One\n".
	"B. Two\n"),
	qr{<ol\W}, "alphalist can be enabled");

$config{mdwn_alpha_lists} = 0;
like(IkiWiki::htmlize("foo", "foo", "mdwn",
	"A. One\n".
	"B. Two\n"),
	qr{<p>A. One\sB. Two</p>\n}, "alphalist can be disabled");

SKIP: {
	skip 'set $IKIWIKI_TEST_ASSUME_MODERN_DISCOUNT if you have Discount 2.2.0+', 4
		unless $ENV{IKIWIKI_TEST_ASSUME_MODERN_DISCOUNT};
	like(IkiWiki::htmlize("foo", "foo", "mdwn",
			"Definition list\n: A useful HTML structure\n"),
		qr{<dl>.*<dt>Definition list</dt>\s*<dd>A useful HTML structure</dd>}s,
		"definition lists are enabled by default");
	like(IkiWiki::htmlize("foo", "foo", "mdwn",
			"```\n#!/bin/sh\n```\n"),
		qr{<pre>\s*<code>\s*[#]!/bin/sh\s*</code>\s*</pre>}s,
		"code blocks are enabled by default");
	like(IkiWiki::htmlize("foo", "foo", "mdwn",
			"<foo_bar>"),
		qr{<foo_bar>},
		"GitHub tag name extensions are enabled by default");
	like(IkiWiki::htmlize("foo", "foo", "mdwn",
			"<style>foo</style>"),
		qr{<style>foo</style>},
		"Styles are not stripped by default");
}

done_testing();
