#!/usr/bin/env python
import logging

from diazo.rules import process_rules
from diazo.utils import pkg_xsl

from lxml import etree

logger = logging.getLogger('diazo')

_runtrace_to_html = pkg_xsl('runtrace_to_html.xsl')


def log_to_xml_string(error_log):
    return """
<runtrace xmlns:css="http://namespaces.plone.org/diazo/css">%s</runtrace>
    """ % "".join(l.message for l in error_log
                  if l.message.startswith('<runtrace '))


def generate_runtrace(rules, error_log, rules_parser=None):
    """Annotate a rules file with the results of a transformation"""
    def condition_name(trace):
        """Generate attribute name for this entry"""
        for k in trace.attrib.keys():
            if(k == 'theme_xmlid'):
                continue
            if(k.startswith('{http://namespaces.plone.org/diazo/css}')):
                continue
            return "runtrace-" + k

    rules_doc = process_rules(rules, rules_parser=rules_parser,
                              stop='add_identifiers')
    trace_doc = etree.XML(log_to_xml_string(error_log))

    for trace in trace_doc.xpath('/runtrace/runtrace'):
        for el in rules_doc.xpath("id('" + trace.attrib['theme_xmlid'] + "')"):
            el.set(condition_name(trace), trace.text or '')
    return rules_doc


def runtrace_to_html(runtrace_doc):
    """Convert the runtrace document into HTML"""
    return _runtrace_to_html(runtrace_doc)


def error_log_to_html(error_log):
    """Convert an error log into an HTML representation"""
    doc = etree.Element('ul')
    for l in error_log:
        if l.message.startswith('<runtrace '):
            continue
        el = etree.Element('li')
        el.attrib['class'] = "domain_%s level_%s type_%s" % (l.domain_name,
                                                             l.level_name,
                                                             l.type_name)
        el.text = "%s [%d:%d]" % (l.message, l.line, l.column)
        doc.append(el)
    return doc


def generate_debug_html(base_url, rules=None, error_log=None,
                        rules_parser=None):
    """Generate an HTML node with debug info"""
    def newElement(tag, content, **kwargs):
        n = etree.Element(tag, **kwargs)
        if hasattr(content, 'tag'):
            n.append(content)
        else:
            n.text = content
        return n

    debug_output_iframe = etree.Element('div', id="diazo-debug-iframe")
    debug_output_iframe.attrib['style'] = "display:none"
    debug_output_iframe.attrib['data-iframe'] = "diazo-debug"
    debug_output_iframe.attrib['data-iframe-style'] = ""
    debug_output_iframe.attrib['data-iframe-position'] = "bottom"
    debug_output_iframe.attrib['data-iframe-resources'] = \
        base_url + '/diazo-debug.css;' + \
        base_url + '/jquery-1.8.3.min.js;' + \
        base_url + '/diazo-debug.js'
    debug_output = etree.Element('div', id="diazo-debug")

    if error_log:
        debug_output.append(newElement('section',
                            error_log_to_html(error_log),
                            id="diazo_error_log"))

    try:
        runtrace_doc = generate_runtrace(rules, error_log, rules_parser)
        debug_output.append(newElement('section',
                            runtrace_to_html(runtrace_doc).getroot(),
                            id="diazo_runtrace"))
    except etree.XMLSyntaxError:
        debug_output.append(newElement('section',
                                       "Rules document could not be parsed!",
                                       id="diazo_runtrace"))

    debug_output_iframe.append(debug_output)
    debug_output_iframe.append(newElement('script', " ",
                               text="text/javascript",
                               src=base_url + '/iframe.js'))
    return debug_output_iframe
