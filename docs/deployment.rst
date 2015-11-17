Deployment
==========

Before it can be used, the deployed theme needs to be deployed to a proxying
web server which can apply the XSLT to the response coming back from another
web application.

In theory, any XSLT processor will do. In practice, however, most websites
do not produce 100% well-formed XML (i.e. they do not conform to the XHTML
"strict" doctype). For this reason, it is normally necessary to use an XSLT
processor that will parse the content using a more lenient parser with some
knowledge of HTML. libxml2, the most popular XML processing library on Linux
and similar operating systems, contains such a parser.

Plone
-----

If you are working with Plone, the easiest way to use Diazo is via the
plone.app.theming_ add-on. This provides a control panel for configuring the
Diazo rules file, theme and other options, and hooks into a transformation
chain that executes after Plone has rendered the final page to apply the Diazo
transform.

Even if you intend to deploy the compiled theme to another web server,
``plone.app.theming`` is a useful development tool: so long as Zope is in
"development mode", it will re-compile the theme on the fly, allowing you to
make changes to theme and rules on the fly. It also provides some tools for
packaging up your theme and deploying it to different sites.

WSGI
----

Diazo ships with two WSGI middleware filters that can be used to apply
the theme:

* ``XSLTMiddleware``, which can apply a compiled theme created with
  ``diazocompiler``
* ``DiazoMiddleware``, which can be used to compile a theme on the fly and
  apply it.

In most cases, you will want to use ``DiazoMiddleware``, since it will cache
the compiled theme. In fact, it uses the ``XSLTMiddleware`` internally.

See :doc:`quickstart` for an example of how to set up a WSGI pipeline using
the ``DiazoMiddleware`` filter, which is exposed to Paste Deploy as
``egg:diazo``. You can use ``egg:diazo#xslt`` for the XSLT filter.

The following options can be passed to ``XSLTMiddleware``:

``filename``
    A filename from which to read the XSLT file
``tree``
    A pre-parsed lxml tree representing the XSLT file

``filename`` and ``tree`` are mutually exclusive. One is required.

``read_network``
    Set this to True to allow resolving resources from the network. Defaults
    to False.
``update_content_length``
    Can be set to False to avoid calculating an updated ``Content-Length``
    header when applying the transformation. This is only a good idea if some
    middleware higher up the chain is going to set the content length instead.
    Defaults to True.
``ignored_extensions``
    Can be set to a list of filename extensions for which the transformation
    should never be applied. Defaults to a list of common file extensions for
    images and binary files.
``environ_param_map``
    Can be set to a dict of ``environ`` keys to parameter names. The
    corresponding values in the WSGI ``environ`` will then be sent to the
    transformation as parameters with the given names.

Additional arguments will be passed to the transformation as parameters. When
using Paste Deploy, they will always be passed as strings.

The following options can be passed to ``DiazoMiddleware``:

``rules``
    Path to the rules file
``theme``
    Path to the theme, if not specified using a ``<theme />`` directive in
    the rules file. May also be a URL to a theme served over the network.
``debug``
    If set to True, the theme will be recompiled on every request, allowing
    changes to the rules to be made on the fly. Defaults to False.
``prefix``
    Can be set to a string that will be prefixed to any *relative* URL
    referenced in an image, link or stylesheet in the theme HTML file before
    the theme is passed to the compiler.

    This allows a theme to be written so that it can be opened and views
    standalone on the filesystem, even if at runtime its static resources are
    going to be served from some other location. For example, an
    ``<img src="images/foo.jpg" />`` can be turned into
    ``<img src="/static/images/foo.jpg" />`` with a ``prefix`` of "/static".
``includemode``
    Can be set to 'document', 'esi' or 'ssi' to change the way in which
    includes are processed
``read_network``
    Set this to True to allow resolving resources from the network. Defaults
    to False.
``update_content_length``
    Can be set to False to avoid calculating an updated ``Content-Length``
    header when applying the transformation. This is only a good idea if some
    middleware higher up the chain is going to set the content length instead.
    Defaults to True.
``ignored_extensions``
    Can be set to a list of filename extensions for which the transformation
    should never be applied. Defaults to a list of common file extensions for
    images and binary files.
``environ_param_map``
    Can be set to a dict of ``environ`` keys to parameter names. The
    corresponding values in the WSGI ``environ`` will then be sent to the
    transformation as parameters with the given names.

When using ``DiazoMiddleware``, the following keys will be added to the
WSGI ``environ``:

``diazo.rules``
    The path to the rules file.
``diazo.absolute_prefix``
    The absolute prefix as set with the ``prefix`` argument
``diazo.path``
    The path portion of the inbound request, which will be mapped to the
    ``$path`` rules variable and so enables ``if-path`` expressions.
``diazo.query_string``
    The query string of the inbound request, which will be
    available in the rules file as the variable ``$query_string``.
``diazo.host``
    The inbound hostname, which will be available in the rules file as the
    variable ``$host``.
``diazo.scheme``
    The request scheme (usually ``http`` or ``https``), which will be
    available in the rules file as the variable ``$scheme``.

Nginx
-----

To deploy an Diazo theme to the Nginx_ web server, you
will need to compile Nginx with a special version of the XSLT module that
can (optionally) use the HTML parser from libxml2.

If you expect the source content to be xhtml well-formed and valid, then you
should be able to avoid the ``xslt_html_parser on;`` directive. You can 
achieve this if you generate the source content.

