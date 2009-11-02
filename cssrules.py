#!/usr/bin/env python
"""Usage: %prog RULES

RULES is a file defining a set of xdv rules in css syntax, e.g:

<rules xmlns="http://namespaces.plone.org/xdv"
       xmlns:css="http://namespaces.plone.org/xdv+css">
       <copy css:content="#content-wrapper" css:theme="#page-content"/>
</rules>
"""
usage = __doc__

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

def convert(rules):
    """Convert css rules to xpath rules element tree in place"""
    for element in rules.xpath("//@*[namespace-uri()='http://namespaces.plone.org/xdv+css']/.."):
        for name, value in element.attrib.items():
            if name.startswith('{%s}' % xmlns['css']):
                element.attrib[fullname(element.nsmap[element.prefix], localname(name))] = css_to_xpath(value)

def main():
    from optparse import OptionParser
    parser = OptionParser(usage=usage)
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("Invalid number of arguments")
    else:
        rules = etree.parse(args[0])
        convert(rules)
        print etree.tostring(rules)

if __name__ == '__main__':
    main()
