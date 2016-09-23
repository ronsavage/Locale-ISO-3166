#!/usr/bin/env perl

use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Capture::Tiny 'capture';

use Locale::ISO::3166::Database;

use Test::More;

# ---------------------------------------------

my(@params);

push @params, '-Ilib', 'scripts/report.statistics.pl';
push @params, '-max', 'info';

my($stdout, $stderr, $result)	= capture{system($^X, @params)};
my(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
my(@expected)					= split(/\n/, <<EOS);
countries_in_db => 249
has_subcounties => 198
subcountries_in_db => 4847
subcountry_types_in_db => 92
EOS

is(@got, @expected, 'report_statistics() returned the expected data');

@params = ();

push @params, '-Ilib', 'scripts/report.Australian.statistics.pl';
push @params, '-max', 'info';

($stdout, $stderr, $result)	= capture{system($^X, @params)};
(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
(@expected)					= split(/\n/, <<EOS);
AU-ACT: Australian Capital Territory
AU-NSW: New South Wales
AU-NT: Northern Territory
AU-QLD: Queensland
AU-SA: South Australia
AU-TAS: Tasmania
AU-VIC: Victoria
AU-WA: Western Australia
EOS

is(@got, @expected, 'report_Australian_statistics() returned the expected data');

done_testing;
