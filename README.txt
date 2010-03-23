=============================
XDV - XSLT Deliverance Engine
=============================

.. contents:: Contents

Introduction
============

XDV is an implementation of the Deliverance concept using pure XSLT. In short,
it is a way to apply a style/theme to a dynamic website.

Consider a scenario where you have some dynamic website, to which you want to
apply a theme built by a web designer. The web designer is not familiar with
the technology behind the dynamic website, and so has supplied a "static HTML"
version of the site. This consists of an HTML file with more-or-less semantic
markup, one or more style sheets, and perhaps some other resources like
images or JavaScript files.

Using XDV, you could apply this theme to your dynamic website as follows:

1. Identify the placeholders in the theme file that need to be replaced with
   dynamic elements. Ideally, these should be clearly identifiable, for
   example with a unique HTML ``id`` attribute.
2. Identify the corresponding markup in the dynamic website. Then write a
   "replace" or "copy" rule using XDV's rules syntax that replaces the theme's
   static placeholder with the dynamic content.
3. Identify markup in the dynamic website that should be copied wholesale into
   the theme. CSS and JavaScript links in the ``<head />`` are often treated
   this way. Write an XDV "append" or "prepend" rule to copy these elements
   over.
4. Identify parts of the theme and/or dynamic website that are superfluous.
   Write an XDV "drop" rule to remove these elements.

The rules file is written using a simple XML syntax. Elements in the theme
and "content" (the dynamic website) can be identified using CSS3 or XPath
syntax.

Once you have a theme HTML file and a rules XML file, you compile these using
the XDV compiler into a single XSLT file. You can then deploy this XSLT file
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
* You can leave the original theme HTML untouched, with makes it easier to
  re-use for other scenarios. For example, you can stitch two unrelated
  applications together by using a single theme file with separate rules
  files. This would result in two compiled XSLT files. You could use location
  match rules or similar techniques to choose which one to invoke for a given
  request.

We will illustrate how to set up XDV for deployment below.

Rules file syntax
=================

The rules file, conventionally called ``rules.xml``, is rooted in a tag
called ``<rules />``::

    <?xml version="1.0" encoding="UTF-8"?>
    <rules xmlns="http://namespaces.plone.org/xdv"
           xmlns:css="http://namespaces.plone.org/xdv+css">
           
           ...
           
    </rules>

Here we have defined two namespaces: the default namespace is used for rules
and XPath selectors. The ``css`` namespace is used for CSS3 selectors. These
are functionally equivalent. In fact, CSS selectors are replaced by the
equivalent XPath selector the pre-processing step of the compiler. Thus, they
have no performance impact.

XDV supports complex CSS3 and XPath selectors, including things like the
``nth-child`` pseudo-selector. You are advised to consult a good reference
if you are new to XPath and/or CSS3.

The following elements are allowed inside the ``<rules />`` element:

``<replace />``
---------------

Used to replace an element in the theme entirely with an element in the
content. For example::

    <replace theme="/html/head/title" content="/html/head/title"/>

The (near-)equivalent using CSS selectors would be::

    <replace css:theme="title" css:content="title"/>

The result of either is that the ``<title />`` element in the theme is
replaced with the ``<title />`` element in the (dynamic) content.

``<copy />``
------------

Used to replace the contents of a placeholder tag with a tag from the
theme. For example::

    <copy css:theme="#main" css:content="#portal-content > *" />

This would replace any placeholder content inside the element with id
``main`` in the theme with all children of the element with id
``portal-content`` in the content. The usual reason for using ``<copy />``
instead of ``<replace />``, is that the theme has CSS styles or other
behaviour attached to the target element (with id ``main`` in this case).

``<append />`` and ``<prepend />``
----------------------------------

Used to copy elements from the content into an element in the theme,
leaving existing content in place. ``<append />`` places the matched
content directly before the closing tag in the theme; append places it
directly after the opening tag. For example::

    <append theme="/html/head" content="/html/head/link" />

This will copy all ``<link />`` elements in the head of the content into
the theme.

