use inc::Module::Install;
use strict;

name 'Editor-Tags';
all_from 'lib/Editor/Tags/File.pm';

requires 'MooseX::FileAttribute';
requires 'MooseX::Declare';
requires 'MooseX::Types::Structured';
requires 'PPI';
requires 'Set::Object';

requires 'Parse::ExuberantCTags'; # actually optional

requires 'App::Persistent'; # only needed for TagListSupport script

test_requires 'Test::Sweet';
test_requires 'Directory::Scratch';
test_requires 'Devel::Hide';

WriteAll;
