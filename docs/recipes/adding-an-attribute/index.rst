Adding an attribute to elements
===============================

This recipe demonstrates adding a ``target`` attribute to any ``a`` (link)
tags on a page. This recipe will also ensure that any children elements
of the given ``a`` tag will be maintained (such as ``img`` tags, as shown)
and that if said attribute is already set, its value will be maintained.
Note that due to processing, the attribute's ordering on the tag may change.

Rules
-----

.. literalinclude:: rules.xml
   :language: xml

Theme
-----

.. literalinclude:: theme.html
   :language: html

Content
-------

.. literalinclude:: content.html
   :language: html

Output
------

.. literalinclude:: output.html
   :language: html
