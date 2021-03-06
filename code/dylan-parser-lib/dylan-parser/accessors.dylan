module: dylan-parser
synopsis: Summary of exported token accessors. Not actually used, because I don't
   want to do all the slot type specifications, but these are what they should be.

/// Synopsis: File headers.
define generic headers (token :: <interchange-file-token>)
=> (seq :: <sequence> /* of <header-token> */);

/// Synopsis: File source record.
define generic source-record (token :: <interchange-file-token>)
=> (rec :: false-or(<source-record-token>));

/// Synopsis: File header keyword.
define generic hdr-keyword (token :: <header-token>)
=> (hdr :: <string>);

/// Synopsis: File header value.
define generic hdr-value (token :: <header-token>)
=> (val :: <string>);

/// Synopsis: Definitions within a source record.
define generic definitions (token :: <source-record-token>)
=> (seq :: <sequence> /* of <definition-token> */);

/// Synopsis: Documentation outside of top-level forms.
define generic unscoped-docs (token :: <source-record-token>)
=> (seq :: <sequence> /* of <markup-content-token> */);

/// Synopsis: Documentation belonging to a particular top-level form.
define generic scoped-docs (token :: <definition-token>)
=> (seq :: <sequence> /* of <markup-content-token> */);

/// Synopsis: Adjective strings.
define generic api-modifiers (token :: <token>)
=> (seq :: <sequence> /* of <string> */);

/// Synopsis: Name of top-level form or referenced API.
define generic api-name (token :: type-union(<definition-token>, <text-name-token>))
=> (name :: <string>);

/// Synopsis: Type of API element, if present & parsable.
define generic api-type
   (token :: type-union(<constant-definer-token>, <variable-definer-token>))
=> (type :: false-or(<text-token>));

/// Synopsis: Value of API element, if present & parsable.
define generic api-value
   (token :: type-union(<constant-definer-token>, <variable-definer-token>))
=> (type :: false-or(<text-token>));

/// Synopsis: Superclass types.
define generic class-supers (token :: <class-definer-token>)
=> (seq :: <sequence> /* of <text-token> */);

/// Synopsis: Slots.
define generic class-slots (token :: <class-definer-token>)
=> (seq :: <sequence> /* of <class-slot> */);

/// Synopsis: Init-keywords.
define generic class-keywords (token :: <class-definer-token>)
=> (seq :: <sequence> /* of <class-keyword> */);

/// Synopsis: Function arguments.
define generic func-params
   (token :: type-union(<generic-definer-token>, <method-definer-token>,
                        <function-definer-token>))
=> (seq :: <sequence> /* of <func-argument> */);

/// Synopsis: Function values.
define generic func-values
   (token :: type-union(<generic-definer-token>, <method-definer-token>,
                        <function-definer-token>))
=> (seq :: <sequence> /* of <func-value> */);

/// Synopsis: Generic function options.
define generic func-options (token :: <generic-definer-token>)
=> (seq :: <sequence> /* of <property-token> */);

/// Synopsis: Class slot modifiers (constant, each-subclass, etc.).
define generic slot-modifiers (slot :: <class-slot>)
=> (seq :: <sequence> /* of <string> */);

/// Synopsis: Class slot getter name.
define generic slot-name (slot :: <class-slot>)
=> (name :: <string>);

/// Synopsis: Class slot type, if specified & parsable.
define generic slot-type (slot :: <class-slot>)
=> (type :: false-or(<text-token>));

/// Synopsis: Class slot initializer (expression or function), if specified & parsable.
define generic slot-init (slot :: <class-slot>)
=> (init :: false-or(<text-token>));

/// Synopsis: Class slot setter name, or #f if no setter.
define generic slot-setter (slot :: <class-slot>)
=> (setter :: false-or(<string>));

/// Synopsis: Class slot documentation.
define generic slot-doc (slot :: <class-slot>)
=> (doc :: false-or(<markup-content-token>));

/// Synopsis: Returns whether class init keyword is required.
define generic keyword-required? (init-key :: <class-keyword>)
=> (req? :: <boolean>);

/// Synopsis: Class init keyword symbol.
define generic keyword-name (init-key :: <class-keyword>)
=> (name :: <string>);

/// Synopsis: Returns the slot name corresponding to a class init keyword, if any.
define generic keyword-slot-name (init-key :: <class-keyword>)
=> (slot-name :: false-or(<string>));

/// Synopsis: Class init keyword type specification, if parsable & present.
define generic keyword-type (init-key :: <class-keyword>)
=> (type :: false-or(<text-token>));

/// Synopsis: Class init keyword default value, if present & parsable.
define generic keyword-init (init-key :: <class-keyword>)
=> (init :: false-or(<text-token>));

/// Synopsis: Class init keyword documentation.
define generic keyword-doc (init-key :: <class-keyword>)
=> (doc :: false-or(<markup-content-token>));

/// Synopsis: Function parameter/value documentation.
define generic param-doc (param :: <func-param>)
=> (doc :: false-or(<markup-content-token>));

/// Synopsis: Function parameter/value name, or keyword parameter symbol.
define generic param-name (param :: <func-param>)
=> (name :: <string>);

/// Synopsis: Function parameter/value type, if parseable & present.
define generic param-type
   (param :: type-union(<required-typed-argument>, <keyword-argument>, <func-value>))
=> (type :: false-or(<text-token>));

/// Synopsis: Function parameter singleton specializer instance, if parsable.
define generic param-instance (param :: <required-singleton-argument>)
=> (inst :: false-or(<text-token>));

/// Synopsis: Function keyword parameter default value, if present & parsable.
define generic param-default (param :: <keyword-argument>)
=> (def :: false-or(<text-token>));

/// Synopsis: Library/module clauses.
define generic namespace-clauses
   (token :: type-union(<library-definer-token>, <module-definer-token>))
=> (clauses :: <sequence> /* of <use-clause-token>, <export-clause-token>, <create-clause-token> */);

define generic export-names (token :: <export-clause-token>)
=> (names :: <sequence> /* of <string> */);

define generic create-names (token :: <create-clause-token>)
=> (names :: <sequence> /* of <string> */);

define generic use-name (token :: <use-clause-token>)
=> (name :: <string>);

define generic use-imports (token :: <use-clause-token>)
=> (renamings :: type-union(singleton(#f), singleton(#"all"),
                            <sequence> /* of <renaming-token> */));

define generic use-exclusions (token :: <use-clause-token>)
=> (names :: false-or(<sequence> /* of <string> */));

define generic use-prefix (token :: <use-clause-token>)
=> (text :: false-or(<string>));

define generic use-renamings (token :: <use-clause-token>)
=> (renamings :: false-or(<sequence> /* of <renaming-token> */));

define generic use-exports (token :: <use-clause-token>)
=> (names :: type-union(singleton(#f), singleton(#"all"),
                        <sequence> /* of <string> */));

define generic import-name (token :: <renaming-token>)
=> (name :: <string>);

define generic local-name (token :: <renaming-token>)
=> (name :: false-or(<string>));

define generic domain-types (token :: <domain-definer-token>)
=> (types :: <sequence> /* of <text-token> */);

define generic main-rule-set (token :: <macro-definer-token>)
=> (rules :: <sequence> /* of main rule set */);

define generic source-text (token :: <text-token>)
=> (text :: <sequence> /* of <character> or <text-name-token> */);

define generic prop-name (token :: <property-token>)
=> (text :: <string>);

define generic prop-value (token :: <property-token>)
=> (text :: <text-token>);
