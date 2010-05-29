from lxml import etree

namespaces = dict(
    xdv="http://namespaces.plone.org/xdv",
    css="http://namespaces.plone.org/xdv+css",
    old="http://openplans.org/deliverance",
    )

def localname(name):
    return name.rsplit('}', 1)[1]

def fullname(namespace, name):
    return '{%s}%s' % (namespace, name)

AC_READ_FILE = etree.XSLTAccessControl(read_file=True, write_file=False, create_dir=False, read_network=False, write_network=False)
AC_READ_NET = etree.XSLTAccessControl(read_file=True, write_file=False, create_dir=False, read_network=True, write_network=False)
