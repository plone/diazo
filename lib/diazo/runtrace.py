#!/usr/bin/env python
import logging

from lxml import etree
from xml.etree import ElementTree

logger = logging.getLogger('diazo')

def log_to_xml_string(error_log):
    return """
<runtrace xmlns:css="http://namespaces.plone.org/diazo/css">%s</runtrace>
    """ % "".join(l.message for l
                               in error_log
                               if l.message.startswith('<runtrace '))

def css_first(a, b):
    # Want CSS-namespaced rules first
    if(a.startswith('{http://namespaces.plone.org/diazo/css}')): return -1
    if(b.startswith('{http://namespaces.plone.org/diazo/css}')): return 1
    return 0

def generate_runtrace(rules, error_log, rules_parser=None):
    if rules_parser is None:
        rules_parser = etree.XMLParser(recover=False)
    rules_doc = etree.parse(rules, parser=rules_parser)
    trace_doc = etree.XML(log_to_xml_string(error_log))
    
    # Put trace_doc in rules_doc so we can reference it in XPath
    rules_doc.getroot().append(trace_doc)
    for i,trace in enumerate(rules_doc.xpath('/*/runtrace/runtrace')):
        # Prefer matching on css: element
        attribs = sorted(trace.attrib.keys(),css_first)
        attrib_path = "/*/runtrace/runtrace[%d]/@%s" % (
            i+1,
            attribs[0].replace('{http://namespaces.plone.org/diazo/css}','dcss:'),
        )
        for el in rules_doc.xpath("//@*[name()=name(%(path)s) and string() = string(%(path)s)]/.." % dict(path=attrib_path)
                                 , namespaces=dict(dcss="http://namespaces.plone.org/diazo/css")):
            if el.tag == 'runtrace': continue
            el.set("runtrace-"+attribs[-1],trace.text)
    rules_doc.getroot().remove(trace_doc)
    return rules_doc
