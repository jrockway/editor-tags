use MooseX::Declare;

class Editor::Tags::Tag {
    use MooseX::FileAttribute;
    use MooseX::Types::Structured qw(Dict Optional);
    use MooseX::Types::Moose qw(Int Str Bool ArrayRef);

    has_file 'associated_file' => (
        required => 1,
    );

    has [qw/name definition/] => (
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has [qw/line offset/] => (
        is       => 'ro',
        isa      => Int,
        required => 1,
    );

    has 'address_pattern' => (
        is         => 'ro',
        isa        => 'Str',
        lazy_build => 1,
    );

    method _build_address_pattern {
        if (my $def = $self->definition) {
            return "/^$def/";
        }
        elsif (my $line = $self->line) {
            return $line;
        }
        else {
            return '';
        }
    }

    has 'extra_info' => (
        is => 'ro',
        isa => Dict[
            access         => Optional[Str],
            file           => Optional[Bool],
            kind           => Optional[Str],
            implementation => Optional[Str],
            inherits       => Optional[ArrayRef[Str]],
            signature      => Optional[Str],
        ],
        required => 1,
        default  => sub { +{} },
    );
}
