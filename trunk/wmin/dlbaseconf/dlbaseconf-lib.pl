use WebminCore;
use datalogger_lib;
use datalogger_var;

init_config();

# hardcoded!!!
my $licfile="/opt/datalogger/etc/.license";
my $filename="/opt/datalogger/etc/datalogger";

# List of fields for this module
my @flist=[
	"COMMPAUSE","COMMFREQ",
	"POLLPAUSE","POLLFREQ",
	"SYNCPAUSE","SYNCFREQ",
	"DLDESCR"
];

my @liclist=[
	"type","released","expiration","generated","md5sum","sha256sum"
	];

sub show_polldata {
	print ui_form_start('polldata.cgi',"POST");
	&dataloggerShowConfig(@flist,$filename);
	print ui_form_end([ [ "command" , $text{'save'} ] ]);
	}

sub show_licensing {
	print ui_form_start('licensing.cgi',"POST");
	&dataloggerShowConfig(@liclist,$licfile,1);
	print ui_form_end([ [ undef, $text{'apply_lic'} ] ]);
	}

sub save_polldata {
	&dataloggerSaveConfig(@flist,$filename);
	}

sub delete_module {

	my ($module,$row) = @_;
	foreach $r (keys %in) {
		if($r =~ /row_/) {
			callDataloggerAPI("iifConfig $module del $in{$r}");
			}
		}
	}

sub save_module {

	my ($module) = @_;

	# get params list via API
	$params=callDataloggerAPI("iifConfig $module params");
	@parray=split /[\n\r ]/,$params;

	# generates from POST
	my $pdata;
	foreach $p (@parray) {
		$pdata.=" '$in{$p}'";
		}
	callDataloggerAPI("iifConfig $module add $pdata");
	}


sub create_module {

	my ($module) = @_;

	# create new rowe/config
	@plist=split /[\n\r ]/, callDataloggerAPI("iifConfig '$module' 'params'");

	print &ui_table_start($text{"create_data"}.": ".$module);
	&dataloggerShowConfig(\@plist,"/tmp/$module.edit");
	print &ui_table_end();

	}

sub display_module {

	my ($module,$value) = @_;

	$dlparams=&dataloggerApiParams($module);
	$dldescr=$dlparams ? $text{"drshow"} : $text{"drnoshow"};
	print &ui_table_start($dldescr.": ".$module);
	#$filedata=callDataloggerAPI("iifConfig $module print");
	#&dataloggerCsvOut($filedata);
	print &ui_table_end();
	print &dataloggerApiTableSelect("mconfig $module");
	}

sub enable_module {
	my ($module) = @_;
	return callDataloggerAPI("iifEnable $module");
	}

sub disable_module {
	my ($module) = @_;
	return callDataloggerAPI("iifDisable $module");
	}

