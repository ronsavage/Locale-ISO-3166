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
	default  => sub{return '.htwww.scraper.wikipedia.iso3166.conf'},
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
	default  => sub{return 'www.scraper.wikipedia.iso3166.sqlite'},
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

Genealogy::Gedcom::Date - Parse GEDCOM dates in French r/German/Gregorian/Hebrew/Julian

=head1 Synopsis

A script (scripts/synopsis.pl):

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Genealogy::Gedcom::Date;

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

	my($parser) = Genealogy::Gedcom::Date -> new(maxlevel => 'debug');

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

L<Genealogy::Gedcom::Date> provides a L<Marpa|Marpa::R2>-based parser for GEDCOM dates.

Calender escapes supported are (case-insensitive): French r/German/Gregorian/Hebrew/Julian.

Gregorian is the default, and does not need to be used at all.

Comparison of 2 C<Genealogy::Gedcom::Date>-based objects is supported by calling the sub
L</compare($other_object)> method on one object and passing the other object as the parameter.

Note: C<compare()> can return any one of four (4) values.

See L<the GEDCOM Specification|http://wiki.webtrees.net/en/Main_Page>, p 45.

=head1 Installation

Install L<Genealogy::Gedcom::Date> as you would for any C<Perl> module:

Run:

	cpanm Genealogy::Gedcom::Date

or run:

	sudo cpan Genealogy::Gedcom::Date

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

C<new()> is called as C<< my($parser) = Genealogy::Gedcom::Date -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Genealogy::Gedcom::Date>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</date([$date])>]):

=over 4

=item o canonical => $integer

Note: Nothing is printed unless C<maxlevel> is set to C<debug>.

=over 4

=item o canonical => 0

Data::Dumper::Concise's Dumper() prints the output of the parse.

=item o canonical => 1

canonical_form() is called on the output of parse() to print a string.

=item o canonical => 2

canonocal_date() is called on each element in the result from parse(), to print strings on
separate lines.

=back

Default: 0.

=item o date => $date

The string to be parsed.

Each ',' is replaced by a space. See the L</FAQ> for details.

Default: ''.

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

Note: The parameters C<canonical> and C<date> can also be passed to L</parse([%args])>.

=head1 Methods

=head2 canonical([$integer])

Here, the [] indicate an optional parameter.

Gets or sets the C<canonical> option, which controls what exactly L</parse([%args])> prints when
L</maxlevel([$string])> is set to C<debug>.

By default nothing is printed.

See L</canonical_date($hashref)>, next, for sample code.

=head2 canonical_date($hashref)

$hashref is either element of the arrayref returned by L</parse([%args])>. The hashref may be
empty.

Returns a date string (or the empty string) normalized in various ways:

=over 4

=item o If Gregorian (in any form) was in the original string, it is discarded

This is done because it's the default.

=item o If any other calendar escape was in the original string, it is preserved

And it's output in all caps.

And as a special case, 'FRENCHR' is returned as 'FRENCH R'.

=item o If About, etc were in the orginal string, they are discarded

This means the C<flag> key in the hashref is ignored.

=back

Note: This method is called by L</parse([%args])> to populate the C<canonical> key in the arrayref
of hashrefs returned by C<parse()>.

Try:

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015'

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 0

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 1

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 2

=head2 canonical_form($arrayref)

Returns a date string containing zero, one or two dates.

This method calls L</canonical_date($hashref)> for each element in the $arrayref. The arrayref
may be empty.

Then it adds information from the C<flag> key in each element, if present.

For sample code, see L</canonical_date($hashref)> just above.

=head2 compare($other_object)

Returns an integer 0 .. 3 (sic) indicating the temporal relationship between the invoking object
($self) and $other_object.

Returns one of these values:

	0 if the dates have different date escapes.
	1 if $date_1 < $date_2.
	2 if $date_1 = $date_2.
	3 if $date_1 > $date_2.

Note: Gregorian years like 1510/02 are converted into 1510 before the dates are compared. Create a
sub-class and override L</normalize_date($date_hash)> if desired.

See scripts/compare.pl for sample code.

See also L</normalize_date($date_hash)>.

=head2 date([$date])

Here, [ and ] indicate an optional parameter.

Gets or sets the date to be parsed.

The date in C<< parse(date => $date) >> takes precedence over both C<< new(date => $date) >>
and C<date($date)>.

This means if you call C<parse()> as C<< parse(date => $date) >>, then the value C<$date> is stored
so that if you subsequently call C<date()>, that value is returned.

Note: C<date> is a parameter to new().

=head2 error()

Gets the last error message.

Returns '' (the empty string) if there have been no errors.

If L<Marpa::R2> throws an exception, it is caught by a try/catch block, and the C<Marpa> error
is returned by this method.

See L</parse([%args])> for more about C<error()>.

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

