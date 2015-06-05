#!/usr/bin/perl -w 

# f5orphan.pl: Script that prints potentially orphaned objects in a bigip.conf file
#
# USAGE:       f5orphan.pl -f <filename> -i <configuration item>
#
# Author:      Bradford White, 20091022
# Contributor: Jesse Mauntel, 20121112
#
# TODO: Add option (-l for ltm) to directly connect to an F5 unit to get the information
# TODO: Add 'all' configuration item which will list all possible orphan config items
# TODO: Add the ability to print the entire definition of a configuration object (same as b list)(use s 
#       option to match across lines.


# ===============================================================
# 0: Load modules, initialize variables and check command syntax
# ===============================================================

use strict;
use warnings;
use Getopt::Std;

my @config_items;

use vars qw/ %opt /;
my $optString = 'f:i:h';


# --------------------------------------------
# Message about this program and how to use it
# --------------------------------------------

sub usage() {

  print STDERR << "EOF";

This program identifies F5 objects that are likely orphaned and can be removed
from the configuration.  Carefully review each item before removal.

  usage: $0 -f <filename> -i <configuration item>

  Valid configuration items: 
    rule | data-group | profile | snatpool | pool | node | monitor

  example: $0 -f bigip.conf -i node

EOF
  exit;
}


# ------------------------------------------------------------------------
# Process command-line arguments, verify required options have been passed
# ------------------------------------------------------------------------

getopts( "f:i:h", \%opt ) or usage();
usage() if $opt{h};
usage() if not $opt{f};
usage() if not $opt{i};


# ------------------------------------------------------------
# Identify the correct search pattern for the requested object
# ------------------------------------------------------------

my %searchPatterns = (
  "node"       => "^ltm\\s$opt{i}\\s(.*)\\s\{",
  "pool"       => "^ltm\\s$opt{i}\\s\/.*\/(.*)\\s\{",
  "rule"       => "^ltm\\s$opt{i}\\s(.*)\\s\{",
  "data-group" => "^ltm\\s$opt{i}\\s.*\\s\/.*\/(.*)\\s\{",
  "monitor"    => "^ltm\\s$opt{i}\\s.*\\s(.*)\\s\{",
  "profile"    => "^ltm\\s$opt{i}\\s.*\\s(.*)\\s\{",
  "snatpool"   => "^ltm\\s$opt{i}\\s(.*)\\s\{"
);

my $searchPattern = $searchPatterns { $opt{i} } or die "Search pattern not identified, exiting...\n";


# ==================
# 1: Parse for items
# ==================

# -------------------------------------------------------------------
# Parse the bigip.conf file and add all items to a @config_items list
# -------------------------------------------------------------------

print "\nChecking file: $opt{f} for unused \"$opt{i}\" objects\n";

open(DATA, $opt{f}) or die "Couldn't open datafile: $!\n";

while (<DATA>) {

  # Find lines that match the object's searchPattern and add them to the oject array
  m/$searchPattern/x and push (@config_items, $1);

}


# ======================
# 2: Count for each item
# ======================

# -----------------------------------------------------------------------
# Count the number of times the item is referenced in the bigip.conf file
# and put the counts into a %count hash
# -----------------------------------------------------------------------

my %count=();

foreach my $item (@config_items) {

  open(DATA, $opt{f}) or die "Couldn't open datafile: $!\n";

  while (<DATA>) {

    # Match lines that contain the item name and increment the count hash for that item
    m/$item\b/x and $count{$item}++;

  }
}


# ============================================================================================
# 3: Print items that have a count of only one (configured but not referenced by other objects)
# ============================================================================================

print "\nPotential $opt{i} orphans:\n\n";

foreach my $item (sort keys %count) {

  $count{$item} == 1 and print "$item\n";

}

print "\n";
