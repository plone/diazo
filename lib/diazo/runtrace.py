#!/usr/bin/env python
import logging

from diazo.rules import process_rules
from diazo.utils import pkg_xsl

from lxml import etree
from xml.etree import ElementTree

logger = logging.getLogger('diazo')

_runtrace_to_html = pkg_xsl('runtrace_to_html.xsl')

def log_to_xml_string(error_log):
    return """
<runtrace xmlns:css="http://namespaces.plone.org/diazo/css">%s</runtrace>
    """ % "".join(l.message for l
                               in error_log
                               if l.message.startswith('<runtrace '))

def generate_runtrace(rules, error_log, rules_parser=None):
    """Annotate a rules file with the results of a transformation"""
    def condition_name(trace):
        """Generate attribute name for this entry"""
        for k in trace.attrib.keys():
            if(k == 'theme_xmlid'): continue
            if(k.startswith('{http://namespaces.plone.org/diazo/css}')): continue
            return "runtrace-"+k
    
    rules_doc = process_rules(rules, rules_parser=rules_parser,
                              stop='add_identifiers')
    trace_doc = etree.XML(log_to_xml_string(error_log))
    
    for trace in trace_doc.xpath('/runtrace/runtrace'):
        for el in rules_doc.xpath("id('"+trace.attrib['theme_xmlid']+"')"):
            el.set(condition_name(trace),trace.text or '')
    return rules_doc

def runtrace_to_html(runtrace_doc):
    """Convert the runtrace document into HTML"""
    return _runtrace_to_html(runtrace_doc)

def generate_debug_html(base_url, rules=None, error_log=None, rules_parser=None):
    """Generate an HTML node with debug info"""
    def newElement(tag, content, **kwargs):
        n = etree.Element(tag, **kwargs)
        if hasattr(content, 'tag'):
            n.append(content)
        else:
            n.text = content
        return n

    debug_output = etree.Element('div', id="diazo_debug")
    debug_output.attrib['style'] = "display:none"
    debug_output.attrib['data-diazoiframe'] = "diazo_debug"
    debug_output.attrib['data-iframe-style'] = ""
    debug_output.attrib['data-iframe-alignment'] = "bottom"
    debug_output.attrib['data-iframe-resources'] = base_url + '/diazo-debug.css'
    runtrace_doc = generate_runtrace(rules, error_log, rules_parser)
    debug_output.append(newElement('section',
        runtrace_to_html(runtrace_doc).getroot(),
        id="diazo_runtrace"
    ))
    #debug_output.insert(-1,
    #    newElement('pre',etree.tostring(compiledTheme,pretty_print=True),
    #    id="diazo_debug_generated_xslt"
    #))
    #debug_output.insert(-1,
    #    newElement('pre',json.dumps(self._formatErrorLog(transform.error_log)),
    #    id="diazo_debug_error_log"
    #))
    debug_output.append(newElement('script', " ",
        text="text/javascript",
        src=base_url + '/diazo-iframe.js',
    ))
    return debug_output
