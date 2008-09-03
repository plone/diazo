========================================
xdv - XSLT engine for Deliverance
========================================

xdv is a mini-project to implement a subset of Deliverance using a
pure XSLT engine.  With xdv, you "compile" your theme and ruleset in
one step, then use a superfast/simple transform on each request
thereafter.  Alternatively, compile your theme during development,
check it into Subversion, and not touch xdv during deployment.

Usage
----------------

1) Edit the ``theme.html``, ``rules.xml``, and ``content.html``.

2) xsltproc compiler.xsl theme.html > compiledtheme.xsl

3) xsltproc compiledtheme.xsl content.html > output.html

4) open output.html

Specifying the rules file
------------------------------

The Deliverance rules file is read into the compiler.xsl file using
the XSLT ``document()`` function.  This function is given a URI, which
it loads and parses.

By default it looks for ``rules.xml`` in the same directory as the
``compiler.xsl``.  However, you can pass a parameter in when compiling
the theme::

  xsltproc --stringparam rulesuri rules.xml compiler.xsl theme.html > compiledtheme.xsl

Running from Python
-----------------------

There is a little bit of support for generating a theme and printing
it to stdout using lxml:

  $ cd xdv
  $ python tests/test_nodes.py

Usage
------------

- Attribute merging can be performed using <prepend>.  For example::

  <prepend theme="/html/body" content="/html/body/@class" />

Not Supported
--------------------

1) Multiple themes or "page types"

2) Link rewriting

3) CSS Selector syntax


