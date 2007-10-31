package AGAVA::AGE::Framework::Library::XML::XPath::Cached;
use strict;
use warnings;
use base "XML::XPath";

##############################################################################
# whatever in Cache:xx hierarchy
our $CACHE_MODULE = "Cache::FileCache";
use Cache::FileCache;

# namespace equals to package name with '::' replace with '/', so directories
# are created
(our $CACHE_NAMESPACE = __PACKAGE__) =~ s|::|/|xg;
##############################################################################

use File::stat;
use XML::XPath::XMLParser;
use XML::Validator::Schema;
use XML::SAX::ParserFactory;

use Storable qw (freeze);
use XML::Simple;

use Carp;

=pod

=head1 NAME

AGAVA::AGE::Framework::Library::XML::XPath::Cached - XPath sublass to cache
parsed XML content.

=head1 SYNOPSIS

	$xpath = new AGAVA::AGE::Framework::Library::XML::XPath::Cached (
					filename => "file.xml", xsdFilename => "file.xsd");
					
=head1 DESCRIPTION

This class is a drop-in replacement for XML::XPath designed to:

=over

=item

speed things up by caching parsed XML content

=item

validate XML content against XML schema

=back


=head1 METHODS

=over 

=cut



=pod

=item B<new (filename =E<gt> file.xml, xsdFilename =E<gt> file.xsd)>

Constructor. Options are:

=over

=item B<filename> - mandatory

