#!/usr/bin/env perl

use strict;
use warnings;

use Locale::ISO::3166::Database;

# ------------------------------

Locale::ISO::3166::Database -> new -> report_statistics;
