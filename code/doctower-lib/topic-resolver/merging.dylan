module: topic-resolver
synopsis: This file merges API topic fragments.


/// Synopsis: Group topics that can be merged together.
// TODO: Maybe merge implicit generic functions with their single methods?
define method group-mergeable-topics (topics :: <sequence>)
=> (grouped-topics :: <sequence>)
   let api-topics = choose(rcurry(instance?, <api-doc>), topics);
   assign-fully-qualified-names(api-topics);
   group-elements(topics, test: test-combinable);
end method;


define method test-combinable (a :: <topic>, b :: <topic>)
=> (combinable? :: <boolean>)
   #f
end method;

define method test-combinable (a :: <api-doc>, b :: <api-doc>)
=> (combinable? :: <boolean>)
   if (a == b)
      #t
   elseif (~a.fully-qualified-name | ~b.fully-qualified-name)
      #f
   elseif (a.fully-qualified-name = b.fully-qualified-name)
      a.object-class = <unbound-doc> | b.object-class = <unbound-doc>
            | a.object-class = b.object-class
   else
      #f
   end if
end method;


/**
Synopsis: Fill in fully qualified names where missing.

Arguments:
topics - A <sequence> of <api-topic>.
**/
define method assign-fully-qualified-names (api-topics :: <sequence>) => ()
   let (identified-topics, unidentified-topics) =
         partition(fully-qualified-name, api-topics);
   for (topic :: <api-doc> in unidentified-topics)
      let presentation-name = topic.title.stringify-title.standardize-title;

      // Find topics with a fully qualified name of the same type, namespace,
      // and presentation name as the current, unknown topic.
      
      local method name-in-list? (name :: <string>, list :: <sequence>)
            => (present? :: <boolean>)
               member?(name, list, test: \=)
            end method,

            method matching-topic? (possible-topic :: <api-doc>)
            => (matches? :: <boolean>)
               if (possible-topic.topic-type = topic.topic-type)
                  if (topic.canonical-namespace)
                     let possible-topic-names =
                           element(possible-topic.names-in-namespace,
                                   topic.canonical-namespace, default: #[]);
                     name-in-list?(presentation-name, possible-topic-names)
                  else
                     any?(curry(name-in-list?, presentation-name),
                          possible-topic.names-in-namespace)
                  end if
               end if
            end method;

      let matching-topics = choose(matching-topic?, identified-topics);
      
      // If there aren't any, this may not be an actual API.
      
      if (matching-topics.empty?)
         if (topic.canonical-namespace)
            api-not-found-in-namespace
                  (location: topic.canonical-namespace-source-loc,
                   topic-type: topic.topic-type.printed-topic-type,
                   api-name: presentation-name,
                   api-namespace: topic.canonical-namespace)
         else
            api-not-found-in-code
                 (location: topic.title-source-loc,
                  topic-type: topic.topic-type.printed-topic-type,
                  api-name: presentation-name)
         end if;
      
      // Otherwise, see what possible fully-qualified-names we found. If we have
      // only one, that is our man.
      
      else
         let fqns = remove-duplicates!
               (map(fully-qualified-name, matching-topics), test: \=);

         if (fqns.size = 1)
            topic.fully-qualified-name := fqns.first
         else
            let fqn-strings = map(curry(format-to-string, "\"%s\""), fqns);
            let warning-func =
                  if (instance?(topic, <module-doc>))
                     ambiguous-module-in-topics
                  else
                     ambiguous-binding-in-topics
                  end if;
            warning-func
                  (location: topic.title-source-loc,
                   qualified-names: fqn-strings.item-string-list,
                   api-name: presentation-name);
         end if;
      end if;
   end for
end method;


/**
Synopsis: Combine a series of partial authored and generated topics into one,
and perform validity checks that require both.

Specifically, this function checks the authored argument, value, and keyword
sections against the automatically-generated ones.

Arguments:
topics   - A sequence of <topic>. If there is more than one topic, then all
         topics are <api-topic> and have identical fully qualified names. If
         there is only one topic, then it may or may not be an <api-topic> and
         may or may not have a fully qualified name.
**/
define method check-and-merge-topics (topics :: <sequence>) => (topic :: <topic>)
   if (topics.size = 1)
      topics.first
   else
      // Ensure that there is no more than one user-authored topic.
      let (generated-topics, authored-topics) = partition(generated-topic?, topics);
      if (authored-topics.size > 1)
         let first-topic = authored-topics.first;
         let locs = map(source-location, authored-topics).item-string-list;
         multiple-topics-for-api(location: first-topic.source-location,
               name: stringify-title(first-topic.title), topic-locations: locs)
      end if;
      
      // Preferentially keep authored topics because they have useful source
      // locations and better ids and authored sections should override
      // corresponding generated sections. 'Merge-two-topics' keeps the first of
      // its arguments, so put authored topics first.
      let topics = concatenate(authored-topics, generated-topics);
      reduce1(merge-two-topics, topics)
   end if
end method;


define method merge-two-topics (a :: <topic>, b :: <topic>)
=> (merged :: <topic>)
   a.fixed-parent := a.fixed-parent | b.fixed-parent;
   a.parent := a.parent | b.parent;

   // Use generated title if possible.
   if (b.generated-topic? & ~b.title.empty?)
      a.title := b.title;
      a.title-source-loc := b.title-source-loc;
   end if;
   
   if (~a.id & b.id)
      a.id := b.id;
      a.id-source-loc := b.id-source-loc;
   end if;

   // If B is generated, do not take its shortdesc or content unless A has neither.
   let ignore-b-content = b.generated-topic? & (a.shortdesc | ~a.content.empty?);
   unless (ignore-b-content)
      a.shortdesc := a.shortdesc | b.shortdesc;
      if (a.content.empty?)
         a.content := b.content
      end if
   end unless;
   
   a.footnotes := concatenate!(a.footnotes, b.footnotes);
   a.related-links := concatenate!(a.related-links, b.related-links);
   a.relevant-to := concatenate!(a.relevant-to, b.relevant-to);
   a
end method;


define method merge-two-topics (a :: <catalog-topic>, b :: <catalog-topic>)
=> (merged :: <catalog-topic>)
   a.qualified-scope-name := a.qualified-scope-name | b.qualified-scope-name;
   next-method()
end method;


define method merge-two-topics (a :: <api-doc>, b :: <api-doc>)
=> (merged :: <api-doc>)
   debug-assert(~a.fully-qualified-name | ~b.fully-qualified-name |
         a.fully-qualified-name = b.fully-qualified-name,
         "Fully qualified names for %= and %= do not match");
   a.existent-api? := a.existent-api? | b.existent-api?;
   a.canonical-namespace := a.canonical-namespace | b.canonical-namespace;
   a.canonical-namespace-source-loc :=
         a.canonical-namespace-source-loc | b.canonical-namespace-source-loc;

   for (b-names keyed-by namespace in b.names-in-namespace)
      let a-names = element(a.names-in-namespace, namespace, default: #[]);
      let combined = union(a-names, b-names, test: \=);
      a.names-in-namespace[namespace] := combined;
   end for;

   a.declarations-section := a.declarations-section | b.declarations-section;
   next-method()
end method;


define method merge-two-topics (a :: <placeholder-doc>, b :: <api-doc>)
   if (instance?(b, <placeholder-doc>))
      next-method()
   else
      merge-two-topics(b, a)
   end if
end method;


define method merge-two-topics (a :: <unbound-doc>, b :: <api-doc>)
=> (merged :: <api-doc>)
   if (instance?(b, <unbound-doc>))
      next-method()
   else
      merge-two-topics(b, a)
   end if
end method;


define method merge-two-topics (a :: <library-doc>, b :: <library-doc>)
=> (merged :: <api-doc>)
   a.modules-section := a.modules-section | b.modules-section;
   next-method()
end method;

define method merge-two-topics (a :: <module-doc>, b :: <module-doc>)
=> (merged :: <api-doc>)
   a.bindings-section := a.bindings-section | b.bindings-section;
   next-method()
end method;

define method merge-two-topics (a :: <class-doc>, b :: <class-doc>)
=> (merged :: <api-doc>)
   check-authored-keywords(a, b);
   a.adjectives-section := a.adjectives-section | b.adjectives-section;
   a.keywords-section := a.keywords-section | b.keywords-section;
   a.conds-section := a.conds-section | b.conds-section;
   a.inheritables-section := a.inheritables-section | b.inheritables-section;
   a.supers-section := a.supers-section | b.supers-section;
   a.subs-section := a.subs-section | b.subs-section;
   a.funcs-on-section := a.funcs-on-section | b.funcs-on-section;
   a.funcs-returning-section := a.funcs-returning-section | b.funcs-returning-section;
   next-method()
end method;

define method merge-two-topics (a :: <variable-doc>, b :: <variable-doc>)
=> (merged :: <api-doc>)
   a.adjectives-section := a.adjectives-section | b.adjectives-section;
   a.value-section := a.value-section | b.value-section;
   next-method()
end method;

define method merge-two-topics (a :: <macro-doc>, b :: <macro-doc>)
=> (merged :: <api-doc>)
   a.syntax-section := a.syntax-section | b.syntax-section;
   a.args-section := a.args-section | b.args-section;
   a.vals-section := a.vals-section | b.vals-section;
   next-method()
end method;

define method merge-two-topics (a :: <function-doc>, b :: <function-doc>)
=> (merged :: <api-doc>)
   check-authored-arguments(a, b);
   check-authored-values(a, b);
   a.adjectives-section := a.adjectives-section | b.adjectives-section;
   a.args-section := a.args-section | b.args-section;
   a.vals-section := a.vals-section | b.vals-section;
   a.conds-section := a.conds-section | b.conds-section;
   next-method()
end method;


/// Synopsis: Warn user if known keywords are undocumented.
define method check-authored-keywords (a :: <class-doc>, b :: <class-doc>) => ()
   let (gen, auth) = pick-generated-authored-topic(a, b);
   let gen-keywords = section-parm-list(gen.keywords-section);
   let auth-keywords = section-parm-list(auth.keywords-section);
   let warning =
         method () => ()
            mismatch-in-api-keywords(location: auth-keywords.source-location,
                  qualified-name: gen.fully-qualified-name)
         end;
   check-parmlist-items(gen-keywords, auth-keywords, warning);
end method;


/// Synopsis: Warn user if known arguments are undocumented.
define method check-authored-arguments (a :: <function-doc>, b :: <function-doc>) => ()
   let (gen, auth) = pick-generated-authored-topic(a, b);
   let gen-args = section-parm-list(gen.args-section);
   let auth-args = section-parm-list(auth.args-section);
   let warning =
         method () => ()
            mismatch-in-api-arguments(location: auth-args.source-location,
                  qualified-name: gen.fully-qualified-name)
         end;
   check-parmlist-items(gen-args, auth-args, warning);
end method;


/// Synopsis: Warn user if known values are undocumented.
define method check-authored-values (a :: <function-doc>, b :: <function-doc>) => ()
   let (gen, auth) = pick-generated-authored-topic(a, b);
   let gen-vals = section-parm-list(gen.vals-section);
   let auth-vals = section-parm-list(auth.vals-section);
   let warning =
         method () => ()
            mismatch-in-api-values(location: auth-vals.source-location,
                  qualified-name: gen.fully-qualified-name)
         end;
   check-parmlist-items(gen-vals, auth-vals, warning);
end method;


define function pick-generated-authored-topic (a :: <topic>, b :: <topic>)
=> (generated :: <topic>, authored :: <topic>)
   if (a.generated-topic?)
      values(a, b)
   else
      values(b, a)
   end if
end function;


define method check-parmlist-items
   (generated :: <parm-list>, authored :: <parm-list>, warning :: <function>)
=> ()
   local method parm-name (parms :: <parm-list>, i :: <integer>) => (s :: <string>)
            parms.items[i,0].stringify-markup.standardize-parm-target
         end method;
   let gen-names = map(curry(parm-name, generated),
                       range(below: generated.items.dimensions.first));
   let auth-names = map(curry(parm-name, authored),
                        range(below: authored.items.dimensions.first));
   unless (gen-names.size = auth-names.size
         & every?(true?, map(string-equal-ic?, gen-names, auth-names)))
      warning()
   end unless
end method;


define method check-parmlist-items
   (generated == #f, authored :: <parm-list>, warning :: <function>)
=> ()
   warning()
end method;


define method check-parmlist-items (generated, authored, warning)
=> ()
end method;
