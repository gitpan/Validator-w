# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Validator.t'

#########################

use Test::More qw(no_plan);
use FindBin qw($Bin);
use lib $Bin. '/../lib';
use Validator;
use Data::Dumper;

BEGIN { use_ok('Validator') }

#########################

my $validator = Validator->new();
ok( ref $validator eq 'Validator', "Validator->new()" );

my $res;
my $fields = getOK(); 
foreach ( @$fields ) {
	$validator->clear();
	$validator->fields( [$_] );
	$res = $validator->isValid();
	ok( $res == 1, "OK test isValid().Result: $res.Name: $_->{name}.Value: $_->{value}" );	
}

$fields = getBAD();
foreach ( @$fields ) {
	$validator->clear();
	$validator->fields([$_]);
	$res = $validator->isValid();
	ok( ref $res eq 'Validator::ErrorCode',
		"BAD test isValid().Result:$res.Name: $_->{name}.Value: $_->{value} " );	
}

$fields = $validator->xmlCached( %{getXMLCachedOpts()} );
foreach ( @$fields ) {
	$validator->clear();
	$validator->fields([$_]);
	$res = $validator->isValid();
	ok( $res == 1, "xml + xsd: OK test isValid().Result: $res.Name: $_->{name}.Value: $_->{value}" );	
}

$fields = $validator->xmlCached( %{getXMLCachedOpts(1)} );
foreach ( @$fields ) {
	$validator->clear();
	$validator->fields([$_]);
	$res = $validator->isValid();
	ok( ref $res eq 'Validator::ErrorCode',
		"xml + xsd: BAD test isValid().Result:$res.Name: $_->{name}.Value: $_->{value} " );
}		

#print Dumper $validator->xmlCached( %{getXMLCachedOpts()} );

print Dumper $validator->funcIsValidAsJS();

sub getXMLCachedOpts {
	my $bad = shift;
	
	my $xsd = $Bin.'/xmlData/form_validator.xsd';
	my $hashref = { xsdFile => $xsd };
	
	if ( $bad ) {
		$hashref->{xmlFile} = $Bin.'/xmlData/simpleBAD.xml';	
	}
	else {
		$hashref->{xmlFile} = $Bin.'/xmlData/simpleOK.xml';
	}
	return $hashref;
}

sub getOK {
	my $inputValidatorOK = [
		{
			name     => 'Integer',
			required => 1,
			value    => 2,
			rules    =>
			  [ { rule => 'integer' }, { rule => 'maxlength', param => 2 }, ]
		},
		{
			name     => 'Integer',
			required => 1,
			error    => 'Integer not in min max',
			value    => 2,
			rules    => [
				{ rule => 'integer' },
				{ rule => 'minlength', param => 1 },
				{ rule => 'maxlength', param => 2 },
			]
		},
		{
			name     => 'Pattern',
			required => 1,
			value    => 'Test string&&',
			rules    => [ { rule => 'pattern', param => '^(Test string&&)$' }, ]
		},
		{
			name     => 'IP',
			required => 1,
			value    => '127.0.0.11',
			rules    => [ { rule => 'ip' }, ]
		},
		{
			name  => 'EMAIL',
			value => 'plcgi1@gmail.com',
			rules => [ { rule => 'email' }, ]
		},
		{
			name  => 'AnyText',
			value => 'фывыв АПРО е 123 <>^&*',
			rules => [ { rule => 'anyText' }, ]
		},
		{
			name  => 'Equals',
			value => '1',
			rules => [ { rule => 'equals', param => '1' }, ]
		},
		{
			name  => 'NOTEquals',
			value => '1',
			rules => [ { rule => 'notEquals', param => '5' }, ]
		}
	];
	return $inputValidatorOK;
}

sub getBAD {
	my $inputValidatorBAD = [
		{
			name  => 'EMAIL',
			value => '<script>@gmail.com',
			rules => [ { rule => 'email' }, ]
		},
		{
			name  => 'Integer',
			error => 'Bad format for Integer',
			value => 43,
			rules =>
			  [ { rule => 'integer' }, { rule => 'maxlength', param => 1 }, ]
		},
		{
			name     => 'Integer',
			required => 1,
			error    => 'Integer not in min max',
			value    => 234,
			rules    => [
				{ rule => 'integer' },
				{ rule => 'minlength', param => 1 },
				{ rule => 'maxlength', param => 2 },
			]
		},
		{
			name     => 'Pattern',
			required => 1,
			error    => 'Bad format for Pattern',
			value    => 'Test stringa',
			rules    => [ { rule => 'pattern', param => '^(Test string)$' }, ]
		},
		{
			name     => 'IP',
			required => 1,
			error    => 'Bad format for IP',
			value    => '1127.0.0.1',
			rules    => [ { rule => 'ip' }, ]
		},
		{
			name     => 'IP',
			required => 1,
			error    => 'Bad format for IP',
			value    => '127.0.10.1000',
			rules    => [ { rule => 'ip' }, ]
		},
		{
			name     => 'IP',
			required => 1,
			error    => 'Bad format for IP',
			value    => '127.10.1.1111',
			rules    => [ { rule => 'ip' }, ]
		},
		{
			name  => 'AnyText',
			value => 'фывыв АПРО е 123 <>^&*',
			rules => [ 
				{ rule => 'anyText' },
				{ rule => 'minlength', param=>1 },
				{ rule => 'maxlength', param=>3 },
			]
		},
		{
			name  => 'Equals',
			value => '1',
			rules => [ { rule => 'equals', param => 'rr' }, ]
		},
		{
			name  => 'NOTEquals',
			value => '1',
			rules => [ { rule => 'notEquals', param => '1' }, ]
		}
	];
	return $inputValidatorBAD;    
}

1;
