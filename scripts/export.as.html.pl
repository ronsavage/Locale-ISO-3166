#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Getopt::Long;

use Locale::ISO::3166::Database::Export;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'web_page_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Locale::ISO::3166::Database::Export -> new(%option) -> as_html;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.html.pl - Export the SQLite database as HTML

=head1 SYNOPSIS

export.as.html.pl [options]

	Options:
	-help
	-web_page_file $aFileName

All switches can be reduced to a single letter.

Exit value: 0.

Default input: share/locale.iso.3166.sqlite.

Default output: Screen.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -web_page_file $aFileName

A HTML file name, to which country and subcountry data is to be output.

Default: iso.3166-2.html

=back

=cut
