module: dylan-topics
synopsis: Entry point and overall control for dylan-topics module.


/// Syn: Quick reference for referring to definitions by name.
define constant *definitions* :: <equal-table> = make(<equal-table>);


/**
We do not generate API reference topics for invalid bindings, that is, bindings
that are only mentioned by name or only inferred to exist. This saves us a fair
amount of time.

An invalid binding may be from a foreign library, but it may also be defined by
some macro. While the author may wish to document the binding, he would only
gain a fully-qualified-name for it if we were to create a topic for it. He may
as well document it as a conceptual API reference topic, as if it were an
anonymous function. In either case, the topic would be included in the list
generated by "LIST OF" directives.

In addition to conceptual topics and API reference topics, there are catalog
topics. These are automatically-generated lists of all modules, classes, etc.,
separate from the lists included in each library and module page. They are only
included in the documentation when listed in the table of contents. If included,
they act as parents for other topics.

This function generates catalog topics and any other topics included in source
code doc comments. And, since this function is going through all the APIs
anyway, it also makes the API list file.
**/
define method topics-from-dylan (api-definitions :: <sequence>)
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   // Make <source-name> quick-reference table.
   for (api-defn :: <definition> in api-definitions)
      for (api-name :: <source-name> in api-defn.aliases)
         *definitions*[api-name] := api-defn
      end for;
   end for;
   
   // Generate topic content for definitions.
   verbose-log("Creating documentation from definitions");
   let topics = make(<stretchy-vector>);
   let catalog-topics = make(<stretchy-vector>);
   let definition-topics = make(<stretchy-vector>);
   for (api-defn in choose(should-have-topic?, api-definitions))
      block ()
         verbose-log("Documenting %s", api-defn.canonical-name);
         let (new-topics, new-catalogs) = make-source-topics(api-defn);
         topics := concatenate!(topics, new-topics);
         catalog-topics := concatenate!(catalog-topics, new-catalogs);

         when (*api-list-file*)
            let new-definition-topics
                  = choose(conjoin(generated-topic?, rcurry(instance?, <api-doc>)),
                           new-topics);
            unless (new-definition-topics.size = 0)
               definition-topics
                     := add!(definition-topics, pair(api-defn, new-definition-topics))
            end unless
         end when
      exception (restart :: <skip-error-restart>)
      end block
   end for;
   
   // Clean up.
   remove-all-keys!(*definitions*);
   
   // Generate API list.
   when (*api-list-file*)
      verbose-log("Writing fully-qualified API names to %s", *api-list-file*);
      with-open-file (api-list = *api-list-file*, direction: #"output")
         write(api-list,
            "# Each first line is the fully qualified name of a library, module, or binding.\n"
            "# Each subsequent indented line is an alternative name for the library, module,\n"
            "# or binding as declared or used in Dylan source code.\n\n");
         for (defn-topic in definition-topics)
            for (topic in defn-topic.tail)
               write-line(api-list, topic.fully-qualified-name)
            end for;
            for (alias in defn-topic.head.aliases)
               when (instance?(alias.source-location, <file-source-location>))
                  format(api-list, "\tDeclared as \"%s\" at %s\n", 
                         alias, alias.source-location)
               end when
            end for;
            api-list.new-line
         end for
      end with-open-file
   end when;

   // Generate global catalog topics.
   let new-topics = topics-from-template
         (#"all-catalog-topics", #f, make(<case-insensitive-string-table>));
   topics := concatenate!(topics, new-topics);
   catalog-topics := concatenate!(catalog-topics, new-topics);
   
   values(topics, catalog-topics)
end method;


/// Synopsis: Determine whether a definition should be documented.
define generic should-have-topic? (definition :: <definition>) => (topic? :: <boolean>);

define method should-have-topic? (binding :: <binding>) => (topic? :: <boolean>)
   binding.valid-binding?
end method;

define method should-have-topic? (namespace :: <namespace>) => (topic? :: <boolean>)
   local method in-namespace? (definition :: <definition>) => (in-namespace? :: <boolean>)
            definition.canonical-name.enclosing-name = namespace.canonical-name
         end method;
   let namespace-definitions = choose(in-namespace?, namespace.definitions.element-sequence);
   any?(should-have-topic?, namespace-definitions)
end method;


/**
Arguments:
   definition  - The API representation to generate docs for; a <definition>.
Values:
   topics         - A sequence of <topic> objects.
   catalog-topics - The subset of returned 'topics' that are catalog topics.
**/
define generic make-source-topics (definition :: <definition>)
=> (topics :: <sequence>, catalog-topics :: <sequence>);


define method make-authored-topics
   (markup-content-tokens :: <sequence>, context-topic :: false-or(<api-doc>))
=> (topics :: <sequence>)
   let topics-per-token = map(rcurry(topics-from-markup, context-topic), 
                              markup-content-tokens);
   let topics = apply(concatenate, #[], topics-per-token);

   // If several markup tokens attach to the same context topic, the context
   // topic will be duplicated. This is unnecessary, so clear out duplicates.
   topics.remove-duplicates
end method;


//
// Source location for automatically-generated topics
//


define class <generated-source-location> (<source-location>)
end class;

define constant $generated-source-location = make(<generated-source-location>);

define method print-message (o :: <generated-source-location>, s :: <stream>)
=> ()
   write(s, "automatically-generated documentation location")
end method;
