from lxml import etree
import logging
import pkg_resources

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
    return LoggingXSLTWrapper(etree.XSLT(etree.parse(pkg_resources.resource_filename('xdv', name), parser=parser)), logger)
