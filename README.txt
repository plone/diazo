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
selectors.

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

Installation
============

To install XDV, you should install the ``xdv`` egg. You can do that using
``easy_install``, ``pip`` or ``zc.buildout``. For example, using
``easy_install`` (ideally in a ``virtualenv``)::
    
    $ easy_install -U xdv

If using ``zc.buildout``, you can use the following ``buildout.cfg`` as a
starting point. This will ensure that the console scripts are installed,
which is important if you need to execute the XDV compiler manually::

    [buildout]
    parts =
        xdv

    [xdv]
    recipe = zc.recipe.egg
    eggs = xdv

Note that ``lxml`` is a dependency of ``xdv``, so you may need to install the
libxml2 and libxslt development packages in order for it to build. On
Debian/Ubuntu you can run::

    $ sudo apt-get install libxslt1-dev

On some operating systems, notably Mac OS X, installing a "good" ``lxml`` egg
can be problematic, due to a mismatch in the operating system versions of the
``libxml2`` and ``libxslt`` libraries that ``lxml`` uses. To get around that,
you can compile a static ``lxml`` egg using the following buildout recipe::

    [buildout]
    # lxml should be first in the parts list
    parts =
        lxml
        xdv
    
    [lxml]
    recipe = z3c.recipe.staticlxml
    egg = lxml
    libxml2-url = http://xmlsoft.org/sources/libxml2-2.7.6.tar.gz
    libxslt-url = http://xmlsoft.org/sources/libxslt-1.1.26.tar.gz
    
    [xdv]
    recipe = zc.recipe.egg
    eggs = xdv

Once installed, you should find ``xdvcompiler`` and ``xdvrun`` in your
``bin`` directory.

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
equivalent XPath selector during the pre-processing step of the compiler.
Thus, they have no performance impact.

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

In most cases, you should not care too much about the inner workings of the
XDV compiler. However, it can sometimes be useful to understand the order
in which rules are applied.

1. ``<before />`` rules are always executed first.
2. ``<drop />`` rules are executed next.
3. ``<replace />`` rules are executed next, provided no ``<drop />`` rule was
   applied to the same theme node.
4. ``<prepend />``, ``<copy />`` and ``<append />`` rules execute next,
   provided no ``<replace />`` rule was applied to the same theme node.
5. ``<after />`` rules are executed last.

Behaviour if theme or content is not matched
--------------------------------------------

If a rule does not match the theme (whether or not it matches the content),
it is silently ignored.

If a ``<replace />`` rule matches the theme, but not the content, the matched
element will be dropped in the theme::

    <replace css:theme="#header" content="#header-element" />

Here, if the element with id ``header-element`` is not found in the content,
the placeholder with id ``header`` in the theme is removed.

Similarly, the contents of a theme node matched with a ``<copy />`` rule will
be dropped if there is no matching content. Another way to think of this is
that if no content node is matched, XDV uses an empty nodeset when copying or
replacing.

If you want the placeholder to stay put in the case of a missing content node,
you can make this a conditional rule::

    <replace css:theme="#header" content="#header-element" if-content="" />

See below for more details on conditional rules.

Advanced usage
--------------

The simple rules above should suffice for most use cases. However, there are
a few more advanced tools at your disposal, should you need them.

Conditional rules
~~~~~~~~~~~~~~~~~

Sometimes, it is useful to apply a rule only if a given element appears or
does not appear in the markup. The ``if-content`` attribute can be used with
any rule to make it conditional.

``if-content`` should be set an XPath expression. You can also use
``css:if-content`` with a CSS3 expression. If the expression matches a node
in the content, the rule will be applied::

    <copy css:theme="#portlets" css:content=".portlet"/>
    <drop css:theme="#portlet-wrapper" if-content="not(//*[@class='portlet'])"/>

This will copy all elements with class ``portlet`` into the ``portlets``
element. If there are no matching elements in the content we drop the
``portlet-wrapper`` element, which is presumably superfluous.

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

