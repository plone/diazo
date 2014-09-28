Compilation
===========

Once you have written your rules file, you need to compile it to an XSLT for
deployment. In some cases, you may have an application server that does this
on the fly, e.g. if you are using the ``plone.app.theming`` package with
Plone. For deployment to a web server like Apache or Nginx, however, you will
need to perform this step manually.

The easiest way to invoke the Diazo compiler is via the ``diazocompiler``
command line script which is installed with the ``diazo`` egg. To see its help
output, do::

    $ bin/diazocompiler --help

To run the compiler with ``rules.xml``::

    $ bin/diazocompiler rules.xml

This will print the compiled XSLT file to the standard output. You can save
it to a file instead using::

    $ bin/diazocompiler -o theme.xsl -r rules.xml

The following command line options are available:

* Use ``-t theme.html`` to supply a theme if none is specified in the rules.
* Use ``-p`` to pretty-print the output for improved readability. There is a
  risk that this could alter rendering in the browser, though, as browsers
  are sensitive to some kinds of whitespace.
* Use ``-a`` to set an absolute prefix - see below.
* Use ``-i`` to set the default external file inclusion mode to one of
  ``document``, ``ssi`` or ``esi``.
* Use ``-n`` to permit fetching resources over a network.
* Use ``--trace`` to output trace logging during the compilation step. This
  can be helpful in debugging rules.

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

Custom parameters
-----------------

Custom parameters may be passed in at runtime to enable advanced ``if``
conditions for rules and theme selection. For this to work, however, the
compiled theme needs to be aware of the possible parameters.

Use the ``-c`` / ``--custom-parameters`` option to ``diazocompiler`` and
``diazorun`` to list the parameter names that should be known to the theme.
Multiple names should be separated by spaces. For example::

    $ bin/diazocompiler -o theme.xsl -r rules.xml -c mode=test,preview

Here, the compiled theme will be aware of the parameters ``$mode`` and
``$test``. The default for ``mode`` will be the string value ``test``.

Using this ``theme.xsl``, it is now possible to pass these parameters. See
the section on Nginx deployment for more details about how to do this with
Nginx, or the next section for how to test it with ``diazorun``.

Testing the compiled theme
--------------------------

To test the compiled theme, you can apply it to a static file representing
the content. The easiest way to do this is via the ``diazorun`` script::

    $ bin/diazorun --xsl theme.xsl content.html

This will print the output to the standard output. You can save it to a file
instead with::

    $ bin/diazorun -o output.html --xsl theme.xsl content.html

For testing, you can also compile and run the theme in one go, by supplying the
``-r`` (rules) argument to ``diazorun``::

    $ bin/diazorun -o output.html -r rules.xml content.html

If you are using any custom parameters, you can specify string values for
them on the command line:

    $ bin/diazorun -o output.html -r rules.xml \
        -c mode=test,preview --parameters mode=live,preview=off \
        content.html

To see the built-in help for this command, run::

    $ bin/diazorun --help

Compiling the theme in Python code
----------------------------------

You can run the Diazo compiler from Python code using the following helper
function::

    >>> from diazo.compiler import compile_theme

Please see the docstring for this function for more details about the
parameters it takes.

``compile_theme()`` returns an XSLT document in ``lxml``'s ``ElementTree``
format. To set up a transform representing the theme and rules, you can do::

    from lxml import etree
    from diazo.compiler import compile_theme

    absolute_prefix = "/static"

    rules = "rules.xml"
    theme = "theme.html"

    compiled_theme = compile_theme(rules, theme,
                                   absolute_prefix=absolute_prefix)

    transform = etree.XSLT(compiled_theme)

You can now use this transformation::

    content = etree.parse(some_content)
    transformed = transform(content)

    output = etree.tostring(transformed)

Please see the ``lxml`` documentation for more details.