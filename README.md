# Navigation

This is a library for managing browser navigation yourself.

The core functionality is the ability to &ldquo;navigate&rdquo; to new URLs, changing the address bar of the broswer *without* the browser kicking off a request to your servers. Instead, you manage the changes yourself in Elm.

This is common in single-page apps (SPAs) where you switch between different pages without doing a full refresh. This can mean you have less network traffic and get people from page to page more quickly.


## Examples

Check out the `examples/` directory of this repo. The `README` there will give you more information.


## Terminology

The term &ldquo;routing&rdquo; is commonly used as a blanket term for anything related to managing the address bar yourself. I think this term is misleading, and probably harmful to the architecture of front-end applications.

  - **On Servers** &mdash; You are literally routing payloads to functions. Servers can make the assumption that all queries are independent. There is no state to persist. There is no concept of &ldquo;going back&rdquo; to some other URL.

  - **In Browsers** &mdash; We treat the address bar as an input (like mouse or keyboard) so we can update our app more efficiently. The whole point is that *nothing* is independent! You *can* persist state. You *can* go back.

My point is that routing on servers has an intuitive and clear meaning. You route payloads to functions. What we want in browsers overlaps only in that we are also dealing with URLs. Otherwise, the goals are entirely different. So why take a term with a clear and obvious meaning and apply it to something 95% unrelated?

Point is, I have named this library `elm-lang/navigation` to emphasize our actual goals in the browser. This library is for managing browser navigation yourself. If you want URL parsing, you can use libraries like `evancz/url-parser`. Between the terms &ldquo;managed navigation&rdquo; and &ldquo;URL parsing&rdquo; we have covered the core concepts in a clearer and more helpful way.