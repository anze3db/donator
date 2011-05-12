#!c:/Perl/bin/perl.exe
package Vzdrzevanje;
use strict;
use DBI;
use DntFunkcije;
use base 'CGI::Application';

my $q = new CGI;


sub Popravi_sfr_agreement(){
	
	#V tabelo sfr_agreement doda polja upokojenec, pokrovitelj, podaljsanje_pogodbe
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo datoteka_vsebina");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN retired char(1) ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	#Dodam novo polje
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN pokrovitelj char(1) ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	#Dodam novo polje
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN podaljsanje_pogodbe char(1) ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	}
}



sub Zamenjaj_id_trr(){
	
	my $i;
	my $dbh;
	my $sql;
	my $sth;
	my $res;
	my $output;
	my @loop;
	my @loop2;
	$dbh = DntFunkcije->connectDB;
	print $q->p("Spreminjam sfr_project_pay_type.id_trr");
	
	$sql="SELECT id_trr, id_vrstica FROM sfr_project_trr ";
	$sth = $dbh->prepare($sql);
	$sth->execute();
	
	while ($res = $sth->fetchrow_hashref){

		$loop[$i]=$res->{id_trr};
		$loop2[$i++]=$res->{id_vrstica};
	}
	
	
	
	my $j=0;
	foreach my $i (@loop){
		
		$output.=$i."=>".$loop2[$j];
		$sql="UPDATE sfr_project_pay_type SET id_trr=? WHERE id_trr=?";
		$sth = $dbh->prepare($sql);
		if($sth->execute($loop2[$j++], $i)){
			$output.= " [USPESNO ZAMENJAN]<br /> ";	
		}
		else{
			$output.= " [PRISLO JE DO NAPAKE]<br /> ";
		}
	
		
	}
	print $output;
	
	$sql="ALTER TABLE sfr_project ALTER COLUMN id_project DROP DEFAULT";
	$sth = $dbh->prepare($sql);
	if($sth->execute()){
			print "tabela uspesno spremenjena ";	
		}
		else{
			print "napaka pri spreminjanju";
		}
	
}
sub NarediTabelo_davcni_zavezanci(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo davcni_zavezanci");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE davcni_zavezanci (".
				" id_dz serial NOT NULL,".
				" vrsta_zavezanca char(1), ".
				" reg_za_ddv char(1), ".
				" davcna_st char(10), ".
				" maticna_st char(10), ".
				" sifra_dejavnosti char(10), ".
				" ime char(110), ".
				" naslov char(110), ".
				" CONSTRAINT davcni_zavezanci_pkey PRIMARY KEY (id_dz) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE davcni_zavezanci OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela uporabniki je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela uporabniki ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}

	
}
sub NarediTabelo_sfr_agreement_comment(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo sfr_agreemenet");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE sfr_agreement_comment (".
				" id_vrstice serial NOT NULL,".
				" id_agreement char(13), ".
				" date timestamp, ".
				" comment text, ".
				" alarm timestamp, ".
				" alarm_active char(1), ".
				" comment_alarm text, ".				
				" tip_komentar char(2), ".
				" reseno char(1), ".
				" CONSTRAINT sfr_agreement_comment_pkey PRIMARY KEY (id_vrstice) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE sfr_agreement_comment OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela uporabniki je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela uporabniki ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}

	
}
sub Dodaj_sheets_deleted(){
	
	#V tabelo sfr_agreement doda polja sheets_deleted
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo datoteka_vsebina");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
		$sql = "ALTER TABLE sheets_series ADD COLUMN sheets_deleted integer DEFAULT 0 ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	}
}
sub Log(){
	print "LOG: ";
	open(LOG, "</var/www/logs/error_log") || Error('open', 'file');
	flock(LOG, 2) || Error('lock', 'file');
	my @logError= <LOG>;
	my $i=0;
	close(LOG) || Error('close', 'file');
	@logError= reverse(@logError);
	my $logNum=@logError;
	my $deleteAt=100000;
	if ($logNum>$deleteAt){
		#rename("../../logs/error_log", "../../logs/error_log2".time) || print('sadas');
		open(LOG, ">var/www/logs/error_log") || Error('open', 'file');
		
	close(LOG) || Error('close', 'file');
	}
	my $print "<strong>ST VRSTIC: $logNum</strong> - brisanje loga pri $deleteAt<br />";
	foreach (@logError){
		$i++;
		$print .= "$i. ".$_."<br />";
			#last if($i==2000);
	}
	return $print;
}
sub NarediTabelo_pomoc(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo sfr_agreemenet");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE pomoc (".
				" id_pomoc serial NOT NULL,".
				" stran char(50), ".
				" besedilo text, ".
				" ustvarjeno timestamp,".
				" CONSTRAINT pomoc_pkey PRIMARY KEY (id_pomoc) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE pomoc OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela pomoc je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela pomoc ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}

	
}
sub PopraviUporabniki(){
	
	#V tabelo sfr_agreement doda polja upokojenec, pokrovitelj, podaljsanje_pogodbe
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo geslo");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
		$sql = "ALTER TABLE uporabniki ALTER COLUMN geslo TYPE char(32)";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Spreminjanje uspelo");
		}
		else{
			print $q->p("napaka ! Spreminjanje ni uspelo");
		}
	}
}
sub NarediTabelo_isci(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo isci");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE isci (".
				" id_isci serial NOT NULL,".
				" tip char (1), ".
				" param text, ".
				" naslov char(50), ".
				" ustvarjeno timestamp,".
				" CONSTRAINT isci_pkey PRIMARY KEY (id_isci) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE isci OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela isci je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela isci ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}

	
}
sub Popravi_sfr_agreement_status_potrdilo(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo sfr_agreement");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN status char(1) DEFAULT 'O' ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN potrdilo timestamp without time zone";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	}
}

