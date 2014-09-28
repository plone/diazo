Basic syntax
============

A Diazo theme consists of a static HTML page (referred to as the "theme") and
a rules file, conventionally called ``rules.xml``.

The rules file contains an XML document that is is rooted in a tag called
``<rules />``::

    <rules
        xmlns="http://namespaces.plone.org/diazo"
        xmlns:css="http://namespaces.plone.org/diazo/css"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

           ...

    </rules>

Here we have defined three namespaces: the default namespace is used for rules
and XPath selectors. The ``css`` namespace is used for CSS3 selectors. These
are functionally equivalent to the XPath selectors. In fact, CSS selectors are
replaced by the equivalent XPath selector during the pre-processing step of
the compiler. Thus, they have no performance impact. The ``xsl`` namespace is
used if you want to add inline XSLT directives for fine-grained control. We
will come to that later in this guide.

    Diazo supports complex CSS3 and XPath selectors, including things like the
    ``nth-child`` pseudo-selector. You are advised to consult a good reference
    if you are new to XPath and/or CSS3.

Rule directives
---------------

The following directives are allowed inside the ``<rules />`` element in the
rules file:

``<theme />``
~~~~~~~~~~~~~

Used to specify the theme file. For example::

    <theme href="theme.html" />

Relative paths are resolved relative to the rules.xml file. For http/https
urls, the ``--network`` switch must be supplied to the ``diazocompiler`` or
``diazorun`` program.

The following attributes are allowed:

``href`` (required)
    A reference to the theme HTML file, as either a relative or absolute
    URL.
``if``
    Used to specify an arbitrary condition that must be true for this theme
    reference to be used. More on this in the section on using multiple themes
    later in this guide.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for this theme reference to be used. More on this in the section
    on using multiple themes later in this guide.
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for this
    theme reference to be used. More on this in the section on using multiple
    themes later in this guide.

``<notheme />``
~~~~~~~~~~~~~~~

Used to turn off all theming in certain conditions. For example::

    <theme href="theme.html" />
    <notheme css:if-content="body.rawpage" />

Multiple ``<notheme />`` elements may be used. If the condition on any of
them is true, the theme will be omitted. That is, they are logically or'd
together.

One or more of the following attributes are required:

``if``
    Used to specify an arbitrary condition for when to omit the theme.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for the theme to be omitted.
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for the
    theme to be omitted.

If more than one attribute is used, the condition of all must be true for the
directive to take effect. That is, they are logically and'ed together.

``<replace />``
~~~~~~~~~~~~~~~

Used to replace an element in the theme entirely with an element in the
content. For example::

    <replace theme="/html/head/title" content="/html/head/title"/>

The (near-)equivalent using CSS selectors would be::

    <replace css:theme="title" css:content="title"/>

The result of either is that the ``<title />`` element in the theme is
replaced with the ``<title />`` element in the (dynamic) content.

The following attributes are allowed:

``theme`` or ``theme-children`` or ``css:theme`` or ``css:theme-children`` (required)
    Used to specify the node(s) in the theme that is to be replaced. When using
    ``theme-children``, all elements inside the tag that matches the XPath
    or CSS expression will be replaced, but the matched tag itself will remain
    intact.
``content`` or ``content-children`` or ``css:content`` or ``css:content-children`` (required)
    Used to specify the node in the content that is to replace the matched
    node(s) in the theme. When using ``content-children``, all elements inside
    the tag that matches the XPath or CSS expression will be used, but the
    matched tag itself will be left out.