input XML file (if '/' is not present in its name, it's not unique
cache-wide and an exception is thrown (Cwd::realpath() is sometimes buggy and
returns undef)

=item B<xsdFilename> - optional

XML schema file to validate XML content against

=item B<xmlSimple> -  hashref

what to pass to XML::Simple::XMLin() - ForceArray=1 and KeyAttr=>[] are
enforced to guarantee XML is treated as safely as possible

=back

=cut

sub new (%)
{
    my ($class, %args) = @_;
    $class = ref ($class) || $class;
    
    # so far, only filename is accepted (no ioref etc.)
    if (!defined ($args{filename}) || ($args{filename} eq ""))
    {
    	croak ("Please pass non-empty filename=>file.xml argument");
    }
	
    
    # absolute path provides cache key uniqueness if filename is passed
    # as e.g. '../config.xml' (from different current dirs)
    # TODO: why does Cwd::realpath() return undef??
    my $xmlFile = $args{filename};
    
    if ($xmlFile !~ /^ \/ /x)
    {
    	croak ("Filename should start with '/': '$xmlFile'");
    }
    
#    my $xmlFile = realpath ($args{filename});
#    if (!defined ($xmlFile))
#    {
#    	croak ("Can't build realpath for file '$xmlFile'");
#    }
    
    # extension point for other types, such as xml://
    # (if $args{xml} is present)
    my $rootPrefix = "file://$xmlFile";
	
	my $cache = $CACHE_MODULE->new ({ namespace => $CACHE_NAMESPACE });
	my $rootNodeKey 	 = "$rootPrefix/xpathRootNode";
	my $xmlFileSizeKey 	 = "$rootPrefix/xmlFileSize";
	my $xmlFileMtimeKey  = "$rootPrefix/xmlFileMtime";
	my $xmlSimpleKey 	 = "$rootPrefix/xmlSimple";
	
	# true - values in cache are relevant and should be used
	my $isCacheValid = 1;
	
	# current file size the same as the one used to store parsed data?
	my $fileSize = $cache->get ($xmlFileSizeKey);
	
	# current file mtime the same as the one used to store parsed data?
	my $fileMtime = $cache->get ($xmlFileMtimeKey);
	
	my $fileStat = stat ($xmlFile);
	
	# no record in cache or values differ
	if (!defined ($fileStat)
		||
		!defined ($fileSize) || ($fileSize != $fileStat->size())
		||
		!defined ($fileMtime) || ($fileMtime != $fileStat->mtime()) )
	{
		$isCacheValid = 0;
	}
	
	
	my $rootNode = $cache->get ($rootNodeKey);
	my $xmlSimple = $cache->get ($xmlSimpleKey);
	
	# nothing or incomplete info in cache (i.e. if we add something to
	# cache parameter set, cache upgrade will be seamless, as cache will
	# become invalid)
	if (!defined ($rootNode) || !defined ($xmlSimple))
	{
		$isCacheValid = 0;
	}
	
	# populate variables and store them in cache
	if ($isCacheValid)
	{
#		die ("Reading from cache");
	}
	
	else
	{
		# validate XML file against XML schema
	    if (defined ($args{xsdFilename}))
	    {
			# XML::Validator::Schema accepts only file names not file content
			my $handler = new XML::Validator::Schema (
										file  => $args{xsdFilename},
										cache => 1);

			my $parser = XML::SAX::ParserFactory->parser (Handler => $handler);
			
		    # dies on error
			eval { $parser->parse_file ($xmlFile) };
		
		    if ($@ ne "")
		    {
				croak ("Invalid syntax: $xmlFile: $@");
		    }
	    }
		    
	    # parse XML file and store result (xpath nodeset) in cache
		my $parser = new XML::XPath::XMLParser (filename => $xmlFile);
		$rootNode = $parser->parse();
		
		$cache->set ($xmlFileSizeKey,  $fileStat->size());
		$cache->set ($xmlFileMtimeKey, $fileStat->mtime());
		$cache->set ($rootNodeKey, $rootNode);
		
		#
		# store XML converted into hash - for toXMLSimple();
		# for the sake of compatibility, ForceArray=1 (i.e. all tags become
		# arrays )and KeyAttr=[] (i.e. no array folding - array-to-hash
		# conversion - based on name/key/id fields)
		#
		$xmlSimple = XMLin ($xmlFile, ForceArray => 1, KeyAttr => []);
		$cache->set ($xmlSimpleKey, $xmlSimple);
	}

	
	my $self = $class->SUPER::new (context => $rootNode);
	
	# cache always contains the parsed XML nodeset after new(), as relevant
	# data is stored there if it was not there before
    $self->{caching}{cache} = $cache;
    
    # it's dangerous to create own class fields, as they can overlap with
    # the parent's fields, but we have to store some data to access cache
    # in find() - at least we use a certain common prefix for own hash
    $self->{caching}{rootPrefix} = $rootPrefix;
    
    # parsed result
    $self->{caching}{xmlSimple} = $xmlSimple;
    
	return $self;
}



=pod

=item B<toXMLSimple()>

Pipes XML file to XML::Simple, returns what XMLin returns.

NOTE: ForceArray=1 is always passed, so all tags are arrayrefs!
Also, KeyAttr=[] is passed to disable array folding based on attr names.

=cut

sub toXMLSimple()
{
	my ($self) = @_;
	return $self->{caching}{xmlSimple};
}



=pod

=item B<find>

Method borrowed from parent class and patched to use cache, if any.
See parent class for method description.

NOTE: for some reason, in real life projects nodeset caching turned out to be
SLOWER, than no caching, so currently this method DOESN'T USE CACHING.

=cut

# rename info find() to override parent method
# (currently Whois stops working if it's done)
sub findCached {
    my $self = shift;
    my $path = shift;
    my $context = shift;
    die "No path to find" unless $path;
    
    if (!defined $context) {
        $context = $self->get_context;
    }
    if (!defined $context) {
        # Still no context? Need to parse...
        my $parser = XML::XPath::XMLParser->new(
                filename => $self->get_filename,
                xml => $self->get_xml,
                ioref => $self->get_ioref,
                parser => $self->get_parser,
                );
        $context = $parser->parse;
        $self->set_context($context);
#        warn "CONTEXT:\n", Data::Dumper->Dumpxs([$context], ['context']);
    }
    
	# PATCH START
    my $parsed_path = $self->{path_parser}->parse($path);
	# PATCH END
	
#    warn "\n\nPATH: ", $parsed_path->as_string, "\n\n";

     
#    warn "evaluating path\n";
	# PATCH START
	my $nodeset;
	
	# cache always exists - see new() - but we check it for safety
	if (!defined ($self->{caching}{cache}))
	{
		die ("No cache found - did you call new() ?");
	}
		
	# it's better to use the $parsed_path->as_string() (not $path), as it's
	# canonical, but path conversion takes time
	my $key = $self->{caching}{rootPrefix}
			. "/"
			. $path;
			
	$nodeset = $self->{caching}{cache}->get ($key);
	
	# nodeset not found in cache - let parent execute the search query
	if (!defined ($nodeset))
	{
	    $nodeset = $self->SUPER::find ($path, $context);
	    $self->{caching}{cache}->set ($key, $nodeset);
#	    warn "Storing in cache: key $key, no. of elements: " . $nodeset->size();
	}
	
	else
	{
#	    warn "Got from cache: key $key, no. of elements: " . $nodeset->size();
	}
	
	return $nodeset;
#    return $parsed_path->evaluate($context);
	# PATCH END
}

#close method list

=pod

=back

=cut

1;
