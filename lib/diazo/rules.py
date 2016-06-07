#!/usr/bin/env python
"""\
Usage: %prog [-r] RULES

Preprocess RULES, an diazo rules file
"""
import logging
import re
from lxml import etree
from six import string_types
from future.moves.urllib.parse import urljoin
from future.moves.urllib.request import urlopen
from diazo.cssrules import convert_css_selectors
from diazo.utils import namespaces, fullname, pkg_xsl, _createOptionParser

logger = logging.getLogger('diazo')
usage = __doc__

IMPORT_STYLESHEET = re.compile(
    r'''(?P<before>@import[ \t]+(?P<paren>url\([ \t]?)?(?P<quote>['"]?))'''
    r'''(?P<url>\S+)(?P<after>(?P=quote)(?(paren)\)))''', re.IGNORECASE)
CONDITIONAL_SRC = re.compile(
    r'''(?P<before><[^>]*?(src|href)=(?P<quote>['"]?))'''
    r'''(?P<url>[^ \t\n\r\f\v>]+)(?P<after>(?P=quote)[^>]*?>)''',
    re.IGNORECASE)
SRCSET = re.compile(r'(?P<descriptors>^\s*|\s*,\s*)(?P<url>[^\s]*)')


update_transform = pkg_xsl('update-namespace.xsl')
normalize_rules = pkg_xsl('normalize-rules.xsl')
include = pkg_xsl('include.xsl')
apply_conditions = pkg_xsl('apply-conditions.xsl')
merge_conditions = pkg_xsl('merge-conditions.xsl')
annotate_themes = pkg_xsl('annotate-themes.xsl')
annotate_rules = pkg_xsl('annotate-rules.xsl')
apply_rules = pkg_xsl('apply-rules.xsl')
fixup_themes = pkg_xsl('fixup-themes.xsl')


def anchor_safe_urljoin(base, url):
    """Join the base with the url only when the url doesn't start with '#'"""
    if url.startswith('#'):
        return url
    else:
        return urljoin(base, url)


def add_identifiers(rules_doc):
    """Add identifiers to the rules for debugging"""
    for i, elem in enumerate(rules_doc.xpath(
            '//diazo:rules | //diazo:rules/diazo:*'
            ' | //old1:rules | //old1:rules/old1:*'
            ' | //old2:rules | //old2:rules/old1:*', namespaces=namespaces)):
        elem.set(fullname(namespaces['xml'], 'id'), 'r%s' % i)
    return rules_doc


def update_namespace(rules_doc):
    """Convert old namespace to new namespace in place
    """
    update = False
    for ns in (namespaces['old1'], namespaces['old2']):
        if rules_doc.xpath("//*[namespace-uri()='%s']" % ns):
            logger.warning('The %s namespace is deprecated, use %s instead.' %
                           (ns, namespaces['diazo']))
            update = True
    for ns in (namespaces['oldcss1'], namespaces['oldcss2']):
        if rules_doc.xpath("//@*[namespace-uri()='%s']" % ns):
            logger.warning('The %s namespace is deprecated, use %s instead.' %
                           (ns, namespaces['css']))
            update = True
    if update:
        new_doc = update_transform(rules_doc)
        # Place the nodes into the old tree to preserve any custom resolvers
        new = new_doc.getroot()
        root = rules_doc.getroot()
        root.clear()
        root.tag = new.tag
        root.nsmap.update(new.nsmap.items())
        root.attrib.update(new.attrib.items())
        root.text = new.text
        root[:] = new[:]
        root.tail = new.tail
    return rules_doc


def escape_curly_brackets(theme_doc):
    for node in theme_doc.iter():
        for attr in node.attrib:
            if '{' in node.attrib[attr]:
                node.attrib[attr] = node.attrib[attr].replace('{', '{{')
            if '}' in node.attrib[attr]:
                node.attrib[attr] = node.attrib[attr].replace('}', '}}')


def expand_theme(element, theme_doc, absolute_prefix):
    prefix = urljoin(absolute_prefix, element.get('prefix', ''))
    apply_absolute_prefix(theme_doc, prefix)
    escape_curly_brackets(theme_doc)
    theme_root = theme_doc.getroot()
    preceding = list(theme_root.itersiblings(preceding=True))
    preceding.reverse()
    following = list(theme_root.itersiblings(preceding=False))
    element.extend(preceding)
    element.append(theme_root)
    element.extend(following)


def expand_themes(rules_doc, parser=None, absolute_prefix=None,
                  read_network=False):
    """Expand <theme href='...'/> nodes with the theme html.
    """
    if absolute_prefix is None:
        absolute_prefix = ''
    base = rules_doc.docinfo.URL
    if parser is None:
        parser = etree.HTMLParser()
    for element in rules_doc.xpath('//diazo:theme[@href]',
                                   namespaces=namespaces):
        url = urljoin(base, element.get('href'))
        if not read_network and \
                url.startswith(('ftp://', 'ftps://', 'http://', 'https://')):
            raise ValueError("Supplied theme '%s', "
                             "but network access denied." % url)
        elif read_network and \
                url.startswith(('ftp://', 'ftps://', 'http://', 'https://')):
            theme = urlopen(url)
        else:
            theme = url
        theme_doc = etree.parse(theme, parser=parser, base_url=url)
        expand_theme(element, theme_doc, absolute_prefix)
    return rules_doc


