use strict;
use warnings;
use Module::Build;

use Prima::Config;

use PDL::Core::Dev;
my $inc = PDL_INCLUDE;
$inc =~ s/^-I//;

my @incs = ($inc, @{$Prima::Config::Config{incpaths}});

my $build = Module::Build->new(
	module_name => 'PDL::Prima::DirectImage',
	license  => 'perl',
	needs_compiler => 1,
	include_dirs => \@incs,
	configure_requires => {
		# meta_merge was added in v 0.28:
		'Module::Build' => 0.28,
	},
	requires => {
		# No I will not support 5.6
		perl					=> '5.8.0',
		PDL						=> '2.4.0',
#		Prima					=> 1.40,
	},
);

$build->create_build_script;
