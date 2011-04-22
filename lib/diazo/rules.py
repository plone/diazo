#!/usr/bin/env python
"""\
Usage: %prog [-r] RULES

Preprocess RULES, an diazo rules file
"""
usage = __doc__

import logging
import re

from optparse import OptionParser
from lxml import etree
from urlparse import urljoin

from diazo.cssrules import convert_css_selectors
from diazo.utils import namespaces, fullname, AC_READ_NET, AC_READ_FILE, pkg_xsl, _createOptionParser

logger = logging.getLogger('diazo')

IMPORT_STYLESHEET = re.compile(r'''(?P<before>@import[ \t]+(?P<paren>url\([ \t]?)?(?P<quote>['"]?))(?P<url>\S+)(?P<after>(?P=quote)(?(paren)\)))''', re.IGNORECASE)
CONDITIONAL_SRC= re.compile(r'''(?P<before><[^>]*?(src|href)=(?P<quote>['"]?))(?P<url>[^ \t\n\r\f\v>]+)(?P<after>(?P=quote)[^>]*?>)''', re.IGNORECASE)


update_transform = pkg_xsl('update-namespace.xsl')
normalize_rules  = pkg_xsl('normalize-rules.xsl')
apply_conditions = pkg_xsl('apply-conditions.xsl')
merge_conditions = pkg_xsl('merge-conditions.xsl')
annotate_themes  = pkg_xsl('annotate-themes.xsl')
annotate_rules   = pkg_xsl('annotate-rules.xsl')
apply_rules      = pkg_xsl('apply-rules.xsl')
fixup_themes     = pkg_xsl('fixup-themes.xsl')


def update_namespace(rules_doc):
    """Convert old namespace to new namespace in place
    """
    update = False
    for ns in (namespaces['old1'], namespaces['old2']):
        if rules_doc.xpath("//*[namespace-uri()='%s']" % ns):
            logger.warning('The %s namespace is deprecated, use %s instead.' % (ns, namespaces['diazo']))
            update = True
    for ns in (namespaces['oldcss1'], namespaces['oldcss2']):
        if rules_doc.xpath("//@*[namespace-uri()='%s']" % ns):
            logger.warning('The %s namespace is deprecated, use %s instead.' % (ns, namespaces['css']))
            update = True
    if update:
        return update_transform(rules_doc)
    else:
        return rules_doc

def expand_themes(rules_doc, parser=None, absolute_prefix=None, read_network=False):
    """Expand <theme href='...'/> nodes with the theme html.
    """
    if absolute_prefix is None:
        absolute_prefix = ''
    base = rules_doc.docinfo.URL
    if parser is None:
        parser = etree.HTMLParser()
    for element in rules_doc.xpath('//diazo:theme[@href]', namespaces=namespaces):
        url = urljoin(base, element.get('href'))
        if url[:6] in ('ftp://', 'http:/', 'https:'):
            raise ValueError("Supplied theme '%s', but network access denied." % url)
        theme_doc = etree.parse(url, parser=parser)
        prefix = urljoin(absolute_prefix, element.get('prefix', ''))
        apply_absolute_prefix(theme_doc, prefix)
        element.append(theme_doc.getroot())
    return rules_doc

def apply_absolute_prefix(theme_doc, absolute_prefix):
    if not absolute_prefix:
        return
    if not absolute_prefix.endswith('/'):
        absolute_prefix = absolute_prefix + '/'
    for node in theme_doc.xpath('//*[@src]'):
        url = urljoin(absolute_prefix, node.get('src'))
        node.set('src', url)
    for node in theme_doc.xpath('//*[@href]'):
        url = urljoin(absolute_prefix, node.get('href'))
        node.set('href', url)
    for node in theme_doc.xpath('//style'):
        node.text = IMPORT_STYLESHEET.sub(
            lambda match: match.group('before') + urljoin(absolute_prefix, match.group('url')) + match.group('after'),
            node.text)
    for node in theme_doc.xpath('//comment()[starts-with(., "[if")]'):
        node.text = IMPORT_STYLESHEET.sub(
            lambda match: match.group('before') + urljoin(absolute_prefix, match.group('url')) + match.group('after'),
            node.text)
        node.text = CONDITIONAL_SRC.sub(
            lambda match: match.group('before') + urljoin(absolute_prefix, match.group('url')) + match.group('after'),
            node.text)

