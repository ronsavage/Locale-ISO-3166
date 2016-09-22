#!/usr/bin/env perl

use strict;
use warnings;

use Locale::ISO::3166;

# --------------------------

my($iso3166) = Locale::ISO::3166 -> new;

$iso3166 -> run;

