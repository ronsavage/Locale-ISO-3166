package Locale::ISO::3166;

use strict;
use warnings;

use File::ShareDir;
use File::Spec;

use Moo;

use Types::Standard qw/Any ArrayRef Bool Int HashRef Str/;

has config_file =>
(
	default  => sub{return '.htlocale-iso-3166.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has sqlite_file =>
(
	default  => sub{return 'locale.iso.3166.sqlite'},
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

	$self -> config_file(File::Spec -> catfile($dir_name, $self -> config_file) );
	$self -> sqlite_file(File::Spec -> catfile($dir_name, $self -> sqlite_file) );

} # End of BUILD.

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

	use Locale::ISO::3166::Database;

	# ------------------------------

	Locale::ISO::3166::Database -> new -> report_statistics;

Output:

	countries_in_db => 249.
	has_subcounties => 198.
	subcountries_in_db => 4847.
	subcountry_types_in_db => 92.

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

=head1 Methods

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