sub Popravi_agreement_pay_installment(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo sfr_agreement");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
	
		$sql = "ALTER TABLE agreement_pay_installment ADD COLUMN storno timestamp without time zone";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		$sql = "ALTER TABLE agreement_pay_installment ADD COLUMN obracun timestamp without time zone";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		$sql = "ALTER TABLE agreement_pay_installment ADD COLUMN date_izpis timestamp without time zone";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		
	}
}

sub UstvariAgreement_notice(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo sfr_agreemenet");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE agreement_notice (".
				" id serial NOT NULL,".
				" id_agreement integer, ".
				" id_vrstica integer, ".
				" besedilo text, ".
				" datum timestamp,".
				" CONSTRAINT agreement_notice_pkey PRIMARY KEY (id) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE agreement_notice OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela pomoc je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela pomoc ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}	
}
sub Dodaj_posto(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo sfr_donator");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
	
		$sql = "ALTER TABLE sfr_donor ADD COLUMN post_name character(50)";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		$sql = "ALTER TABLE sfr_donor ADD COLUMN post_name_mail character(50)";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}		
	}
}
sub UstvariUporabniki_tmp(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo sfr_agreemenet");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE uporabniki_tmp (".
				" id serial NOT NULL,".
				" id_user integer, ".
				" id_unique integer, ".
				" tmp_field1 text, ".
				" tmp_field2 text, ".
				" tmp_toggle integer, ".				
				" tmp_date1 timestamp,".
				" tmp_date2 timestamp,".
				" tmp_source text,".
				" CONSTRAINT uporabniki_tmp_pkey PRIMARY KEY (id) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE uporabniki_tmp OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela pomoc je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela pomoc ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}	
}


sub UstvariUser_log(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo uporabniki_log");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE uporabniki_log (".
				" id serial NOT NULL, ".
				" id_uporabnik integer, ".
				" time timestamp, ".
				" page text, ".
				" action character(1), ".
				" remote_addrs character(20), ".				
				" user_agent character(100), ".
				" action_id text, ".
				" action_source character(100), ".
				" CONSTRAINT uporabniki_log_pkey PRIMARY KEY (id) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE uporabniki_log OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela user_log je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela user_log ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}	
}

