#!/usr/bin/env python
"""\
Usage: %prog RULES

RULES is a file defining a set of xdv rules in css syntax, e.g:

<rules xmlns="http://namespaces.plone.org/xdv"
       xmlns:css="http://namespaces.plone.org/xdv+css">
       <copy css:content="#content-wrapper" css:theme="#page-content"/>
</rules>\
"""
usage = __doc__

from optparse import OptionParser
from lxml import etree
from lxml.cssselect import css_to_xpath

import utils

import logging
logger = logging.getLogger('xdv')

def convert_css_selectors(rules, prefix='//'):
    """Convert css rules to xpath rules element tree in place
    """
    #XXX: There is a :root pseudo-class - http://www.w3.org/TR/css3-selectors/#root-pseudo
    # We may wish to add support to lxml.cssselect for it some day.
    for element in rules.xpath("//@*[namespace-uri()='%s']/.." % utils.namespaces['css']):
        for name, value in element.attrib.items():
            if name.startswith('{%s}' % utils.namespaces['css']):
                if value:
                    element.attrib[utils.localname(name)] = css_to_xpath(value, prefix=prefix)
                else:
                    element.attrib[utils.fullname(element.nsmap[element.prefix], utils.localname(name))] = ""

def main():
    """Called from console script
    """
    parser = OptionParser(usage=usage)
    parser.add_option("-o", "--output", metavar="output.html",
                      help="Output filename (instead of stdout)",
                      dest="output", default=sys.stdout)
    parser.add_option("-p", "--pretty-print", action="store_true",
                      help="Pretty print output",
                      dest="pretty_print", default=False)
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("Invalid number of arguments")
    rules = etree.parse(args[0])
    convert_css_selectors(rules)
    rules.write(options.output, pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
