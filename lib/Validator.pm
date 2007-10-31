package Validator;

use 5.008007;
use strict;
use warnings;

use JSON::XS qw(to_json);
use AGAVA::AGE::Framework::Library::XML::XPath::Cached;

our %EXPORT_TAGS = (
	'all' => [
		qw(

		  )
	]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

use Validator::ErrorCode;
use Validator::Rules::Base;
use Class::Accessor::Fast;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/fields errorCount errorCode/);

sub new {
	my $class = shift;
	my %opt = @_;
	
	my $this = $class->SUPER::new();
	
	bless $this,$class;
	
	return $this;
}

sub clear {
	my $this = shift;
	
	$this->fields([]);
	$this->{errFields} = undef;	
}

sub isValid {
	my $this = shift;

	my $rulesObj = Validator::Rules::Base->new();

	foreach my $f ( @{ $this->fields } ) {
		my $fieldName  = $f->{name};
		my $required   = $f->{required};
		my $fieldValue = $f->{value};
		my $rules      = $f->{rules};
		my $count      = 0;

		# checking on required
		if ( $required && $required == 1 && length($fieldValue) < 1 ) {
			$f->{error} = "Param $fieldName required" unless $f->{error};
			$this->appendErrField($f);
			next;
		}    # END if ( $required eq '1' && !length($fieldValue) )
		foreach my $r (@$rules) {
			my $func = $r->{rule};
			
			next if ( !$required && !$fieldValue );
			
			my $res = $rulesObj->$func( $fieldValue, $r->{param} );
			if ( !$res ) {
				$f->{error} = "Wrong format for $fieldName" unless $f->{error};
				$this->appendErrField($f);
			}
		}    # END foreach my $r ( keys %$rules )
		
		if ( !$this->{errFields} ) {
			$f->{value} = _filter($f->{value});
		}
	}    # END foreach my $f ( @{$this->fields} )
	my $errors = ++$#{ $this->{errFields} };
	if ( $errors > 0 ) {
		my $err = Validator::ErrorCode->new();

		$err->errorCount($errors);
		$err->errorFields( $this->{errFields} );
		$err->errorMsg();

		return $err;
	}    # END if( $this->errCount() > 0 )

	return 1;
}

sub xmlCached {
	my $this = shift;
	my %opt  = @_; # ( xmlFile => 'path/to/xml/file', xsdFile => '/path/to/xsd/file', values => { fieldName => fieldValue } )
	
	foreach ( qw( xmlFile xsdFile ) ) {
		die "Param $_ is required" unless $opt{$_};
	} 
	
	# hopefully not having to parse the file speeds things up remarkably
	my $xmlCached = AGAVA::AGE::Framework::Library::XML::XPath::Cached->new(
		filename    => $opt{xmlFile},    
		xsdFilename => $opt{xsdFile}
	);

	my $config = $xmlCached->toXMLSimple();
	
	$opt{convertMethod} = \&convertXMLSimpleToValidator unless $opt{convertMethod};
	
	$config = &{ $opt{convertMethod} }( $config );
	
	return $config;
}

sub appendField {
	my $this  = shift;
	my $field = shift;

	push @{ $this->{fields} }, $field;
}

sub appendErrField {
	my $this  = shift;
	my $field = shift;

	push @{ $this->{errFields} }, $field;
}

sub funcIsValidAsJS {
	my $this     = shift;
	my $formName = shift || '' ;

	return unless $this->fields();

	my $fieldsAsJSON = $this->fieldsAsJSON();

	my $funcName = $formName . '_JSValidator';
	my $func     = qq~
<script language="javascript">
    window.$funcName = function() {
	    var validator = new Validator;
	    var fields = $fieldsAsJSON;
	    validator.SetForm(fields, '$formName');
		validator.Process();
		return validator.success;
    }
</script>
~;

	return $func;
}

sub fieldsAsJSON {
	my $this = shift;

	return unless $this->fields();

	my $json = to_json( $this->fields() );

	return $json;
}

