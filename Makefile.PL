#!/usr/bin/env perl

use inc::Module::Install;

# -----------------------

name 'Locale-ISO-3166';

license 'perl';

all_from 'lib/Locale/ISO/3166.pm';

install_share;

license 'perl';

resources
repository => 'https://github.com/ronsavage/Locale-ISO-3166.git';

requires 'Config::Tiny'					=> 2.14;
requires 'DBD::SQLite'					=> 1.50;
requires 'DBI'							=> 1.620;
requires 'DBIx::Admin::CreateTable'		=> 2.07;
requires 'File::ShareDir'				=> 1.03;
requires 'File::Slurper'				=> 0.008;
requires 'File::Spec'					=> 3.33;
requires 'Getopt::Long'					=> 2.38;
requires 'Log::Handler'					=> 0.84;
requires 'Mojo::DOM'					=> 0; # This is just for my Makefile.PL cross-checker.
requires 'Moo'							=> 2.001001;
requires 'open'							=> 1.08;
requires 'parent'						=> 0.225;
requires 'perl'							=> 5.10.1;
requires 'PerlIO::utf8_strict'			=> 0.006; # Optionally used by File::Slurper.
requires 'Pod::Usage'					=> 1.51;
requires 'Sort::Naturally'				=> 1.03;
requires 'strict'						=> 1.04;
requires 'Types::Standard'				=> 1.000005;
requires 'Unicode::CaseFold'			=> 1.00;
requires 'Unicode::Normalize'			=> 1.25;
requires 'warnings'						=> 1.12;

test_requires 'Test::More'				=> '1.302022';	# Used by xt/t/pod.t.
test_requires 'Test::Pod'				=> '1.51';		# Used by xt/t/pod.t.

WriteAll;
