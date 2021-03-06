package Locale::ISO::3166::Database::Import;

use parent 'Locale::ISO::3166::Database';
use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

use File::Slurper qw/read_binary/;
use File::Spec;

use JSON;

use Moo;

use Types::Standard qw/HashRef Str/;

use Unicode::CaseFold;	# For fc().

has code2 =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.00';

# -----------------------------------------------

sub populate
{
	my($self)		= @_;
	(my $package	= __PACKAGE__) =~ s/::/-/g;
	my($dir_name)	= $ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package);
	my($app_name)	= 'Locale-ISO-3166';
	my($json_name)	= 'iso_3166-1.json';
	my($path)		= File::Spec -> catfile($dir_name, $json_name);
	my($json)		= read_binary($path);
	$json			= decode_json($json);	# Hashref.
	$json			= $$json{'3166-1'};		# Arrayref.

	my(@one);

	for my $item (@$json)
	{
		$$item{official_name} = defined($$item{official_name}) ? $$item{official_name} : $$item{name};

		push @one, $item;
	}

	$self -> dbh -> begin_work;

	my($code2index)	= $self -> _save_countries(\@one);
	$json_name		= 'iso_3166-2.json';
	$path			= File::Spec -> catfile($dir_name, $json_name);
	$json			= read_binary($path);
	$json			= decode_json($json);	# Hashref.
	$json			= $$json{'3166-2'};		# Arrayref.

	my(@two);

	for my $item (@$json)
	{
		push @two, $item;
	}

	$self -> _save_subcountry_info($code2index, \@two);
	$self -> dbh -> commit;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate.

# -----------------------------------------------

sub populate_subcountry
{
	my($self)			= @_;
	my($code2)			= $self -> code2;
	my($in_file)		= "data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html";
	my($dom)			= Mojo::DOM -> new(read_text($in_file) );
	my($record_count)	= 0; # Set because logged outside the loop.
	my($table_count)	= 0;


	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountry.

# ----------------------------------------------

sub _save_countries
{
	my($self, $table) = @_;

	$self -> dbh -> do('delete from countries');

	my($i)   = 0;
	my($sql) = 'insert into countries '
				. '(alpha_2, alpha_3, fc_official_name, fc_name, has_subcountries, name, numeric, official_name) '
				. 'values (?, ?, ?, ?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	my(%code2index);

	for my $item (sort{$$a{name} cmp $$b{name} } @$table)
	{
		$i++;

		$code2index{$$item{alpha_2} } = $i;

		$sth -> execute
		(
			$$item{alpha_2},
			$$item{alpha_3},
			fc $$item{name},
			fc $$item{official_name},
			'No', # The default for 'has_subcountries'. Updated later.
			$$item{name},
			$$item{numeric},
			$$item{official_name},
		);
	}

	$sth -> finish;

	return \%code2index;

} # End of _save_countries.

# ----------------------------------------------

sub _save_subcountry_info
{
	my($self, $code2index, $table) = @_;

	my($alpha_2);
	my($country_id);
	my(%subcountry, $suffix);
	my(%type);

	for my $item (@$table)
	{
		($alpha_2, $suffix)			= ($1, $2) if ($$item{code} =~ /(..)-(.+)/);
		$country_id					= $$code2index{$alpha_2};
		$subcountry{$country_id}	= [] if (! $subcountry{$country_id});
		$type{$$item{type} }		= $$item{code};

		push @{$subcountry{$country_id} }, $item
	}

	$self -> dbh -> do('delete from subcountry_types');

	my($fc_type);
	my(%seen);
	my(@word);

	for my $type (keys %type)
	{
		@word		= map{ucfirst} split(/\s+/, $type);
		$type		= join(' ', @word);
		$fc_type	= fc $type;

		if (! $seen{$fc_type})
		{
			$seen{$fc_type} = $type;
		}
	}

	my($sql_1)					= 'insert into subcountry_types (fc_name, name) values (?, ?)';
	my($sth_1)					= $self -> dbh -> prepare($sql_1) || die "Unable to prepare SQL: $sql_1\n";
	my($subcountry_type_id)		= 0;

	my(%type_id);

	for $fc_type (sort keys %seen)
	{
		$type_id{$fc_type} = ++$subcountry_type_id;

		$sth_1 -> execute($fc_type, $seen{$fc_type});
	}

	$sth_1 -> finish;

	my($sql_2)	= 'insert into subcountries (country_id, subcountry_type_id, code, fc_name, name) values (?, ?, ?, ?, ?)';
	my($sth_2)	= $self -> dbh -> prepare($sql_2) || die "Unable to prepare SQL: $sql_1\n";
	my($sql_3)	= 'update countries set has_subcountries = ? where id = ?';
	my($sth_3)	= $self -> dbh -> prepare($sql_3) || die "Unable to prepare SQL: $sql_2\n";

	my(%country_id);

	for $country_id (sort keys %subcountry)
	{
		my(@subcountries) = @{$subcountry{$country_id} };

		if ($#subcountries >= 0)
		{
			$sth_3 -> execute('Yes', $country_id);
		}

		for my $item (@subcountries)
		{
			$fc_type					= fc $$item{type};
			$subcountry_type_id			= $type_id{$fc_type};

			$sth_2 -> execute($country_id, $subcountry_type_id, $$item{code}, fc $$item{name}, $$item{name});
		}
	}

	$sth_2 -> finish;
	$sth_3 -> finish;

} # End of _save_subcountry_info.

# -----------------------------------------------

1;

=pod

=head1 NAME

Locale::ISO::3166::Database::Import - Part of the interface to www.scraper.wikipedia.iso3166.sqlite

=head1 Synopsis

See L<Locale::ISO::3166/Synopsis>.

=head1 Description

Documents the methods used to populate the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro.

See L<Locale::ISO::3166/Description> for a long description.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Locale::ISO::3166::Database::Import>.

This is the class's contructor.

Usage: C<< Locale::ISO::3166::Database::Import -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o code2 => $2_letter_code

Specifies the code2 of the country whose subcountry page is to be downloaded.

=back

=head1 Methods

This module is a sub-class of L<Locale::ISO::3166::Database> and consequently
inherits its methods.

=head2 code2($code)

Get or set the 2-letter country code of the country or subcountry being processed.

Also, I<code2> is an option to L</new()>.

=head2 new()

See L</Constructor and initialization>.

=head2 populate_countries()

Populate the I<countries> table.

=head2 populate_subcountry()

Populate the I<subcountries> table, for 1 subcountry.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling
this method.

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
