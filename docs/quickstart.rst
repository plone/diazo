Quickstart
==========

There are several ways to use Diazo:

* If you want to theme `Plone`_, you should use `plone.app.theming`_
* If you want to theme a Python WSGI application, you can use the WSGI
  middleware component described here and in more detail in :doc:`deployment`.
* If you want to theme just about anything, you can deploy a compiled theme to
  `nginx`_ or another web server

To test Diazo, however, the easiest way is to set up a simple proxy. The idea
is to run a local webserver that applies the Diazo theme to a response coming
from an existing website, either locally or somewhere on the internet.

To set up the proxy, we will use `Buildout`_.

1. Create a directory for the buildout::

    $ mkdir diazo-test

2. Download the latest Buildout `bootstrap.py`_ and put it in this directory::

    $ cd diazo-test
    $ wget http://downloads.buildout.org/2/bootstrap.py

3. Create a ``buildout.cfg`` in this directory with the following contents.
   Please read the inline comments and adjust your copy as necessary::

    [buildout]
    versions = versions

    # Uncomment the `lxml` line if you are on OS X or want to compile your
    # own lxml binary egg on Linux. This will not work on Windows.

    parts =
    #   lxml
        diazo

    [diazo]
    recipe = zc.recipe.egg
    eggs =
        diazo [wsgi]
        gearbox
        rutter
        webobentrypoints

    [lxml]
    recipe = z3c.recipe.staticlxml
    egg = lxml

    [versions]
    # Lastest versions as of 2015-04-24
    PasteDeploy = 1.5.2
    Tempita = 0.5.2
    WebOb = 1.4
    argparse = 1.3.0
    cliff = 1.12.0
    cmd2 = 0.6.8
    diazo = 1.1.1
    experimental.cssselect = 0.3
    future = 0.14.3
    gearbox = 0.0.7
    lxml = 3.4.3
    prettytable = 0.7.2
    pyparsing = 2.0.3
    repoze.xmliter = 0.6
    rutter = 0.2
    setuptools = 15.1
    six = 1.9.0
    stevedore = 1.4.0
    webobentrypoints = 0.1.0
    zc.buildout = 2.3.1
    zc.recipe.egg = 2.0.1

4. Bootstrap the buildout (this is only required once)::

    $ python bootstrap.py

   Note: You should use a Python binary version 2.6 or above. Python 3 is
   currently untested and may not work.

5. Run the buildout (this is required each time you change ``buildout.cfg``)::

    $ bin/buildout

   You should now have the binaries ``bin/paster``, ``bin/diazocompiler``,
   ``bin/diazorun`` and maybe a few others.

6. Place the theme in a directory. The theme is a static HTML design, usually
   with placeholder content and images, stylesheets and JavaScript resources
   included via relative links. You would normally be able to test the theme
   by opening it from the filesystem.

   For the purposes of this quick-start guide, we'll create a very simple
   theme::

    $ mkdir theme

   In the ``theme`` directory, we place a ``theme.html``::

    <html>
        <head>
            <title>My own Diazo</title>
            <link rel="stylesheet" href="./theme.css" />
        </head>
        <body>
            <h1 id="title">My own Diazo home page</h1>
            <div id="content">
                <!-- Placeholder -->
                Lorem ipsum ...
            </div>
        </body>
    </html>

   We also create ``theme.css``::

    h1 {
        font-size: 18pt;
        font-weight: bold;
    }

    .headerlink {
        color: #DDDDDD;
        font-size: 80%;
        text-decoration: none;
        vertical-align: top;
    }

    .align-right {
        float: right;
        margin: 0 10px;
        border: dotted #ddd 1px;
    }

7. Create the rules file. The rules file contains the Diazo directives that
   merge the content (the thing we are applying the theme to) into the theme,
   replacing placeholders with real content.

   For this example, we'll theme diazo.org, copying in the ``.content``
   area and dropping the indices and tables.

   We create ``rules.xml`` at the top level (next to ``buildout.cfg``)::

    <rules
        xmlns="http://namespaces.plone.org/diazo"
        xmlns:css="http://namespaces.plone.org/diazo/css"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

        <theme href="theme/theme.html" />

        <drop css:content="#indices-and-tables" />
        <replace css:theme-children="#content" css:content-children=".content" />

    </rules>

  See :doc:`basic` for details about the rules syntax.

   **Hint:** Use tools like Firefox's Firebug or Chrome's Developer Tools to
   inspect the theme and content pages, looking for suitable ids and classes
   to build the rules from.

8. Create the configuration file for the proxy server. This uses the Paste
   Deploy toolset to set up a WSGI application.

   At the top level (next to ``buildout.cfg``), we create ``proxy.ini``::

    [server:main]
    use = egg:gearbox#wsgiref
    host = 0.0.0.0
    port = 5000

    [composite:main]
    use = egg:rutter#urlmap
    /static = static
    / = default

    # Serve the theme from disk from /static (as set up in [composite:main])
    [app:static]
    use = egg:webobentrypoints#staticdir
    path = %(here)s/theme

    # Serve the Diazo-transformed content everywhere else
    [pipeline:default]
    pipeline = theme
               content

    # Reference the rules file and the prefix applied to relative links
    # (e.g. the stylesheet). We turn on debug mode so that the theme is
    # re-built on each request, making it easy to experiment.

    [filter:theme]
    use = egg:diazo
    rules = %(here)s/rules.xml
    prefix = /static
    debug = true

    # Proxy the diazo docs hosted at http://docs.plone.org as content
    # not using http://docs.diazo.org since there's a redirect in place
    [app:content]
    use = egg:webobentrypoints#proxy
    address = http://docs.plone.org/external/diazo/docs/index.html
    suppress_http_headers = accept-encoding

9. Run the proxy::

    $ bin/gearbox serve --reload -c proxy.ini

10. Test, by opening up ``http://localhost:5000/`` in your favourite web
    browser.

.. _Plone: http://plone.org
.. _plone.app.theming: http://pypi.python.org/pypi/plone.app.theming
.. _nginx: http://wiki.nginx.org
.. _Buildout: http://www.buildout.org
.. _bootstrap.py: http://downloads.buildout.org/2/bootstrap.py