=head2 normalize_date($date_hash)

Normalizes $date_hash for each date during a call to L</compare($other_object)>.

Override in a sub-class if you wish to change the normalization technique.

=head2 parse([%args])

Here, [ and ] indicate an optional parameter.

C<parse()> returns an arrayref. See the L</FAQ> for details.

If the arrayref is empty, call L</error()> to retrieve the error message.

In particular, the arrayref will be empty if the input date is the empty string.

C<parse()> takes the same parameters as C<new()>.

Warning: The array can contain 1 element when 2 are expected. This can happen if your input contains
'From ... To ...' or 'Between ... And ...', and one of the dates is invalid. That is, the return
value from C<parse()> will contain the valid date but no indicator of the invalid one.

=head1 Extensions to the Gedcom specification

This chapter lists exactly how this code differs from the Gedcom spec.

=over 4

=item o Input may be in Unicode

=item o Input may be in any case

=item o Input may omit calendar escapes when the date is unambigous

=item o Any of the following tokens may be used

=over 4

=item o abt, about, circa

=item o aft, after

=item o and

=item o bc, b.c., bce

=item o bef, before

=item o bet, between

=item o cal, calculated

=item o french r, frenchr, german, gregorian, hebrew, julian,

=item o est, estimated

=item o from

=item o German BCE

vc, v.c., v.chr., vchr, vuz, v.u.z.

=item o German month names

jan, feb, mär, maer, mrz, apr, mai, jun, jul, aug, sep, sept, okt, nov, dez

=item o Gregorian month names

jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec

=item o Hebrew month names

tsh, csh, ksl, tvt, shv, adr, ads, nsn, iyr, svn, tmz, aav, ell

=item o int, interpreted

=item o to

=back

=back

=head1 FAQ

=head2 What is the format of the value returned by parse()?

It is always an arrayref.

If the date is like '1950' or 'Bef 1950 BCE', there will be 1 element in the arrayref.

If the date contains both 'From' and 'To', or both 'Between' and 'And', then the arrayref will
contain 2 elements.

Each element is a hashref, with various combinations of the following keys. You need to check the
existence of some keys before processing the date.

This means missing values (day, month, bce) are never fabricated. These keys only appear in the
hashref if such a token was found in the input.

Keys:

=over 4

=item o bce

If the input contains any (case-insensitive) BCE indicator, under any calendar escape, the C<bce>
key will hold the exact indicator.

=item o canonical => $string

L</parse([%args])> calls L</canonical_date($hashref)> to populate this key.

=item o day => $integer

If the input contains a day, then the C<day> key will be present.

=item o flag => $string

If the input contains any of the following (case-insensitive), then the C<flag> key will be present:

=over 4

=item o Abt or About

=item o Aft or After

=item o And

=item o Bef or Before

=item o Bet or Between

=item o Cal or Calculated

=item o Est or Estimated

=item o From

=item o Int or Interpreted

=item o To

=back

$string will take one of these values (case-sensitive):

=over 4

=item o ABT

=item o AFT

=item o AND

=item o BEF

=item o BET

=item o CAL

=item o EST

=item o FROM

=item o INT

=item o TO

=back

=item o kind => 'Date' or 'Phrase'

The C<kind> key is always present, and always takes the value 'Date' or 'Phrase'.

If the value is 'Phrase', see the C<phrase> and C<type> keys.

During processing, there can be another - undocumented - element in the arrayref. It represents
the calendar escape, and in that case C<kind> takes the value 'Calendar'. This element is discarded
before the final arrayref is returned to the caller.

=item o month => $string

If the input contains a month, then the C<month> key will be present. The case of $string will be
exactly whatever was in the input.

=item o phrase => "($string)"

If the input contains a date phrase, then the C<phrase> key will be present. The case of $string
will be exactly whatever was in the input.

parse(date => 'Int 10 Nov 1200 (Approx)') returns:

	[
	  {
	    day => 10,
	    flag => "INT",
	    kind => "Date",
	    month => "Nov",
	    phrase => "(Approx)",
	    type => "Gregorian",
	    year => 1200
	  }
	]

parse(date => '(Unknown)') returns:

	[
	  {
	    kind => "Phrase",
	    phrase => "(Unknown)",
	    type => "Phrase"
	  }
	]

See also the C<kind> and C<type> keys.

=item o suffix => $two_digits

If the year contains a suffix (/00), then the C<suffix> key will be present. The '/' is
discarded.

Obviously, this key can only appear when the year is of the Gregorian form 1700/00.

See also the C<year> key below.

=item o type => $string

The C<type> key is always present, and takes one of these case-sensitive values:

=over 4

=item o 'French r'

=item o German

=item o Gregorian

=item o Hebrew

=item o Julian

=item o Phrase

See also the C<kind> and C<phrase> keys.

