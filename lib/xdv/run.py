#!/usr/bin/env python
"""\
Usage: %prog TRANSFORM CONTENT

  TRANSFORM is the compiled theme transform
  CONTENT is an html file.
  
Usage: %prog -t THEME -r RULES [options] CONTENT
"""
usage = __doc__

import sys
import os.path
from lxml import etree
from optparse import OptionParser
from compiler import compile_theme
from utils import AC_READ_NET, AC_READ_FILE

class RunResolver(etree.Resolver):
    def __init__(self, directory):
        self.directory = directory
        
    def resolve(self, url, id, context):
        # libxml2 does not do this correctly on it's own with the HTMLParser
        # but it does work in Apache
        url = os.path.join(self.directory, url)
        return self.resolve_filename(url, context)

def main():
    """Called from console script
    """
    op = OptionParser(usage=usage)
    op.add_option("-t", "--theme", metavar="theme.html",
                  help="Theme file",
                  dest="theme", default=None)
    op.add_option("-r", "--rules", metavar="rules.xml",
                  help="XDV rules file", 
                  dest="rules", default=None)
    op.add_option("-e", "--extra", metavar="extra.xsl",
                  help="XDV extraurl XSLT file (depracated, use inline xsl in the rules instead)",
                  dest="extra", default=None)
    op.add_option("-o", "--output", metavar="output.html",
                  help="Output filename (instead of stdout)",
                  dest="output", default=sys.stdout)
    op.add_option("-p", "--pretty-print", action="store_true",
                  help="Pretty print output (can alter rendering on the browser)",
                  dest="pretty_print", default=False)
    op.add_option("--xinclude", action="store_true",
                  help="Run XInclude on rules.xml (depracated, xinclude is always run)",
                  dest="xinclude", default=True)
    op.add_option("-n", "--network", action="store_true",
                  help="Allow reads to the network to fetch resources",
                  dest="read_network", default=False)
    (options, args) = op.parse_args()

    if options.read_network:
        access_control = AC_READ_NET
    else:
        access_control = AC_READ_FILE

    if len(args) == 2:
        transform_path, content = args
        parser = etree.XMLParser()
        output_xslt = etree.parse(transform_path, parser=parser)
    elif len(args) == 1:
        if options.theme and options.rules:
            content, = args
            parser = etree.HTMLParser()
            output_xslt = compile_theme(rules=options.rules, theme=options.theme, extra=options.extra, parser=parser, access_control=access_control)
        else:
            op.error("Theme and rules must be supplied.")
    else:
        op.error("Wrong number of arguments.")

    if content == '-':
        content = sys.stdin

    parser.resolvers.add(RunResolver(os.path.dirname(content)))
    transform = etree.XSLT(output_xslt, access_control=access_control)
    content_doc = etree.parse(content, parser=etree.HTMLParser())
    output_html = transform(content_doc)
    output_html.write(options.output, encoding='UTF-8', pretty_print=options.pretty_print)
    for msg in transform.error_log:
        print msg

if __name__ == '__main__':
    main()
