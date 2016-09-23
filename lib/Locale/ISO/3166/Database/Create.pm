package Locale::ISO::3166::Database::Create;

use parent 'Locale::ISO::3166::Database';
use strict;
use warnings;

our $VERSION = '1.00';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
countries
subcountry_types
subcountries
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

}	# End of create_all_tables.

# --------------------------------------------------

sub create_countries_table
{
	my($self)        = @_;
	my($table_name)  = 'countries';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id					$primary_key,
alpha_2				char(2) not null,
alpha_3				char(3) not null,
fc_official_name	varchar(255) not null,
fc_name				varchar(255) not null,
has_subcountries	varchar(3) not null,
name				varchar(255) not null,
numeric				char(3) not null,
official_name		varchar(255) not null,
timestamp			timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_countries_table.

# --------------------------------------------------

sub create_subcountries_table
{
	my($self)        = @_;
	my($table_name)  = 'subcountries';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id					$primary_key,
country_id			integer not null references countries(id),
subcountry_type_id	integer not null references subcountry_types(id),
code				varchar(255) not null,
fc_name				varchar(255) not null,
name				varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_subcountries_table.

# --------------------------------------------------

sub create_subcountry_types_table
{
	my($self)        = @_;
	my($table_name)  = 'subcountry_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id		$primary_key,
fc_name	varchar(255) not null,
name	varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_subcountry_types_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
subcountries
subcountry_types
countries
/)
	{
		$self -> drop_table($table_name);
	}

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);
	$self -> report($table_name, 'dropped', '');

} # End of drop_table.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result. \n";
	}
	else
	{
		print "Table '$table_name' $message. \n";
	}

} # End of report.

# -----------------------------------------------

1;

=pod

=head1 NAME

Locale::ISO::3166::Database::Create - Create/drop tables in www.scraper.wikipedia.iso3166.sqlite

=head1 Synopsis

See L<Locale::ISO::3166/Synopsis>.

=head1 Description

Documents the methods end-users need to create/drop tables in the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro.

See scripts/create.tables.pl and scripts/drop.tables.pl.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Locale::ISO::3166::Database::Create>.

This is the class's contructor.

Usage: C<< Locale::ISO::3166::Database::Create -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options: None.

=head1 Methods

This module is a sub-class of L<Locale::ISO::3166::Database> and consequently
inherits its methods.

=head2 create_all_tables()

Create these tables:

=over 4

=item o countries

=item o subcountries

=item o subcountry_categories

=item o subcountry_info

=back

=head2 create_countries_table()

Create the I<countries> table.

=head2 create_subcountries_table()

Create the I<subcountries> table.

=head2 create_subcountry_categories_table()

Create the I<subcountry_categories> table.

=head2 create_subcountry_info_table()

Create the I<subcountry_info> table.

=head2 drop_all_tables()

Create these tables:

=over 4

=item o countries

=item o subcountries

=item o subcountry_categories

=item o subcountry_info

=back

=head2 drop_table($table_name)

Drop the table called $table_name,

=head2 new()

See L</Constructor and initialization>.

=head2 report($table_name, $message, $result)

For $table_name, if the result of the create or drop is an error, die with $message.

If there was no error, log a create/drop message at level I<debug>.

=head1 FAQ

For the database schema, etc, see L<Locale::ISO::3166/FAQ>.

=head1 References

See L<Locale::ISO::3166/References>.

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
