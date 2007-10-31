package Validator::Rules::Base;

use 5.008007;
use strict;
use warnings;

use  Mail::RFC822::Address qw(valid);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $this = {};
	bless $this,$class;
	return $this;
}

sub integer {
	my $this = shift;
	my $fieldValue = shift;
	my $res = ( $fieldValue =~/^\d+$/ );
	return $res;		
}
	
sub pattern	{
	my $this = shift;
	my $fieldValue 	= shift;
	my $pattern		= shift;
	
	my $res = ( $fieldValue =~ /$pattern/ );
	return $res;		
}
		
sub ip {
	my $this = shift;
	my $fieldValue 	= shift;
	
	my $res = ( $fieldValue=~/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/ );
	return $res;
}	

sub email {
	my $this = shift;
	my $fieldValue 	= shift;
	
	my $res = valid($fieldValue);
	
	return $res;
}	

sub maxlength {
	my $this = shift;
	my $fieldValue 	= shift;
	my $maxLength 	= shift;
	
	unless ( $fieldValue =~/^[\p{IsDigit}]+$/) {
		$fieldValue = length($fieldValue);
	}
		
	my $res = ( $fieldValue <= $maxLength ) ;
	return $res;		
}
		
sub minlength {
	my $this = shift;
	my $fieldValue 	= shift;
	my $minLength 	= shift;
	
	unless ( $fieldValue =~/^[\p{IsDigit}]+$/) {
		$fieldValue = length($fieldValue);
	}
		
	my $res = ( $fieldValue >= $minLength ) ;
	return $res;
}

sub anyText {
	my $this = shift;
	my $fieldValue 	= shift;
	
	#my $re = q/^[\p{IsAlpha}|\p{IsDigit}|\p{IsSpace}|\p{IsS}|\p{IsP}|\p{IsZ}|\p{InCyrillic}]+$/;
	
	my $re = '.*';
	
	my $res = $this->pattern($fieldValue,$re);
	
	return $res;
}

sub equals {
	my $this 	= shift;
	my $value1 	= shift;
	my $value2 	= shift;
	
	my $res = $value1 eq $value2;
	
	return $res;
}

sub notEquals {
	my $this 	= shift;
	my $value1 	= shift;
	my $value2 	= shift;
	
	my $res = $this->equals($value1,$value2);
	
	return !$res;
}
1;
__END__

=head1 NAME

Validator::Rules::Base - Perl extension for field values validation

=head1 SYNOPSIS

  use Validator::Rules::Base;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Validator::Rules::Base, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
