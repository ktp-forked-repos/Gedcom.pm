#!/usr/local/bin/perl -w

# This program was generated by lines2perl, which is part of Gedcom.pm.
# Gedcom.pm is Copyright 1999-2012, Paul Johnson (paul@pjcj.net)
# Version 1.17 - 29th December 2012

# Gedcom.pm is free.  It is licensed under the same terms as Perl itself.

# The latest version of Gedcom.pm should be available from my homepage:
# http://www.pjcj.net

use strict;

require 5.005;

use diagnostics;
use integer;

use Getopt::Long;

use Gedcom::LifeLines 1.17;

my $Ged;                                                         # Gedcom object
my %Opts;                                                              # options
my $_Traverse_sub;                                     # subroutine for traverse

sub out  { print  STDERR @_ unless $Opts{quiet} }
sub outf { printf STDERR @_ unless $Opts{quiet} }

sub initialise ()
{
  die "usage: $0 -gedcom_file file.ged\n"
    unless GetOptions(\%Opts,
                      "gedcom_file=s",
                      "quiet!",
                      "validate!",
                     ) and defined $Opts{gedcom_file};
  local $SIG{__WARN__} = sub { out "\n@_" };
  out "reading...";
  $Ged = Gedcom->new
  (
    gedcom_file  => $Opts{gedcom_file},
    callback     => sub { out "." }
  );
  if ($Opts{validate})
  {
    out "\nvalidating...";
    my %x;
    my $vcb = sub
    {
     my ($r) = @_;
     my $t = $r->{xref};
     out "." if $t && !$x{$t}++;
    };
    $Ged->validate($vcb);
  }
  out "\n";
  set_ged($Ged);
}

$SIG{__WARN__} = sub
{
  out $_[0] unless $_[0] =~ /^Use of uninitialized value/
};

# /*
# namefreq
# 
# Tabulate frequency of first names in database.
# 
# Version 1 - 1993 Jun 16 - John F. Chandler
# Version 2 - 1993 Jun 18 (sort output by frequency)
# Version 3 - 1995 Mar 8  (requires LL 3.0 or higher)
# 			(Uses Jim Eggert's Quicksort routine)
# 
# This report counts occurrences of all first (given) names in the
# database.  Individuals with only surnames are not counted.  If the
# surname is listed first, the next word is taken as the given name.
# 
# The output file is normally sorted in order of decreasing frequency,
# but the sort order can be altered by changing func "compare", e.g.,
# comment out the existing "set" and uncomment the one for alphabetical
# order.
# 
# This program works only with LifeLines.
# 
# */
my $name_counts;
# /* used by comparison in sorting by frequency */
# /* Comparison function for sorting.  Same convention as strcmp. */
sub compare ($$)
{
  my($astring, $bstring) = @_;
  my $ret;
  # /* alphabetical:
  # 	return(strcmp(astring,bstring)) */
  # /* decreasing frequency: */
  # 	
  if ($ret = ($name_counts->{$bstring} - $name_counts->{$astring}))
  {
    return ($ret);
  }
  return (&strcmp($astring, $bstring));
}

# /*
#    quicksort: Sort an input list by generating a permuted index list
#    Input:  alist  - list to be sorted
#    Output: ilist  - list of index pointers into "alist" in sorted order
#    Needed: compare- external function of two arguments to return -1,0,+1
# 		    according to relative order of the two arguments
# */
sub quicksort ($$)
{
  my($alist, $ilist) = @_;
  my $index;
  my $len;
  $len = (scalar @$alist);
  $index = $len;
  LOOP: while ($index)
  {
    $ilist->[$index - 1] = $index;
    $index--;
  }
  display &qsort($alist, $ilist, 1, $len);
  undef
}

# /* recursive core of quicksort */
sub qsort ($$$$)
{
  my($alist, $ilist, $left, $right) = @_;
  my $mid;
  my $pcur;
  my $pivot;
  if ($pcur = &getpivot($alist, $ilist, $left, $right))
  {
    $pivot = $alist->[$ilist->[$pcur - 1] - 1];
    $mid = &partition($alist, $ilist, $left, $right, $pivot);
    display &qsort($alist, $ilist, $left, ($mid - 1));
    display &qsort($alist, $ilist, $mid, $right);
  }
  undef
}

# /* partition around pivot */
sub partition ($$$$$)
{
  my($alist, $ilist, $left, $right, $pivot) = @_;
  my $ge;
  my $gt;
  my $lt;
  my $tmp;
  LOOP: while (1)
  {
    $tmp = $ilist->[$left - 1];
    $ilist->[$left - 1] = $ilist->[$right - 1];
    $ilist->[$right - 1] = $tmp;
    LOOP: while ((&compare($alist->[$ilist->[$left - 1] - 1], $pivot) < 0))
    {
      $left++;
    }
    LOOP: while ((&compare($alist->[$ilist->[$right - 1] - 1], $pivot) >= 0))
    {
      $right--;
    }
    if (($left > $right))
    {
      last LOOP;
    }
  }
  return ($left);
}

# /* choose pivot */
sub getpivot ($$$$)
{
  my($alist, $ilist, $left, $right) = @_;
  my $gt;
  my $le;
  my $left0;
  my $lt;
  my $pivot;
  my $rel;
  $pivot = $alist->[$ilist->[$left - 1] - 1];
  $left0 = $left;
  $left++;
  LOOP: while (($left <= $right))
  {
    $rel = &compare($alist->[$ilist->[$left - 1] - 1], $pivot);
    if (($rel > 0))
    {
      return ($left);
    }
    if (($rel < 0))
    {
      return ($left0);
    }
    $left++;
  }
  return (0);
}