sub Datoteke_dodaj_id_datoteke(){
	#V tabeli dototeka ter datoteka_vsebina doda polje id_datoteka
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("1. Prijava na bazo");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		#$sql = "ALTER TABLE datoteke_vsebina DROP  FOREIGN KEY (id_ime_datoteke)";
		$sql = "ALTER TABLE datoteke_vsebina DROP CONSTRAINT datoteke_vsebina_id_ime_datoteke_fkey";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" DROP  FOREIGN KEY uspelo");
		}
		else{
			print $q->p("napaka ! DROP  FOREIGN KEY  ni uspelo");
		}
		#ALTER TABLE products ALTER COLUMN product_no DROP NOT NULL;
		print $q->p("Spreminjam strukturo datoteka");
		#najprej odstrani Constraints
		print $q->p("odstranjam Constraints (id_ime_datoteke)");
		$sql = "ALTER TABLE datoteke DROP CONSTRAINT datoteke_pkey";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" odstrani Constraints uspelo");
		}
		else{
			print $q->p("napaka ! odstrani Constraints ni uspelo");
		}
		#odstranim NOT NULL
		print $q->p("odstranjam not_null (id_ime_datoteke)");
		#ALTER TABLE products DROP CONSTRAINT some_name;
		$sql = "ALTER TABLE datoteke ALTER COLUMN id_ime_datoteke DROP NOT NULL";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" odstrani NOT NULL uspelo");
		}
		else{
			print $q->p("napaka ! odstrani NOT NULL ni uspelo");
		}
		#Dodam novo polje
		$sql = "ALTER TABLE datoteke ADD COLUMN id_datoteka SERIAL";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		#Dodam Primary key
		$sql = "ALTER TABLE datoteke ADD CONSTRAINT datoteke_pkey PRIMARY KEY (id_datoteka) ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje PRIMARY KEY uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje PRIMARY KEY ni uspelo");
		}
		print $q->p("Spreminjam strukturo datoteka_vsebina");
		#Dodam novo polje
		$sql = "ALTER TABLE datoteke_vsebina ADD COLUMN id_datoteka integer ";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
		#Sedaj posodobi polja
		my $i;
		my @loop;
		my @loop2;
		$sql="SELECT id_datoteka, id_ime_datoteke FROM datoteke ";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my $res;
		my $output;
		$output = "";
		while ($res = $sth->fetchrow_hashref){

			$loop[$i]=$res->{id_ime_datoteke};
			$loop2[$i++]=$res->{id_datoteka};
			print $q->p("x".$res->{id_datoteka});
		}		

		my $j=0;
		foreach my $i (@loop){
			
			$output.=$i."=>".$loop2[$j];
			$sql="UPDATE datoteke_vsebina SET id_datoteka =? WHERE id_ime_datoteke=?";
			$sth = $dbh->prepare($sql);
			if($sth->execute($loop2[$j++], $i)){
				$output.= " [USPESNO ZAMENJAN]<br /> ";	
			}
			else{
				$output.= " [PRISLO JE DO NAPAKE]<br /> ";
			}

			
		}
		
	}
}
sub Dodaj_obracun(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("Spreminjam strukturo sfr_agreement");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
	#Dodam novo polje
	
		$sql = "ALTER TABLE sfr_agreement ADD COLUMN obracun timestamp";
		print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" Dodajanje polja uspelo");
		}
		else{
			print $q->p("napaka ! Dodajanje polja ni uspelo");
		}
	}
}
sub NarediTabelo_datoteke_izvozene(){
	my $dbh;
	my $sql;
	my $sth;
	print $q->p("generiram tabelo datoteke_izvozene");
	$dbh = DntFunkcije->connectDB;
    if ($dbh) 
    {
		$sql = "CREATE TABLE datoteke_izvozene (".
				" id serial NOT NULL,".
				" id_user char(50), ".
				" filename char(50), ".
				" content text, ".
				" date timestamp, ".
				" CONSTRAINT datoteke_izvozene_pkey PRIMARY KEY (id) )".
				" WITHOUT OIDS ;".
				" ALTER TABLE datoteke_izvozene OWNER TO postgres ;";
		
        print $q->p("sql: ".$sql);
		$sth = $dbh->prepare($sql);
		if ($sth->execute()) {
			print $q->p(" tabela datoteke_izvozene je zgenerirana");
		}
		else{
			print $q->p("napaka ! tabela datoteke_izvozene ni uspelo zgenerirati: ".$sth->errstr);
		}
		
	}

	
}
sub fix_SI_TAX{
	my $dbh;
	my $sql;
	my $sth;
	my $res;

	$dbh = DntFunkcije->connectDB;
    if ($dbh) {
		$sql = "SELECT tax_number, liable_for_tax, id_donor FROM sfr_donor WHERE liable_for_tax = 1";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while ($res = $sth->fetchrow_hashref) {
			my $id = $res->{'id_donor'};
			my $tax = $res->{'tax_number'};
			$sql = "UPDATE sfr_donor SET tax_number = ? WHERE id_donor = ?";
			
			$tax =~ s/SI//;
			#print "UPDATE sfr_donor SET tax_number = '$tax' WHERE id_donor = '$id'";
			my $sth2 = $dbh->prepare($sql);
			$sth2->execute($tax, $id);			
			
		}
		
	}
}


print $q->header(-charset=>"utf-8" );

print $q->start_html(-title=>"Vzdrzevanje", 
                     -encoding=>"utf-8", 
                     -lang=>"sl-SI",
                     #-script=>{-src=>"../CarpeDiemJS/CDJsFunc.js", -type=>"text/javascript"},  #javascript fajli ne morejo biti v cgi-bin
					 #-onKeydown=>"doDocKeydown()",
					 #-onLoad=>"document.myForm.edb_id_agreement.focus()"
                    );
#print $q->start_form(-name => "myForm", -onsubmit=>"return false;");

