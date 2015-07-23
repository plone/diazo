from copy import deepcopy
from lxml import etree
import os
from diazo.compiler import compile_theme


class SubTransform(etree.XSLTExtension):

    def __init__(self, conf):

        super(SubTransform, self).__init__()
        self.conf = conf

    def execute(self, context, self_node, input_node, output_parent):

        rules = self_node.attrib["rules"]

        rules = os.path.join(self.conf['diazo_path'], rules)

        compiled_theme = compile_theme(rules)

        transformer = etree.XSLT(compiled_theme)

        transformed = transformer(deepcopy(input_node))

        output_parent.append(transformed.getroot())
