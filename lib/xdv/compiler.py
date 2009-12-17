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

import os.path
import sys
from lxml import etree
from optparse import OptionParser

COMPILER_PATH = os.path.join(os.path.dirname(__file__), 'compiler.xsl')
compiler_transform = etree.XSLT(etree.parse(COMPILER_PATH))

def compile_theme(rules, theme, extra=None, css=False):
    """Invoke the xdv compiler
    """
    parser = etree.HTMLParser()
    theme_doc = etree.parse(theme, parser=parser)
    params = {}
    if rules:
        params['rulesuri'] = "'%s'" % prepare_filename(rules)
    if extra:
        params['extraurl'] = "'%s'" % prepare_filename(extra)
    compiled = compiler_transform(theme_doc, **params)
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
    """Called fromconsole script
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
    (options, args) = parser.parse_args()
    
    if len(args) !=2:
        parser.error("Wrong number of arguments.")
    rules, theme = args

    output_xslt = compile_theme(rules=rules, theme=theme, extra=options.extra)
    output_xslt.write(options.output, pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
