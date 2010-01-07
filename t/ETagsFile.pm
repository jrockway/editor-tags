use MooseX::Declare;

class t::ETagsFile with t::Role::TagFileTest {
    use Test::Sweet;
    use Editor::Tags::File::ETags;

    method file_class { 'Editor::Tags::File::ETags' }

    method compare_tags($got, $expected) {
        my $name = $expected->name;
        is $got->line, $expected->line, "$name - line numbers match";
        is $got->offset, $expected->offset, "$name - offsets match";
        is $got->definition, $expected->definition, "$name - definitions match";
    }

    test etags_data_exists_in_file {
        my $data = $self->collection->build_file_contents;
        ok $data, 'got data in output file';

        like $data, qr/^\x0c$ . ^Foo[.]pm,\d+$ ./xms, 'have header for Foo.pm';
        like $data, qr/^\x0c$ . ^Bar[.]pm,\d+$ ./xms, 'have header for Bar.pm';
        like $data, qr/^\x0c$ . ^Complex[.]pm,\d+$ ./xms, 'have header for Complex.pm';
        like $data, qr/^sub function\x7fFoo::function\x012,0/m, 'have entry for Foo::function';
        like $data, qr/^package Foo;\x7fFoo\x011,0/m, 'have entry for Foo';
        like $data, qr/^    package Bar;\x7fBar\x012,4/m, 'have entry for Bar';
        like $data, qr/^    method complex\x7fcomplex\x013,4/m, 'have entry for complex method';
    }

}
