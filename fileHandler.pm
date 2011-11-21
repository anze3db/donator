#!/usr/bin/perl
# fileHandler.cgi
$| = 1;
my $i=0;
my $frstChar;
my $file;
my $tmpStr;
my @parts;
my $poz;
my $scndChar;
my $strLen;
my $variable;
my $value;
my $vrstica;
read( STDIN, $tmpStr, $ENV{ "CONTENT_LENGTH" } );
@parts = split( /-----------------------------/, $tmpStr );

foreach my $pr (@parts){
	
	$i++;
	$pr =~ /name="(.*?)"/;
	$variable = $1;
	$value = DntFunkcije::trim($');
	
	if ($variable  eq "vrsta_uvoza_dok"){
		if ($value  eq 'datoteke z banke'){
			#print "Uvazam z banke<br>";
			UvoziZBanke($parts[$i], 0);
			#UvoziDavcneZavezance($parts[$i], 0);
			#print "content-type: text/html\n\n";
		}
		elsif ($value  eq 'davcni zavezanci'){
			#print "Uvazam davcne zavezance<br>";
			UvoziDavcneZavezance($parts[$i], 0);
		}
		elsif ($value  eq 'delno davcni zavezanci'){
			#print "Uvazam delne davcne zavezance<br>";
			UvoziDavcneZavezance($parts[$i], 1);
		}
		
	}
	#chomp $pr;
	#$pr = DntFunkcije::trim($pr);
	#$poz = index($pr,"form-data; name=",0);
	#print "Poz:".$poz."x".$pr."y";
	#if ($poz > 0){
	#	$frstChar = 1;
	#	$frstChar = index($pr, "\"",$poz);
	#	
	#	if ($frstChar > 0){
	#		#chomp ($pr);
	#		#$pr = DntFunkcije::trim($pr);
	#		$strLen = length ($pr);
	#		$scndChar = index($pr, "\"",$frstChar+1);
	#		$variable = substr($pr, $frstChar+1, $scndChar-$frstChar-1);
	#		$value = substr($pr, $scndChar+5, $strLen-$scndChar-5);
	#		if ($variable  eq "vrsta_uvoza_dok"){
	#			if ($value  eq 'datoteke z banke'){
	#				print "Uvazam z banke";
	#				UvoziZBanke($tmpStr);
	#			}
	#			elsif ($value  eq 'davcni zavezanci'){
	#				print "Uvazam davcne zavezance";
	#				UvoziDavcneZavezance($tmpStr, 0);
	#			}
	#			elsif ($value  eq 'delno davcni zavezanci'){
	#				print "Uvazam delne davcne zavezance";
	#				UvoziDavcneZavezance($tmpStr, 1);
	#			}
	#		}
			#print " Spremenljivka:".$variable."Vrednost:".$value.
			#		"prvi:".$frstChar." drugi:".$scndChar." sirina:".$strLen.
			#		"<br>Vse:".$pr;
			#		#$scndChar." ".$pr;
	#	}
	#	else {
	#		print "Napaka";
	#	}
	#}
	#else {
		#print $pr.'xxx';
	#}
	#print "<br>";
	
}
#print "[redirect header]url=/DntBranjeDatotek.pm?rm=Nepotrjene_datoteke"

sub UvoziZBanke($$){
	
	my $dbh;
	my $str = shift;
	my $id = shift;
	my $napaka = "";
	my $napaka_str = "";
	#preberi ime datoteke:
	$str =~  /filename="(.*?)"/;
	my $filename=$1;
	#print "datoteka:".$filename;
	#print "Zacetek datoteke:".$filename."<br>";
	#preberi content type:
	$str =~ /Content-Type:\ (.*?)(\n|\r)/;
	my $contentType=$1;
	#content je vse, kar sledi content typu:
	my @content=split('\n',DntFunkcije::trim($'));	
	$dbh = DntFunkcije->connectDB;
	if ($dbh){
		my $cas;
		my $datum;
		my $sql;
		my $sth;
		my $res;
		($datum,$cas) = DntFunkcije::time_stamp(); #localtime;
		
		$sql = "SELECT id_ime_datoteke FROM datoteke WHERE id_ime_datoteke = ?";
		$sth = $dbh->prepare($sql);
        $sth->execute($filename);
		if($res = $sth->fetchrow_hashref){
			$napaka = 3;
			my $np_str = "";
			if($napaka > 0){
				$np_str = "&napaka=$napaka&str=$napaka_str";
			}
		
			#print "Konec datoteke:<br>";
			print "Status: 301 Moved Permanently\n";
			print "Location: /DntBranjeDatotek.cgi?rm=uspeh".$np_str."\n\n";
			exit;
		}
		
		$sql = "INSERT INTO datoteke (id_ime_datoteke,
            datum, zaprta, prejeta_poslana)
            VALUES (?,?,?,?)";
        $sth = $dbh->prepare($sql);
        $sth->execute($filename, $datum, 'O', 'I');
		
		$sql = "SELECT currval('datoteke_id_datoteka_seq') as last";
		$sth = $dbh->prepare($sql);
		#print $sql;
		$sth->execute();
		my $last_id;
		my $res2;
		
		if($res2 = $sth->fetchrow_hashref){
			$last_id=$res2->{'last'};
		}
		else{
			return $sql;
		}
		#print $last_id." ".$sql;
		
		#obdelava contenta:
		$sql = "INSERT INTO datoteke_vsebina (id_ime_datoteke,
                vsebina_vrstice, vrstica, id_datoteka,
                s1_vrsta_zapisa, s2_vrsta_knjizenja, s4_vrsta_informacije,
				s5_status, potrjeno, trr_projekt )
                VALUES (?,
                ?, ?, ?,
                ?, ?, ?,
				?, ?, ?)";
        $sth = $dbh->prepare($sql);
		my $i = 1;
        my $s1;
        my $s2;
        my $s4;
        my $s5;
		my $trr_projekt;
		foreach $vrstica (@content){

			#print $vrstica."\n";
			$vrstica = DntFunkcije::trim($vrstica);
			$s1 = substr($vrstica,0,2);
			$s2 = substr($vrstica,26,1);
			$trr_projekt = substr($vrstica,53,18);
			$s4 = substr($vrstica,164,2);
			$s5 = substr($vrstica,166,2);
			if ($sth->execute($filename,
                         DntFunkcije::trim($vrstica), $i, $last_id,
                         $s1, $s2, $s4,
						 $s5, '0', $trr_projekt)){
				#vse ok
			}
			else {
				print "Napaka ".$sth->errstr.$vrstica."<br>";
			}
           
			$i = $i+1;
			#print $last_id."  aa".$vrstica."<br>";
		}
		
	}
	else{
		print "Napaka:<br>".
			"Povezava na bazo ni uspela!";
	}
	my $np_str = "";
	if($napaka > 0){
		$np_str = "&napaka=$napaka&str=$napaka_str";
	}
	#print "Konec datoteke:<br>";
	print "Status: 301 Moved Permanently\n";
	print "Location: /DntBranjeDatotek.cgi?rm=uspeh".$np_str."\n\n";
	exit;
	#obdelava contenta:
	#my $i=0;
	#my $tip="?";
	#my $sql;
	#
	#print "<br>zdej sem kle<br>";
	#@parts = split( /-----------------------------/, $tmpStr );
	#foreach my $pr (@parts){
	#	chomp $pr;
	#	$pr = DntFunkcije::trim($pr);
	#	$poz = index($pr,"form-data; name=",0);
		#print "<br>vrstica:".$poz."x".$pr."y";
		#if ($poz > 0){
		#	$frstChar = 1;
		#	$frstChar = index($pr, "\"",$poz);
		#	
		#	if ($frstChar > 0){
		#		#chomp ($pr);
		#		#$pr = DntFunkcije::trim($pr);
		#		$strLen = length ($pr);
		#		$scndChar = index($pr, "\"",$frstChar+1);
		#		$variable = substr($pr, $frstChar+1, $scndChar-$frstChar-1);
		#		$value = substr($pr, $scndChar+5, $strLen-$scndChar-5);
		#		if ($variable  eq "vrsta_uvoza_dok"){
		#			if ($value  eq 'datoteke z banke'){
		#				print "Uvazam z banke";
		#				UvoziZBanke(@parts);
		#			}
		#			elsif ($value  eq 'davcni zavezanci'){
		#				print "Uvazam davcne zavezance";
		#			}
		#			elsif ($value  eq 'delno davcni zavezanci'){
		#				print "Uvazam delne davcne zavezance";
		#			}
		#		}
		#		#print " Spremenljivka:".$variable."Vrednost:".$value.
		#		#		"prvi:".$frstChar." drugi:".$scndChar." sirina:".$strLen.
		#		#		"<br>Vse:".$pr;
		#		#		#$scndChar." ".$pr;
		#	}
		#	else {
		#		print "Napaka";
		#	}
		#}
		#else {
		#	print $pr.'xxx';
		#}
	#	print "<br>";
	#}
}
sub UvoziDavcneZavezance($$){

	my $str = shift;
	my $id = shift;

	#preberi ime datoteke:
	$str =~  /filename="(.*?)"/;
	my $filename=$1;
	#preberi content type:
	$str =~ /Content-Type:\ (.*?)(\n|\r)/;
	my $contentType=$1;
	my $napaka=0;
	my $napaka_str;
	#content je vse, kar sledi content typu:
	my @content=split(/\n/,$');
	
	#obdelava contenta:
	my $i=0;
	my $j=0;
	my $tip="?";
	my $sql;
	my $sth;
	my $dbh;
	
	if($filename =~ /^PO/){

		$tip="D";
	}
	elsif($filename =~ /^FOzD/){

		$tip="S";
	}
	elsif($filename =~ /^FObD/){
		
		$tip="F";
	}
	else{
		
		$napaka=1;
	}
	$dbh = DntFunkcije->connectDB;
	if ($dbh && $napaka == 0){
		if($id == 0){
			$sql="DELETE FROM davcni_zavezanci WHERE vrsta_zavezanca='$tip'";
			$sth = $dbh->prepare($sql);
			unless($sth->execute()){
				
				my $napaka_opis = $sth->errstr."<br />$sql";
				$napaka = 2;
			}					
		}	
		if($tip eq "F"){
				
			$sql="INSERT INTO davcni_zavezanci (vrsta_zavezanca, davcna_st)".
				" VALUES ";
			foreach $vrstica (@content){		   
				if(length(DntFunkcije::trim($vrstica))>0){
					my $davcnaSt=substr($vrstica,2,8);
					
					if($i==0){
						$sql.="('$tip', '$davcnaSt')";
						$i++;
					}
					else{
						$sql.=", ('$tip', '$davcnaSt')";
					}
				}
			}
			$sth = $dbh->prepare($sql);
			unless($sth->execute()){
				
				my $napaka_opis = $sth->errstr."<br />$sql";
				$napaka = 2;
			}	
				
		}
		else{
			$sql="INSERT INTO davcni_zavezanci (vrsta_zavezanca, reg_za_ddv, davcna_st, maticna_st, sifra_dejavnosti, ime, naslov) VALUES "
				." (?, ?, ?, ?, ?, ?, ?)";
			foreach $vrstica (@content){
				if(length(DntFunkcije::trim($vrstica))>0){
					my $davcniZavezanec;
					if(substr($vrstica, 2, 1) eq '*'){
						$davcniZavezanec="1";
					}
					else{
						$davcniZavezanec="0";
					}
					my $davcnaSt=substr($vrstica,4,8);
					my $maticnaSt=substr($vrstica,13,10);
					my $sifraDejavnosti=substr($vrstica,35,6);
					my $ime=(DntFunkcije::trim(substr($vrstica,42,100)));
					my $naslov=(DntFunkcije::trim(substr($vrstica,143,100)));
						
					$sth = $dbh->prepare($sql);
					unless($sth->execute($tip, $davcniZavezanec, $davcnaSt,
										 $maticnaSt, $sifraDejavnosti, $ime, $naslov)){
						
						my $napaka_opis = $sth->errstr;
					}
					
				}						
			}
			
		}
	}
	my $np_str = "";
	if($napaka > 0){
		$np_str = "&napaka=$napaka&str=$napaka_str";
	}
	print "Status: 301 Moved Permanently\n";
	print "Location: /DntBranjeDatotek.cgi?rm=uspeh".$np_str."\n\n";
	exit;
	

}
	
