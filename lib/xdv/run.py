#!/usr/bin/env python
"""\
Usage: %prog TRANSFORM CONTENT

  TRANSFORM is the compiled theme transform
  CONTENT is an html file.
  
Usage: %prog -t THEME -r RULES [options] CONTENT
"""
usage = __doc__

import sys
from lxml import etree
from optparse import OptionParser
from compiler import compile_theme

def main():
    """Called from console script
    """
    parser = OptionParser(usage=usage)
    parser.add_option("-t", "--theme", metavar="theme.html",
                      help="Theme file",
                      dest="theme", default=None)
    parser.add_option("-r", "--rules", metavar="rules.xml",
                      help="XDV rules file", 
                      dest="rules", default=None)
    parser.add_option("-e", "--extra", metavar="extra.xsl",
                      help="XDV extraurl XSLT file",
                      dest="extra", default=None)
    parser.add_option("-o", "--output", metavar="output.html",
                      help="Output filename (instead of stdout)",
                      dest="output", default=sys.stdout)
    parser.add_option("-p", "--pretty-print", action="store_true",
                      help="Pretty print output (can alter rendering on the browser)",
                      dest="pretty_print", default=False)
    (options, args) = parser.parse_args()
    
    if len(args) == 2:
        transform_path, content = args
        transform = etree.XSLT(etree.parse(transform_path))
    elif len(args) == 1:
        if options.theme and options.rules:
            content, = args
            output_xslt = compile_theme(rules=options.rules, theme=options.theme, extra=options.extra)
            transform = etree.XSLT(output_xslt)
        else:
            parser.error("Theme and rules must be supplied.")
    else:
        parser.error("Wrong number of arguments.")

    if content == '-':
        content = sys.stdin

    output_html = transform(etree.parse(content, parser=etree.HTMLParser()))

    output_html.write(options.output, encoding='utf-8', pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
