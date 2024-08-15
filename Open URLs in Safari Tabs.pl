#!/usr/bin/perl

# Description: http://daringfireball.net/2010/08/open_urls_in_safari_tabs
# License: See below.
# http://gist.github.com/507356

use strict;
use warnings;
use URI::Escape;

my $text = do { local $/; <> };
my @urls;
my $url_regex = qr{(?xi)
\b
(							# Capture 1: entire matched URL
  (?:
    [a-z][\w-]+:				# URL protocol and colon
    (?:
      /{1,3}						# 1-3 slashes
      |								#   or
      [a-z0-9%]						# Single letter or digit or '%'
      								# (Trying not to match e.g. "URI::Escape")
    )
    |							#   or
    www\d{0,3}[.]				# "www.", "www1.", "www2." … "www999."
    |							#   or
    [a-z0-9.\-]+[.][a-z]{2,4}/	# looks like domain name followed by a slash
  )
  (?:							# One or more:
    [^\s()<>]+						# Run of non-space, non-()<>
    |								#   or
    \(([^\s()<>]+|(\([^\s()<>]+\)))*\)	# balanced parens, up to 2 levels
  )+
  (?:							# End with:
    \(([^\s()<>]+|(\([^\s()<>]+\)))*\)	# balanced parens, up to 2 levels
    |									#   or
    [^\s`!()\[\]{};:'".,<>?«»“”‘’]		# not a space or one of these punct chars
  )
)
};

# Build an AppleScript-syntax list of the URLs in the input text.
while ($text =~ m{$url_regex}g) {
	my $u = $1;
	$u =~ s{([\x{80}-\x{ffff}])}{uri_escape($1)}eg; # Encode non-ASCII characters
	push @urls, qq{"$u"};
}
my $urls_as_applescript_list = join ", ", @urls;

# Get the user's default web browser; if it isn't Safari or WebKit, use Safari
# in the AppleScript. (And also use Safari if the backticks command fails.)
my $browser = `export VERSIONER_PERL_PREFER_32_BIT=yes; /usr/bin/perl -MMac::InternetConfig -le 'print +(GetICHelper "http")[1]'`;
chomp $browser;
unless ($browser =~ /^(?:Safari|WebKit)$/i) {
	$browser = "Safari";
}

# Create and run the AppleScript.
my $applescript = <<"END_SCRIPT";
set _url_list to {$urls_as_applescript_list}

tell application "$browser"
	-- activate # Uncomment to have browser activate when invoked
	make new document
	set _w to window 1
	repeat with _url in _url_list
		tell _w to make new tab with properties {URL:_url}
	end repeat
	tell _w to close tab 1 -- the empty tab the window started with
end tell
END_SCRIPT

print $applescript;

system("/usr/bin/osascript", "-e", $applescript);

__END__

LICENSE

http://www.opensource.org/licenses/mit-license.php

Copyright (c) 2011 John Gruber

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
