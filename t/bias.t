#!/usr/local/bin/perl -w

# Copyright 1999-2000, Paul Johnson (pjcj@cpan.org)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.transeda.com/pjcj

# Version 1.06 - 13th February 2000

use strict;

use lib -d "t" ? "t" : "..";

use Lines;

my $report = (-d "t" ? "t/" : "") . "lines/bias";

Lines->test(tests          => 36,
            report         => $report,
            lines_report   => "$report.l",
            report_command => $ENV{lines} ? "$report.l\n" : undef,
            generate       => $ENV{generate},
            perl_program   => "$report.plx",
            perl_report    => "$report.p",
            perl_command   => "");