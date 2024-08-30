#!/usr/bin/perl
#
# Pre-commit hook for running Checkstyle on changed Java sources
#
# To use this you need:
# 1. Checkstyle's jar file somewhere
# 2. A Checkstyle XML check file somewhere
# 3. To configure git:
#   * git config --add checkstyle.jar <location of jar>
#   * git config --add checkstyle.checkfile <location of checkfile>
#   * git config --add java.command <path to java executable> [optional
#     defaults to assuming it's in your path]
# 4. Put this in your .git/hooks directory as pre-commit
#
# Now, when you commit, you will be disallowed from doing so
# until you pass your Checkstyle checks.

use strict;
use warnings;


# Retrieve the list of staged files
my $diff_command = "git diff --cached --name-only";
open my $file_handle, '-|', $diff_command or die "Cannot run '$diff_command': $!\n";

# Configuration retrieval
my $config_check_file = 'checkstyle.checkfile';
my $config_jar = 'checkstyle.jar';
my $config_java = 'java.command';

my $check_file = `git config --get $config_check_file`;
my $checkstyle_jar = `git config --get $config_jar`;
my $java_command = `git config --get $config_java`;

if (!$check_file || !$checkstyle_jar) {
    die "You must configure Checkstyle in your git config:\n"
      . "\t$config_check_file - path to your Checkstyle XML file\n"
      . "\t$config_jar - path to your Checkstyle jar file\n"
      . "\t$config_java - path to your Java executable (optional)\n";
}

$java_command = "java" if (!$java_command);

chomp($check_file);
chomp($checkstyle_jar);
chomp($java_command);

# Build Checkstyle command
my $checkstyle_command = "$java_command -jar $checkstyle_jar -c $check_file";

my @java_files;

while (my $file = <$file_handle>) {
    chomp $file;
    next unless $file =~ /\.java$/;  # Only consider .java files
    push @java_files, $file;
    $checkstyle_command .= " $file";
}

if (@java_files) {
    print STDERR "Running Checkstyle on the following files:\n";
    print STDERR join("\n", @java_files), "\n";
    
    # Execute Checkstyle command
    if (run_and_log_system($checkstyle_command)) {
        print STDERR "Commit aborted due to Checkstyle errors.\n";
        exit 1;
    }
}

exit 0;

sub run_and_log_system {
    my ($cmd) = @_;
    print STDERR "Running command: $cmd\n";  # Print the command for debugging
    my $result = system($cmd);
    return $result != 0;  # Return true if command failed
}
