Old changelog
=============

1.0rc4 - 2011-11-02
-------------------

* Add support for @if-not and @if-not-content.

* Add support for specifying mode on inclusion rules.

* Preserve comments preceding/following html tag in theme. Closes #12249.

* Fix quote_param to always use lxml.etree.XSLT.strparam.

* Handle rules file without a theme to allow drop or replace content.

1.0rc3 - 2011-07-04
-------------------

* Support for ``filter_xpath`` requests for ESI/SSI includes.

* Do not try to transform HEAD requests, otherwise you get:
  ``XMLSyntaxError: no element found``.
  [maurits]

1.0rc2 - 2011-06-08
-------------------

* Fix detection of Content-Type.

* Add doctype option to wsgi middleware to support HTML5 output.

* Fix line endings for included external content.

1.0rc1 - 2011-05-24
-------------------

* Fix diazocompiler --output option.

1.0b4 - 2011-05-17
------------------

* Implement drop theme-children.

1.0b3 - 2011-05-16
------------------

* Filter out additional xmlns with notheme.

1.0b2 - 2011-04-27
------------------

* Enable attribute to be included from external documents.

* Enable use of variables/parameters in drop/strip/replace content rule
  conditions.

* Fix a bug whereby a theme could not be loaded from a network location
  even if read_network was enabled.

1.0b1 - 2011-04-22
------------------

* Updated css namespace url to http://namespaces.plone.org/diazo/css

* Added <replace content="...">...</replace> directive.

* Added the ``wsgi`` module, which contains a WSGI middleware filter for
  applying a Diazo themes, as well as a lower level one for applying an
  XSLT transformation to HTML output.

* Moved documentation from the README to the diazo.org website. See
  http://svn.plone.org/svn/plone/plone.org/diazo-docs/trunk.

* Added ``<merge />`` directive

* Added ``<notheme />`` directive

* Added ``<strip />`` directive

* Revised rule set to be based on ``theme-children`` and ``content-children``
  and an explicit ``attributes`` parameter. ``<copy />`` is now only used for
  copying of attributes. ``<prepend />`` and ``<append />`` are deprecated
  in favour of ``<before />`` and ``<after />`` using ``theme-children``.

* Use experimental.cssselect to better work with location paths.

* Renamed XDV to Diazo.

0.4b3 - 2010-09-09
------------------

* Path conditions with @if-path.

* Serialize using XSLT method in diazorun to respect <xsl:output method="html"/>

* Fix for default theme.

* Fix for themes in nested rules tags.

0.4b2 - 2010-08-16
------------------

* When no conditional themes match, pass the document through without theming.

* Fix loading of compiler stylesheets so as not to be affected by resolvers.

0.4b1 - 2010-08-06
------------------

* Multistage compiler breaks down work into smaller, more easily debugged
  chunks. (In the spirit of the original DVNG prototype.)

* Refactoring of generated XSLT to perform its work in a single pass, bringing
  a 30-50% speedup.

* Multiple theme support using the new <theme> directive.

* Nested <rules> and condition merging allows for condition grouping.

* Allow comments to be selected in the theme.

* Tweaked ``ssi`` includemode for Apache compatibility. The previous
  ``wait="yes"`` behaviour no longer seems necessary with current versions of
  Nginx, but is available using the ``ssiwait`` includemode.

* CSS expressions are now converted to relative rather than absolute xpaths.
  While this makes no difference to their use in diazo directives (which are
  executed in the context of the root node), more flexibility is available
  when used with inline XSL.
