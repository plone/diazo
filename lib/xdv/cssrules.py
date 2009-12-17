#!/usr/bin/env python
"""\
Usage: %prog RULES

RULES is a file defining a set of xdv rules in css syntax, e.g:

<rules xmlns="http://namespaces.plone.org/xdv"
       xmlns:css="http://namespaces.plone.org/xdv+css">
       <copy css:content="#content-wrapper" css:theme="#page-content"/>
</rules>
"""
usage = __doc__

from optparse import OptionParser
from lxml import etree
from lxml.cssselect import css_to_xpath

xmlns = dict(
    xdv="http://namespaces.plone.org/xdv",
    css="http://namespaces.plone.org/xdv+css",
    old="http://openplans.org/deliverance",
    )

def localname(name):
    return name.rsplit('}', 1)[1]

def fullname(namespace, name):
    return '{%s}%s' % (namespace, name)

def convert_css_selectors(rules):
    """Convert css rules to xpath rules element tree in place"""
    for element in rules.xpath("//@*[namespace-uri()='%s']/.." % xmlns['css']):
        for name, value in element.attrib.items():
            if name.startswith('{%s}' % xmlns['css']):
                element.attrib[fullname(element.nsmap[element.prefix], localname(name))] = css_to_xpath(value, prefix='')

def main():
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
