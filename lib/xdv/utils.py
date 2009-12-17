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

class Resolver(etree.Resolver):

    def __init__(self, strings={}, files={}, filenames=[]):
        self.strings = {}
        self.files = {}
        self.filenames = set(filenames)

    def resolve(self, url, pubid, context):
        result = self.strings.get(url)
        if result is not None:
            return self.resolve_string(result, context)
        result = self.files.get(url)
        if result is not None:
            return self.resolve_file(result, context)
        if url in self.filenames:
            return self.resolve_filename(url, context)