If multiple rules of the same type match the same theme node but have
different ``if-content`` expressions, they will be combined as an
if..else if...else block::

    <copy theme="/html/body/h1" content="/html/body/h1/text()" if-content="/html/body/h1"/>
    <copy theme="/html/body/h1" content="//h1[@id='first-heading']/text()" if-content="//h1[@id='first-heading']"/>
    <copy theme="/html/body/h1" content="/html/head/title/text()" />

These rules all attempt to fill the text in the ``<h1 />`` inside the body.
The first rule looks for a similar ``<h1 />`` tag and uses its text. If that
doesn't match, the second rule looks for any ``<h1 />`` with id
``first-heading``, and uses its text. If that doesn't match either, the
final rule will be used as a fallback (since it has no ``if-content``),
taking the contents of the ``<title />`` tag in the head of the content
document.

Including external content
~~~~~~~~~~~~~~~~~~~~~~~~~~

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

Sometimes, the theme is almost perfect, but cannot be modified, for example
because it is being served from a remote location that you do not have access
to, or because it is shared with other applications.

XDV allows you to modify the theme using "inline" markup in the rules file.
You can think of this as a rule where the matched ``content`` is explicitly
stated in the rules file, rather than pulled from the response being styled.

For example::

    <xdv:rules
        xmlns:xdv="http://namespaces.plone.org/xdv"
        xmlns:css="http://namespaces.plone.org/xdv+css"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        >

        <xdv:append theme="/html/head">
            <style type="text/css">
                /* From the rules */
                body > h1 { color: red; }
            </style>
        </xdv:append>

    </xdv:rules>

Notice how we have placed the rules in an explicit ``xdv`` namespace, so that
we can write the "inline" HTML without a namespace prefix.

In the example above, the ``<append />`` rule will copy the ``<style />``
attribute and its contents into the ``<head />`` of the theme. Similar rules
can be constructed for ``<copy />``, ``<replace />``, ``<prepend />``, 
``<before />`` or ``<after />``.

It is even possible to insert XSLT instructions into the compiled theme in
this manner. Having declared the ``xsl`` namespace as shown above, we can do
something like this::

    <xdv:replace css:theme="#details">
        <dl id="details">
            <xsl:for-each css:select="table#details > tr">
                <dt><xsl:copy-of select="td[1]/text()"/></dt>
                <dd><xsl:copy-of select="td[2]/node()"/></dd>
            </xsl:for-each>
        </dl>
    </xdv:replace>

Note that css expressions are converted to "placeless" XPath expressions,
so ``css:select="table#details > tr"`` converts to
``select="//table[@id='details]/tr"``. This means it would not be possible to
use ``css:select="td:first-child > *"`` as you want a relative selector here.
You can, of course, just use a manual XPath in a ``select`` attribute instead.

XInclude
~~~~~~~~

You may wish to re-use elements of your rules file across multiple themes.
This is particularly useful if you have multiple variations on the same theme
used to style different pages on a particular website.

Rules files can be included using the XInclude protocol. By default, XInclude
processing is disabled (since it is a slight performance hit at compile
time), but it can be enabled in the XDV compiler using a command line option.

Inclusions use standard XInclude syntax. For example::

    <rules
        xmlns="http://namespaces.plone.org/xdv"
        xmlns:css="http://namespaces.plone.org/xdv+css"
        xmlns:xi="http://www.w3.org/2001/XInclude">
        
        <xi:include href="standard-rules.xml#xpointer(/*/node())" />
    
    </rules>

An xpointer is used so as not to pull in the outer <rules> element.

Compilation
===========

Once you have written your rules file, you need to compile it to an XSLT for
deployment. In some cases, you may have an application server that does this
on the fly, e.g. if you are using the ``collective.xdv`` package with Plone.
For deployment to a web server like Apache or nginx, however, you will need
to perform this step manually.

The easiest way to invoke the XDV compiler is via the ``xdvcompiler`` command
line script which is installed with the ``xdv`` egg. To see its help output,
do::

    $ bin/xdvcompiler --help

To run the compiler with ``rules.xml`` operating on ``theme.html``::

    $ bin/xdvcompiler rules.xml theme.html

