#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 24;

use_ok 'KaiBashira::Inflector';

my $inflector = KaiBashira::Inflector->new;

#pluralize
ok $inflector->pluralize( "post"                         ) eq "posts"                     , " pluralize - case 1";
ok $inflector->pluralize( "octopus"                      ) eq "octopi"                    , " pluralize - case 2";
ok $inflector->pluralize( "sheep"                        ) eq "sheep"                     , " pluralize - case 3";
ok $inflector->pluralize( "words"                        ) eq "words"                     , " pluralize - case 4";
ok $inflector->pluralize( "CamelOctopus"                 ) eq  "CamelOctopi"              , " pluralize - case 5";
ok $inflector->pluralize( "moves"                        ) eq  "move"                     , " pluralize - case 6";

#singularize
ok $inflector->singularize( "posts"                       ) eq  "post"                    , " singularize - case 1";
ok $inflector->singularize( "octopi"                      ) eq  "octopus"                 , " singularize - case 2";
ok $inflector->singularize( "sheep"                       ) eq  "sheep"                   , " singularize - case 3";
ok $inflector->singularize( "word"                        ) eq  "word"                    , " singularize - case 4";
ok $inflector->singularize( "CamelOctopi"                 ) eq  "CamelOctopus"            , " singularize - case 5";
ok $inflector->singularize( "moves"                       ) eq  "move"                    , " singularize - case 6";

#capitalize
ok $inflector->capitalize( "heLLO, World"                ) eq "Hello, world"              , " capitalize - case 1";

#camelize
ok $inflector->camelize( "kai_bashira_record"            ) eq "KaiBashiraRecord"          , " camelize - case 1";
ok $inflector->camelize( "kai_bashira_record"        , 0 ) eq "kaiBashiraRecord"          , " camelize - case 2";
ok $inflector->camelize( "kai_bashira_record/errors"     ) eq "KaiBashiraRecord::Errors"  , " camelize - case 3";
ok $inflector->camelize( "kai_bashira_record/errors" , 0 ) eq "kaiBashiraRecord::Errors"  , " camelize - case 4";

#underscore
ok $inflector->underscore( "KaiBashiraRecord"            ) eq "kai_bashira_record"        , " underscore - case 1";
ok $inflector->underscore( "KaiBashiraRecord::Errors"    ) eq "kai_bashira_record/errors" , " underscore - case 2";

#dasherize
ok $inflector->dasherize( "puni_puni"                    ) eq "puni-puni"                 , " dasherize - case 1"; 

#demodulize
ok $inflector->demodulize( "KaiBashiraRecord::CoreExtensions::String::Inflections" )
                                                           eq "Inflections"               , " demodulize - case 1"; 
ok $inflector->demodulize( "Inflections"                 ) eq "Inflections"               , " demodulize - case 2";

#parameterize
ok $inflector->parameterize( "Donald E. Knuth"           ) eq "donald-e-knuth"            , " parameterize - case 1";