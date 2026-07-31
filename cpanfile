requires 'Moo';
requires 'MooX::Role::JSON_LD', '2.1.1';
requires 'MooX::Role::SEOTags', '1.2.1';
requires 'App::BlurFill', '0.1.0';
requires 'Image::Size';
requires 'Path::Tiny';
requires 'Template';
requires 'YAML::XS';
on test => sub { requires 'Test2::V0'; };
