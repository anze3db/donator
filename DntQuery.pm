package DntQuery;
use strict;
use warnings;
use base qw(Apache::Request);
use Apache::Constants qw(REDIRECT);

my $url = "Content-Type: text/html; charset=utf-8\n\n";

sub header_props{
	my $self = shift;
	$url = shift;
	
	
}
sub new {
    my($class, @args) = @_;
    $url = "Content-Type: text/html; charset=utf-8\n\n";
    return bless { _r => Apache::Request->new(@args) }, $class;
}
sub header {
    my $self = shift;
    #$self->send_http_header();
    return $url;
	return "\n\n";
}

sub redirect {

	print "Location: $_[2]";
	return REDIRECT;
	#my $self = shift;
	#print "Location: http://smotko.psywerx.net/" . $self->{url};
	#return REDIRECT;

}
sub setCookie {
	
	return "Set-Cookie: ";
}
sub strong{
	my($class, @p) = @_;
	return '<strong>'.$p[0].'</strong>';
}
sub a{
	my($class, @p) = @_;
	return "<a ". _html_params($p[0]) . ">$p[1]</a>";
}
sub p{
	
}
sub start_table{
    my($class, %p) = @_;
	return '<table '. _html_params(\%p) .' >';
}
sub start_Tr{
	return '<tr>';
}
sub th{
	my($class, @p) = @_;
	return '<th>' . $p[0] . '</th>';
}
sub td{
	my($class, @p) = @_;
	return '<td>' . $p[0] . '</td>';
}
sub end_table{
	return '</table>';
}
#FORMS:
sub start_form{
	my($class, %p) = @_;
	return '<form ' . _html_params(\%p) . ' >';
}
sub button{
	my($class, %p) = @_;
	return '<input type="button" ' . _html_params(\%p) . ' />';	
}
sub hidden{
	my($class, %p) = @_;
	return '<input type="hidden" ' . _html_params(\%p) . ' />';
}
sub submit{
	my($class, %p) = @_;
	return '<input type="submit" ' . _html_params(\%p) . ' />';
}
sub checkbox{
	my($class, %p) = @_;
	
	return "<input type='checkbox' "._html_params(\%p) . " /><label>$p{-label}</label>";
}
sub textfield{
	my($class, %p) = @_;
	return '<input type = "text" ' . _html_params(\%p) . ' />';
}
sub endform{
	return '</form>';
}


sub radio_group{
	my($class, %p) = @_;
	my $str = '';

	foreach ( @{ $p{-values} } ){
		my $selected = '';
		if( $_ eq $p{-default} ) { $selected = 'checked="checked"'; }
		$str .= '<input type="radio" id="' . $p{-name}.$_ .'" value = "' . $_ .'" '. _html_params(\%p) .' ' . $selected . ' /><label for="' . $p{-name}.$_ .'">'. $_ .'</label>';
	}
	return $str;
}
sub end_form{
	return '</form>';
}
sub textarea{
	my($class, %p) = @_;
	my $value = $p{-value};
	delete $p{-value};
	
	return "<textarea "._html_params(\%p).">" . $value . "</textarea>";
}
#Private function:
sub _html_params{
	my $params = '';
	my ($element) = @_;
	foreach my $key (keys %$element){
		if(defined $$element{$key} && $key ne '-values' && $key ne '-linebreak' && $key ne '-default' && $key ne '-label'){
			$params .=  substr($key, 1) . '="' . $$element{$key} . '" ';
		}
    }
	return DntFunkcije::trim($params);
}


1;
