import logging
import pkg_resources
import sys

from lxml import etree
from optparse import OptionParser

logger=logging.getLogger('xdv')

namespaces = dict(
    xdv="http://namespaces.plone.org/xdv",
    css="http://namespaces.plone.org/xdv+css",
    old="http://openplans.org/deliverance",
    xsl="http://www.w3.org/1999/XSL/Transform",
    )

def localname(name):
    return name.rsplit('}', 1)[1]

def fullname(namespace, name):
    return '{%s}%s' % (namespace, name)

AC_READ_FILE = etree.XSLTAccessControl(read_file=True, write_file=False, create_dir=False, read_network=False, write_network=False)
AC_READ_NET = etree.XSLTAccessControl(read_file=True, write_file=False, create_dir=False, read_network=True, write_network=False)

class CustomResolver(etree.Resolver):
    def __init__(self, data):
        self.data = data
        
    def resolve(self, url, pubid, context):
        output = self.data.get(url)
        if output is not None:
            return self.resolve_string(output, context)


class LoggingXSLTWrapper:
    def __init__(self, xslt, logger):
        self.xslt = xslt
        self.logger = logger
    def __call__(self, *args, **kw):
        result = self.xslt(*args, **kw)
        for msg in self.xslt.error_log:
            if msg.type == etree.ErrorTypes.ERR_OK:
                self.logger.debug(msg.message)
            else:
                self.logger.debug(msg)
        return result


def pkg_xsl(name, parser=None):
    return LoggingXSLTWrapper(etree.XSLT(etree.parse(open(pkg_resources.resource_filename('xdv', name)), parser=parser)), logger)


def _createOptionParser(usage):
    parser = OptionParser(usage=usage)
    parser.add_option("-o", "--output", metavar="output.xsl",
                      help="Output filename (instead of stdout)",
                      dest="output", default=sys.stdout)
    parser.add_option("-p", "--pretty-print", action="store_true",
                      help="Pretty print output (may alter rendering in browser)",
                      dest="pretty_print", default=False)
    parser.add_option("--trace", action="store_true",
                      help="Compiler trace logging",
                      dest="trace", default=False)
    parser.add_option("-a", "--absolute-prefix", metavar="/",
                      help="relative urls in the theme file will be made into absolute links with this prefix.",
                      dest="absolute_prefix", default=None)
    parser.add_option("-i", "--includemode", metavar="INC",
                      help="include mode (document, ssi, ssiwait or esi)",
                      dest="includemode", default=None)
    parser.add_option("-n", "--network", action="store_true",
                      help="Allow reads to the network to fetch resources",
                      dest="read_network", default=False)
    parser.add_option("-t", "--theme", metavar="theme.html",
                      help="Theme file",
                      dest="theme", default=None)
    parser.add_option("-r", "--rules", metavar="rules.xml",
                      help="XDV rules file", 
                      dest="rules", default=None)
    parser.add_option("-e", "--extra", metavar="extra.xsl",
                      help="Extra XSL to be included in the transform (depracated, use inline xsl in the rules instead)",
                      dest="extra", default=None)
    return parser
