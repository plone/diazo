
from lxml import etree

class XDV:

    def __init__(self, testnumber):
        testnumber = testnumber
        themefn = "theme.html"
        rulesfn = "rules.xml"
        contentfn = "content.html"

        themedoc = etree.ElementTree(file=themefn)
        contentdoc = etree.ElementTree(file=contentfn)

        compilerfn = "compiler.xsl"
        compilerdoc = etree.ElementTree(file=compilerfn)
        compiler = etree.XSLT(compilerdoc)

        # Make a compiled version
        params = {
            'rulesuri': rulesfn,
            'boilerplate': 'boilerplate.xsl',
            }
        ct = compiler(themedoc, **params)
        print str(ct)

def main():
    xdv = XDV("01")


if __name__ == "__main__":
    main()