As a special case, you can copy individual *attributes* from a content
element to an element in the theme using ``<prepend />``::

    <prepend theme="/html/body" content="/html/body/@class" />

This would copy the ``class`` attribute of the ``<body />`` element in
the content into the theme (replacing an existing attribute with the
same name if there is one).

``<before />`` and ``<after />``
--------------------------------

These are equivalent to ``<append />`` and ``<prepend />``, but place
the matched content before or after the matched theme element, rather
than immediately inside it. For example:
    
    <before css:theme="#content" css:content="#info-box" />

This would place the element with id ``info-box`` from the content
immediately before the element with id ``content`` in the theme. If we
wanted the box below the content instead, we could do::

    <after css:theme="#content" css:content="#info-box" />
    
``<drop />``
------------

Used to drop elements from the theme or the content. This is the only
element that accepts either ``theme`` or ``content`` attributes (or their
``css:`` equivalents), but not both::

    <drop css:content="#portal-content .about-box" />
    <copy css:theme="#content" css:content="#portal-content > *" />

This would copy all children of the element with id ``portal-content`` in
the theme  into the element with id ``content`` in the theme, but only
after removing any element with class ``about-box`` inside the content
element first. Similarly::

    <drop theme="/html/head/base" />

Would drop the ``<base />`` tag from the head of the theme.

Order of rule execution
-----------------------

XXX: Laurence needs to check this

In most cases, you should not care too much about the inner workings of the
XDV compiler. However, it can sometimes be useful to understand the order
in which rules are applied.

1. ``<drop />`` rules referring to the *content* are applied first. Thus,
   anything that is dropped from the content will never be matched by any
   other rule.
2. ``<before />`` rules execute next, followed by ``<after />`` rules.
3. ``<replace />`` rules execute next.
4. ``<prepend />``, ``<copy />`` and ``<append />`` rules are then executed.
5. Finally, ``<drop />`` rules referring to the *theme* are applied, meaning
   they can also match elements that have landed in the theme as a result of
   one of the above rules.

Behaviour if theme or content is not matched
--------------------------------------------

XXX: Laurence needs to check this - is it correct? Does the same rule apply
to all rules, or only to <copy /> and <replace />?

If a rule does not match the theme (whether or not it matches the content),
it is silently ignored.

If a rule matches the theme, but not the content, the matched element will
be dropped in the theme::

    <replace css:theme="#header" content="#header-element" />

If the element with id ``header-element`` is not found in the content, the
placeholder with id ``header`` in the theme is removed.

If you want the placeholder to stay put, you can make this a conditional
rule::

    <replace css:theme="#header" content="#header-element" if-content="" />

See below for more details on conditional rules.

Advanced usage
--------------

The simple rules above should suffice for most use cases. However, there are
a few more advanced tools at your disposal, should you need them.

Conditional rules
~~~~~~~~~~~~~~~~~

XXX: Laurence needs to check this

Sometimes, it is useful to apply a rule only if a given element appears or
does not appear in the markup. The ``if-content`` attribute can be used with
any rule to make it conditional.

``if-content`` should be set an XPath expression. You can also use
``css:if-content`` with a CSS3 expression. If the expression matches a node
in the content, the rule will be applied::

    <copy css:theme="#portlets" css:content=".portlet"/>
    <drop css:theme="#portlet-wrapper" if-content="not(//*[@class='portlet'])"/>

This will copy all elements with class ``portlet`` into the ``portlets``
element. If there are no matching elements in the content, the ``portlets``
element will be dropped as normal. However, we also drop the
``portlet-wrapper`` element in this case, as it is presumably superfluous.

Here is another example using CSS selectors::

    <copy css:theme="#header" css:content="#header-box > *" css:if-content="#personal-bar"/>

This will copy the children of the element with id ``header-box`` in the
content into the element with id ``header`` in the theme, so long as an
element with id ``personal-bar`` also appears somewhere in the content.

