use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Validator',
    VERSION_FROM      => 'lib/Validator.pm', # finds $VERSION
    PREREQ_PM	  => { 
    	'JSON::XS' => 0,
    	'Class::Accessor::Fast' => 0,
    	'Mail::RFC822::Address' => 0,
    	'AGAVA::AGE::Framework::Library::XML::XPath::Cached' => 0,
    	'XML::XPath' => 0,
    	'Cache::FileCache' => 0,
    	'XML::XPath::XMLParser' => 0,
    	'XML::Validator::Schema' => 0,
    	'XML::Simple' => 0,
    	'XML::SAX::ParserFactory' => 0
    },	
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Validator.pm', # retrieve abstract from module
       AUTHOR         => 'Alex Nosoff <plcgi1@gmail.com>') : ()),
);