This will print the compiled XSLT file to the standard output. You can save
it to a file instead using::

    $ bin/xdvcompiler -o theme.xsl rules.xml theme.html

The following command line options are available:

* Use ``-p`` to pretty-print the output for improved readability. There is a
  risk that this could alter rendering in the browser, though, as browsers
  are sensitive to some kinds of whitespace.
* Use ``-a`` to set an absolute prefix - see below.
* Use ``-i`` to set the default external file inclusion mode to one of
  ``document``, ``ssi`` or ``esi``.
* Use ``-e`` to specify an "extras" XSLT file to be included in the compiled
  theme. This allows you to include arbitrary XSLT instructions beyond what
  XDV creates for you.
* Use ``--trace`` to output trace logging during the compilation step. This
  can be helpful in debugging rules.
* Use ``--xinclude`` to process XInclude instructions in the rules file.

Check the output of the ``--help`` option for more details.

Absolute prefix
---------------

The compiler can be passed an "absolute prefix". This is a string that will be
prefixed to any *relative* URL referenced an image, link or stylesheet in the
theme HTML file, before the theme is passed to the compiler. This allows a
theme to be written so that it can be opened and views standalone on the
filesystem, even if at runtime its static resources are going to be served
from some other location.

For example, say the theme is written with relative URLs for images and
external resources, such as ``<img src="images/foo.jpg" />``. When the
compiled theme is applied to a live site, this is unlikely to work for
any URL other than a sibling of the ``images`` folder.

Let's say the theme's static resources are served from a simple web server
and made available under the directory ``/static``. In this case, we can
set an absolute prefix of ``/static``. This will modify the ``<img />`` tag
in the compiled theme so that it becomes an absolute path that will work for
any URL: ``<img src="/static/images/foo.jpg"`` />

Testing the compiled theme
--------------------------

To test the compiled theme, you can apply it to a static file representing
the content. The easiest way to do this is via the ``xdvrun`` script::

    $ bin/xdvrun theme.xsl content.html

This will print the output to the standard output. You can save it to a file
instead with::

    $ bin/xdvrun -o output.html theme.xsl content.html

For testing, you can also compile and run the theme in one go, by using the
``-r`` (rules) and ``-t`` (theme) arguments to ``xdvrun``::

    $ bin/xdvrun -o output.html -r rules.xml -t theme.html content.html

To see the built-in help for this command, run::
    
    $ bin/xdvrun --help

Compiling the theme in Python code
----------------------------------

You can run the XDV compiler from Python code using the following helper
function::

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
* ``absolute_prefix`` can be set an string to be used as the "absolute prefix"
  for relative URLs - see above.
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
    from xdv.compiler import compile_theme
    
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

See the `collective.xdv <http://plone.org/products/collective.xdv>`_
documentation for details.

Nginx
-----

XDV currently requires a version of Nginx with xslt html parsing support
patched in. The latest patched version may be downloaded from the `html-xslt
project page <http://code.google.com/p/html-xslt/>`_.

When building Nginx, make sure to enable the xslt module::

    $ ./configure --with-http_xslt_module

If libxml2 or libxslt are installed in a non-standard location you may need to
supply the ``--with-libxml2=/opt`` and ``--with-libxslt=/opt`` options. This requires that you
set an appropriate ``LD_LIBRARY_PATH`` (Linux / BSD) or ``DYLD_LIBRARY_PATH`` (Mac OS
X) environment variable when running Nginx.

For theming a static site, enable the xsl transform as follows::

    location / {
        xslt_stylesheet /path/to/compiled-theme.xsl;
        xslt_html_parser on;
        xslt_types text/html;
    }

Nginx may also be configured as a transforming proxy server::

    location / {
        xslt_stylesheet /path/to/compiled-theme.xsl;
        xslt_html_parser on;
        xslt_types text/html;
        rewrite ^(.*)$ /VirtualHostBase/http/localhost/Plone/VirtualHostRoot$1 break;
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-XDV "true";
        proxy_set_header Accept-Encoding "";
    }

