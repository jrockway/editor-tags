use MooseX::Declare;

class t::CTagsFile with t::Role::TagFileTest {
    use Test::Sweet;
    use Editor::Tags::File::CTags;

    method file_class { 'Editor::Tags::File::CTags' }

    method compare_tags($got, $expected) {
        my $name = $expected->name;
        is $got->address_pattern, $expected->address_pattern, "$name - address patterns match";
    }
}
