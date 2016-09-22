package Locale::ISO::3166;

use strict;
use warnings;

use File::ShareDir;
use File::Spec;

use Log::Handler;

use Moo;

use Types::Standard qw/Any ArrayRef Bool Int HashRef Str/;

has config_file =>
(
	default  => sub{return '.htlocale-iso-3166.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has sqlite_file =>
(
	default  => sub{return 'locale-iso-3166.sqlite'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self)		= @_;
	(my $package	= __PACKAGE__) =~ s/::/-/g;
	my($dir_name)	= $ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package);

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

	$self -> config_file(File::Spec -> catfile($dir_name, $self -> config_file) );
	$self -> sqlite_file(File::Spec -> catfile($dir_name, $self -> sqlite_file) );

} # End of BUILD.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level = 'notice' if (! defined $level);
	$s     = ''       if (! defined $s);

	$self -> logger -> $level($s) if ($self -> logger);

}	# End of log.

# --------------------------------------------------

sub run
{
	my($self) = @_;

	return 0;

} # End of run.

# --------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

Locale::ISO::3166 - Provide access to ISO 3166 codes in an SQLite db

=head1 Synopsis

A script (scripts/synopsis.pl):

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Locale::ISO::3166;

	# --------------------------

	sub process
	{
		my($count, $parser, $date) = @_;

		print "$count: $date: ";

		my($result) = $parser -> parse(date => $date);

		print "Canonical date @{[$_ + 1]}: ", $parser -> canonical_date($$result[$_]), ". \n" for (0 .. $#$result);
		print 'Canonical form: ', $parser -> canonical_form($result), ". \n";
		print "\n";

	} # End of process.

	# --------------------------

	my($parser) = Locale::ISO::3166 -> new(maxlevel => 'debug');

	process(1, $parser, 'Julian 1950');
	process(2, $parser, '@#dJulian@ 1951');
	process(3, $parser, 'From @#dJulian@ 1952 to Gregorian 1953/54');
	process(4, $parser, 'From @#dFrench r@ 1955 to 1956');
	process(5, $parser, 'From @#dJulian@ 1957 to German 1.Dez.1958');

One-liners:

	perl scripts/parse.pl -max debug -d 'Between Gregorian 1701/02 And Julian 1703'

Output:

	Return value from parse():
	[
	  {
	    canonical => "1701/02",
	    flag => "BET",
	    kind => "Date",
	    suffix => "02",
	    type => "Gregorian",
	    year => 1701
	  },
	  {
	    canonical => "\@#dJULIAN\@ 1703",
	    flag => "AND",
	    kind => "Date",
	    type => "Julian",
	    year => 1703
	  }
	]

	perl scripts/parse.pl -max debug -d 'Int 10 Nov 1200 (Approx)'

Output:

	[
	  {
	    canonical => "10 Nov 1200 (Approx)",
	    day => 10,
	    flag => "INT",
	    kind => "Date",
	    month => "Nov",
	    phrase => "(Approx)",
	    type => "Gregorian",
	    year => 1200
	  }
	]

	perl scripts/parse.pl -max debug -d '(Unknown)'

Output:

	Return value from parse():
	[
	  {
	    canonical => "(Unknown)",
	    kind => "Phrase",
	    phrase => "(Unknown)",
	    type => "Phrase"
	  }
	]

See the L</FAQ> for the explanation of the output arrayrefs.

See also scripts/parse.pl and scripts/compare.pl for sample code.

Lastly, you are I<strongly> encouraged to peruse t/*.t.

=head1 Description

L<Locale::ISO::3166> provides access to ISO 3166-1 and 3166-2 codes in an SQLite database.

=head1 Installation

Install L<Locale::ISO::3166> as you would for any C<Perl> module:

Run:

	cpanm Locale::ISO::3166

or run:

	sudo cpan Locale::ISO::3166

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Locale::ISO::3166 -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Locale::ISO::3166>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</maxlevel([$maxlevel])>]):

=over 4

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>, for the lexer and parser to use.

Default: A logger of type L<Log::Handler> which writes to the screen.

To disable logging, just set 'logger' to the empty string (not undef).

=item o maxlevel => $logOption1

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

By default nothing is printed.

Typical values are: 'error', 'notice', 'info' and 'debug'.

The default produces no output.

Default: 'notice'.

=item o minlevel => $logOption2

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=back

=head1 Methods

=head2 log($level, $s)

If a logger is defined, this logs the message $s at level $level.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set 'logger' to the empty string (not undef), in the call to L</new()>.

This logger is passed to other modules.

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is ceated.
See L<Log::Handler::Levels>.

Typical values are: 'notice', 'info' and 'debug'. The default, 'notice', produces no output.

The code emits a message with log level 'error' if Marpa throws an exception, and it displays
the result of the parse at level 'debug' if maxlevel is set that high. The latter display uses
L<Data::Dumper::Concise>'s function C<Dumper()>.

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created.
See L<Log::Handler::Levels>.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 new([%args])

The constructor. See L</Constructor and Initialization>.

=head1 FAQ

=head2 Where does the data come from?

L<https://pkg-isocodes.alioth.debian.org/>

=head1 See Also


=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Locale-ISO-3166>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale::ISO::3166>.

=head1 Credits

Thanx to Kim Ryan for pointing me to the Debian resource L<https://pkg-isocodes.alioth.debian.org/>.

=head1 Author

L<Locale::ISO::3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

Homepage: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
