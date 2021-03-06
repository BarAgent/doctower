module: markup-rep
synopsis: Classes comprising documentation.


/**
Synopsis: List of elements corresponding to the markup-words grammar.
   text-word         - <string> and <character>
   image-ref         - <inline-image>
   quote             - <xref>, <vi-xref>, <api-name>, <bold>, etc.
   bracketed-render-span   - <dita-content> or <html-content>
   line-marker-ref   - An <xref> to a <line-marker> or <line-marker-placeholder>.
   footnote-ref      - An <xref> to a <footnote> or <footnote-placeholder>.
   exhibit-ref       - An <xref> to an <exhibit> or <exhibit-placeholder>.
   synopsis-ref      - <conref>
**/
define constant <markup-seq> = limited(<stretchy-vector>,
      of: type-union(<string>, <character>, <inline-image>, <html-content>,
                     <dita-content>, <conref>, <xref>, <api/parm-name>, <cite>,
                     <term>, <term-style>, <code-phrase>, <entity>, <bold>,
                     <italic>, <underline>, <emphasis>));

define method markup-seq (#rest elements) => (seq :: <markup-seq>)
   make-limited-seq(<markup-seq>, elements)
end method;


/**                     
Synopsis: List of elements corresponding to content-block grammar.
   marginal-code-block  - <code-block>
   marginal-verbatim-block - <pre>
   figure-ref-line      - <fig>
   ditto-ref-line       - <ditto-placeholder>
   bracketed-raw-block  - <code-block> or <pre>
   table                - <simple-table>
   bullet-list          - <unordered-list>
   numeric-list         - <ordered-list>
   hyphenated-list      - <one-line-defn-list>
   phrase-list          - <many-line-defn-list>
   paragraph            - <paragraph>
**/
define constant <content-seq> = limited(<stretchy-vector>,
   of: type-union(<code-block>, <pre>, <fig>, <ditto-placeholder>,
                  <simple-table>, <unordered-list>, <ordered-list>, <defn-list>,
                  <paragraph>));

define method content-seq (#rest elements) => (seq :: <content-seq>)
   make-limited-seq(<content-seq>, elements)
end method;


//
// Topic content
//


define class <section> (<markup-element>)
   slot id :: false-or(<string>) = #f,
         init-keyword: #"id";
   slot title :: <title-seq> = make(<title-seq>),
         init-keyword: #"title";
   slot content :: <content-seq> = make(<content-seq>),
         init-keyword: #"content";

   slot title-source-loc :: <source-location> = $unknown-source-location;
   slot id-source-loc :: <source-location> = $unknown-source-location;
end class;

/**
In DITA, footnotes are done with <fn>. In HTML, they are rendered at the end of
the topic before sub-topics.
**/
define class <footnote> (<markup-element>)
   slot index :: type-union(<character>, <integer>), 
         init-keyword: #"index";
   slot content :: <content-seq> = make(<content-seq>),
         init-keyword: #"content";
end class;

/// In DITA, exhibits are done with <fig>.
define class <exhibit> (<markup-element>)
   slot index :: type-union(<character>, <integer>),
         init-keyword: #"index";
   slot title :: false-or(<string>) = #f,
         init-keyword: #"title";
   slot content :: <content-seq> = make(<content-seq>),
         init-keyword: #"content";
end class;


//
// Section/topic content
//


define class <paragraph> (<markup-element>)
   slot content :: <markup-seq> = make(<markup-seq>),
         init-keyword: #"content";
end class;

define class <note> (<markup-element>)
   slot content :: <content-seq> = make(<content-seq>),
         init-keyword: #"content";
end class;

define class <warning-note> (<note>)
end class;

// TODO: If all items of <ordered-list> or <unordered-list> are one paragraph,
// make it a compact list. In HTML, render without <p>.

define class <ordered-list> (<markup-element>)
   slot start :: type-union(<integer>, <character>), 
         init-keyword: #"start";
   slot items :: <vector> /* of <content-seq> */,
         init-keyword: #"items";
end class;

define class <unordered-list> (<markup-element>)
   slot items :: <vector> /* of <content-seq> */,
         init-keyword: #"items";
end class;

define class <defn-list> (<markup-element>)
   slot items :: <array> /* n rows by 2 cols, first col of <markup-seq>,
                            second col of <content-seq> */,
         init-keyword: #"items";
end class;

define class <one-line-defn-list> (<defn-list>)
end class;

define class <many-line-defn-list> (<defn-list>)
end class;

/// Mixin class for <defn-list> indicating an argument or value list.
define class <parm-list> (<object>)
end class;

define class <one-line-parm-list> (<one-line-defn-list>, <parm-list>)
end class;

define class <many-line-parm-list> (<many-line-defn-list>, <parm-list>)
end class;

define class <fig> (<markup-element>)
   slot image-name :: <string>;
   slot abs-size :: false-or(<integer>) = #f;
   slot rel-size :: false-or(<integer>) = #f;
   slot title :: false-or(<string>) = #f;
end class;

define class <simple-table> (<markup-element>)
   slot headings :: <vector>;
   slot items :: <array>;
end class;

define class <code-block> (<pre>)
end class;


//
// Section/topic content placeholders
//


define class <ditto-placeholder> (<markup-element>)
   slot target :: type-union(<topic>, <target-placeholder>),
      init-keyword: #"target";
end class;


//
// Inline content
//


/// This will be rendered as a DITA <p> or <ph> element with a conref attribute
/// or an HTML <p> or text. The #"shortdesc" style is only relevent to <topic>
/// targets.
define class <conref> (<markup-element>)
   slot target :: type-union(<topic>, <section>, <target-placeholder>),
      init-keyword: #"target";
   slot style :: one-of(#"title", #"shortdesc"),
      init-keyword: #"style";
end class;

/// This will be rendered as an empty DITA <ph> or HTML anchor. Technically,
/// DITA <codeph> is a sub-class of <ph>, but I'm not using them at all the same.
/// Don't want to include content in the tag in case DITA processors won't consider
/// it as code in a code block.
define class <line-marker> (<markup-element>)
   slot index :: type-union(<integer>, <character>), 
         init-keyword: #"index";
end class;

define class <inline-image> (<markup-element>)
   slot image-name :: <string>, init-keyword: #"image";
   slot alt-text :: <string>, init-keyword: #"alt-text";
end class;

define class <pre> (<markup-element>)
   slot content :: <sequence> /* of <string>, <line-marker> */
         = make(<stretchy-vector>);
end class;

define class <html-content> (<markup-element>)
   slot content :: <string>, init-keyword: #"content";
end class;

define class <dita-content> (<markup-element>)
   slot content :: <string>, init-keyword: #"content";
end class;
