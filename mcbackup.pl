#!/usr/bin/perl
# Minecraft backup script
# Written by Barret Rennie

# This script is intended to be run via cron(8).

use strict;

use Archive::Tar;
use File::Find;
use File::Path;
use File::stat;
use POSIX qw(strftime);

no warnings "File::Find";

$Archive::Tar::warn = 0;

# Begin configuration

# The screen Minecraft runs on
my $screen = "";

# The directory Minecraft is in; use an absolute path.
my $mcdir = "";

# The backup directory; use an absolute path.
my $backups = "";

# The number of backups to keep
my $numbackups = 1;

# The format to pass to strftime; the default is YYYY-MM-DD.
my $datefmt = "%Y-%m-%d";

# The worlds to backup (do not include nether worlds).
my @worlds = ();

# The path to sendmail (usually /usr/sbin/sendmail); leave it blank to disable.
my $sendmail = "";

# Who to email in case the backup fails
my @mailto = ();

# Who is the mail from
my $address = "";

# End configuration

my @errors;

sub error($) { push(@errors, pop()); }

sub date() { return strftime($datefmt, localtime()); }

sub mcsend($) { system("screen", "-x", $screen, "-X", "stuff", pop() . "\r"); }

sub mail_errors()
{
	open(my $handle, "|${sendmail} -t") or return;

	print $handle "To: " . join(",", @mailto) . "\n";
	print $handle "From: \"Minecraft Backup\" <${address}>\n";
	print $handle "Subject: Backup Errors " . date() . "\n";
	print $handle "Content-type: text/plain\n\n";

	print $handle "The following errors occured during the backup process:\n\n";

	foreach my $error (@errors)
	{
		print $handle $error . "\n";
	}
	
	close($handle);
}

sub backup($)
{
	my $subdir = pop();
	my $date = date();
	my $archive = "${backups}${subdir}/${subdir}_${date}.tar.bz2";
	my @files;
	
	# Strip $mcdir from all file paths; the resulting file paths are relative to
	# $mcdir.
	
	my $pusher = sub
	{
		push(@files, substr($File::Find::name, length($mcdir)));
	};

	if (! -e "${backups}${subdir}")
	{
		if (!make_path("${backups}${subdir}"))
		{
			error("Could not create path \"${backups}${subdir}\": $!");
			return;
		}
	}

	find($pusher, "${mcdir}${subdir}");
	
	if (!Archive::Tar->create_archive($archive, "bzip2", @files))
	{
		error("${Archive::Tar::error} (${archive})");
	}
}

sub clean($)
{
	my $subdir = pop();
	my %mtimes;
	my @files;

	%mtimes = map { $_ => stat($_)->mtime } glob("${subdir}_*.tar.bz2");

	# Sort in reverse to get the oldest files first.
	@files = sort {$mtimes{$b} <=> $mtimes{$a}} keys(%mtimes);

	while ($#files > $numbackups)
	{
		my $file = pop(@files);
		unlink($file) or error("Could not delete file \"${file}\": $!");
	}
}

# Assure that the paths end with /
$mcdir .= "/" unless (substr($mcdir, -1) eq "/");
$backups .= "/" unless (substr($backups, -1) eq "/");

if (-e "${mcdir}server.log.lck")
{
	mcsend("say Backing up all worlds...");

	mcsend("save-off");
	mcsend("save-all");
	
	# We must wait for the map to save, but it does not take very long.
	sleep(2);
}

foreach my $world (@worlds)
{
	if (!chdir($mcdir))
	{
		error("Could not chdir to \"${mcdir}\": $!");
		last;
	}
	
	backup($world);
	backup($world . "_nether");
	
	if (!chdir("${backups}${world}"))
	{
		error("Could not chdir to \"${backups}${world}\": $!");
		last;
	}
	
	clean($world);
	clean($world . "_nether");
}

if (-e "${mcdir}server.log.lck")
{
	mcsend("save-on");
	
	mcsend("Backup completed.");
}

if (@errors && $sendmail)
{
	mail_errors();
}