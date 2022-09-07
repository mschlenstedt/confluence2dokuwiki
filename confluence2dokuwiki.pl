#!/usr/bin/perl

use utf8;
use Encode qw(decode encode);
use Text::Unidecode;
use File::Basename;
use Data::Dumper;

##############################################################
# START Settings
##############################################################

# Remove Confluence Footer created by Confluence Export routine
my $remove_footer = 1;

# Remove "Created by..." created by Confluence Export routine
my $remove_createdby = 1;

# Remove Confluence Table of Contents
my $remove_toc = 1;

# Table of Contents Section Name
my $tocname = "Inhalt";

# Remove Attachement Section created by Confluence Export routine
my $remove_attachementsec = 1;

# Correct all wiki internal links to new location
# (if disabled, all internal links will point to the html
# file from the confluence export)
my $correct_internal_links = 1;

# Move main pages to (sub-)namespaces with equal name
# This is useful if you used confluence subpages. You main page
# will then be moved to the sub-namespace.
my $move_main_to_sub = 1;
my $name_mainpage = "start.txt";

##############################################################
# END Settings
##############################################################

# Pandoc
my $pandocbin = qx(which pandoc);
chomp ($pandocbin);

if (!-x $pandocbin) {
	die "Cannot find pandoc binary or pandoc binary not in my \$PATH.";
}

# Parameter
my $dir = $ARGV[0];

if (!-d $dir) {
	die "No folder given. Call $0 FOLDER_WITH_CONFLUENCE_EXPORT";
}

# Read given folder with Confluence Space export
my @files;
opendir(DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
        	# Use a regular expression to ignore files beginning with a period
		if ($file !~ m/\.html/ || $file !~ m/\.htm/) {
			next;
		}
		push (@files, $file);
	}
closedir(DIR);

# Delete old databsse
unlink ("linkdatabase.dat");

