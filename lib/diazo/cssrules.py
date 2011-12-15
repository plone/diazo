#!/usr/bin/env python
"""\
Usage: %prog RULES

RULES is a file defining a set of diazo rules in css syntax, e.g:

<rules xmlns="http://namespaces.plone.org/diazo"
       xmlns:css="http://namespaces.plone.org/diazo/css">
       <copy css:content="#content-wrapper" css:theme="#page-content"/>
</rules>\
"""
usage = __doc__

from optparse import OptionParser
from lxml import etree
from experimental.cssselect import css_to_xpath

import utils

import logging
logger = logging.getLogger('diazo')

def convert_css_selectors(rules):
    """Convert css rules to xpath rules element tree in place
    """
    #XXX: There is a :root pseudo-class - http://www.w3.org/TR/css3-selectors/#root-pseudo
    # We may wish to add support to lxml.cssselect for it some day.
    for element in rules.xpath("//@*[namespace-uri()='%s']/.." % utils.namespaces['css']):
        tag_localname = utils.localname(element.tag)
        tag_namespace = utils.namespace(element.tag)        
        css_prefix = element.attrib.get(utils.fullname(utils.namespaces['css'], 'prefix'), None)
        for name, value in element.attrib.items():
            if not name.startswith('{%s}' % utils.namespaces['css']):
                continue
            localname = utils.localname(name)
            if localname == 'prefix':
                continue
            if not value:
                element.attrib[localname] = ""
                continue
            if css_prefix is not None:
                prefix = css_prefix
            elif (tag_namespace == utils.namespaces['diazo'] and localname in ('content', 'content-children', 'if-content', 'if-not-content') or
                (tag_namespace == utils.namespaces['xsl'] and localname in ('match',))
                ):
                prefix = '//'
            else:
                prefix = 'descendant-or-self::'                    
            element.attrib[localname] = css_to_xpath(value, prefix=prefix)

    return rules

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
