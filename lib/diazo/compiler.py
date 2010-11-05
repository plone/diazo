#!/usr/bin/env python
"""\
Usage: %prog [options] [-r] RULES [-t] THEME

  THEME is an html file.
  RULES is a file defining a set of diazo rules in css syntax, e.g:
    <rules xmlns="http://namespaces.plone.org/diazo">
        <copy content="//div[@id='content-wrapper']"
              theme="//div[@id='page-content']"/>
    </rules>\
"""
usage = __doc__

import logging
import pkg_resources
import sys

from lxml import etree

from diazo.rules import process_rules
from diazo.utils import namespaces, AC_READ_NET, AC_READ_FILE, pkg_xsl, _createOptionParser, CustomResolver

logger = logging.getLogger('diazo')

emit_stylesheet = pkg_xsl('emit-stylesheet.xsl')

def set_parser(stylesheet, parser, compiler_parser=None):
    dummy_doc = etree.parse(open(pkg_resources.resource_filename('diazo', 'dummy.html')), parser=parser)
    name = 'file:///__diazo__'
    resolver = CustomResolver({name: stylesheet})
    if compiler_parser is None:
        compiler_parser = etree.XMLParser()
    compiler_parser.resolvers.add(resolver)
    identity = pkg_xsl('identity.xsl', compiler_parser)
    output_doc = identity(dummy_doc, docurl="'%s'"%name)
    compiler_parser.resolvers.remove(resolver)
    return output_doc

def compile_theme(rules, theme=None, extra=None, css=True, xinclude=True, absolute_prefix=None, update=True, trace=False, includemode=None, parser=None, compiler_parser=None, rules_parser=None, access_control=None, read_network=False, indent=None):
    """Invoke the diazo compiler.
    
    * ``rules`` is the rules file
    * ``theme`` is the theme file
    * ``extra`` is an optional XSLT file with Diazo extensions (depracated, use
      inline xsl in the rules instead)
    * ``css``   can be set to False to disable CSS syntax support (providing a
      moderate speed gain)
    * ``xinclude`` can be set to False to disable XInclude support during the
      compile phase (providing a moderate speed gain)
    * ``absolute_prefix`` can be set to a string that will be prefixed to any
      *relative* URL referenced in an image, link or stylesheet in the theme
      HTML file before the theme is passed to the compiler. This allows a
      theme to be written so that it can be opened and views standalone on the
      filesystem, even if at runtime its static resources are going to be
      served from some other location. For example, an
      ``<img src="images/foo.jpg" />`` can be turned into 
      ``<img src="/static/images/foo.jpg" />`` with an ``absolute_prefix`` of
      "/static".
    * ``update`` can be set to False to disable the automatic update support for
      the old Deliverance 0.2 namespace (for a moderate speed gain)
    * ``trace`` can be set to True to enable compiler trace information
    * ``includemode`` can be set to 'document', 'esi' or 'ssi' to change the
      way in which includes are processed
    * ``parser`` can be set to an lxml parser instance; the default is an HTMLParser
    * ``compiler_parser``` can be set to an lxml parser instance; the default is a
      XMLParser
    * ``rules_parser`` can be set to an lxml parser instance; the default is a
      XMLParser.
    """
    if access_control is not None:
        read_network = access_control.options['read_network']
    rules_doc = process_rules(
        rules=rules,
        theme=theme,
        extra=extra,
        css=css,
        xinclude=xinclude,
        absolute_prefix=absolute_prefix,
        update=update,
        trace=trace,
        includemode=includemode,
        parser=parser,
        rules_parser=rules_parser,
        read_network=read_network,
        )
    params = {}
    if indent is not None:
        params['indent'] = indent and "'yes'" or "'no'"
    compiled_doc = emit_stylesheet(rules_doc, **params)
    compiled_doc = set_parser(etree.tostring(compiled_doc), parser, compiler_parser)
    return compiled_doc


def main():
    """Called from console script
    """
    parser = _createOptionParser(usage=usage)
    (options, args) = parser.parse_args()

    if options.rules is None:
        if len(args) == 2 and options.theme is None:
            options.rules, options.theme = args
        elif len(args) == 1:
            options.rules, = args
        else:
            parser.error("Wrong number of arguments.")
    elif args:
        parser.error("Wrong number of arguments.")

    if options.trace:
        logger.setLevel(logging.DEBUG)

    output_xslt = compile_theme(
        rules=options.rules,
        theme=options.theme,
        extra=options.extra,
        trace=options.trace,
        absolute_prefix=options.absolute_prefix,
        includemode=options.includemode,
        read_network=options.read_network,
        )
    output_xslt.write(options.output, encoding='utf-8', pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
