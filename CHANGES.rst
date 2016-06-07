Changelog
=========

1.2.3 (2016-06-07)
------------------

New:

- Add absolute url prefix to xlink:href attributes
  [krissik]


1.2.2 (2015-10-30)
------------------

New:

* Allowed content-to-content inclusion.
  [elro, ebrehault]


1.2.1 (2015-09-07)
------------------

* Absolute prefix support for srcset attributes
  [huubbouma]


1.2.0 (2015-09-03)
------------------

* Extend cssselect instead of using experimental.cssselect
  [elro]


1.1.2 (2015-09-03)
------------------

* Allow inline content for after and before.
  [ebrehault, elro]

* Fixed issue with remote themes via https connections
  [loechel]


1.1.1 (2015-03-21)
------------------

* Make flake8 happy by moving imports to top of file.
  [elro]


1.1.0 (2014-10-23)
------------------

* Python 3 support.
  [regebro, elro]


1.0.6 (2014-09-11)
------------------

* Use formencode's xml_compare method to compare test results. This solves test
  failures on several systems.
  [timo]

* Also evaluate if-not-content. However, we are at risk of replicating
  apply-conditions.xsl in it's entirety. this needs refactoring.
  [lentinj]

* Remove any xml:lang attribute from content to prevent multiple
  xml:lang attributes when the html tag's attributes are copied.
  [danjacka]

1.0.5 (2014-01-27)
------------------

* Escape curly brackets on theme attributes.
  [TracyWebTech]

1.0.4 (2013-08-14)
------------------

* Provide the request's query string as the ``$query_string`` variable
  for use in the rules file.
  [davidjb]

* Fix ``diazo.scheme`` definition to be correct. Previously, this was
  defined as ``request.host``.
  [davidjb]

1.0.3 (2012-11-11)
------------------

* Support selectors matching multiple elements for merge attributes, e.g.
  ``<merge attributes="class" css:theme="body" css:content="#one, #two"/>``
  [elro]

* Also evaluate merged-condition. This means a rule tag will turn red
  when a condition on an outer rules tag doesn't match.
  [lentinj]

* use boolean(), not count() for if-content. Otherwise we
  generate expressions like "count(nodeset and other_nodeset)",
  which aren't valid.
  [lentinj]

* Output contents of error log as part of debugging output
  [lentinj]

* Debugging output.
  [lentinj]

* Don't close the response unless Diazo is transforming it.
  [mitchellrj]

* fix error caused by empty style tag e.g. <style/>
  [djay]

1.0.2 (2012-08-30)
------------------

* Handle error when serializing empty responses by returning an unthemed
  response. Previously, empty text/html responses resulted in an raised
  exception, resulting in a 500 response and no output.
  [davidjb]

* Allow attributes (i.e. xml:id) to pass through on drop @attribute nodes
  [lentinj]

1.0.1 (2012-05-09)
------------------

* Fixed to not apply absolute prefix for relative urls starting with '#'.
  [datakurre]

1.0 (2012-04-15)
----------------

* Preserve resolvers in the rules document when updating from an old namespace.

* Add javascript / css include support to WSGIResolver.

* Refactoring if WSGI middleware to use WebOb better and fix corner cases.

* Use same xpath prefix for css:if-not-content and css:if-content.

* Add support for @if-not-path.

Note: for older changes, see ``docs/changelog.rst``.
