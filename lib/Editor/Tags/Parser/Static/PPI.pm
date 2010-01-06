use MooseX::Declare;

class Editor::Tags::Parser::Static::PPI
  with (Editor::Tags::Parser::FromFile) {
    use MooseX::FileAttribute;
    use MooseX::Types::Path::Class qw(File);
    use MooseX::Types::Structured qw(Dict);
    use MooseX::Types::Moose qw(ArrayRef);

    use Editor::Tags::Tag;
    use Editor::Tags::Types qw(Tag);

    use PPI;
    use Tie::File;

    use 5.010;

    has_file 'file' => (
        must_exist => 1,
        required   => 1,
    );

    method new_from_file($class: $filename, @rest) {
        return $class->new( file => $filename, @rest );
    }

    has 'document' => (
        init_arg   => undef,
        is         => 'ro',
        isa        => 'PPI::Document',
        lazy_build => 1,
    );

    has 'methods' => (
        init_arg   => undef,
        is         => 'ro',
        isa        => ArrayRef[Tag],
        auto_deref => 1,
        lazy_build => 1,
    );

    method new_tag(@args) {
        return Editor::Tags::Tag->new(
            associated_file => $self->file,
            @args,
        );
    }

    method _build_document {
        return PPI::Document->new( $self->file->stringify );
    }


    my $next_nonwhitespace = sub {
        my $next = shift;
        while ( $next = $next->next_sibling ) {
            return $next unless $next->isa('PPI::Token::Whitespace');
        }
    };

    method _build_methods {
        my $doc = $self->document;
        tie my @file , 'Tie::File' , $self->file->stringify;

        my @result;

        my $package;
        $doc->find( sub {
            my ($top, $token) = @_;

            if( $token->isa('PPI::Statement::Package')
                  || ( $token->isa('PPI::Token::Word') &&
                       $token->literal ~~ [qw/class role/]
                     )){
                my $defn;
                if( $token->can('namespace') ) {
                    $package = $token->namespace;
                    $defn = $token->content;
                }
                else {
                    $package = $token->snext_sibling->literal;
                    $defn = $token->literal. $token->next_sibling->content. $token->next_sibling->next_sibling->literal;
                }
                my ($line, $offset) = @{$token->location};
                push @result, Editor::Tags::Tag->new(
                    associated_file => $self->file,
                    name            => $package,
                    definition      => $defn,
                    line            => $line,
                    offset          => $offset,
                    extra_info      => {
                        kind => 'package',
                        file => 1,
                    },
                );
            }
            elsif( $token->isa('PPI::Statement::Sub') ){
                my $sub = $token;
                my ($line, $offset) = @{$sub->location};
                my $name = $sub->name;
                my $tag = Editor::Tags::Tag->new(
                    associated_file => $self->file,
                    name            => "${package}::$name",
                    definition      => substr ($file[$line-1], 0, $offset + 4 + length($name) - 1),
                    line            => $line,
                    offset          => $offset,
                    extra_info      => {
                        access    => 'sub',
                        signature => $sub->prototype || '',
                        kind      => 'sub',
                        file      => 1,
                    },
                );

                push @result, $tag;

            }

            elsif( $token->isa('PPI::Token::Word') &&
                  # also before/after/around/inner?
                  $token->literal ~~ [qw/method override/]){
                my $elt = $token;
                my $name = $next_nonwhitespace->($elt);
                my $proto_or_block = $next_nonwhitespace->($name);
                my ($proto, $block);
                if ($proto_or_block->isa('PPI::Structure::List')) {
                    $proto = $proto_or_block;
                    $block = $next_nonwhitespace->($proto_or_block);
                }
                else {
                    $block = $proto_or_block;
                }

                if($block->isa('PPI::Structure::Block')){
                    my ($line, $offset) = @{$name->location};
                    push @result, $self->new_tag(
                        name            => "${package}::". $name->literal,
                        definition      => substr ($file[$line-1], 0, $offset + length($name->literal) - 1),
                        line            => $line,
                        offset          => $offset,
                        extra_info      => {
                            access    => ($name->literal =~ /^_/ ? 'private' : 'public'),
                            signature => eval { $proto->literal } || '',
                            kind      => $elt->literal,
                            file      => 1,
                        },
                    );
                }
            }
        });

        return \@result;
    }

    method tags {
        return $self->methods;
    }
}
