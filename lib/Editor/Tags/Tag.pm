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

    method to_etag {
        return $self->definition . "\x{7f}". $self->name. "\x{01}". $self->line. ','. $self->offset;
    }

    method to_ctag {
        my $definition = $self->definition;
        return join "\t", $self->name, $self->associated_file, qq{/^$definition/};#, %{$self->extra_info};
    }
}