Removing the Accept-Encoding header is sometimes necessary to prevent the
backend server compressing the response (and preventing transformation). The
response may be compressed in Nginx by setting ``gzip on;`` - see the `gzip
module documentation <http://wiki.nginx.org/NginxHttpGzipModule>`_ for
details. In this example an X-XDV header was set so the backend server may
choose to serve different different CSS resources.

Including external content
~~~~~~~~~~~~~~~~~~~~~~~~~~

As an event based server, it is not practical to add ``document()`` support to
the Nginx XSLT module for in-transform inclusion. Instead, external content is
included through SSI in a subrequest.

Example nginx.conf::

    worker_processes  1;
    events {
        worker_connections  1024;
    }
    http {
        include mime.types;
        gzip on;
        server {
            listen 80;
            server_name localhost;
            root html;

            # Decide if we need to filter
            if ($args ~ "^(.*);filter_xpath=(.*)$") {
                set $newargs $1;
                set $filter_xpath $2;
                # rewrite args to avoid looping
                rewrite    ^(.*)$    /_include$1?$newargs?;
            }

            location @include500 { return 500; }
            location @include404 { return 404; }

            location ^~ /_include {
                # Restrict _include (but not ?;filter_xpath=) to subrequests
                internal;
                error_page 404 = @include404;
                # Cache page fragments in Varnish for 1h when using ESI mode
                expires 1h;
                # Proxy
                rewrite    ^/_include(.*)$    $1    break;
                proxy_pass http://127.0.0.1:80;
                # Protect against infinite loops
                proxy_set_header X-Loop 1$http_X_Loop; # unary count
                proxy_set_header Accept-Encoding "";
                error_page 500 = @include500;
                if ($http_X_Loop ~ "11111") {
                    return 500;
                }
                # Filter by xpath
                xslt_stylesheet filter.xsl
                    xpath=$filter_xpath
                    ;
                xslt_html_parser on;
                xslt_types text/html;
            }

            location / {
                xslt_stylesheet theme.xsl;
                xslt_html_parser on;
                xslt_types text/html;
                ssi on; # Not required in ESI mode
            }
        }
    }

In this example the subrequest is set to loop back on itself, so the include
is taken from a themed page. ``filter.xsl`` (in the lib/xdv directory) and
``theme.xsl`` should both be placed in the same directory as ``nginx.conf``.

An example buildout is available in ``nginx.cfg``.

Varnish
-------

To enable ESI in Varnish simply add the following to your VCL file::

    sub vcl_fetch {
        if (obj.http.Content-Type ~ "text/html") {
            esi;
        }
    }

An example buildout is available in ``varnish.cfg``.

Apache
------

XDV currently requires a version of mod_transform with html parsing support
and a disabled mod_depends. The latest patched versions may be downloaded from
the `html-xslt project page <http://code.google.com/p/html-xslt/>`_.

As well as the libxml2 and libxslt development packages, you will require
libapreq2 and the Apache development pacakges::

    $ sudo apt-get install libxslt1-dev libapache2-mod-apreq2 libapreq2-dev apache2-threaded-dev

Install mod_depends then mod_transform using the standard procedure::

    $ ./configure
    $ make
    $ sudo make install

Example virtual host configuration (e.g. /etc/apache2/sites-available/default)::

    NameVirtualHost *
    LoadModule depends_module /usr/lib/apache2/modules/mod_depends.so
    LoadModule transform_module /usr/lib/apache2/modules/mod_transform.so
    <VirtualHost *>

        FilterDeclare THEME
        FilterProvider THEME XSLT resp=Content-Type $text/html

        TransformOptions +ApacheFS +HTML
        TransformSet /theme.xsl
        TransformCache /theme.xsl /etc/apache2/theme.xsl

        <LocationMatch "/">
            FilterChain THEME
        </LocationMatch>
        
    </VirtualHost>

The +ApacheFS directive enables XSLT ``document()`` inclusion.

Unfortunately it is not possible to theme error responses (such as a 404 Not
Found page) with Apache as these do not pass through the filter chain.
