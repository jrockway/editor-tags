use MooseX::Declare;

class Editor::Tags::Tag with MooseX::Clone {
    use MooseX::FileAttribute;
    use MooseX::Types::Structured qw(Dict Optional);
    use MooseX::Types::Moose qw(Int Str Bool ArrayRef);

    has_file 'associated_file' => (
        required => 1,
    );

    has 'name' => (
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has 'definition' => (
        is         => 'ro',
        isa        => Str,
        lazy_build => 1,
    );

    has [qw/line offset/] => (
        is      => 'ro',
        isa     => Int,
        default => 0,
    );

    has 'address_pattern' => (
        is         => 'ro',
        isa        => 'Str',
        lazy_build => 1,
    );

    method _build_address_pattern {
        if ($self->has_definition) {
            return "/^". $self->definition. "/";
        }
        elsif (my $line = $self->line) {
            return $line;
        }

        return '';
    }

    method _build_definition {
        if ($self->has_address_pattern){
            my $p = $self->address_pattern;
            $p =~ s{^/\^}{};
            $p =~ s{\$?/$}{};
            return $p;
        }
        return '';
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
