from lxml import etree

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
