package Locale::ISO::3166::Database::Import;

use parent 'Locale::ISO::3166::Database';
use feature 'say';
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

sub populate_countries
{
	my($self)		= @_;
	(my $package	= __PACKAGE__) =~ s/::/-/g;
	my($dir_name)	= $ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package);
	my($app_name)	= 'Locale-ISO-3166';
	my($json_name)	= 'iso_3166-1.json';
	my($path)		= File::Spec -> catfile($dir_name, $json_name);
	my($json)		= read_binary($path);
	$json			= decode_json($json);

	say $json;

#	my($code2index)			= $self -> _save_countries($codes);
#	my($names)				= $self -> _parse_country_page_2;
#	my($subcountry_count)	= $self -> _save_subcountry_info($code2index, $names);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_countries.

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

# -----------------------------------------------

sub populate_subcountries
{
	my($self)  = @_;

	# Find which subcountries have been downloaded but not imported.
	# %downloaded will contain 2-letter codes.

	my(%downloaded);

	my($downloaded)           = $self -> find_subcountry_downloads;
	@downloaded{@$downloaded} = (1) x @$downloaded;
	my($countries)            = $self -> read_countries_table;
	my($subcountries)         = $self -> read_subcountries_table;

	my($country_id);
	my(%imported);

	for my $subcountry_id (keys %$subcountries)
	{
		$country_id                                 = $$subcountries{$subcountry_id}{country_id};
		$imported{$$countries{$country_id}{code2} } = 1;
	}

	# 2: Import if not already imported.

	$self -> dbh -> begin_work;

	my($code2);

	for $country_id (sort keys %$countries)
	{
		$code2 = $$countries{$country_id}{code2};

		next if ($imported{$code2});

		next if ($$countries{$country_id}{has_subcountries} eq 'No');

		$self -> code2($code2);
		$self -> populate_subcountry;
	}

	$self -> dbh -> commit;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountries.

# ----------------------------------------------

sub _save_countries
{
	my($self, $table) = @_;

	$self -> dbh -> begin_work;
	$self -> dbh -> do('delete from countries');

	my($i)   = 0;
	my($sql) = 'insert into countries '
				. '(code2, code3, fc_name, has_subcountries, name, number) '
				. 'values (?, ?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	my(%code2index);

	for my $element (sort{$$a{name} cmp $$b{name} } @$table)
	{
		$i++;

		$code2index{$$element{code2} } = $i;

		$sth -> execute
		(
			$$element{code2},
			$$element{code3},
			fc $$element{name},
			'No', # The default for 'has_subcountries'. Updated later.
			$$element{name},
			$$element{number},
		);
	}

	$sth -> finish;
	$self -> dbh -> commit;

	return \%code2index;

} # End of _save_countries.

# ----------------------------------------------

sub _save_subcountry_info
{
	my($self, $code2index, $table) = @_;

	$self -> dbh -> begin_work;
	$self -> dbh -> do('delete from subcountry_info');

	my($has_subcountries_count)	= 0;
	my($i)						= 0;
	my($sql_1)					= 'insert into subcountry_info '
									. '(country_id, name, sequence) '
									. 'values (?, ?, ?)';
	my($sth_1)					= $self -> dbh -> prepare($sql_1) || die "Unable to prepare SQL: $sql_1\n";
	my($sql_2)					= 'update countries set has_subcountries = ? where id = ?';
	my($sth_2)					= $self -> dbh -> prepare($sql_2) || die "Unable to prepare SQL: $sql_2\n";

	my($country_id);
	my($subcountry, $sequence, %seen);

	for my $element (@$table)
	{
		next if (scalar @{$$element{subcountries} } == 0);

		$has_subcountries_count++;

		$sequence = 0;

		for $subcountry (@{$$element{subcountries} })
		{
			$i++;
			$sequence++;

			$country_id = $$code2index{$$element{code2} };

			$sth_1 -> execute
			(
				$country_id,
				$subcountry,
				$sequence
			);
		}

		# We can use $country_id because it has the same value every time thru the loop above.

		$sth_2 -> execute('Yes', $country_id);

		if ($seen{$country_id})
		{
			$self -> log(warning => "Seeing country_id $country_id for the 2nd time");
		}

		$seen{$country_id} = 1;
	}

	$sth_1 -> finish;
	$sth_2 -> finish;
	$self -> dbh -> commit;

} # End of _save_subcountry_info.

# ----------------------------------------------

sub _save_subcountry
{
	my($self, $count, $table)	= @_;
	my($code2)					= $self -> code2;
	my($countries)				= $self -> read_countries_table;

	# Find which country has the code we're processing.

	my($country_id) = first {$$countries{$_}{code2} eq $code2} keys %$countries;

	die "Unknown country code: $code2\n" if (! $country_id);

	my($categories)			= $self -> read_subcountry_categories_table;
	my($max_category_id)	= max (keys %$categories);

	$self -> dbh -> do("delete from subcountries where country_id = $country_id");

	my($i)   = 0;
	my($sql) = 'insert into subcountries (country_id, subcountry_category_id, code, fc_name, name, sequence) values (?, ?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	my($category_id);
	my($element);

	for my $key (sort{$$table{$a}{code} cmp $$table{$b}{code} } keys %$table)
	{
		$i++;

		$category_id	= 0;
		$element		= $$table{$key};

		for my $id (keys %$categories)
		{
			if ($$element{category} eq $$categories{$id}{name})
			{
				$category_id = $id;

				last;
			}
		}

		if ($category_id == 0)
		{
			$max_category_id++;

			# Note: The 2nd assignment is for the benefit of the 'if' in the previous loop,
			# at a later point in time.

			$category_id						= $max_category_id;
			$$categories{$category_id}{name}	= $$element{category};
			my($sql_2)							= 'insert into subcountry_categories (id, name) values (?, ?)';
			my($sth_2)							= $self -> dbh -> prepare($sql_2) || die "Unable to prepare SQL: $sql_2\n";

			$sth_2 -> execute($category_id, $$element{category});
		}

		$sth -> execute($country_id, $category_id, $$element{code}, fc $$element{name}, $$element{name}, $i);
	}

	$sth -> finish;

	return $i;

} # End of _save_subcountry.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database::Import - Part of the interface to www.scraper.wikipedia.iso3166.sqlite

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis>.

=head1 Description

Documents the methods used to populate the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro.

See L<WWW::Scraper::Wikipedia::ISO3166/Description> for a long description.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database::Import>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database::Import -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o code2 => $2_letter_code

Specifies the code2 of the country whose subcountry page is to be downloaded.

=back

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently
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

=head2 populate_subcountries()

Populate the I<subcountries> table, for all subcountries.

=head1 FAQ

For the database schema, etc, see L<WWW::Scraper::Wikipedia::ISO3166/FAQ>.

=head1 References

See L<WWW::Scraper::Wikipedia::ISO3166/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Scraper::Wikipedia::ISO3166>.

=head1 Author

C<WWW::Scraper::Wikipedia::ISO3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in
2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
