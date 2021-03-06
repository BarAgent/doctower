module: dylan-rep
synopsis: Representation of Dylan source names and code fragments, and general
          API objects.


//
// API objects
//


/// Subclasses are partitioned into <definition>, <implicit/explicit-defn>,
/// <slot>, <init-arg>, <param>, and <value>.
define abstract class <api-object> (<source-location-mixin>)
end class;


/// Synopsis: A mixin class for API objects that can be documented.
///
/// - All <definition>, <init-arg>, <param>, and <value> instances are
///   documentable, though the latter three do not allow full markup.
///
/// - <Implicit/explicit-defn> instances are not documentable, except for
///   instances of <implicit-generic-defn>. This exception allows methods 
///   to be documented independently of their generic.
///
/// - <Slot> is not documentable since we only keep them in a simple list for
///   "inherited slot" clauses. Any markup goes to the corresponding getter,
///   setter, or initialization argument.
define abstract class <documentable-api-object> (<api-object>)
   /// Sequence of <markup-content-token>.
   slot markup-tokens :: <sequence> = make(<stretchy-vector>), 
      init-keyword: #"markup";
end class;


/// Synopsis: Get all markup tokens from one or more API objects.
define method all-markup-tokens (items :: type-union(<sequence>, <api-object>))
=> (tokens :: <sequence>)
   let tokens = make(<stretchy-vector>);
   visit-api-markup-tokens(items,
         method (doc :: <documentable-api-object>, #key, #all-keys)
         => (do-slots? :: <boolean>)
            tokens := concatenate!(tokens, doc.markup-tokens);
            #t
         end);
   tokens
end method;


//
// Scoped names
//


define abstract class <source-name> (<source-location-mixin>)
   constant virtual slot local-name :: <string>;
end class;


define class <library-name> (<source-name>)
   constant slot library-name :: <string>, required-init-keyword: #"library";
end class;


define class <module-name> (<source-name>)
   constant slot library-name :: <string>, init-keyword: #"library";
   constant slot module-name :: <string>, required-init-keyword: #"module";
   keyword #"within", type: <library-name>;
end class;


define class <binding-name> (<source-name>)   
   constant slot library-name :: <string>, init-keyword: #"library";
   constant slot module-name :: <string>, init-keyword: #"module";
   constant slot binding-name :: <string>, required-init-keyword: #"binding";
   keyword #"within", type: <module-name>;
end class;


/// This method ensures the 'module' init argument is supplied and handles the
/// 'within' init argument. Using 'make' to ensure the presence of the 'module'
/// argument for <module-name> itself and to supply defaults from the 'within'
/// argument before slot initialization.
define method make
   (cls == <module-name>, #rest keys,
    #key module :: <string>, within :: false-or(<library-name>) = #f)
=> (inst :: <module-name>)
   if (within)
      apply(next-method, cls, within:, #f, module:, module,
            library:, within.library-name, keys)
   else
      next-method()
   end if;
end method;


/// This method ensures the 'binding' init argument is supplied and handles the
/// 'within' init argument. Using 'make' to ensure the presence of the 'binding'
/// argument for <binding-name> itself and to supply defaults from the 'within'
/// argument before slot initialization.
define method make
   (cls == <binding-name>, #rest keys,
    #key binding :: <string>, within :: false-or(<module-name>) = #f)
=> (inst :: <binding-name>)
   if (within)
      apply(next-method, cls, within:, #f, binding:, binding,
            module:, within.module-name, library:, within.library-name, keys)
   else
      next-method()
   end if;
end method;


define inline method local-name (source-name :: <library-name>) => (name :: <string>)
   source-name.library-name
end method;

define inline method local-name (source-name :: <module-name>) => (name :: <string>)
   source-name.module-name
end method;

define inline method local-name (source-name :: <binding-name>) => (name :: <string>)
   source-name.binding-name
end method;


define method enclosing-name (bind :: <binding-name>) => (mod :: <module-name>)
   make(<module-name>, library: bind.library-name, module: bind.module-name,
        source-location: bind.source-location);
end method;

define method enclosing-name (mod :: <module-name>) => (lib :: <library-name>)
   make(<library-name>, library: mod.library-name,
        source-location: mod.source-location);
end method;

define method enclosing-name (lib :: <library-name>) => (false :: singleton(#f))
   #f
end method;


define method \= (name1 :: <library-name>, name2 :: <library-name>)
=> (equal? :: <boolean>)
   name1 == name2
      | string-equal-ic?(name1.library-name, name2.library-name)
end method;

define method \= (name1 :: <module-name>, name2 :: <module-name>)
=> (equal? :: <boolean>)
   name1 == name2
      | string-equal-ic?(name1.library-name, name2.library-name)
      & string-equal-ic?(name1.module-name, name2.module-name)
end method;

define method \= (name1 :: <binding-name>, name2 :: <binding-name>)
=> (equal? :: <boolean>)
   name1 == name2
      | string-equal-ic?(name1.library-name, name2.library-name)
      & string-equal-ic?(name1.module-name, name2.module-name)
      & string-equal-ic?(name1.binding-name, name2.binding-name)
end method;


define constant $ranked-name-types
      = vector(<binding-name>, <module-name>, <library-name>);

define method \< (n1 :: <source-name>, n2 :: <source-name>)
=> (n1-first? :: <boolean>)
   unless (n1 == n2)
      let less-than? = case-insensitive-less?;
      let equal-to? = string-equal-ic?;
      let rank1 = find-key($ranked-name-types, curry(instance?, n1));
      let rank2 = find-key($ranked-name-types, curry(instance?, n2));
      case
         rank1 > rank2 => #t;
         rank1 < rank2 => #f;
         otherwise =>
            let has-module? = rank1 <= 1;
            let has-binding? = rank1 = 0;
            if (less-than?(n1.library-name, n2.library-name))
               #t
            elseif (has-module? & equal-to?(n1.library-name, n2.library-name))
               if (less-than?(n1.module-name, n2.module-name))
                  #t
               elseif (has-binding? & equal-to?(n1.module-name, n2.module-name))
                  if (less-than?(n1.binding-name, n2.binding-name))
                     #t
                  end if
               end if
            end if;
      end case
   end unless
end method;


define method equal-hash (source-name :: <library-name>, state :: <hash-state>)
=> (hash :: <integer>, state :: <hash-state>)
   case-insensitive-string-hash(source-name.library-name, state)
end method;

define method equal-hash (source-name :: <module-name>, state :: <hash-state>)
=> (hash :: <integer>, state :: <hash-state>)
   values-hash(case-insensitive-string-hash, state,
         source-name.library-name, source-name.module-name)
end method;

define method equal-hash (source-name :: <binding-name>, state :: <hash-state>)
=> (hash :: <integer>, state :: <hash-state>)
   values-hash(case-insensitive-string-hash, state,
         source-name.library-name, source-name.module-name, source-name.binding-name)
end method;


//
// Fragments
//


/// Synopsis: A fragment of source code.
define class <fragment> (<source-location-mixin>)
   /// Sequence of <character> and <source-name>.
   slot source-text :: <sequence>, required-init-keyword: #"text";
end class;


/// Synopsis: An constant expression, computed once during compilation or
/// program setup.
define class <computed-constant> (<fragment>)
end class;


/// Synopsis: A type expression.
define class <type-fragment> (<computed-constant>)
end class;


/// Synopsis: A type expression referring to a singleton type, either of the
/// "a == x" or "a :: singleton(x)" variety.
define class <singleton-type-fragment> (<type-fragment>)
   constant slot singleton-expr :: <fragment>, required-init-keyword: #"expression";
end class;


/// Synopsis: An expression evaluated repeatedly as needed. For example, the
/// default value of a keyword parameter.
define class <code-fragment> (<fragment>)
end class;


/// Synopsis: Returns true if a fragment is a simple <source-name>.
define method simple-name? (frag :: <fragment>) => (name? :: <boolean>)
   frag.source-text.size = 1 & instance?(frag.source-text.first, <source-name>)
end method;


/// Synopsis: Choose <source-name> elements from the 'source-text' of a
/// <fragment>.
define method fragment-names (frag :: <fragment>) => (names :: <sequence>)
   choose(rcurry(instance?, <source-name>), frag.source-text)
end method;


/// Synopsis: Return the <source-name> elements from a collection of <fragment>
/// where the name is the whole of the fragment.
define method simple-names (fragments :: <sequence>) => (names :: <sequence>)
   let simple-frags = choose(simple-name?, fragments);
   map(compose(first, fragment-names), simple-frags)
end method;


/// Fragments are equal when they are of the same kind and contents.
define method \= (frag1 :: <fragment>, frag2 :: <fragment>)
=> (equal? :: <boolean>)
   (frag1.object-class = frag2.object-class) & (frag1.source-text = frag2.source-text)
end method;
