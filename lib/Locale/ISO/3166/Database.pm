package Locale::ISO::3166::Database;

use parent 'Locale::ISO::3166';
use strict;
use warnings;

use DBD::SQLite;

use DBI;

use DBIx::Admin::CreateTable;

use Moo;

use Types::Standard qw/Any HashRef Str/;

has attributes =>
(
	default  => sub{return {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has creator =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dbh =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dsn =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has engine =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has password =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has time_option =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has username =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> dsn('dbi:SQLite:dbname=' . $self -> sqlite_file);
	$self -> dbh(DBI -> connect($self -> dsn, $self -> username, $self -> password, $self -> attributes) ) || die $DBI::errstr;
	$self -> dbh -> do('PRAGMA foreign_keys = ON');

	$self -> creator
		(
		 DBIx::Admin::CreateTable -> new
		 (
		  dbh     => $self -> dbh,
		  verbose => 0,
		 )
		);

	$self -> engine
		(
		 $self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
		);

	$self -> time_option
		(
		 $self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
		);

} # End of BUILD.

# ----------------------------------------------

sub get_country_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from countries') )[0];

} # End of get_country_count.

# -----------------------------------------------

sub get_statistics
{
	my($self) = @_;

	return
	{
		countries_in_db			=> $self -> get_country_count,
		has_subcounties			=> $#{$self -> who_has_subcountries} + 1,
		subcountries_in_db		=> $self -> get_subcountry_count,
		subcountry_types_in_db	=> $self -> get_subcountry_type_count,
	};

} # End of get_statistics.

# ----------------------------------------------

sub get_subcountry_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from subcountries') )[0];

} # End of get_subcountry_count.

# ----------------------------------------------

sub get_subcountry_type_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from subcountry_types') )[0];

} # End of get_subcountry_type_count.

# ----------------------------------------------

sub read_countries_table
{
	my($self) = @_;
	my($sth)  = $self -> dbh -> prepare('select * from countries');

	$sth -> execute;
	$sth -> fetchall_hashref('id');

} # End of read_countries_table.

# ----------------------------------------------

sub read_subcountries_table
{
	my($self) = @_;
	my($sth)  = $self -> dbh -> prepare('select * from subcountries');

	$sth -> execute;
	$sth -> fetchall_hashref('id');

} # End of read_subcountries_table.

# -----------------------------------------------

sub report_Australian_statistics
{
	my($self)		= @_;
	my($countries)	= $self -> read_countries_table;

	my($index);

	for my $i (keys %$countries)
	{
		if ($$countries{$i}{name} eq 'Australia')
		{
			$index = $i;

			last;
		}
	}

	my($subcountries) = $self -> read_subcountries_table;

	my(@states);

	for my $i (keys %$subcountries)
	{
		if ($$subcountries{$i}{country_id} == $index)
		{
			push @states, $$subcountries{$i};
		}
	}

	@states = sort{$$a{code} cmp $$b{code} } @states;

	print "$$_{code}: $$_{name}.\n" for @states;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of report_Australian_statistics.

# -----------------------------------------------

sub report_statistics
{
	my($self)  = @_;
	my($count) = $self -> get_statistics;

	print "$_.\n" for map{"$_ => $$count{$_}"} sort keys %$count;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of report_statistics.

# ----------------------------------------------

sub who_has_subcountries
{
	my($self)		= @_;
	my($countries)	= $self -> read_countries_table;

	my(@has);

	for my $id (keys %$countries)
	{
		push @has, $id if ($$countries{$id}{has_subcountries} eq 'Yes');
	}

	return [@has];

} # End of who_has_subcountries.

# -----------------------------------------------

1;

=pod

=head1 NAME

Locale::ISO::3166::Database - The interface to local.iso.3166.sqlite

=head1 Synopsis

See L<Locale::ISO::3166/Synopsis>.

=head1 Description

Documents the methods end-users need to access the SQLite database,
I<local.iso.3166.sqlite>, which ships with this distro.

See L<Locale::ISO::3166/Description>.

See scripts/export.as.csv.pl, scripts/export.as.html.pl and scripts/report.statistics.pl.

See L<the demo page|...> for an exported version of the database.

See also data/*.csv for the exported files, 1 per table.

=head1 Constructor and initialization

new(...) returns an object of type C<Locale::ISO::3166::Database>.

This is the class's contructor.

Usage: C<< Locale::ISO::3166::Database -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</attributes([$hashref])>]):

=over 4

=item o attributes => $a_hash_ref

Sets the hashref of options passed as the 4th parameter to L<DBI>'s C<connect()> method.

Default: {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1}.

=item o dsn => $string

Sets the DSN passed as the 1st parameter to L<DBI>'s C<connect()> method.

Default: 'dbi:SQLite:dbname=' . The value returned by sqlite_file().
See L<Locale::ISO::3166/sqlite_file([$string])> for details.

=item o password => $string

Sets the password passed as the 3rd parameter to L<DBI>'s C<connect()> method.

Default: '' (the empty string).

=item o username => $string

Sets the username passed as the 2nd parameter to L<DBI>'s C<connect()> method.

Default: '' (the empty string).

=back

=head1 Methods

This module is a sub-class of L<Locale::ISO::3166> and consequently inherits its methods, while
adding these.

=head2 attributes($hashref)

Get or set the hashref of attributes passes to L<DBI>'s I<connect()> method.

Also, I<attributes> is an option to L</new()>.

=head2 get_country_count()

Returns the result of: 'select count(*) from countries'.

=head2 get_statistics()

Returns a hashref of database statistics:

	{
	    countries_in_db        => 249,
	    has_subcounties        => 198,
	    subcountries_in_db     => 4847,
	    subcountry_types_in_db => 92,
	}

Called by L</report_statistics()>.

=head2 get_subcountry_count()

Returns the result of: 'select count(*) from subcountries'.

=head2 get_subcountry_type_count()

Returns the result of: 'select count(*) from subcountry_types'.

=head2 new()

See L</Constructor and initialization>.

=head2 read_countries_table()

Returns a hashref of hashrefs for this SQL: 'select * from countries'.

The key of the hashref is the primary key (integer) of the I<countries> table.

This is discussed further in L<Locale::ISO::3166/Methods which return hashrefs>.

=head2 read_subcountries_table

Returns a hashref of hashrefs for this SQL: 'select * from subcountries'.

The key of the hashref is the primary key (integer) of the I<subcountries> table.

This is discussed further in L<Locale::ISO::3166/Methods which return hashrefs>.

=head2 report_Australian_statistics

Prints some info for Australia. Does not call L</report_statistics()>.

=head2 report_statistics()

Prints various database statistics at the I<info> level.

Calls L</get_statistics()>. See that module for what this module reports.

=head2 who_has_subcountries()

Returns an arrayref of primary keys (integers) in the I<countries> table, of those countries who have
subcountry entries in the I<subcountries> table.

=head1 FAQ

For the database schema, etc, see L<Locale::ISO::3166/FAQ>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale::ISO::3166>.

=head1 Author

C<Locale::ISO::3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
