Drop empty tags
===============

This recipe demonstrates adding a caption to an image inserted by user in Plone 5.

The rule checks if an image's title attribute was set, which is allowed in TinyMCE's Insert Image dialog. You can still set alt (as you should) without triggering this rule. But by providing title, it enables an image caption with two independently stylable elements.

Note this rule performs an on-the-fly content side transformation, meaning no references to your theme are necessary.

Rules
-----

.. literalinclude:: rules.xml
   :language: xml

Content
-------

.. literalinclude:: content.html
   :language: html

Output
------

.. literalinclude:: output.html
   :language: html