# Loop through all files
foreach my $inputfile (@files) {

	$dir =~ s/\/$//g;
	$inputfile = $dir . "/" . $inputfile;

	my @suffixes = (".html", ".htm");   
	my ($filename,$path,$suffix) = fileparse($inputfile, @suffixes);

	print "\nInput File: $inputfile\n";
	print "Input Basename: $filename\n";
	print "Input Path: $path\n";
	print "Input Suffix:: $suffix\n";

	if ($inputfile eq "") {
		print "No HTML file given: $inputfile. Skipping\n\n";
		next;
	}

	if (!-e $inputfile) {
		print "Given HTML file does not exist: $inputfile. Skipping.\n\n";
		next;
	}

	if ($suffix eq "") {
		print "No HTML file given: $inputfile. Skipping.\n\n";
		next;
	}

	my $confl_pagename = $filename;
	$confl_pagename =~ s/_(\d+)$//;
	my $confl_pageid = $1;
	$confl_pageid = $confl_pagename if ($confl_pageid eq "");

	my $dw_pagename = lc ($confl_pagename);
	#$dw_pagename = Encode::decode("UTF-8", $dw_pagename);
	$dw_pagename = unidecode($dw_pagename);

	print "Confluence Pagename: $confl_pagename\n";
	print "Confluence Page ID: $confl_pageid\n";
	print "DokuWiki Pagename: $dw_pagename\n";

	my $outputfile = $dw_pagename;
	my $outputfilenew = $outputfile; # Only needed for later on renaming
	my $tmpfile = $dw_pagename . ".tmp";
	print "Tmp. Output File: $tmpfile\n";

	print "\n########### Start pandoc to convert HTML to DokuWiki ###########\n\n";

	system ("$pandocbin --verbose --from=html --to=dokuwiki --output=$tmpfile $inputfile");

	if (!-e $tmpfile) {
		die "Something went wrong while using pandoc to convert from HTML to DokuWiki format.";
	}

	print "\n########### End pandoc ###########\n\n\n";

	open(IN, $tmpfile) or die("Could not open $tmpfile");
	binmode IN, ':encoding(UTF-8)';
	open(OUT, ">", $outputfile) or die("Could not open $outputfile");
	binmode OUT, ':encoding(UTF-8)';

	my $confl_space;
	my $dw_ns;

	my $check_ns = 1;
	my $weareintocsec;
	my $firstheading = 0;

	foreach $line (<IN>)  {

		$line =~ s/\n//;

		# Filter out blank lines until we reached first heading (title) - outerwise indexmenu plugin
		# show not the correct page titles
		if (!$firstheading && $line eq "") {
			next;
		}

		# First Links / Numeric List represent the Namespaces / Subpages
		if ($line =~ m/^\s+\- \[\[(.*)\|(.*)\]\]$/ && $check_ns) {
			if ($1 eq "index.html") { # This is Confluence Space
				$confl_space = $2;
				next;
			}
			elsif ($2 ne $confl_space) {
				my $tempns = $2;
				$tempns =~ s/://g;
				$dw_ns .= ":" . lc($tempns);
				next;
			}
			next;
		} else {
			my $check_ns = 0; # Stop checking for Namespaces after first x lines of document
			if ($dw_ns eq "") {
				$dw_ns = ":";
			}
			#$dw_ns = Encode::decode("UTF-8", $dw_ns);
			$dw_ns = unidecode($dw_ns);
			$dw_ns =~ s/\s+//g;
			$dw_ns =~ s/[^:A-Za-z0-9]//g;
			#$dw_ns =~ s/_+//g;
			$dw_ns =~ s/^:+/:/g;
			#$dw_ns =~ s/_*$//g;
			#$dw_ns =~ s/^_*//g;
			#$dw_ns =~ s/_:/:/g;
			#$dw_ns =~ s/:_/:/g;
			$dw_ns =~ s/^://g;
			$dw_ns = lc($dw_ns);
		}
		
		# Filter Page Heading
		if ($line =~ m/(=*) ($confl_space : )(.*) (=*)$/) {
			print OUT "$4 $3 $4\n";
			my $tmppagename = $3;
			if (!$firstheading) { # This is the first heading
				$firstheading = 1;
				if ($dw_pagename =~ m/^\d+$/) { # rename if there was only pageid in confluence without "real" name
					#$tmppagename = Encode::decode("UTF-8", $tmppagename);
					$tmppagename = unidecode($tmppagename);
					$tmppagename =~ s/\s+//g;
					$tmppagename =~ s/[^:A-Za-z0-9]//g;
					#$tmppagename =~ s/_$//g;
					#$tmppagename =~ s/^_//g;
					#$tmppagename =~ s/_+/_/g;
					$tmppagename = lc($tmppagename);
					$outputfilenew = lc($tmppagename);
					print "NEW DokuWiki Pagename: " . lc($tmppagename) . "\n";
				}
			}
			next;
		}
		
		# Filter Confluence Footer
		if ($line =~ m/^Document generated by Confluence/ && $remove_footer) {
			next;
		}
		if ($line =~ m/^\[\[http:\/\/www\.atlassian\.com\/\|Atlassian\]\]/ && $remove_footer) {
			next;
		}
		
		# Filter Created by line
		if ($line =~ m/^Created by / && $remove_createdby) {
			next;
		}
		
		# Filter Attachement section - this is always the last section. Finish conversation
		if ($line =~ m/=* Attachments: =*$/ && $remove_attachementsec) {
			last;
		}
		
		# Filter Table of Contents
		if ($line =~ m/=* $tocname =*/ && $remove_toc) {
			$weareintocsec = 1;
			next;
		}
		
		# We are in TOC section....
		if ($weareintocsec) {
			if ($line =~ m/^\s*$/ || $line =~ m/^\s+\* /) {
				next;
			} else {
				$weareintocsec = 0;
			}
		}
		
		# Filter internal anchor links
		$line =~ s/#$confl_pagename\-/#/g;

		# Filter Confluence Icons
		$line =~ s/\{\{images\/icons\/.*\}\}//g;
		
		# Filter non-image attachements (links to attachements)
		# Example: [[attachments/1193708001/1228539788.pdf|{{attachments/thumbnails/1193708001/1228539788?0x250}}]]
		#          [[attachments/1193708001/1228539788.pdf]]
		$line =~ s/\[\[attachments\/$confl_pageid\/([^\]\|]*)\|\{\{attachments\/thumbnails\/$confl_pageid\/[^\]]*\]\]/\{\{$dw_ns:$1|$1\}\}/g;
		$line =~ s/\[\[attachments\/$confl_pageid\/([^\]]*)\]\]/\{\{$dw_ns:$1\}\}/g;

		# Filter image attachements
		# Example: {{attachments/1215135897/1215135927.jpg?width=179?179x150}}
		if ($line =~ m/\{\{attachments\/$confl_pageid/) {
			$line =~ s/([^\}]*\?[^\}]*)\?[^\}]*\}\}/$1\}\}/g;
			$line =~ s/width=/w=/g;
			$line =~ s/height=/h=/g;
			$line =~ s/\?\d+x\d+//g;
		}
		$line =~ s/\{\{attachments\/$confl_pageid\/([^\}]*)\}\}/\{\{$dw_ns:$1\}\}/g;

		# Print line if nothing else to filter
		print OUT $line . "\n";

	}

	close(IN);
	close(OUT);

	print "DokuWiki Namespace is: $dw_ns\n";

	# Create path with namespaces for page and copy page
	$dw_ns_path = $dw_ns;
	$dw_ns_path =~ s/:/\//g;
	$dw_ns_path .= "/" if $dw_ns_path ne "";
	$outputfilenew = unidecode($outputfilenew);
	$outputfilenew =~ s/\s+//g;
	$outputfilenew =~ s/[^A-Za-z0-9]//g;
	print "Output File: ./pages/$dw_ns_path$outputfilenew.txt\n\n";
	system ("mkdir -p  ./pages/$dw_ns_path");
	system("cp $outputfile ./pages/$dw_ns_path$outputfilenew.txt");
	unlink ($outputfile);
	unlink ($tmpfile);

	# Create path with namespaces for media and copy media
	if (-e $path . "attachments/$confl_pageid") {
		system ("mkdir -p  ./media/$dw_ns_path");
		system ("cp -r $path" . "attachments/$confl_pageid/* ./media/$dw_ns_path");
	} else {
		print "No attachements found for this page.\n";
	}

	# "Register" file for later on internal link correction
	open(FILE, '>>', "linkdatabase.dat") or die("Could not open linkdatabase.dat");
		$dw_ns .= ":" if $dw_ns ne "";
		$dw_ns =~ s/^://;
		my $filepath = $dw_ns;
		$filepath =~ s/:/\//g;
		print FILE "./pages/$filepath$outputfilenew.txt" . "|" . $filename . $suffix . "|" . "$dw_ns" . "$outputfilenew.txt\n";
	close (FILE);
	
	print "\n\nAll files copied to ./media and ./pages.\n\n";
	

} # End Loop through all files