sub convertXMLSimpleToValidator {
	my $param = shift;
	
	my @res;
	foreach my $field ( @{$param->{Field}} ) {
		my (@rules,$hashref);
		
		foreach my $rule ( @{$field->{Rules}->[0]->{Rule}} ) {
			$hashref = {
				rule => $rule->{name},
			};
			$hashref->{param}	= $rule->{Param}->[0] if $rule->{Param}; 
			push @rules, $hashref;	
		}
		$hashref = {
			name	=>	$field->{Name}->[0],
			value	=>	$field->{Value}->[0],
			error	=>	$field->{ErrorString}->[0],
			rules	=>	\@rules
		};
		
		if ( $field->{Required}->[0] eq 'true') {
			$hashref->{required} = 1;	
		} 
		else {
			$hashref->{required} = 0;
		}
		
		push @res,$hashref;
	}
	
	return \@res;
}

#------------------------------------------------------------------------------
sub _filter {
    my $str = shift;

    if ( ref ( $str ) eq 'ARRAY' ) {
        foreach ( @{$str} ) {
            my $regexp = qr/\0|#|\&|"|<|>|\(|\)|\|/;
            $str =~ s/($regexp)/_translateSymbols($1)/ge;
        }
    }
    else {
        my $regexp = qr/\0|#|\&|"|<|>|\(|\)|\|/;
        $str =~ s/($regexp)/_translateSymbols($1)/ge if $str;
    }

    return $str;
}

#------------------------------------------------------------------------------
sub _translateSymbols {
    my $sym = shift;
    if ( $sym eq "\0" ) { $sym= ''; }
    elsif ( $sym eq '#' ) { $sym = '&#35;'; }
    elsif ( $sym eq '&' ) { $sym = '&#38;'; }
    elsif ( $sym eq '"' ) { $sym = '&quot;'; }
    elsif ( $sym eq '<' ) { $sym = '&lt;'; }
    elsif ( $sym eq '>' ) { $sym = '&gt;'; }
    elsif ( $sym eq '|' ) { $sym = '&brvbar;'; }
    elsif ( $sym eq '(' ) { $sym = '&#40;'; }
    elsif ( $sym eq ')' ) { $sym = '&#41;'; }

    return $sym;
}
#------------------------------------------------------------------------------
1;

1;
__END__

=head1 NAME

Validator - Input params validator

=head1 SYNOPSIS

  	use Validator;
  	
  	my $fields = [
		{
			name		=>	'Integer',
			error		=>	'Bad format for Integer',
			value		=>	43,
			rules	=>	[
				{ rule => 'integer' },
				{ rule => 'maxlength', param => 1 },
			]
		},
		{ ... }
	];
	
	my $validator = Validator->new();
	$validator->fields($fields);
	my $valid = $validator->isValid();
	
	if ( ref $valid eq 'Validator::ErrorCode' ) {
		# error handling
		$valid->errorCode();
		# or 
		$valid->errorMsg();
	}		

in JSON

# Example of array for validator settings
#	fields =
#	[
#		{
#			name: 'child_frm_1_txt1',
#			required: 1,
#			error: ErrorMessage,
#			value: value
#			rules: [
#				{ rule: 'integer' },
#				{ rule: 'maxlength', param: 3 }
#			]
#		},
#		{
#			name: 'child_frm_1_txt2',
#			required: 0,
#			rules: [
#				{ rule: 'email' },
#			]
#		},
#		{
#			name: 'child_frm_2_txt1',
#			required: 1,
#			rules: [
#				{ rule: 'datetime', param:  'YYYY-MM-DD hh:mm'  }
#			]
#		},
#		{
#			name: 'child_frm_2_txt2',
#			required: 1,
#			rules: [
#				{ rule: 'minlength', param: 2 },
#				{ rule: 'maxlength', param: 5 }
#			]
#		}
#	]
#*/

=head1 DESCRIPTION

Class for input method validation by rules from Validator::Rules::Base 

=head2 EXPORT

TODO

=head1 SEE ALSO

TODO

=head1 AUTHOR

Alex Nosoff E<lt>plcgi1@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000 by Alex Nosoff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
