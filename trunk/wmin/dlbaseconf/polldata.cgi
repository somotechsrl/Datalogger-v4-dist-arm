#!/usr/bin/perl

require 'dlbaseconf-lib.pl';

&ui_print_header(undef, $text{'working'}, "", undef, 1, 1);
&show_polldata();
&ui_print_footer("", $text{'return'});

