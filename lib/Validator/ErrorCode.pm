package Validator::ErrorCode;

use 5.008007;
use strict;
use warnings;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Validator::ErrorCode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/errorCount errorFields errorMsg/);

#  формат кода ошибки
sub errorMsg {
	my $this = shift;
	
	my @msg = ();
	foreach ( @{$this->errorFields} ) {
		push @msg,$_->{error} if ($_->{error});
	}
	$this->{errorMsg} = join '.',@msg;
	return \@msg;
}

sub errorMsgAsString {
	my $this = shift;
	
	return $this->{errorMsg};
}

sub errorCode {
	my $this = shift;
	
	return {
		errorCount	=> 	$this->errorCount(),
		errorFields	=>	$this->errorFields()
	}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Validator::ErrorCode - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Validator::ErrorCode;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Validator::ErrorCode, created by h2xs. It looks like the
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
