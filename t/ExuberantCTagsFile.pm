use MooseX::Declare;

class t::ExuberantCTagsFile extends t::CTagsFile {
    use Test::Sweet;
    use Editor::Tags::File::ExuberantCTags;

    method file_class { 'Editor::Tags::File::ExuberantCTags' }
}
