namespaces = dict(
    xdv="http://namespaces.plone.org/xdv",
    css="http://namespaces.plone.org/xdv+css",
    old="http://openplans.org/deliverance",
    )

def localname(name):
    return name.rsplit('}', 1)[1]

def fullname(namespace, name):
    return '{%s}%s' % (namespace, name)
