#!/usr/bin/perl
# David Rice
# This script will generate an rss feed of git logs

use XML::RSS;
use Git;
use strict;

my %dept = (
	'test' => {
		dir => '<path/to/git/server/',
		title => "local test",
		link => "https:<path/to/file.xml",
		},
	);
my $deptkey = $ARGV[0];


my $rss = XML::RSS->new(version => '2.0');

# This will give perl control over the git repository so it can generate the logs.
my $repo = Git->repository(Directory => $dept{$deptkey}{dir});

# if passed a commandline numeric argument it will generate that many logs, otherwise it will create
# a default of 25.
my @log;
if(defined $ARGV[1]){
	@log = split('\n', $repo->command('log', '--stat', "-n $ARGV[1]"));
}
else{
	@log = split('\n', $repo->command('log', '--stat', "-n 25"));
}

# definition of the rss channel
$rss->channel(
	title	=>	$dept{$deptkey}{title},
	link	=>	$dept{$deptkey}{link},
	);

# this section will parse the git log into, author, date, message, merge and path so that it can be 
# added to the rss feed later in the script.
my $i = 0;
my %logdet;
foreach my $line(@log){
	if($line =~ /^Author/){
		$line =~ /\:/;
		$line = $';
		$logdet{$i}{author} = $line;
		$i++;
	}
	elsif($line =~ /^Date/){
		$line =~ /\-/;
		$line = $`;
		$line =~ /\:/;
		$line = $';
		$logdet{$i-1}{date} = $line;
	}
	elsif($line =~ /^ / && $line !~ /files changed/ && $line !~ /\//){ #if the line starts as whitespace but doesnt have /
		$line =~ s/^\s+//;
		$logdet{$i-1}{message} .= $line." ";
	}
	elsif($line =~ /Merge branch/){
		$line =~ s/^\s+//;
		$logdet{$i-1}{merge} = $line;
	}
	elsif($line =~ /\//){ # if the line contains /
		$line =~ s/^\s+//;
		$line =~ /\|/;
		$line = $`;
		$logdet{$i-1}{path} = $line;
	}
}

# this section will use the recently created hashes of git logs and add them to an rss feed.
for(my $j=0; $j<$i; $j++){
	my $title = ($logdet{$j}{date}." - ".$logdet{$j}{author});
	my $link = "";
	if (!exists $logdet{$j}{path} || $logdet{$j}{path} !~ /^\w/){
		$link = "<insert a link here>";
	}
	else {
		$link = $logdet{$j}{path};
	}
	my $description;
	if(exists $logdet{$j}{merge}){
		$description = $logdet{$j}{merge};
	}
	else{
		$description = $logdet{$j}{message};
	}

	if (defined $logdet{$j}{path}){
		$rss->add_item(
			title => $title."",
			link => "https://<path/to/file.xml>",
			description => $description." - ".$link,
   		);
	}
	else{
		$rss->add_item(
			title => $title."",
			link => "https://<path/to/file.xml>",
			description => $description,
   		);
	}	
}

#$rss->{output} = "2.0";
# this will print in an .xml file
print $rss->as_string();