unless($q->param()) {

	print $q->h1("Vzdrzevanje. Vpisan ni noben parameter");
	print $q->button(-name=>"btn_nazaj", -value=>"Nazaj", -onClick=>"javascript:window.history.back()");
	
}
else 
{
    
        
		if ($q->param('hid_menu') eq "popravi_sfr_agreement") {
			#Doda se polje TRR v tabelo datoteka vsebina
			#http://localhost/cgi-bin/Vzdrzevanje.pl?hid_menu=popravi_sfr_agreement
			#20080819
			Popravi_sfr_agreement();
		}
		elsif ($q->param('hid_menu') eq "zamenjaj_id_trr") {
			#Zamenja id_trr z id_vrstica v sfr_project_pay_type.id_trr
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=zamenjaj_id_trr
			#20080903
			Zamenjaj_id_trr();
		}
		elsif ($q->param('hid_menu') eq "dodaj_sheets_deleted") {
			#Doda se polje sheets_deleted v tabelo sheets_series
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=dodaj_sheets_deleted
			#20080905
			Dodaj_sheets_deleted();
		}
		elsif ($q->param('hid_menu') eq "ustvari_davcni_zavezanci") {
			#Doda tabelo davcnih zavezancev
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_davcni_zavezanci
			#20080905
			NarediTabelo_davcni_zavezanci();
		}
		elsif ($q->param('hid_menu') eq "ustvari_sfr_agreement_comment") {
			#Doda komentarje za sfr_agreement
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_sfr_agreement_comment
			#20080915
			NarediTabelo_sfr_agreement_comment();
		}
		elsif ($q->param('hid_menu') eq "log") {
			#Izpise zadnjih nekaj errorjev v error_log-u.
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=log
			#20080921
			Log();
		}
		elsif ($q->param('hid_menu') eq "ustvari_pomoc") {
			#Doda tabelo pomoc
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_pomoc
			#20080925
			NarediTabelo_pomoc();
		}
		elsif ($q->param('hid_menu') eq "popravi_uporabniki") {
			#Popravi geslo pri uporabnikih (iz 20 na 32 bit).
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=popravi_uporabniki
			#20080929
			PopraviUporabniki();
		}
		elsif ($q->param('hid_menu') eq "ustvari_isci") {
			#Doda tabelo isci
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_isci
			#20080925
			NarediTabelo_isci();
		}
		elsif ($q->param('hid_menu') eq "popravi_sfr_agreement_status_potrdilo") {
			#Doda status in potrdilo v tabelo sfr_agreement
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=popravi_sfr_agreement_status_potrdilo
			#20081028
			Popravi_sfr_agreement_status_potrdilo();
		}
		elsif ($q->param('hid_menu') eq "popravi_agreement_pay_installment") {
			#Doda placano, storno, date_izpis, potrdilo v tabelo agreement_pay_installment
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=popravi_agreement_pay_installment
			#20081028
			Popravi_agreement_pay_installment();
		}
		elsif ($q->param('hid_menu') eq "ustvari_agreement_notice") {
			#Doda tabelo opominov
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_agreement_notice
			#20081202
			UstvariAgreement_notice();
		}
		elsif ($q->param('hid_menu') eq "dodaj_posto") {
			#Doda posto v sfr_donor
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=dodaj_posto
			#20081202
			Dodaj_posto();
		}
		elsif ($q->param('hid_menu') eq "ustvari_user_tmp") {
			#Doda user_tmp tabelo
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_user_tmp
			#20081220
			UstvariUporabniki_tmp();
		}
		elsif ($q->param('hid_menu') eq "ustvari_user_log") {
			#Doda user_tmp tabelo
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=ustvari_user_log
			#20090119
			UstvariUser_log();
		}
		elsif ($q->param('hid_menu') eq "dodaj_id_datoteke") {
			#Doda se polje id_datoteke v tabelo datoteka ter datoteka_vsebina
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=dodaj_id_datoteke
			#20090320
			Datoteke_dodaj_id_datoteke();
		}
		elsif ($q->param('hid_menu') eq "dodaj_obracun") {
			#V tabelo sfr_staff se doda polje obracun
			#http://10.10.10.18/DntVzdrzevanje.cgi?hid_menu=dodaj_obracun
			#20090428
			Dodaj_obracun();
		}
		elsif ($q->param('hid_menu') eq "ustvari_datoteke_izvozene") {
			#Ustvari datoteke_izvozene.
			#http://10.10.10.18/Vzdrzevanje.cgi?hid_menu=ustvari_datoteke_izvozene
			#20090924
			
			NarediTabelo_datoteke_izvozene();
		}
		elsif ($q->param('hid_menu') eq "fix_SI_TAX") {
			#Ustvari datoteke_izvozene.
			#http://10.10.10.18/Vzdrzevanje.cgi?hid_menu=fix_SI_TAX
			#20091001
			
			fix_SI_TAX()
		}

		
}

#$sql = "ALTER TABLE sfr_agreement ADD COLUMN retired char(1) ";
1;    # Perl requires this at the end of all modules