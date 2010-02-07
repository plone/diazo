#!/usr/bin/env python
"""\
Usage: %prog [options] RULES THEME

  THEME is an html file.
  RULES is a file defining a set of xdv rules in css syntax, e.g:
    <rules xmlns="http://namespaces.plone.org/xdv">
        <copy content="//div[@id='content-wrapper']"
              theme="//div[@id='page-content']"/>
    </rules>\
"""
usage = __doc__

import re
import os.path
import sys
import logging
from lxml import etree
from optparse import OptionParser

from utils import namespaces
from cssrules import convert_css_selectors

logger = logging.getLogger('xdv')

HERE = os.path.dirname(__file__)

IMPORT_STYLESHEET_PATTERN = '@import url\\([\'"](.+)[\'"]\\);'

COMPILER_PATH = os.path.join(HERE, 'compiler.xsl')

UPDATE_PATH = os.path.join(HERE, 'update-namespace.xsl')
update_transform = etree.XSLT(etree.parse(UPDATE_PATH))

def update_namespace(rules):
    """Convert old namespace to new namespace in place
    """
    if rules.xpath("//*[namespace-uri()='%s']" % namespaces['old']):
        logger.warning('The %s namespace is deprecated, use %s instead.' % (namespaces['old'], namespaces['xdv']))
        return update_transform(rules)
    else:
        return rules

class CompileResolver(etree.Resolver):
    def __init__(self, rules, extra=None):
        self.rules = rules
        self.extra = extra
        
    def resolve(self, url, pubid, context):
        if url == 'xdv:rules':
            return self.resolve_string(self.rules, context)
        if url == 'xdv:extra' and self.extra is not None:
            return self.resolve_string(self.extra, context)

def to_absolute(src, prefix):
    """Turn a url 
    """
    if src.startswith('/') or '://' in src:
        return src
        
    if src.startswith('./'):
        return "%s/%s" % (prefix, src[2:])
    else:
        return "%s/%s" % (prefix, src)

def apply_absolute_prefix(theme_doc, absolute_prefix):
    for node in theme_doc.xpath('*//style | *//script | *//img | *//link'):
        if node.tag == 'img' or node.tag == 'script':
            src = node.get('src')
            if src:
                node.set('src', to_absolute(src, absolute_prefix))
        elif node.tag == 'link':
            href = node.get('href')
            if href:
                node.set('href', to_absolute(href, absolute_prefix))
        elif node.tag == 'style':
            node.text = re.sub(IMPORT_STYLESHEET_PATTERN, r'@import url("%s/\1");' % absolute_prefix, node.text, re.I)

def compile_theme(rules, theme, extra=None, css=True, xinclude=False, absolute_prefix=None, update=True, trace=False, includemode=None, parser=None, compiler_parser=None):
    """Invoke the xdv compiler.
    
    * ``rules`` is the rules file
    * ``theme`` is the theme file
    * ``extra`` is an optional XSLT file with XDV extensions
    * ``css``   can be set to False to disable CSS syntax support (providing a
      moderate speed gain)
    * ``xinclude`` can be set to True to enable XInclude support (at a
      moderate speed cost)
    * ``update`` can be set to False to disable the automatic update support for
      the old Deliverance 0.2 namespace (for a moderate speed gain)
    * ``trace`` can be set to True to enable compiler trace information
    * ``includemode`` can be set to 'document' or 'ssi' to change the way in
      which includes are processed
    * ``parser`` can be set to an lxml parser class; the default is HTMLParser
    * ``compiler_parser``` can be set to an lxml parser class; the default is
      XMLParser
    """
    rules_doc = etree.parse(rules)
    if xinclude:
        rules_doc.xinclude()
    if update:
        rules_doc = update_namespace(rules_doc)
    if css:
        convert_css_selectors(rules_doc)
    
    if parser is None:
        parser = etree.HTMLParser()
    theme_doc = etree.parse(theme, parser=parser)
    
    if absolute_prefix:
        apply_absolute_prefix(theme_doc, absolute_prefix)
    
    if compiler_parser is None:
        compiler_parser = etree.XMLParser()
    compiler_transform = etree.XSLT(etree.parse(COMPILER_PATH, parser=compiler_parser))

    params = dict(rulesuri="'xdv:rules'")
    if extra:
        params['extraurl'] = "'xdv:extra'"
        resolver = CompileResolver(etree.tostring(rules_doc), etree.tostring(etree.parse(extra)))
    else:
        resolver = CompileResolver(etree.tostring(rules_doc))
    if trace:
        params['trace'] = '1'
    if includemode:
        params['includemode'] = "'%s'" % includemode

    compiler_parser.resolvers.add(resolver)
    compiled = compiler_transform(theme_doc, **params)
    for msg in compiler_transform.error_log:
        logger.info(msg)
    return compiled

def prepare_filename(filename):
    """Make file name string parameters compatible with xdv's compiler.xsl
    """
    filename = os.path.abspath(filename)
    if sys.platform.startswith('win'):
        # compiler.xsl on Windows wants c:/foo/bar instead of C:\foo\bar
        filename = filename.replace('\\', '/')
    return filename

def main():
    """Called from console script
    """
    parser = OptionParser(usage=usage)
    parser.add_option("-e", "--extra", metavar="extra.xsl",
                      help="XDV extraurl XSLT file",
                      dest="extra", default=None)
    parser.add_option("-o", "--output", metavar="output.xsl",
                      help="Output filename (instead of stdout)",
                      dest="output", default=sys.stdout)
    parser.add_option("-p", "--pretty-print", action="store_true",
                      help="Pretty print output (can alter rendering on the browser)",
                      dest="pretty_print", default=False)
    parser.add_option("--trace", action="store_true",
                      help="Compiler trace logging",
                      dest="trace", default=False)
    parser.add_option("--xinclude", action="store_true",
                      help="Run XInclude on rules.xml",
                      dest="xinclude", default=False)
    parser.add_option("-i", "--includemode", metavar="INC",
                      help="include mode (document or ssi)",
                      dest="includemode", default=None)
    (options, args) = parser.parse_args()
    
    if len(args) !=2:
        parser.error("Wrong number of arguments.")
    rules, theme = args

    if options.trace:
        logger.setLevel(logging.DEBUG)

    output_xslt = compile_theme(rules=rules, theme=theme, extra=options.extra, trace=options.trace, xinclude=options.xinclude, includemode=options.includemode)
    output_xslt.write(options.output, encoding='utf-8', pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
