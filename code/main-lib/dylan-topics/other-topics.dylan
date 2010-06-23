module: dylan-topics
synopsis: Code to generate constant, empty binding, and macro docs.


/// Placeholder bindings cannot have topics generated from source, since they
/// aren't defined in source.
define method make-source-topics (binding :: <placeholder-binding>)
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   values(#[], #[])
end method;


/// Empty bindings cannot have user-authored documentation; they must be
/// documented as a class, etc. But if they aren't, this generates a page for
/// them.
define method make-source-topics (binding :: <empty-binding>) 
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   let generated-topic = make(<unbound-doc>, generated: #t, existent-api: #t,
         id: binding.canonical-id, title: binding.canonical-title,
         qualified-name: binding.definition-qualified-name,
         source-location: binding.source-location,
         title-id-source-location: $generated-source-location,
         qualified-name-source-location: $generated-source-location);

   let vars = table(<case-insensitive-string-table>, "unbound" => binding);
   let topics = topics-from-template(#"unbound-topic", generated-topic, vars);
   values(topics, #[]);
end method;


define method make-source-topics (binding :: <constant-binding>)
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   make-const/var-topics(binding, "const", #"constant-topic")
end method;

define method make-source-topics (binding :: <variable-binding>)
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   make-const/var-topics(binding, "var", #"variable-topic")
end method;


define method make-const/var-topics
   (binding :: type-union(<constant-binding>, <variable-binding>),
    template-var :: <string>, template-name :: <symbol>)
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   
   // Create body of generated topic.
   
   let generated-topic = make(<variable-doc>, generated: #t, existent-api: #t,
         id: binding.canonical-id, title: binding.canonical-title,
         qualified-name: binding.definition-qualified-name,
         source-location: binding.source-location,
         title-id-source-location: $generated-source-location,
         qualified-name-source-location: $generated-source-location);
   
   let vars = table(<case-insensitive-string-table>, template-var => binding);
   let topics = topics-from-template(template-name, generated-topic, vars);

   // Create authored topics.
   
   let authored-topic = make(<variable-doc>, generated: #f, existent-api: #t,
         id: binding.canonical-id, title: binding.canonical-title,
         qualified-name: binding.definition-qualified-name,
         source-location: binding.source-location,
         title-id-source-location: $generated-source-location,
         qualified-name-source-location: $generated-source-location);

   let authored-topics = make-authored-topics(binding.markup-tokens, authored-topic);
   topics := concatenate!(topics, authored-topics);

   values(topics, #[])
end method;


define method make-source-topics (binding :: <macro-binding>) 
=> (topics :: <sequence>, catalog-topics :: <sequence>)
   let generated-topic = make(<macro-doc>, generated: #t, existent-api: #t,
         id: binding.canonical-id, title: binding.canonical-title,
         qualified-name: binding.definition-qualified-name,
         source-location: binding.source-location,
         title-id-source-location: $generated-source-location,
         qualified-name-source-location: $generated-source-location);

   let vars = table(<case-insensitive-string-table>, "macro" => binding);
   let topics = topics-from-template(#"macro-topic", generated-topic, vars);
   values(topics, #[]);
end method;