``attributes``
    If you want to replace attributes instead of tags, you can use the
    ``attributes`` attribute to provide a space-separated list of attributes
    that should be replaced on the matched theme node(s). For example, with
    ``attributes="class"`` the ``class`` attribute on the matched theme
    node(s) will be replaced by the ``class`` attribute of the matched content
    node(s).

    **Note:** As with ``<replace />`` rules working on tags, if the named
    attribute(s) do not exist on the both the theme and content nodes, nothing
    will happen. If you want to copy attributes regardless of whether they
    exist on the theme node(s) or not, you can use ``<copy />`` instead.

    Using ``attributes="class id"``, the ``class`` and ``id`` attributes will
    be replaced.

    As a special case, you can write ``attributes="*"`` to drop all attributes
    on the matched theme node and copy over all attributes from the matched
    content node.

    **Note:** You should not use ``theme-children`` or ``content-children``
    or their CSS equivalents when using ``attributes``.

    See also ``<merge />``, ``<copy />`` and ``<drop />``
``method``
    If you have any ``<drop />`` or other rules that manipulate the *content*,
    and you do not want that manipulation to be taken into account when
    performing this replacement, you can add ``method="raw"`` to the
    ``<replace />`` rule.
``if``
    Used to specify an arbitrary condition for when to perform the
    replacement.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for the replacement to be performed
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for the
    replacement to be performed.

For more advanced usage of ``<replace>``,
see :ref:`modifying-the-theme-on-the-fly`
and :ref:`modifying-the-content-on-the-fly`.

``<before />`` and ``<after />``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These are equivalent to ``<replace />`` except that the node(s) matched in
the content are inserted before or after the node(s) matched in the theme,
respectively. For example::

    <before css:theme="#content" css:content="#info-box" />

This would place the element with id ``info-box`` from the content
immediately before the element with id ``content`` in the theme. If we
wanted the box below the content instead, we could do::

    <after css:theme="#content" css:content="#info-box" />

To insert the box immediately inside the ``#content`` node, before any of its
existing children, we could do::

    <before css:theme-children="#content" css:content="#info-box" />

``<before />`` and ``<after />`` have the same required and optional
attributes as ``<replace />``, except for ``attributes``, which is not
supported.

``<drop />``
~~~~~~~~~~~~

Used to drop elements from the theme or the content. This is the only
element that accepts either ``theme`` or ``content`` attributes (or their
``css:`` and ``-children`` equivalents), but not both::

    <drop css:content="#portal-content .about-box" />
    <replace css:theme-children="#content" css:content="#portal-content" />

This would copy all children of the element with id ``portal-content`` in
the theme  into the element with id ``content`` in the theme, but only
after removing any element with class ``about-box`` inside the content
element first.

Similarly::

    <drop theme="/html/head/base" />

Would drop the ``<base />`` tag from the head of the theme.

The following attributes are allowed:

``theme`` or ``theme-children`` or ``css:theme`` or ``css:theme-children``
    Used to specify the node(s) in the theme that is to be dropped. When using
    ``theme-children``, all elements inside the tag that matches the XPath
    or CSS expression will be dropped, but the matched tag itself will remain
    intact.
``content`` or ``content-children`` or ``css:content`` or ``css:content-children``
     Used to specify the node(s) in the content that is to be dropped. When
     using ``content-children``, all elements inside the tag that matches the
     XPath or CSS expression will be dropped, but the matched tag itself will
     remain intact.
``attributes``
    If you want to drop attributes instead of whole tags, you can use the
    ``attributes`` attribute to provide a space-separated list of attributes
    that should be dropped on the matched theme node(s). For example, with
    ``attributes="class"`` the ``class`` attribute will be dropped from the
    matched node(s). Using ``attributes="class id"``, the ``class`` and ``id``
    attributes will both be dropped.

    As a special case, you can write ``attributes="*"`` to drop all attributes
    on the matched theme node.

    **Note:** You should not use ``theme-children`` or ``content-children``
    or their CSS equivalents when using ``attributes``.

    See also ``<merge />`` and ``<replace />``
``if``
    Used to specify an arbitrary condition for when to perform the
    drop.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for the drop to be performed
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for the
    drop to be performed.

``<strip />``
~~~~~~~~~~~~~

