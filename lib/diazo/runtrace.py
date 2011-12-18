#!/usr/bin/env python
import logging

from diazo.rules import process_rules

from lxml import etree
from xml.etree import ElementTree

logger = logging.getLogger('diazo')

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
            el.set(condition_name(trace),trace.text)
    return rules_doc
