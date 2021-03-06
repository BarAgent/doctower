module: markup-parser

//
// Types
//

define constant <topic-content-types> =
      type-union(<paragraph-directive-token>,
                 <link-directive-token>,
                 <links-directive-token>,
                 <word-directive-token>,
                 <division-directive-token>,
                 <titled-section-token>,
                 <section-directive-token>,
                 <footnote-token>,
                 <exhibit-token>,
                 <division-content-types>);
                 
define constant <division-content-types> =
      type-union(<marginal-code-block-token>,
                 <marginal-verbatim-block-token>,
                 <figure-ref-line-token>,
                 <ditto-ref-line-token>,
                 <bracketed-raw-block-token>,
                 <table-token>,
                 <bullet-list-token>,
                 <numeric-list-token>,
                 <hyphenated-list-token>,
                 <phrase-list-token>,
                 <indented-content-directive-token>,
                 <paragraph-token>);

define constant <topic-content-sequence> =
      limited(<vector>, of: <topic-content-types>);

define constant <division-content-sequence> =
      limited(<vector>, of: <division-content-types>);

//
// Markup
//

define caching parser markup-block :: <markup-content-token>
   rule seq(opt(indent), markup-content, opt(dedent), opt-many-spc-ls, not-next(char))
      => tokens;
   yield tokens[1];
afterwards (context, tokens, value, start-pos, end-pos, fail: fail)
   check-paired-indentation(tokens[0], tokens[2], fail)
end;

// exported
define caching parser markup-content (<source-location-token>)
   rule seq(opt(topic-content), opt-many(topic)) => tokens;
   slot default-topic-content :: <topic-content-sequence> = 
      as(<topic-content-sequence>, tokens[0] | #[]);
   slot topics :: <sequence>
      /* of <directive-topic-token> or <titled-topic-token> */ =
      tokens[1] | #[]; 
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Topics
//

define caching parser topic :: type-union(<directive-topic-token>, <titled-topic-token>)
   rule choice(directive-topic, titled-topic) => token;
   yield token;
end parser;

// exported
define caching parser directive-topic (<source-location-token>)
   rule seq(topic-directive-title, opt(topic-content)) => tokens;
   slot topic-type :: <symbol> = tokens[0].title-type;
   slot topic-title :: <topic-directive-title-token> = tokens[0];
   slot topic-nickname :: false-or(<title-nickname-token>) =
      tokens[0].title-nickname;
   slot content :: <topic-content-sequence> =
      as(<topic-content-sequence>, tokens[1] | #[]);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser titled-topic (<source-location-token>)
   rule seq(topic-title, opt(topic-content)) => tokens;
   slot topic-title :: <topic-or-section-title-token> = tokens[0];
   slot topic-nickname :: false-or(<title-nickname-token>) =
      tokens[0].title-nickname;
   slot content :: <topic-content-sequence> =
      as(<topic-content-sequence>, tokens[1] | #[]);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

define caching parser topic-content :: <topic-content-sequence>
   rule many(choice(section, footnote, exhibit, division-content)) => tokens;
   yield as(<topic-content-sequence>, integrate-sequences(tokens));
end;

//
// Sections
//

define caching parser section
      :: type-union(<titled-section-token>,
                    <section-directive-token>,
                    <paragraph-directive-token>,
                    <link-directive-token>,
                    <links-directive-token>,
                    <word-directive-token>,
                    <division-directive-token>,
                    <division-content-sequence>,
                    <section-directive-token>)
   rule choice(directive-section, titled-section) 
      => token;
   yield token;
end;

// null-directive yields <division-content-sequence>
define caching parser directive-section
      :: type-union(<section-directive-token>,
                    <paragraph-directive-token>,
                    <link-directive-token>,
                    <links-directive-token>,
                    <word-directive-token>,
                    <division-directive-token>,
                    <division-content-sequence>)
   rule choice(section-directive, paragraph-directive, link-directive,
               links-directive, word-directive, division-directive,
               null-directive)
      => token;
   yield token;
end;

// exported
define caching parser titled-section (<source-location-token>)
   rule seq(section-title, opt(division-content)) => tokens;
   slot section-title :: <topic-or-section-title-token> = tokens[0];
   slot section-nickname :: false-or(<title-nickname-token>) =
      tokens[0].title-nickname;
   slot content :: <division-content-sequence> =
      as(<division-content-sequence>, tokens[1] | #[]);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
// Not subclassed from <titled-section-token> because of the disjoint
// section-title slot.
define caching parser section-directive (<source-location-token>)
   rule seq(section-directive-title, opt(division-content))
      => tokens;
   slot section-title :: <section-directive-title-token> = tokens[0];
   slot section-nickname :: false-or(<title-nickname-token>) =
      tokens[0].title-nickname;
   slot content :: <division-content-sequence> =
      as(<division-content-sequence>, tokens[1] | #[]);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Footnotes and exhibits
//

// exported
define caching parser footnote (<source-location-token>)
   rule seq(sol, opn-brack-spc, choice(number, ordinal), spc-cls-brack, colon,
            spaces, markup-words, ls, opt(division-content))
      => tokens;
   slot index :: type-union(<integer>, <character>) = tokens[2];
   slot content :: <division-content-sequence> =
      prepend-words(tokens[6], tokens[8]);
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

// exported
define caching parser exhibit (<source-location-token>)
   rule seq(sol, opn-brack-spc, exhibit-lit, many-spc-ls, choice(number, ordinal),
            spc-cls-brack, colon, opt-seq(spaces, text-til-ls), ls,
            division-content)
      => tokens;
   slot index :: type-union(<integer>, <character>) = tokens[4];
   slot caption :: false-or(<string>) =
      tokens[7] & remove-multiple-spaces(tokens[7][1].text);
   slot content :: <division-content-sequence> = tokens[9];
afterwards (context, tokens, value, start-pos, end-pos)
   note-source-location(context, value)
end;

//
// Division content
//

// The choose removes #f (i.e. blank-lines) from the content blocks.
define caching parser division-content :: <division-content-sequence>
   rule many(choice(seq(nil(#f), indented-content),
                    seq(not-next(division-break), content-block)))
      => tokens;
   yield as(<division-content-sequence>,
            choose(true?, integrate-sequences(collect-subelements(tokens, 1))));
end;

define caching parser division-break
   rule choice(topic-or-section-title, topic-directive-title,
               section-directive-title, directive-spec, footnote, exhibit);
end;

// The choose removes #f (i.e. blank-lines) from the content blocks.
define caching parser indented-content :: <division-content-sequence>
   rule seq(indent, many(content-block), dedent) => tokens;
   yield as(<division-content-sequence>, choose(true?, tokens[1]));
end;

define caching parser remainder-and-indented-content :: <division-content-sequence>
   rule seq(markup-words, ls, opt(indented-content)) => tokens;
   yield prepend-words(tokens[0], tokens[2]);
end;