def apply_absolute_prefix(theme_doc, absolute_prefix):
    if not absolute_prefix:
        return
    if not absolute_prefix.endswith('/'):
        absolute_prefix = absolute_prefix + '/'
    for node in theme_doc.xpath('//*[@src]'):
        url = urljoin(absolute_prefix, node.get('src'))
        node.set('src', url)
    for xlink_attr in theme_doc.xpath('//@*[local-name()="xlink:href"]'):
        node = xlink_attr.getparent()
        url = urljoin(absolute_prefix, node.get('xlink:href'))
        node.set('xlink:href', url)
    for node in theme_doc.xpath('//*[@srcset]'):
        srcset = node.get('srcset')
        srcset = SRCSET.sub(
            lambda match: match.group('descriptors') + urljoin(
                absolute_prefix, match.group('url')),
            srcset)
        node.set('srcset', srcset)
    for node in theme_doc.xpath('//*[@href]'):
        url = anchor_safe_urljoin(absolute_prefix, node.get('href'))
        node.set('href', url)
    for node in theme_doc.xpath('//style'):
        if node.text is None:
            continue
        node.text = IMPORT_STYLESHEET.sub(
            lambda match: match.group('before') + urljoin(
                absolute_prefix, match.group('url')) + match.group('after'),
            node.text)
    for node in theme_doc.xpath('//comment()[starts-with(., "[if")]'):
        node.text = IMPORT_STYLESHEET.sub(
            lambda match: match.group('before') + urljoin(
                absolute_prefix, match.group('url')) + match.group('after'),
            node.text)
        node.text = CONDITIONAL_SRC.sub(
            lambda match: match.group('before') + urljoin(
                absolute_prefix, match.group('url')) + match.group('after'),
            node.text)


def add_extra(rules_doc, extra):
    root = rules_doc.getroot()
    extra_elements = extra.xpath('/xsl:stylesheet/xsl:*',
                                 namespaces=namespaces)
    root.extend(extra_elements)
    return rules_doc


def add_theme(rules_doc, theme, parser=None, absolute_prefix=None,
              read_network=False):
    if not read_network and \
            isinstance(theme, string_types) and \
            theme[:6] in ('ftp://', 'http:/', 'https:'):
        raise ValueError("Supplied theme '%s', "
                         "but network access denied." % theme)
    if absolute_prefix is None:
        absolute_prefix = ''
    if parser is None:
        parser = etree.HTMLParser()
    root = rules_doc.getroot()
    element = root.makeelement(fullname(namespaces['diazo'], 'theme'))
    root.append(element)
    theme_doc = etree.parse(theme, parser=parser)
    expand_theme(element, theme_doc, absolute_prefix)
    return rules_doc


def fixup_theme_comment_selectors(rules):
    """Comments must be converted to <xsl:comment> to be output, doing it early
    allows them to get an xml:id so they can be matched in the theme. The theme
    selector needs rewriting to replace comment() with xsl:comment
    """
    for element in rules.xpath("//@theme[contains(., 'comment()')]/.."):
        element.attrib['theme'] = element.attrib['theme'].replace(
            'comment()', 'xsl:comment')
    return rules


def process_rules(rules, theme=None, extra=None, trace=None, css=True,
                  xinclude=True, absolute_prefix=None, includemode=None,
                  update=True, parser=None, rules_parser=None,
                  read_network=False, stop=None):
    if trace:
        trace = '1'
    else:
        trace = '0'
    if rules_parser is None:
        rules_parser = etree.XMLParser(recover=False)
    rules_doc = etree.parse(rules, parser=rules_parser)
    if stop == 0:
        return rules_doc
    if parser is None:
        parser = etree.HTMLParser()
    if xinclude:
        # XXX: read_network limitation not yet supported
        #   for xinclude
        rules_doc.xinclude()
    if stop == 1:
        return rules_doc
    rules_doc = add_identifiers(rules_doc)
    if stop == 2 or stop == 'add_identifiers':
        return rules_doc
    if update:
        rules_doc = update_namespace(rules_doc)
    if stop == 3:
        return rules_doc
    if css:
        rules_doc = convert_css_selectors(rules_doc)
    if stop == 4:
        return rules_doc
    rules_doc = fixup_theme_comment_selectors(rules_doc)
    if stop == 5:
        return rules_doc
    rules_doc = expand_themes(rules_doc, parser, absolute_prefix, read_network)
    if theme is not None:
        rules_doc = add_theme(rules_doc, theme, parser, absolute_prefix,
                              read_network)
    if stop == 6:
        return rules_doc
    if includemode is None:
        includemode = 'document'
    includemode = "'%s'" % includemode
    rules_doc = normalize_rules(rules_doc, includemode=includemode)
    if stop == 7:
        return rules_doc
    rules_doc = apply_conditions(rules_doc)
    if stop == 8:
        return rules_doc
    rules_doc = merge_conditions(rules_doc)
    if stop == 9:
        return rules_doc
    rules_doc = fixup_themes(rules_doc)
    if stop == 10:
        return rules_doc
    rules_doc = annotate_themes(rules_doc)
    if stop == 11:
        return rules_doc
    rules_doc = include(rules_doc)
    if stop == 12:
        return rules_doc
    rules_doc = annotate_rules(rules_doc)
    if stop == 13:
        return rules_doc
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
    root = rules_doc.getroot()
    if not root.tail:
        root.tail = '\n'
    rules_doc.write(options.output, pretty_print=options.pretty_print)


if __name__ == '__main__':
    main()