Above, we also saw the special case of an empty ``if-content`` (which also
works with an empty ``css:if-content``). This is a shortcut that means "use
the expression in the ``content`` or ``css:content``` attribute as the
condition". Hence the following two rules are equivalent::

    <copy css:theme="#header" css:content="#header-box > *" css:if-content="#header-box > *"/>
    <copy css:theme="#header" css:content="#header-box > *" css:if-content=""/>

Including external content
~~~~~~~~~~~~~~~~~~~~~~~~~~

XXX: Laurence needs to check/complete this

Normally, the ``content`` attribute of any rule selects nodes from the
response being returned by the underlying dynamic web server. However, it is
possible to include content from a different URL using the ``href`` attribute
on any rule (other than ``<drop />``). For example::

    <append css:theme="#left-column" css:content="#portlet" href="/extra.html"/>

This will resolve the URL ``/extra.html``, look for an element with id
``portlet`` and then append to to the element with id ``left-column`` in the
theme.

The inclusion can happen in one of three ways:

* Using the XSLT ``document()`` function. This is the default, but it can
  be explicitly specified by adding an attribute ``method="document"`` to the 
  rule element. Whether this is able to resolve the URL depends on how and
  where the compiled XSLT is being executed::
  
    <append css:theme="#left-column" css:content="#portlet" href="/extra.html" method="document" />
  
* Via a Server Side Include directive. This can be specified by setting the
  ``method`` attribute to ``ssi``::
  
    <append css:theme="#left-column" css:content="#portlet" href="/extra.html" method="ssi"/>

  The output will look something like this::
  
    <!--# include  virtual="/extra.html?;filter_xpath=//*[@id%20=%20'portlet']" wait="yes" -->
  
  This SSI instruction would need to be processed by a fronting web server
  such as Apache or nginx. Also note the ``;filter_xpath`` query string
  parameter. Since we are deferring resolution of the referenced document
  until SSI processing takes place (i.e. after the compiled XDV XSLT transform
  has executed), we need to ask the SSI processor to filter out elements in
  the included file that we are not interested in. This requires specific
  configuration. An example for nginx is included below.

* Via an Edge Side Includes directive. This can be specified by setting the
  ``method`` attribute to ``esi``::
  
    <append css:theme="#left-column" css:content="#portlet" href="/extra.html" method="esi"/>

  The output is similar to that for the SSI mode::

    <esi:include src="/extra.html?;filter_xpath=//*[@id%20=%20'portlet']"></esi:include>
  
  Again, the directive would need to be processed by a fronting server, such
  as Varnish. Chances are an ESI-aware cache server would not support
  arbitrary XPath filtering. If the referenced file is served by a dynamic
  web server, it may be able to inspect the ``;filter_xpath`` parameter and
  return a tailored response. Otherwise, if a server that can be made aware
  of this is placed in-between the cache server and the underlying web server,
  that server can perform the necessary filtering.

Modifying the theme on the fly
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

XXX: Laurence needs to check/complete this

Compilation
===========

XXX: Laurence needs to check/complete this - do we need a CSS pre-processing
 step?

Once you have written your rules file, you need to compile it to an XSLT for
deployment. In some cases, you may have an application server that does this
on the fly, e.g. if you are using the ``collective.xdv`` package with Plone.
For deployment to a web server like Apache or nginx, however, you will need
to perform this step manually.

Compilation uses the XSLT file ``compiler.xsl``. The easiest way to run this
is with the ``xsltproc`` command, which should come installed with
``libxslt``. You will need to install ``libxslt`` if you don't have it already.

To execute the compiler::

    $ xsltproc --nonet --html compiler.xsl theme.html > compiledtheme.xsl

This will look for a rules file called ``rules.xml`` in the current directory.
If you need to specify an alternative file, you can do::

    $ xsltproc --nonet --html --stringparam rulesuri rules.xml compiler.xsl theme.html > compiledtheme.xsl

There are various other parameters which can be specified using the
``--stringparam`` syntax:

* ``rulesuri``, which gives a URI or filename to the rules file.
* ``boilerplateurl``, which gives a URL to the ``boilerplate.xsl`` file.
  You probably don't need to override this.
* ``extraurl``, which gives a URL to an XSLT file which will be inserted into
  the compiled theme. Use this to include arbitrary XSLT instructions in the
  compiled theme.
* ``trace``, which can be set to 1 to enable debug tracing during the
  compilation step.
* ``includemode``, which can be set to one of ``document``, ``ssi`` or
  ``esi`` to specify the default inclusion method for external content when
  using the ``href`` attribute.
* ``ssiprefix``, ``ssisuffix``, which can be used to add a prefix or suffix to
  a URI generated for SSI inclusion.
* ``ssiquerysuffix``, which can be used to change the ``;filter_xpath=``
  request variable name in a URL generated for SSI inclusion.
* ``esiprefix``, ``esisuffix`` and ``esiquerysuffix``, which serve the same
  function for ESI inclusions.

Testing the compiled theme
--------------------------

To test the compiled theme, you can apply it to a static file representing
the content, e.g. with::

    $ xsltproc --nonet --html compiledtheme.xsl content.html > output.html

Open ``output.html`` to see the transformed theme.

Compiling the theme in Python code
----------------------------------

XXX: Laurence needs to check this

XDV can be used without Python, but it is primarily distributed as part of
the ``xdv`` Python package. This provides a test suite and certain utilities.
One of those utilities is a method to compile an XDV XSLT file::

    >>> from xdv.compiler import compile_theme

This method takes the following arguments:

* ``rules`` is the rules file, given either as a file name or a string with
  the file contents.
* ``theme`` is the theme file, given either as a file name or a string with
  the file contents
* ``extra`` is an optional XSLT file with XDV extensions, given as a URI
* ``css``   can be set to False to disable CSS syntax support (providing a
  moderate speed gain)
* ``xinclude`` can be set to ``True`` to enable XInclude support (at a
  moderate speed cost). If enabled, XInclude syntax can be used to split the
  rules file into multiple, re-usable fragments.
* ``absolute_prefix`` can be set to a string that will be prefixed to any
  *relative* URL referenced in an image, link or stylesheet in the theme
  HTML file before the theme is passed to the compiler. This allows a
  theme to be written so that it can be opened and views standalone on the
  filesystem, even if at runtime its static resources are going to be
  served from some other location. For example, an
  ``<img src="images/foo.jpg" />`` can be turned into 
  ``<img src="/static/images/foo.jpg" />`` with an ``absolute_prefix`` of
  "/static".
* ``update`` can be set to ``False`` to disable the automatic update support
  for the old Deliverance 0.2 namespace (for a moderate speed gain)
* ``trace`` can be set to True to enable compiler trace information
* ``includemode`` can be set to 'document', 'esi' or 'ssi' to change the way
  in which includes are processed
* ``parser`` can be set to an lxml parser instance; the default is an
  HTMLParser
* ``compiler_parser``` can be set to an lxml parser instance; the default is a
  XMLParser
* ``rules_parser`` can be set to an lxml parser instance; the default is a
  XMLParse.

The parser parameters may be used to add custom resolvers for external content
if required. See the `lxml <http://codespeak.net/lxml>`_ documentation for
details.

``compile_theme()`` returns an XSLT document in ``lxml``'s ``ElementTree``
format. To set up a transform representing the theme and rules, you can do::

    from lxml import etree
    
    extraurl = None
    absolute_prefix = "/static"
    xinclude = False
            
    rules = "rules.xml"
    theme = "theme.html"
            
    compiled_theme = compile_theme(rules, theme, extra=extraurl, 
                                   xinclude=xinclude,
                                   absolute_prefix=absolute_prefix)
            
    transform = etree.XSLT(compiled_theme)
    
You can now use this transformation::

    content = etree.parse(some_content)
    transformed = transform(content)
    
    output = etree.tostring(transformed)

Please see the ``lxml`` documentation for more details.

Deployment
==========

Plone
-----

nginx
-----

XXX: Laurence needs to check this

Varnish
-------

XXX: Laurence needs to check this

Apache
------

XXX: Laurence needs to check this

