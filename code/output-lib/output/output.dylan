module: output


/**
Synopsis: Navigation information for a topic.
*/

define class <topic-nav> (<object>)
   constant slot next-topic :: false-or(<topic>),
      required-init-keyword: #"next";
   constant slot prev-topic :: false-or(<topic>),
      required-init-keyword: #"prev";
   constant slot parent-topics :: <simple-object-vector>,
      required-init-keyword: #"parents";
   constant slot child-topics :: <simple-object-vector>,
      required-init-keyword: #"children";
end class;


/**
Synopsis: HREF targets generated from target IDs or index numbers.

The 'target-href' keyword will be the 'href' attribute of links to the target,
and the 'target-id' keyword will be the 'id' attribute of the target itself.

For DITA output, 'target-href' will be 'topicid' or 'topicid/contentid' and the
corresponding 'target-id' will be 'topicid' or 'contentid'. For HTML output,
'target-href' will be as in the DITA output and the corresponding 'target-id'
will be the same as 'target-href'.

The '<topic-target>' and '<section-target>' classes have additional keywords:
'title-href' and 'title-id'. These work like the 'target-href' and 'target-id'
keywords except that they are only used in DITA title conrefs.
*/

define abstract class <target> (<object>)
   constant slot target-href :: <string>,
      required-init-keyword: #"href";
   constant slot target-id :: <string>,
      required-init-keyword: #"id";
end class;

define class <topic-target> (<target>)
   constant slot title-href :: <string>,
      required-init-keyword: #"title-href";
   constant slot title-id :: <string>,
      required-init-keyword: #"title-id";
end class;

define class <section-target> (<target>)
   constant slot title-href :: <string>,
      required-init-keyword: #"title-href";
   constant slot title-id :: <string>,
      required-init-keyword: #"title-id";
end class;

define class <footnote-target> (<target>)
end class;

define class <ph-marker-target> (<target>)
end class;


/**
Synopsis: Filenames and other information for each kind of output file, relative
to and independent of *output-directory*.
*/

define abstract class <output-file> (<object>)
   constant slot locator :: <file-locator>,
      required-init-keyword: #"file";
end class;

define class <topic-output-file> (<output-file>)
   constant slot topic :: <topic>,
      required-init-keyword: #"topic";
end class;

define class <redirect-output-file> (<output-file>)
   constant slot destination :: <output-file>,
      required-init-keyword: #"dest";
end class;

define class <toc-output-file> (<output-file>)
   constant slot tree :: <ordered-tree>,
      required-init-keyword: #"tree";
end class;

define class <copied-output-file> (<output-file>)
   constant slot origin :: <file-locator>,
      required-init-keyword: #"origin";
end class;

define class <index-output-file> (<output-file>)
end class;


