#!/usr/bin/env perl

use strict;
use warnings;

use File::ShareDir;

# -----------------

my($app_name)	= 'Locale-ISO-3166';
my($db_name)	= shift || 'locale.iso.3166.sqlite';
my($path)		= File::ShareDir::dist_file($app_name, $db_name);

print "Using: File::ShareDir::dist_file('$app_name', '$db_name'): \n";
print "Found: $path\n";
