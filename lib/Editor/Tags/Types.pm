package Editor::Tags::Types;
use strict;
use warnings;

use MooseX::Types -declare => ['Tag'];

class_type Tag, { class => 'Editor::Tags::Tag' };

1;