def add_extra(rules_doc, extra):
    root = rules_doc.getroot()
    extra_elements = extra.xpath('/xsl:stylesheet/xsl:*', namespaces=namespaces)
    root.extend(extra_elements)
    return rules_doc

def add_theme(rules_doc, theme, parser=None, absolute_prefix=None, read_network=False):
    if isinstance(theme, basestring) and theme[:6] in ('ftp://', 'http:/', 'https:'):
        raise ValueError("Supplied theme '%s', but network access denied." % theme)
    if absolute_prefix is None:
        absolute_prefix = ''
    if parser is None:
        parser = etree.HTMLParser()
    root = rules_doc.getroot()
    element = root.makeelement(fullname(namespaces['diazo'], 'theme'))
    theme_doc = etree.parse(theme, parser=parser)
    prefix = urljoin(absolute_prefix, element.get('prefix', ''))
    apply_absolute_prefix(theme_doc, prefix)
    element.append(theme_doc.getroot())   
    root.append(element)
    return rules_doc

def fixup_theme_comment_selectors(rules):
    """Comments must be converted to <xsl:comment> to be output, doing it early
    allows them to get an xml:id so they can be matched in the theme. The theme
    selector needs rewriting to replace comment() with xsl:comment
    """
    for element in rules.xpath("//@theme[contains(., 'comment()')]/.."):
        element.attrib['theme'] = element.attrib['theme'].replace('comment()', 'xsl:comment')
    return rules

def process_rules(rules, theme=None, extra=None, trace=None, css=True, xinclude=True, absolute_prefix=None,
                  includemode=None, update=True, parser=None, rules_parser=None, read_network=False, stop=None):
    if trace:
        trace = '1'
    else:
        trace = '0'
    if rules_parser is None:
        rules_parser = etree.XMLParser(recover=False)
    rules_doc = etree.parse(rules, parser=rules_parser)
    if stop == 0: return rules_doc
    if parser is None:
        parser = etree.HTMLParser()
    if xinclude:
        rules_doc.xinclude() # XXX read_network limitation not yet supported for xinclude
    if stop == 1: return rules_doc
    if update:
        rules_doc = update_namespace(rules_doc)
    if stop == 2: return rules_doc
    if css:
        rules_doc = convert_css_selectors(rules_doc)
    if stop == 3: return rules_doc
    rules_doc = fixup_theme_comment_selectors(rules_doc)
    if stop == 4: return rules_doc
    rules_doc = expand_themes(rules_doc, parser, absolute_prefix, read_network)
    if theme is not None:
        rules_doc = add_theme(rules_doc, theme, parser, absolute_prefix, read_network)
    if stop == 5: return rules_doc
    if includemode is None:
        includemode = 'document'
    includemode = "'%s'" % includemode
    rules_doc = normalize_rules(rules_doc, includemode=includemode)
    if stop == 6: return rules_doc
    rules_doc = apply_conditions(rules_doc)
    if stop == 7: return rules_doc
    rules_doc = merge_conditions(rules_doc)
    if stop == 8: return rules_doc
    rules_doc = fixup_themes(rules_doc)
    if stop == 9: return rules_doc
    rules_doc = annotate_themes(rules_doc)
    if stop == 10: return rules_doc
    rules_doc = annotate_rules(rules_doc)
    if stop == 11: return rules_doc
    rules_doc = apply_rules(rules_doc, trace=trace)
    return rules_doc


def main():
    """Called from console script
    """
    parser = _createOptionParser(usage=usage)
    parser.add_option("-s", "--stop", metavar="n", type="int",
                      help="Stop preprocessing at stage n", 
                      dest="stop", default=None)
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

    rules_doc = process_rules(
        options.rules,
        theme=options.theme,
        extra=options.extra,
        trace=options.trace,
        absolute_prefix=options.absolute_prefix,
        includemode=options.includemode,
        read_network=options.read_network,
        stop=options.stop,
        )
    rules_doc.write(options.output, pretty_print=options.pretty_print)

if __name__ == '__main__':
    main()
