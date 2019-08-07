# Needed for debug
use strict;
use warnings;
use Data::Dump;  # use Data::Dumper;

my %text;
use WebminCore;
init_config();

# define datalogger global path
my $DLPACKAGE="/opt/datalogger";
my $DLBWIDTH="width=16em;min-width: 16em;";

#========================================================================
# loads variables from file - returns assoc array with data
# format is compatible with data|name|value format used by display 
#========================================================================
sub dataloggerLoadConfig {

	my ($flist,$filename) = @_;

	# reads variable from file
	my %fdata;

	# reads config data in assoc array from file
	open(CONF, $filename);
	while(<CONF>) {
		s/[\'\r\n]//g;
		my ($name, $value) = split(/=/, $_);
		if ($name && $value) {
			$fdata{$name}=$value;
			}
		}
	close(CONF);

	# generates required fields list
	my @data;
	for my $fform (@$flist) {
		my $fname=@$fform[0];
		my $ftype=@$fform[1];
		my $fsize=@$fform[2];
		my $value=$fdata{$fname};

		my $checked;
		if($ftype eq "checkbox") {
			$checked=$value==1 ? "checked" : "";
			$value=1;
			}

		my $finput="<input type='$ftype' size='$fsize' $checked  value='$value' name='$fname'>";
		push(@data, [ $fname , $text{$fname}, $finput ] );
		}

	return @data;
	}
	

#========================================================================
# saves ALL variables to file - returns assoc array with data
# format is compatible with data|name|value format used by display 
#========================================================================
sub dataloggerSaveConfig {

	my ($flist,$filename) = @_;

	# reads POST
	ReadParse();

	open(FD,">",$filename) or die $!;

	# generates required fields list
	for my $fform (@$flist) {
		my $fname=@$fform[0];
		my $ftype=@$fform[1];
		my $value=$in{$fname};

		if($ftype eq "checkbox") {
			if($value ne 1) {
				$value=0
				};
			}

		print FD "$fname='$value'\n";
		}
	close(FD);

	}
	

#========================================================================
# generates html table from Config generic file 
# format name='values in the variable' as must be bbash compliant
#========================================================================
sub dataloggerShowConfig {

	my ($flist,$filename) = @_;

	# loads configyration parameters
	my @data=dataloggerLoadConfig($flist,$filename);

	# Show the table with add links
	print &ui_columns_table(
		undef,
		100,
		\@data,
		undef,
		0,
		undef,
		$text{'table_nodata'},
		);
	}


#========================================================================
# Generates Array from CSV 'standard' datalogger API
#========================================================================
sub  dataloggerArrayFromCSV {

	my ($filedata) = @_;
	my @head,my @data;
	
	#print "<pre>$filedata</pre>";

	# extracts data from textfile
	foreach my $line (split /\n/,$filedata) {

		# extracts row head and nr
		# standard CSV received by API is:
		# 	 separated by '|' 
		# 	 with head/data prefix
		my @row=split /[|]/, $line;
		my $typ=shift @row;

		# creates array(s)
		if($typ eq "head") {
			@head=@row;
			}
		if($typ eq "data") {
			push(@data,[ @row ]);
			}
		}

	#dd \@data;
	
	return (\@head,\@data);
	}

#========================================================================
# Generates Select list from data generated by api/selXXXXX
#========================================================================
sub  dataloggerShowSelect {

	my ($value,$selectName,$apiVars) = @_;
	my $selectValue=$value ne "" ? $value : %in{$selectName};

	# extracts from api value
	my $filedata=`$apiVars $DLPACKAGE/api/sel/$selectName`;	

	# this is a CSV with '|' as separator - first line is 'head'
	my ($rhead,$rdata)=dataloggerArrayFromCSV($filedata);
	my @head=\@$rhead,my @options=\@$rdata;
	
	print &ui_select($selectName,$selectValue,@options,undef,undef,undef,undef,"onchange='submit()'");

	##if($selectValue eq "") $selectValue=@options[0][0];
	
	return $selectValue;
	}


#========================================================================
# Generates Driver Params form Enabled Driver
#========================================================================
sub  dataloggerDriverParamsOptions {

	return;
	my ($module) = @_;
	my $plist=`$DLPACKAGE/api/iifConfig $module params`;


	foreach my $param (split / /,$plist) {
		my $found=undef;
		if($param eq "mbserial") {
			$found=dataloggerShowSelect(undef,$param);
			}
		if($param eq "mbchannel") {
			$found=dataloggerShowSelect(undef,"mbserial");
			}
		if($param eq "mbaddress") {
			$found=dataloggerShowSelect(undef,$param);
			}
		if($found==undef) {
			print "$param:UNFOUND";
			}
		}


	print $plist;
	}

#========================================================================
# Generates Submit Buttons for Enabled Drivers
#========================================================================
sub  dataloggerShowSubmitModule {

	my ($title) = @_;
	
	my $button_name="module";
	my $fn,my @fl,my $button_desc;
	$fn=`ls $DLPACKAGE/etc/iif.d`;
	@fl = split(/[ \t\n\r]/,$fn);	
	
	print &ui_table_start($title);
	print &ui_buttons_start();
	foreach my $button_value (@fl) {
		my $button_descr=`/opt/datalogger/api/iifAltDescr $button_value`;
		print &ui_submit($button_value,$button_name,0,"value='$button_value' style='$DLBWIDTH'");
		}
	print &ui_buttons_end();
	print &ui_table_end();
	}


#========================================================================
# Converts CSV table to Columns Table Webmin
#========================================================================
sub dataloggerCsvOut {

	my ($filedata) = @_;

	# this is a CSV with '|' as separator - first line is 'head'
	my ($rhead,$rdata)=dataloggerArrayFromCSV($filedata);
	my @head=@$rhead,my @data=@$rdata;

	# normalized head (from webmin language table, if any)
	my @nhead;
	foreach my $f (@head) {push(@nhead,$text{$f} ne '' ? $text{$f} : $f);}

	# Show the table with add links
	print &ui_columns_table(
		\@nhead,
		100,
		\@data,
		undef,
		0,
		undef,
		$text{'table_nodata'},
		);
	}


#========================================================================
# Generic data file output - tries to automagically recognize format
#========================================================================
sub dataloggerFileOut {

	my ($title,$filedata) = @_;
	
	# block title
	print &ui_table_start($title);

	# check if is a 'CSV' data file or flat
	# must contain data[|] statements
	if($filedata =~ /[\n]?data[|]/) {
		&dataloggerCsvOut($filedata);
		}
	# XML/HTML file - to display we must escape <>
	 elsif($filedata =~ /<\?xml/) {
		$filedata =~ s/</\&lt;/g;
		$filedata =~ s/>/\&gt;/g;
		print "<pre>$filedata</pre>"; 
		}
	else {
		print "<pre>$filedata</pre>"; 
		}

	print &ui_table_end(); 
	}

return 1;
exit;
