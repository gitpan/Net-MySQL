#!perl

use Net::MySQL;
use Getopt::Std;
use strict;

use constant PROMPT          => 'mysql.PP> ';
use constant WELCOME_MESSAGE => "Welcome to the MySQL.PP monitor. Type 'quit' for quit mysq.PP.\n";
use constant QUIT_MESSAGE    => "Bye\n";


my %option;
getopts '?vh:u:P:', \%option;
my $database = shift;
show_version() if $option{v};
show_usage()   if $option{'?'} || ! defined $database;
$option{h} ||= 'localhost';
$option{u} ||= $ENV{USER};
$option{P} ||= 3306;

my $password;
system 'stty -echo';
print 'Enter password: ';
chomp($password = <STDIN>);
system 'stty echo';
print "\n";

my $mysql = Net::MySQL->new(
	hostname => $option{h},
	port     => $option{P},
	database => $database,
	user     => $option{u},
	password => $password,
	debug => 0,
);
print WELCOME_MESSAGE;
print PROMPT;
while (my $query = <>) {
	chomp $query;
	last if $query =~ /^(?:q(?:uit)?|exit|logout|logoff)$/i;
	if ($query !~ /^\s*$/) {
		eval {
			$mysql->query($query);
			if ($mysql->is_error) {
				print $mysql->get_error_message, "\n";
			}
			elsif ($mysql->has_selected_record) {
				my $record = $mysql->create_record_iterator;
				while (my $column = $record->each) {
					printf "%s\n", join ', ', @$column;
				}
			}
			else {
				printf "%d records\n", $mysql->get_affected_rows_length;
			}
		};
		if ($@) {
			print "$@\n";
		}
	}
	print PROMPT;
}

print QUIT_MESSAGE;
$mysql->close;
exit;


sub show_usage
{
	die <<__USAGE__;
Usage: mysq.pl [-?v] -h HOSTNAME [-P PORT] [-u USER] DATABASE

  -?   Display this help and exit.
  -h   Connect to host.
  -P   Port number to user for connection.(default 3306)
  -u   User for login if not current user.
  -v   Output version information and exit.

  Example:
    % mysql.pl -h mysql.example.jp -u root mydatabase
__USAGE__
}

sub show_version
{
	die <<__VERSION__;
$0  Ver $Net::MySQL::VERSION
__VERSION__
}

__END__