Otherwise, if you expect non-xhtml compliant html, you need to compile Nginx 
from source. At the time of this writing, the html-xslt_ project proposes 
full Nginx sources for Nginx 0.7 and 0.8, whereas Nginx is now 1.6 and 1.7. 
Here is an alternative `patch
<https://github.com/jcu-eresearch/nginx-custom-build/blob/master/nginx-xslt-html-parser.patch>`_
you should be able to apply to any Nginx source code with the command-line
``patch src/http/modules/ngx_http_xslt_filter_module.c nginx-xslt-html-parser.patch``.

In the future, the necessary patches to enable HTML mode parsing will
hopefully be part of the standard Nginx distribution. There also is a
`Nginx ticket <http://trac.nginx.org/nginx/ticket/609>`_ asking for the 
xslt_html_parser in the http_xslt_module.

Using a properly patched Nginx, you can configure it with XSLT support like
so::

    $ ./configure --with-http_xslt_module

If you are using zc.buildout and would like to build Nginx, you can start
with the following example::

    [buildout]
    parts =
        ...
        Nginx

    ...

    [Nginx]
    recipe = zc.recipe.cmmi
    url = http://html-xslt.googlecode.com/files/Nginx-0.7.67-html-xslt-4.tar.gz
    extra_options =
        --conf-path=${buildout:directory}/etc/Nginx.conf
        --sbin-path=${buildout:directory}/bin
        --error-log-path=${buildout:directory}/var/log/Nginx-error.log
        --http-log-path=${buildout:directory}/var/log/Nginx-access.log
        --pid-path=${buildout:directory}/var/Nginx.pid
        --lock-path=${buildout:directory}/var/Nginx.lock
        --with-http_stub_status_module
        --with-http_xslt_module

If libxml2 or libxslt are installed in a non-standard location you may need to
supply the ``--with-libxml2=<path>`` and ``--with-libxslt=<path>`` options.
This requires that you set an appropriate ``LD_LIBRARY_PATH`` (Linux / BSD) or
``DYLD_LIBRARY_PATH`` (Mac OS X) environment variable when running Nginx.

For theming a static site, enable the XSLT transform in the Nginx
configuration as follows::

    location / {
        xslt_stylesheet /path/to/compiled-theme.xsl
            path='$uri'
            ;
        xslt_html_parser on;
        xslt_types text/html;
    }

Notice how we pass the ``path`` parameter, which will enable ``if-path``
expressions to work. It is possible to pass additional parameters to use in
an ``if`` condition, provided the compiled theme is aware of these. See the
previous section about the compiler for more details.

Nginx may also be configured as a transforming proxy server::

    location / {
        xslt_stylesheet /path/to/compiled-theme.xsl
            path='$uri'
            ;
        xslt_html_parser on;
        xslt_types text/html;
        rewrite ^(.*)$ /VirtualHostBase/http/localhost/Plone/VirtualHostRoot$1 break;
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Diazo "true";
        proxy_set_header Accept-Encoding "";
    }

Removing the Accept-Encoding header is sometimes necessary to prevent the
backend server compressing the response (and preventing transformation). The
response may be compressed in Nginx by setting ``gzip on;`` - see the `gzip
module documentation <https://www.nginx.com/resources/admin-guide/compression-and-decompression/>`_ for
details.

In this example an X-Diazo header was set so the backend server may choose to
serve different different CSS resources.

Including external content with SSI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As an event based server, it is not practical to add ``document()`` support to
the Nginx XSLT module for in-transform inclusion. Instead, external content is
included through SSI in a sub-request. The SSI sub-request includes a query
string parameter to indicate which parts of the resultant document to include,
called ``;filter_xpath`` - see above for a full example. The configuration
below uses this parameter to apply a filter::

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
                xslt_stylesheet theme.xsl
                    path='$uri'
                    ;
                xslt_html_parser on;
                xslt_types text/html;
                ssi on; # Not required in ESI mode
            }
        }
    }

In this example the sub-request is set to loop back on itself, so the include
is taken from a themed page. ``filter.xsl`` (in the lib/diazo directory) and
``theme.xsl`` should both be placed in the same directory as ``Nginx.conf``.

An example buildout is available in ``Nginx.cfg`` in this package.

Varnish
-------

To enable ESI in Varnish simply add the following to your VCL file::

    sub vcl_fetch {
        if (obj.http.Content-Type ~ "text/html") {
            esi;
        }
    }

An example buildout is available in ``varnish.cfg`` in the Diazo distribution.

Apache
------

Diazo requires a version of ``mod_transform`` with html parsing support.
The latest compatible version may be downloaded from the html-xslt_ project
page.

As well as the libxml2 and libxslt development packages, you will require the
appropriate Apache development package::

    $ sudo apt-get install libxslt1-dev apache2-threaded-dev

(or ``apache2-prefork-dev`` when using PHP.)

Install mod_transform using the standard procedure::

    $ ./configure
    $ make
    $ sudo make install

An example virtual host configuration is shown below::

    NameVirtualHost *
    LoadModule transform_module /usr/lib/apache2/modules/mod_transform.so
    <VirtualHost *>

        FilterDeclare THEME
        FilterProvider THEME XSLT resp=Content-Type $text/html

        TransformOptions +ApacheFS +HTML +HideParseErrors
        TransformSet /theme.xsl
        TransformCache /theme.xsl /etc/apache2/theme.xsl

        <LocationMatch "/">
            FilterChain THEME
        </LocationMatch>

    </VirtualHost>

The ``ApacheFS`` directive enables XSLT ``document()`` inclusion, though
beware that the includes documents are currently parsed using the XML rather
than HTML parser.

Unfortunately it is not possible to theme error responses (such as a 404 Not
Found page) with Apache as these do not pass through the filter chain.

As parameters are not currently supported, path expression are unavailable.

.. _plone.app.theming: http://pypi.python.org/pypi/plone.app.theming
.. _html-xslt: http://code.google.com/p/html-xslt/