/** Synopsis: Determine related topic links for each topic. */
define method topic-link-map (doc-tree :: <ordered-tree>) => (nav-map :: <table>)
   let nav-map = make(<table>);
   for (topic :: false-or(<topic>) keyed-by topic-key :: <ordered-tree-key> in doc-tree)
      unless (~topic)   // Root of doc-tree is #f.
         let next-key = topic-key.succ-key;
         let prev-key = topic-key.pred-key;
         let child-keys = topic-key.inf-key-sequence;

         let parent-keys = make(<list>);
         for (parent-key = topic-key.sup-key then parent-key.sup-key,
               while: parent-key ~= doc-tree.root-key)
            parent-keys := add!(parent-keys, parent-key)
         end for;

         let doc-tree-elem = curry(element, doc-tree);
         nav-map[topic] := make(<topic-nav>,
               parents: map-as(<simple-object-vector>, doc-tree-elem, parent-keys),
               children: map-as(<simple-object-vector>, doc-tree-elem, child-keys),
               next: next-key & element(doc-tree, next-key, default: #f),
               prev: prev-key & element(doc-tree, prev-key, default: #f));
      end unless
   end for;
   nav-map
end method;


/** Synopsis: Returns generic id for target elements in output files. */
define method target-navigation-ids (doc-tree :: <ordered-tree>)
=> (target-ids :: <table>)
   let target-ids = make(<table>);
   let topic-count = max(0, doc-tree.size - 1);
   let topic-digits = digits(topic-count);
   let topic-num = 1;
   for (topic in doc-tree)
      unless (~topic) // Root of doc-tree is #f

         // Topic ID

         target-ids[topic] := format-to-string(":Topic-%0*d", topic-digits, topic-num);
         topic-num := topic-num + 1;
         
         // Content IDs

         let section-list = make(<stretchy-vector>);
         let footnote-list = make(<stretchy-vector>);
         let line-list = make(<stretchy-vector>);

         local method add-to-list
                  (obj :: type-union(<section>, <footnote>, <ph-marker>),
                   #key setter, visited)
               => (visit-slots? :: <boolean>)
                  select (obj by instance?)
                     <section> =>
                        section-list := add!(section-list, obj);
                     <footnote> =>
                        footnote-list := add!(footnote-list, obj);
                     <ph-marker> =>
                        line-list := add!(line-list, obj);
                  end select;
                  #t
               end method,

               method process-list
                  (list :: <stretchy-vector>, name :: <string>)
               => ()
                  let width = digits(list.size);
                  for (elem keyed-by num in list)
                     target-ids[elem] := format-to-string(":%s-%0*d", name, width, num)
                  end for
               end method;
               
         visit-targets(topic, add-to-list);
         process-list(section-list, "Sect");
         process-list(footnote-list, "Foot");
         process-list(line-list, "Line");
      end unless
   end for;
   target-ids
end method;


/** Synopsis: Template names for output type. */
define generic output-templates (output :: <symbol>) => (templates :: <sequence>);


/**
Synopsis: Determines output file information.

This includes general project output files, such as the .ditamap file or
index.html, as well as topic files. Currently, there is a one-to-one mapping
between topic and file, but I leave this open to change.

Arguments:
output      - The output type; either #"html" or #"dita".
doc-tree    - The <ordered-tree> containing the documentation representation.

Values:
topic-files - A <table> keyed by <topic> containing the output file information
              for that topic.
file-info   - A <sequence> containing all output file information.
*/
define generic output-file-info
   (output :: <symbol>, doc-tree :: <ordered-tree>)
=> (topic-files :: <table>, special-files :: <table>, file-info :: <sequence>);


/**
Synopsis: Generates id and href information for target elements in output files.
*/
define generic target-link-info
   (output :: <symbol>, doc-tree :: <ordered-tree>, fallback-ids :: <table>,
    topic-file-info :: <table>)
=> (target-info :: <table>);


/**
Synopsis: Creates output files in destination directory.
*/
define generic write-output-file
   (output :: <symbol>, file-info :: <output-file>,
    link-map :: <table>, link-info :: <table>, special-file-info :: <table>)
=> ();


define method write-output-file
   (output :: <symbol>, file-info :: <copied-output-file>,
    link-map :: <table>, link-info :: <table>, special-file-info :: <table>)
=> ();
   let output-locator = merge-locators(file-info.locator, *output-directory*);
   with-file-error-handlers (default-locator: file-info.origin)
      copy-file(file-info.origin, output-locator, if-exists: #"replace");
   end with-file-error-handlers
end method;


define method as-filename-part (string :: <string>) => (filename-part :: <string>)
   let string = string.copy-sequence;
   let bad-chars = vector(' ', '\\', '#', '?', file-system-separator());
   replace-elements!(string, rcurry(member?, bad-chars), always('_'));
   string
end method;


/** Synopsis: Digits required to display a number. */
define method digits (num :: <integer>) => (digits :: <integer>)
   if (num = 0)
      1
   else
      floor(math-log(num, base: 10)) + 1
   end if
end method;


define method text-from-template
   (template-name :: <symbol>, #key operations, variables)
=> (text :: <string>)
   let template = template-by-name(template-name);
   process-template(template, operations: operations, variables: variables)
end method;


define method output-from-template
   (template-name :: <symbol>, file-info :: <output-file>,
    #key operations, variables)
=> ()
   let content = text-from-template(template-name,
         operations: operations, variables: variables);

   let output-locator = merge-locators(file-info.locator, *output-directory*);
   with-file-error-handlers (default-locator: output-locator)
      ensure-directories-exist(output-locator);
      with-open-file (file = output-locator, direction: #"output")
         write(file, content);
      end with-open-file;
   end with-file-error-handlers;
end method;


define method xml-sanitizer (raw :: <string>) => (sanitized :: <string>)
   let sanitized = make(<stretchy-vector>);
   for (c in raw)
      select (c)
         '&' =>   sanitized := concatenate!(sanitized, "&amp;");
         '<' =>   sanitized := concatenate!(sanitized, "&lt;");
         '>' =>   sanitized := concatenate!(sanitized, "&gt;");
         '\'' =>  sanitized := concatenate!(sanitized, "&apos;");
         '"' =>   sanitized := concatenate!(sanitized, "&quot;");
         otherwise =>
            sanitized := add!(sanitized, c);
      end select;
   end for;
   as(<string>, sanitized)
end method;
