package DntUporabnikiLog;
use base 'CGI::Application';
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use strict;
use DBI;
#use HTML::Template;
#use CGI::Session;
#use Data::Dumper;
use DntFunkcije;
use Digest::MD5 qw(md5_hex);

sub cgiapp_prerun {
	
    my $self = shift;
    my $q = $self->query();
	my $nivo='r';
	my $str = $q->param('rm');
	#nastavi write nivo funkcij, ki zapisujejo v bazo:
	if ($str eq 'Shrani' || $str eq 'zbrisi' || $str eq 'uredi'){
		$nivo = 'w';
	}
	
    my $user = DntFunkcije::AuthenticateSession(52, $nivo);
	# Redirect to login, če uporabnik ni prijavljen
	if($user == 0){    
        $self->prerun_mode('login');
    }
	# Redirect to error, če nima pravic za ogled strani
	elsif($user == -1){    
        $self->prerun_mode('error');
    }	
}

sub setup {

    my $self = shift;
    #$self->dbh_config("dbi:PgPP:dbname=donator;host=localhost", "uporabnikgres", "ni2mysql");

    
    $self->run_modes(
        'seznam' => 'UporabnikiSeznam',
		'Prikazi' => 'UporabnikiSeznam',
		'uredi' => 'UporabnikiUredi',
		'Shrani' => 'UporabnikiShrani',
		'zbrisi' => 'Zbrisi',
		'Preusmeri' => 'Preusmeri',
		'login' => 'Login',
		'error' => 'Error'
    );
	
	#SfrSeznamDonatorjev'
    #$self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub UporabnikiSeznam{
	
    my $self = shift;
    my $q = $self->query();	
	my $seja= $q->param('seja');	
	my $html_output ;
	my $ime= $q->param('edb_ime');
	my $izbran = $q->param('det');
	my @loop;
	my $menu_pot;
	my $triPike;
	my $poKorenuIme= $q->param('po_korenu_ime');
	my $st= $q->param('edb_st');
	my $uporabnik= $q->param('uporabnik');
    my $template ;
	my $table_item0;
	my $table_item1;
	my $table_item2;
	my $table_item3;
	my $button;
	$self->param(testiram =>'rez');
	    
    # Fill in some parameters	
    $menu_pot = $q->a({-href=>"dntStart.cgi?seja="}, "Zacetek")  ;
	$template = $self->load_tmpl(	    
		'DntUporabnikiLog.tmpl',
		 cache => 1,
   );
    $template->param(
		#MENU_POT => $menu_pot,
		IME_DOKUMENTA => 'Log',
		POMOC => "<input type='button' value='?' ".
		"onclick='Pomoc(\"$ENV{SCRIPT_NAME}\", \"$ENV{QUERY_STRING}\")'  >",
		MENU => DntFunkcije::BuildMenu(),
		
	);
	#Ce so se parametri za poizvedbo izpise rezultat

        my $dbh;
		my $res;
		my $sql;
		my $sth;
		
		my $sth2;
		my $res2;
		
		my $hid_sort = $q->param("hid_sort");
		$dbh = DntFunkcije->connectDB;
		
		if ($dbh) {
			if($izbran){
				#prikaze tabelo s podrobnostmi:
				$table_item0="Cas";
				$table_item1="IP naslov";
				$table_item2="Stran";
				$table_item3="Operacija";
				$button = '<input type="button" name = "nazaj" value = "Nazaj" onclick = "window.history.back()" />';
				$sql = " SELECT *".
					   " FROM uporabniki_log as a, uporabniki as b ".
					   " WHERE b.id_uporabnik=a.id_uporabnik ";
				if(!($izbran eq "vse")){
					$sql .= " AND a.id_uporabnik='$izbran'";
				}
				$sql .= " ORDER BY time DESC LIMIT 1000";
				$sth = $dbh->prepare($sql);
				
				#return $sql;
				$sth->execute();
				while ($res = $sth->fetchrow_hashref) {
					my $info = "Parametri: ";
					#reformatira stolpca operacija in stran:
					my $id_up=$res->{'id_uporabnik'};
					$res->{'page'} =~ m/\?/;
					$info .= $';
					#shrani ime strani v spremenljvko stran:
					my $stran = $`;
					$info =~ s/&/, /g;
					
					$stran =~ s/\///;
					$stran =~ s/.cgi//g;
					#poisce ime operacije(tisto kar sledi 'rm='):
					$res->{'page'} =~ m/[^\w]rm=[^&]*/;
					my $operacija .= $&;
					$operacija =~ s/[^\w]rm=//;
					if($res->{'page'} =~ m/(id_\w*?=\d*)+/){
						$operacija .= ", ".$&;
					}
					#isce strani, kjer je bil uporabljen edb_id:
					elsif($res->{'page'} =~ m/edb_id=\d*/){
						$operacija .= ", ".$&;
						$operacija =~ s/edb_id/id/;						
					}
					if($operacija =~ m/shrani, id=/){
						$operacija = "shrani - nov vnos";
					}
					#pripravi idje pri brisanju za izpis:
					if($operacija =~ m/zbrisi/){
						$info =~ m/brisiId/;
						$operacija = $';
						$operacija =~ s/\&brisiId/, /;
						$operacija =~ s/=//g;
						$operacija = "brisi id=".$operacija;
					}
					#odstrani nepotrebne podatke pri seznamih:
					if($operacija =~ m/seznam/){
						$operacija = "seznam";						
					}
					#razlikuje med novim vnosom in rejanjem:
					if($operacija =~ m/uredi/ && !($operacija =~ m/id/) ){
						$operacija = "dodaj";
					}
					#kozmetični popravek pri novi pogodbi:
					if($operacija =~ m/posta/ && $info=~m/pogodba/){
						$operacija = "prikazi pole";
						$stran = "DntPogodbe.cgi";
					}
					
					my %row = (				
						ime => DntFunkcije::sl_date_ura($res->{'time'}),
						admin => DntFunkcije::trim($res->{'remote_addrs'}),
						cas => $stran,
						info => $info,
						agent => $res->{'user_agent'},
						id => DntFunkcije::trim($res->{'uporabnik'}),
						link => $operacija
					);
					# put this row into the loop by reference             
					push(@loop, \%row);
				}				
			}
			else{
				$button = '<input type="button" name = "Pokazi" value = "Pokazi vse" onclick = "self.location=\'?rm=seznam&det=vse\'" />';
				$table_item0="Uporabnik";
				$table_item1="Administrator";
				$table_item2="Zadnjic aktiven";
				$table_item3="Podrobnosti";
			#if(length($ime)+length($st)>0){
				$sql = " SELECT DISTINCT".
							" a.id_uporabnik, b.id_uporabnik, ".
							" b.uporabnik, b.id_uporabnik, b.administrator ".
					   " FROM uporabniki_log as a, uporabniki as b ".
					   " WHERE b.id_uporabnik=a.id_uporabnik";
				$sth = $dbh->prepare($sql);
				#return $sql;
				$sth->execute();
				while ($res = $sth->fetchrow_hashref) {
					my $id_up=$res->{'id_uporabnik'};
					$sql=" SELECT time FROM uporabniki_log ".
						 " WHERE id_uporabnik='$id_up' ORDER BY time DESC LIMIT 1";
					$sth2 = $dbh->prepare($sql);
					$sth2->execute();
					$res2 = $sth2->fetchrow_hashref;
					my %row = (				
						ime => DntFunkcije::trim($res->{'uporabnik'}),
						admin => DntFunkcije::trim($res->{'administrator'}),
						cas => DntFunkcije::sl_date_ura($res2->{'time'}),
						id => DntFunkcije::trim($res->{'id_uporabnik'}),
						link => $q->a({-href=>"?rm=seznam&det=".$id_up}, "Podrobnosti")
					);
					# put this row into the loop by reference             
					push(@loop, \%row);
				}
			}
			$template->param(donator_loop => \@loop,

					edb_ime => DntFunkcije::trim($ime),
					item0 => $table_item0,
					item1 => $table_item1,
					item2 => $table_item2,
					item3 => $table_item3,
					nazaj => $button,
					#edb_triPike => $triPike,
					edb_st => DntFunkcije::trim($st));
			#}	
		}
		else{
			return 'Povezava do baze ni uspela';
		}
                
    # Parse the template
    $html_output = $template->output; #.$tabelica;
	return $html_output;
    
}

sub Zbrisi(){
	my $self = shift;
    my $q = $self->query();
	my $redirect_url = "?rm=seznam";
	my $dbh;
	my $res;
	my $sql;
	my $sth;
	$dbh = DntFunkcije->connectDB;
	if ($dbh) {
		$sql = "DELETE FROM uporabniki_log WHERE 1=1";
		$sth = $dbh->prepare($sql);				
		#return $sql;
		$sth->execute();
	}
	
	$self->header_type('redirect');
	$self->header_props(-url => $redirect_url);
	return $redirect_url;
	
}
1;    # Perl requires this at the end of all modules