=back

=item o year => $integer

If the input contains a year, then the C<year> key is present.

If the year contains a suffix (/00), see also the C<suffix> key, above. This means the value of
the C<year> key is never "$integer/$two_digits".

=back

=head2 When should I use a calendar escape?

=over 4

=item o In theory, for every non-Gregorian date

In practice, if the month name is unique to a specific language, then the escape is not needed,
since L<Marpa::R2> and this code automatically handle ambiguity.

Likewise, if you use a Gregorian year in the form 1700/01, then the calendar escape is obvious.

The escape is, of course, always inserted into the values returned by the C<canonical> pair of
methods when they process non-Gregorian dates. That makes their output compatible with
other software. And no matter what case you use specifying the calendar escape, it is always
output in upper-case.

=item o When you wish to force the code to provide an unambiguous result

All Gregorian and Julian dates are ambiguous, unless they use the year format 1700/01.

So, to resolve the ambiguity, add the calendar escape.

=back

=head2 Why is '@' escaped with '\' when L<Data::Dumper::Concise>'s C<Dumper()> prints things?

That's just how that module handles '@'.

=head2 Does this module accept Unicode?

Yes.

See t/German.t for sample code.

=head2 Can I change the default calendar?

No. It is always Gregorian.

=head2 Are dates massaged before being processed?

Yes. Commas are replaced by spaces.

=head2 French month names

See L</Extensions to the Gedcom specification>.

=head2 German month names

See L</Extensions to the Gedcom specification>.

=head2 Hebrew month names

See L</Extensions to the Gedcom specification>.

=head2 What happens if C<parse()> is given a string like 'To 2000 From 1999'?

The code I<does not> reorder the dates.

=head2 Why was this module renamed from DateTime::Format::Gedcom?

The L<DateTime> suite of modules aren't designed, IMHO, for GEDCOM-like applications. It was a
mistake to use that name in the first place.

By releasing under the Genealogy::Gedcom::* namespace, I can be much more targeted in the data
types I choose as method return values.

=head2 Why did you choose Moo over Moose?

My policy is to use the lightweight L<Moo> for all modules and applications.

=head1 Trouble-shooting

Things to consider:

=over 4

=item o Error message: Marpa exited at (line, column) = ($line, $column) within the input string

Consider the possibility that the parse ends without a C<successful> parse, but the input is the
prefix of some input that C<can> lead to a successful parse.

Marpa is not reporting a problem during the read(), because you can add more to the input string,
and Marpa does not know that you do not plan to do this.

=item o You tried to enter the German month name 'Mär' via the shell

Read more about this by running 'perl scripts/parse.pl -h', where it discusses '-d'.

=item o You mistyped the calendar escape

Check: Are any of these valid?

=over 4

=item o @#FRENCH@

=item o @#JULIAN@

=item o @#djulian

=item o @#juliand

=item o @#djuliand

=item o @#dJulian@

=item o Julian

=item o @#dJULIAN@

=back

Yes, the last 3 are accepted by this module, and the last one is accepted by other software.

=item o The date is in American format (month day year)

=item o You used a Julian calendar with a Gregorian year

Dates - such as 1900/01 - which do not fit the Gedcom definition of a Julian year, are filtered
out.

=back

=head1 See Also

L<File::Bom::Utils>.

L<Genealogy::Gedcom>

L<DateTime>

L<DateTimeX::Lite>

L<Time::ParseDate>

L<Time::Piece> is in Perl core. See L<http://perltricks.com/article/59/2014/1/10/Solve-almost-any-datetime-need-with-Time-Piece>

L<Time::Duration> is more sophisticated than L<Time::Elapsed>

L<Time::Moment> implements L<ISO 8601|https://en.wikipedia.org/wiki/ISO_8601>

L<http://blogs.perl.org/users/buddy_burden/2015/09/a-date-with-cpan-part-1-state-of-the-union.html>

L<http://blogs.perl.org/users/buddy_burden/2015/10/a-date-with-cpan-part-2-target-first-aim-afterwards.html>

L<http://blogs.perl.org/users/buddy_burden/2015/10/-a-date-with-cpan-part-3-paving-while-driving.html>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Genealogy-Gedcom-Date>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy::Gedcom::Date>.

=head1 Credits

Thanx to Eugene van der Pijll, the author of the Gedcom::Date::* modules.

Thanx also to the authors of the DateTime::* family of modules. See
L<http://datetime.perl.org/wiki/datetime/dashboard> for details.

Thanx for Mike Elston on the perl-gedcom mailing list for providing French month abbreviations,
amongst other information pertaining to the French language.

Thanx to Michael Ionescu on the perl-gedcom mailing list for providing the grammar for German dates
and German month abbreviations.

=head1 Author

L<Genealogy::Gedcom::Date> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Homepage: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
