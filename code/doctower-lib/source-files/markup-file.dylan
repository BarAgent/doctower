module: source-files
synopsis: Calls parser for files containing nothing but markup.


define method topics-from-markup-files (locator-seq :: <sequence>)
=> (topic-seq :: <sequence>)
   let per-file-topics = map(topics-from-markup-file, locator-seq);
   reduce(concatenate!, make(<stretchy-vector>), per-file-topics)
end method;


define method topics-from-markup-file (locator :: <file-locator>)
=> (topics :: <sequence>)
   // Read and parse file.
   let token = parse-markup-file(locator);

   // Generate authored topics and placeholders.
   topics-from-markup(token, #f);
end method;


define method parse-markup-file (locator :: <file-locator>)
=> (token :: <markup-content-token>)
   verbose-log("Parsing %s", locator);
   with-open-file (file = locator)
      let text = file.canonical-text-stream;
      block ()
         parse-markup(text, text.line-col-position-func, locator);
      cleanup
         text.close;
      end block;
   end with-open-file
end method;