sub main ()
{
  my $eq;
  my $fname;
  my $gindx;
  my $ilist;
  my $index;
  my $indi;
  my $namelist;
  my $names;
  my $ncomp;
  my $nmatch;
  my $not;
  my $num;
  my $or;
  my $sindx;
  $namelist = [];
  $name_counts = {};
  $names = [];
  $ilist = [];
  $num = 0;
  LOOP: for $indi ($Ged->individuals)
  {
    $num++;
    if ((! ($num % 20)))
    {
      display &print(".");
    }
    display &extractnames(&inode($indi), $namelist, $ncomp, $sindx);
    $gindx = 1;
    if (($sindx == 1))
    {
      $gindx = 2;
    }
    $fname = &save($namelist->[$gindx - 1]);
    if ((($sindx > 1) || ($ncomp > $sindx)))
    {
      if ($nmatch = $name_counts->{$fname})
      {
        $nmatch = ($nmatch + 1);
      }
      else
      {
        push @$names, $fname;
        $nmatch = 1;
      }
      $name_counts->{$fname} = $nmatch;
    }
  }
  display "Frequency of given names (first only) in the database\n\n";
  display "Name              Occurrences\n\n";
  display &quicksort($names, $ilist);
  $num = 0;
  LOOP: for $index (@$ilist)
  {
    $num++;
    $fname = $names->[$index - 1];
    display $fname;
    $nmatch = $name_counts->{$fname};
    display &col((25 - &strlen(&d($nmatch))));
    display &d($nmatch);
    display "\n";
  }
  undef
}


initialise();
main();
flush();
0

__END__

Original LifeLines program follows:

/*
namefreq

Tabulate frequency of first names in database.

Version 1 - 1993 Jun 16 - John F. Chandler
Version 2 - 1993 Jun 18 (sort output by frequency)
Version 3 - 1995 Mar 8  (requires LL 3.0 or higher)
			(Uses Jim Eggert's Quicksort routine)

This report counts occurrences of all first (given) names in the
database.  Individuals with only surnames are not counted.  If the
surname is listed first, the next word is taken as the given name.

The output file is normally sorted in order of decreasing frequency,
but the sort order can be altered by changing func "compare", e.g.,
comment out the existing "set" and uncomment the one for alphabetical
order.

This program works only with LifeLines.

*/
global(name_counts)	/* used by comparison in sorting by frequency */

/* Comparison function for sorting.  Same convention as strcmp. */
func compare(astring,bstring) {
/* alphabetical:
	return(strcmp(astring,bstring)) */
/* decreasing frequency: */
	if(ret,sub(lookup(name_counts,bstring),lookup(name_counts,astring))){
		return(ret)
	}
	return(strcmp(astring,bstring))
}

/*
   quicksort: Sort an input list by generating a permuted index list
   Input:  alist  - list to be sorted
   Output: ilist  - list of index pointers into "alist" in sorted order
   Needed: compare- external function of two arguments to return -1,0,+1
		    according to relative order of the two arguments
*/
proc quicksort(alist,ilist) {
    set(len,length(alist))
    set(index,len)
    while(index) {
	setel(ilist,index,index)
	decr(index)
    }
    call qsort(alist,ilist,1,len)
}

/* recursive core of quicksort */
proc qsort(alist,ilist,left,right) {
    if(pcur,getpivot(alist,ilist,left,right)) {
	set(pivot,getel(alist,getel(ilist,pcur)))
	set(mid,partition(alist,ilist,left,right,pivot))
	call qsort(alist,ilist,left,sub(mid,1))
	call qsort(alist,ilist,mid,right)
    }
}

/* partition around pivot */
func partition(alist,ilist,left,right,pivot) {
    while(1) {
	set(tmp,getel(ilist,left))
	setel(ilist,left,getel(ilist,right))
	setel(ilist,right,tmp)
	while(lt(compare(getel(alist,getel(ilist,left)),pivot),0)) {
	    incr(left)
	}
	while(ge(compare(getel(alist,getel(ilist,right)),pivot),0)) {
	    decr(right)
	}
	if(gt(left,right)) { break() }
    }
    return(left)
}

/* choose pivot */
func getpivot(alist,ilist,left,right) {
    set(pivot,getel(alist,getel(ilist,left)))
    set(left0,left)
    incr(left)
    while(le(left,right)) {
	set(rel,compare(getel(alist,getel(ilist,left)),pivot))
	if (gt(rel,0)) { return(left) }
	if (lt(rel,0)) { return(left0) }
	incr(left)
    }
    return(0)
}

proc main ()
{
	list(namelist)
	table(name_counts)
	list(names)
	list(ilist)

	forindi (indi, num) {
		if(not(mod(num,20))) {print(".")}
		extractnames(inode(indi), namelist, ncomp, sindx)
		set(gindx,1) if(eq(sindx,1)) { set(gindx,2) }
		set(fname, save(getel(namelist, gindx)))
		if( or( gt(sindx,1), gt(ncomp,sindx))) {
			if(nmatch, lookup(name_counts, fname)) {
				set(nmatch, add(nmatch, 1))
			}
			else {
				enqueue(names, fname)
				set(nmatch, 1)
			}
			insert(name_counts, fname, nmatch)
		}
	}
	"Frequency of given names (first only) in the database\n\n"
	"Name              Occurrences\n\n"

	call quicksort(names,ilist)
	forlist(ilist, index, num) {
		set(fname,getel(names,index))
		fname
		set(nmatch, lookup(name_counts, fname))
		col(sub(25, strlen(d(nmatch))))
		d(nmatch) "\n"
	}
}

