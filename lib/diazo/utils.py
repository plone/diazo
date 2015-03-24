import logging
import pkg_resources
import sys

from lxml import etree
from optparse import OptionParser
from six import string_types, integer_types, PY3

if PY3:
    stdout = sys.stdout.buffer
else:
    stdout = sys.stdout

strparam = etree.XSLT.strparam

logger = logging.getLogger('diazo')

namespaces = dict(
    diazo="http://namespaces.plone.org/diazo",
    css="http://namespaces.plone.org/diazo/css",
    old1="http://openplans.org/deliverance",
    old2="http://namespaces.plone.org/xdv",
    oldcss1="http://namespaces.plone.org/xdv+css",
    oldcss2="http://namespaces.plone.org/diazo+css",
    xml="http://www.w3.org/XML/1998/namespace",
    xsl="http://www.w3.org/1999/XSL/Transform",
)


def localname(name):
    return name.rsplit('}', 1)[1]


def namespace(name):
    return name.rsplit('}', 1)[0][1:]


def fullname(namespace, name):
    return '{%s}%s' % (namespace, name)


AC_READ_FILE = etree.XSLTAccessControl(
    read_file=True, write_file=False, create_dir=False, read_network=False,
    write_network=False)
AC_READ_NET = etree.XSLTAccessControl(
    read_file=True, write_file=False, create_dir=False, read_network=True,
    write_network=False)


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


def pkg_parse(name, parser=None):
    with open(pkg_resources.resource_filename('diazo', name)) as f:
        return etree.parse(f, parser=parser)


def pkg_xsl(name, parser=None):
    return LoggingXSLTWrapper(etree.XSLT(pkg_parse(name, parser)), logger)


def quote_param(value):
    """Quote for passing as an XSL parameter.

    Works with strings, booleans, numbers and None.
    """

    if isinstance(value, string_types):
        return strparam(value)
    elif isinstance(value, bool):
        return value and 'true()' or 'false()'
    elif isinstance(value, integer_types + (float,)):
        value = repr(value)
    elif value is None:
        return '/..'
    else:
        raise ValueError("Cannot convert %s", value)


def split_params(s):
    """Turn foo,bar=baz into {'foo': None, 'bar': 'baz'}
    """

    xsl_params = {}
    for param in s.split(','):
        tokens = [t.strip() for t in param.split('=')]
        xsl_params[tokens[0]] = len(tokens) > 1 and tokens[1] or None
    return xsl_params


def _createOptionParser(usage):
    parser = OptionParser(usage=usage)
    parser.add_option("-o", "--output", metavar="output.xsl",
                      help="Output filename (instead of stdout)",
                      dest="output", default=stdout)
    parser.add_option("-p", "--pretty-print", action="store_true",
                      help="Pretty print output (may alter rendering in "
                           "browser)",
                      dest="pretty_print", default=False)
    parser.add_option("--trace", action="store_true",
                      help="Compiler trace logging",
                      dest="trace", default=False)
    parser.add_option("-a", "--absolute-prefix", metavar="/",
                      help="relative urls in the theme file will be made into "
                           "absolute links with this prefix.",
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
                      help="Diazo rules file",
                      dest="rules", default=None)
    parser.add_option("-c", "--custom-parameters",
                      metavar="param1,param2=defaultval",
                      help="Comma-separated list of custom parameter names "
                           "with optional default values that the compiled "
                           "theme will be able accept when run",
                      dest="xsl_params", default=None)
    parser.add_option("-e", "--extra", metavar="extra.xsl",
                      help="Extra XSL to be included in the transform "
                           "(depracated, use inline xsl in the rules instead)",
                      dest="extra", default=None)
    return parser
