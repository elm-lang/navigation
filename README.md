# Navigation

Normally when the address bar changes, the browser sends some HTTP requests to load new pages.

This library lets you capture navigation and handle it yourself. No need to kick off a request to your servers.


## Examples

Check out the `examples/` directory of this repo. The `README` there will give you more information.


## Context

You want your website to load quickly, especially if many users will be on mobile phones. You also want to send as little data as possible to users, especially if they have slow internet connections or data caps.

> For some reason, this general goal is called “Single Page Apps” or SPAs in the JavaScript world. It is odd in that the essence is that you want to manage multiple pages intelligently, and maybe “asset management” would have been clearer, but that ship has sailed.

One important trick is to use the browser cache as much as possible. Ideally, when a user navigates to a new page, they do not make *any* HTTP requests. They have it all already. In a good case, you have most of the JS code you need already, and you just ask for a tiny bit more.

Normally, browser navigation causes an HTTP request for some HTML. That HTML may then fetch some JavaScript and images and other stuff. By capturing navigation events (like this library does) you can skip that first HTTP request and figure out a way to get only the assets you are missing.


### Additional Approaches

Capturing navigation is a start, but you ultimately want a few things in addition to this library:

  - **Server-Side Rendering** &mdash; If you view is managed by JavaScript, you typically load an HTML page, and then load your JavaScript, and then the browser draws everything. Pages will load faster if you hard-code the first frame into the HTML directly. In that world, you load an HTML page, the browser draws everything, you load your JavaScript, and everything becomes interactive. Drawing is no longer blocked on the second HTTP request. This is also nice for people who have JavaScript disabled.

  - **Bundling Assets** &mdash; Each page needs a bunch of JavaScript to render. One way to do it is to put all the JS necessary for the page into a single file. With Elm, that may be 30kb to 50kb per page after minification and gzip, which is not a huge deal in many scenarios. If you have 100 pages, many of them may actually share significant sections of code. Perhaps they all share a dependency on `elm-lang/core` and `elm-lang/html`. These *dependencies* are also likely to be quite stable, even if the pages are changing, so a better strategy would be to cut your assets into smaller bundles that can be shared across pages and stay cached even as you make changes to individual pages.

This is all *possible* in JavaScript, but it is quite an ordeal. These things are not possible in Elm right now. Rather than hacking them together by accident, like in JavaScript, these capabilities will become available as part of Elm itself. They will be purposefully designed to work together well and be pleasant to use. If these are a hard requirement for your project, it is probably best to experiment with Elm in a less constrained setting until they are officially supported.