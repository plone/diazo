Introduction
============

Consider a scenario where you have a dynamic website, to which you want to
apply a theme built by a web designer. The web designer is not familiar with
the technology behind the dynamic website, and so has supplied a static HTML
wireframe of the site. This consists of an HTML file with more-or-less
semantic markup, one or more style sheets, and perhaps some other resources
like images or JavaScript files.

Using Diazo, you could apply this theme to your dynamic website as follows:

1. Identify the placeholders in the theme file that need to be replaced with
   dynamic elements. Ideally, these should be clearly identifiable, for
   example with a unique HTML ``id`` attribute.
2. Identify the corresponding markup in the dynamic website. Then write a
   "replace" or "copy" rule using Diazo's rules syntax that replaces the
   theme's static placeholder with the dynamic content.
3. Identify markup in the dynamic website that should be copied wholesale into
   the theme. CSS and JavaScript links in the ``<head />`` are often treated
   this way. Write an Diazo "append" or "prepend" rule to copy these elements
   over.
4. Identify parts of the theme and/or dynamic website that are superfluous.
   Write an Diazo "drop" rule to remove these elements.

The rules file is written using a simple XML syntax. Elements in the theme
and "content" (the dynamic website) can be identified using CSS3 or XPath
selectors.

Once you have a theme HTML file and a rules XML file, you compile these using
the Diazo compiler into a single XSLT file. You can then deploy this XSLT file
with your application. An XSLT processor (such as mod_transform in Apache)
will then transform the dynamic content from your website into the themed
content your end users see. The transformation takes place on-the-fly for
each request.

Bear in mind that:

* You never have to write, or even read, a line of XSLT (unless you want to).
* The XSLT transformation that takes place for each request is very fast.
* Static theme resources (like images, stylesheets or JavaScript files) can
  be served from a static webserver, which is normally much faster than
  serving them from a dynamic application.
* You can leave the original theme HTML untouched, which makes it easier to
  re-use for other scenarios. For example, you can stitch two unrelated
  applications together by using a single theme file with separate rules
  files. This would result in two compiled XSLT files. You could use location
  match rules or similar techniques to choose which one to invoke for a given
  request.

We will illustrate how to set up Diazo for deployment later in this guide.