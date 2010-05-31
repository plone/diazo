#!/usr/bin/env python
"""\
Usage: %prog RULES

Preprocess RULES, and xdv rules file
"""
usage = __doc__

import logging
import pkg_resources
import re

from optparse import OptionParser
from lxml import etree
from urlparse import urljoin

from xdv.cssrules import convert_css_selectors
from xdv.utils import namespaces, fullname, AC_READ_NET, AC_READ_FILE

logger = logging.getLogger('xdv')

IMPORT_STYLESHEET = re.compile(r'''(@import\s+(?:url\(['"]?|['"]))(.+)(['"]?\)|['"])''', re.IGNORECASE)

def pkg_xsl(name):
    return etree.XSLT(etree.parse(pkg_resources.resource_filename('xdv', name)))

update_transform = pkg_xsl('update-namespace.xsl')
normalize_rules  = pkg_xsl('normalize-rules.xsl')
annotate_themes  = pkg_xsl('annotate-themes.xsl')
annotate_rules   = pkg_xsl('annotate-rules.xsl')
apply_rules      = pkg_xsl('apply-rules.xsl')
emit_stylesheet  = pkg_xsl('emit-stylesheet.xsl')


def update_namespace(rules_doc):
    """Convert old namespace to new namespace in place
    """
    if rules_doc.xpath("//*[namespace-uri()='%s']" % namespaces['old']):
        logger.warning('The %s namespace is deprecated, use %s instead.' % (namespaces['old'], namespaces['xdv']))
        return update_transform(rules_doc)
    else:
        return rules_doc

def expand_themes(rules_doc, parser=None, absolute_prefix=None):
    """Expand <theme href='...'/> nodes with the theme html.
    """
    if absolute_prefix is None:
        absolute_prefix = ''
    base = rules_doc.docinfo.URL
    if parser is None:
        parser = etree.HTMLParser()
    for element in rules_doc.xpath('xdv:theme[@href]', namespaces=namespaces):
        url = urljoin(base, element.get('href'))
        theme_doc = etree.parse(url, parser=parser)
        prefix = urljoin(absolute_prefix, element.get('prefix', ''))
        apply_absolute_prefix(theme_doc, prefix)
        element.append(theme_doc.getroot())
    return rules_doc

def apply_absolute_prefix(theme_doc, absolute_prefix):
    for node in theme_doc.xpath('//*[@src]'):
        url = urljoin(absolute_prefix, node.get('src'))
        node.set('src', url)
    for node in theme_doc.xpath('//*[@href]'):
        url = urljoin(absolute_prefix, node.get('href'))
        node.set('href', url)
    for node in theme_doc.xpath('//comment() | //style'):
        if node.tag == 'style' or node.tag == etree.Comment and node.text.startswith("[if IE"):
            node.text = IMPORT_STYLESHEET.sub(lambda match: match.group(1) + urljoin(absolute_prefix, match.group(2)) + match.group(3), node.text)

def add_extra(rules_doc, extra):
    root = rules_doc.getroot()
    extra_elements = extra.xpath('/xsl:stylesheet/xsl:*', namespaces=namespaces)
    root.extend(extra_elements)
    return rules_doc

def add_theme(rules_doc, theme, parser=None, absolute_prefix=None):
    if absolute_prefix is None:
        absolute_prefix = ''
    if parser is None:
        parser = etree.HTMLParser()
    root = rules_doc.getroot()
    element = root.makeelement(fullname(namespaces['xdv'], 'theme'))
    theme_doc = etree.parse(theme, parser=parser)
    prefix = urljoin(absolute_prefix, element.get('prefix', ''))
    apply_absolute_prefix(theme_doc, prefix)
    element.append(theme_doc.getroot())   
    root.append(element)
    return rules_doc

def process_rules(rules, theme=None, extra=None, trace=None, css=True, xinclude=True, absolute_prefix=None, includemode=None, update=True, parser=None, rules_parser=None, compiler_parser=None, access_control=None):
    if rules_parser is None:
        rules_parser = etree.XMLParser(recover=False)
    rules_doc = etree.parse(rules, parser=rules_parser)

    if xinclude:
        rules_doc.xinclude()
    if update:
        rules_doc = update_namespace(rules_doc)
    if css:
        rules_doc = convert_css_selectors(rules_doc)
    rules_doc = expand_themes(rules_doc, parser, absolute_prefix)
    if theme is not None:
        rules_doc = add_theme(rules_doc, theme, parser, absolute_prefix)
    if includemode is None:
        includemode = 'document'
    includemode = "'%s'" % includemode
    rules_doc = normalize_rules(rules_doc, includemode=includemode)
    rules_doc = annotate_themes(rules_doc)
    rules_doc = annotate_rules(rules_doc)
    rules_doc = apply_rules(rules_doc)
    compiled_doc = emit_stylesheet(rules_doc)
    #import pdb; pdb.set_trace()
    return compiled_doc



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
    parser.add_option("-a", "--absolute-prefix", metavar="/",
                      help="relative urls in the theme file will be made into absolute links with this prefix.",
                      dest="absolute_prefix", default=None)
    parser.add_option("-i", "--includemode", metavar="INC",
                      help="include mode (document, ssi or esi)",
                      dest="includemode", default=None)
    parser.add_option("-t", "--theme", metavar="theme.html",
                      help="Theme file",
                      dest="theme", default=None)
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("Invalid number of arguments")
    rules = args[0]
    rules_doc = process_rules(rules, theme=options.theme, absolute_prefix=options.absolute_prefix, includemode=options.includemode)
    rules_doc.write(options.output, pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