Used to strip a tag from the theme or content, leaving its children intact.
You can think of this as the inverse of ``<drop />`` with ``theme-children``
or ``content-children``. For example::

    <strip css:theme="#content" />

This will remove the element with id ``content``, leaving in place all its
children.

Similarly::

    <strip css:content="#main-area .wrapper" />
    <replace css:theme="#content-area" css:content="#main-area" />

This will replace the theme's element with the id ``content-area`` with the
element in the content that has the id ``main-area``, but will strip out any
nested tags with the CSS class ``wrapper`` found inside ``#main-area``.

``<strip />`` uses the same attributes and semantics as ``<drop />``.

``<merge />``
~~~~~~~~~~~~~

Used to merge the values of attributes in the content with attributes with the
same name in the theme. This is mainly useful for merging CSS classes::

    <merge attributes="class" css:theme="body" css:content="body" />

If the theme has the following body tag::

    <body class="alpha beta">

and the content has::

    <body class="delta gamma">

then the result will be::

    <body class="alpha beta delta gamma">

The following attributes are allowed:

``attributes`` (required)
    A space-separated list of attributes to merge. A given attribute must
    exist on both the theme and the content nodes for the rule to have any
    effect.
``theme`` or ``css:theme`` (required)
    The theme node(s) to merge the attribute value(s) with.
``content`` (required)
    The content node(s) to merge the attribute value(s) from.
``separator``
    The separator to use when merging attributes. The default is to use
    a space. Use ``separator=""`` to merge with no separator.
``if``
    Used to specify an arbitrary condition for when to perform the
    merge.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for the merge to be performed
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for the
    merge to be performed.

``<copy />``
~~~~~~~~~~~~

Used to copy an attribute from a node in the content to a node in the theme.
Unlike ``<replace />``, ``<copy />`` will work even if the attribute does
not exist on the target theme node. If it *does* exist, it will be replaced.
For example::

    <copy attributes="class" css:theme="body" css:content="body"/>

The following attributes are allowed:

``theme`` or ``css:theme`` (required)
    Used to specify the node(s) in the theme where the attribute should be
    copied.
``content`` or ``css:content`` (required)
    Used to specify the node(s) in the content from which the attribute should
    be copied.
``attributes`` (required)
    A space-separated list of attributes that should be copied to the theme.

    As a special case, you can write ``attributes="*"`` to drop all attributes
    on the matched theme node and copy over all attributes from the matched
    content node.
``if``
    Used to specify an arbitrary condition for when to perform the
    copy.
``if-path``
    Used to specify a URL path segment that must be matched by the current
    request for the copy to be performed
``if-content`` or ``css:if-content``
    Used to specify an element that must be present in the content for the
    copy to be performed.

Order of rule execution
-----------------------

In most cases, you should not care too much about the inner workings of the
Diazo compiler. However, it can sometimes be useful to understand the order
in which rules are applied.

1. ``<before />`` rules using ``theme`` (but not ``theme-children``) are
   always executed first.
2. ``<drop />`` rules are executed next.
3. ``<replace />`` rules using ``theme`` (but not ``theme-children``) are
   executed next, provided no ``<drop />`` rule was applied to the same theme
   node or ``method="raw"`` was used.
4. ``<strip />`` rules are executed next. Note that ``<strip />`` rules do
   not prevent other rules from firing, even if the content or theme node
   is going to be stripped.
5. Rules that operate on attributes.
6. ``<before />`` and ``<replace />`` and ``<after />`` rules using
   ``theme-children`` execute next, provided no ``<replace />`` rule using
   ``theme`` was applied to the same theme node previously.
7. ``<after />`` rules using ``theme`` (but not ``theme-children``) are
   executed last.

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
that if no content node is matched, Diazo uses an empty nodeset when copying
or replacing.

If you want the placeholder to stay put in the case of a missing content node,
you can make this a conditional rule::

    <replace css:theme="#header" content="#header-element" if-content="" />

See the next section for more details on conditional rules.