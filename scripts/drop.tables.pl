#!/usr/bin/env perl

use strict;
use warnings;

use Locale::ISO::3166::Database::Create;

# ----------------------------

Locale::ISO::3166::Database::Create -> new -> drop_all_tables;