# Correct now some things we only can start if whole new files and filestructure exists

# Move main pages to sub-namespaces and rename to e.g. start.txt
if ($move_main_to_sub) {;
	print "\n";
	
	open(LINKS, '+<', "linkdatabase.dat") or die("Could not open linkdatabase.dat");
		binmode LINKS, ':encoding(UTF-8)';

		my @lines = <LINKS>;
		seek LINKS, 0, 0;
		truncate LINKS, 0;

		foreach $line (@lines)  {

			$line =~ s/\n//;
			my @fields = split (/\|/, $line);
			my @suffixes = (".txt");   
			my ($filename,$path,$suffix) = fileparse($fields[0], @suffixes);
			if (-d "$path$filename" && !-e "$path$filename/$name_mainpage") { # ns with equal name to file exists -> subpages
				my $newfile = "$path$filename/$name_mainpage";
				print "Found sub-namespace: Move $path$filename/$filename$suffix to $newfile\n";
				my @ns = split (/\//, $newfile);
				my $ns;
				foreach (@ns) { # Create new ns
					next if $_ =~ m/^pages$/ || $_ =~ m/\./ || $_ =~ m/\.txt$/;
					$ns .= "$_:";
				}
				system("mv $path$filename$suffix $newfile");
				print LINKS "$newfile|@fields[1]|$ns$name_mainpage\n";
				# Move and correct attachements
				open(PAGE, '+<', "$newfile") or die("Could not open $newfile");
					binmode PAGE, ':encoding(UTF-8)';
					my @pagelines = <PAGE>;
					seek PAGE, 0, 0;
					truncate PAGE, 0;
					foreach $pageline (@pagelines)  {
						$pageline =~ s/\n//;
						my $oldns;
						my $newns;
						while($pageline =~ m/([^\{\}]*)(\{\{[^\}]*\}\})([^\{\}]*)/g ) {
							my $link = $2;
							$link =~ s/[\{\}]*//g;
							$link =~ s/\?.*//g;
							$link =~ s/\|.*//g;
							$link =~ s/:/\//g;
							my $mediapath = $path;
							$mediapath =~ s/\/pages\//\/media\//g;
							if (-e "./media/$link") {
								print "Found media ./media/$link. Move to $mediapath$filename\n";
								system ("mkdir -p $mediapath$filename");
								system ("mv ./media/$link $mediapath$filename");
							}
							$oldns = $path;
							$oldns =~ s/\.\/pages\///g;
							$oldns =~ s/\//:/g;
							$oldns =~ s/:$//g;
							$newns = "$mediapath$filename";
							$newns =~ s/\.\/media\///g;
							$newns =~ s/\//:/g;
							$newns =~ s/:$//g;
						}
						$pageline =~ s/$oldns/$newns/g;
						print PAGE $pageline . "\n";
					}
				close (PAGE);
			} else {
				print LINKS $line . "\n";
			}

		}
	close (LINKS);

}

# Correct wiki internal links
if ($correct_internal_links) {;
	print "\n";
	
	open(LINKS, '<', "linkdatabase.dat") or die("Could not open linkdatabase.dat");
		binmode LINKS, ':encoding(UTF-8)';
		my @linklines = <LINKS>;
	close (LINKS);

	foreach $linkline (@linklines)  {

		$linkline =~ s/\n//;
		my @fields = split (/\|/, $linkline);
		if (-e @fields[0]) {
			print "Converting internal links in @fields[0]\n";
			open(PAGE, '<', "@fields[0]") or die("Could not open @fields[0]");
				binmode PAGE, ':encoding(UTF-8)';
				my @pagelines = <PAGE>;
			close (PAGE);
			foreach $linkline1 (@linklines) {
				$linkline1_ =~ s/\n//;
				my @fields1 = split (/\|/, $linkline1);
					foreach (@pagelines) {
						$_ =~ s/@fields1[1]/@fields1[2]/g;
						$_ =~ s/\n//g;
					}
			}
			open(PAGE, '>', "@fields[0]") or die("Could not open @fields[0]");
				binmode PAGE, ':encoding(UTF-8)';
				foreach (@pagelines) {
					print PAGE $_ . "\n";
				}
			close (PAGE);

		}

	}

}

print "\n\nAll files done. Good bye.\n\n";
exit(0);
