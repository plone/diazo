
from lxml import etree

class XDV:

    def __init__(self, testnumber):
        testnumber = testnumber
        themefn = "tests/theme-%s.html"      % testnumber
        rulesfn = "tests/rules-%s.xml"       % testnumber
        contentfn = "tests/content-%s.html"  % testnumber

        themedoc = etree.ElementTree(file=themefn)
        contentdoc = etree.ElementTree(file=contentfn)

        compilerfn = "compiler.xsl"
        compilerdoc = etree.ElementTree(file=compilerfn)
        compiler = etree.XSLT(compilerdoc)

        # Make a compiled version
        params = {
            'rulesuri': rulesfn,
            }
        ct = compiler(themedoc, **params)
        for msg in compiler.error_log:
            print msg
        print str(ct)

def main():
    xdv = XDV("00")


if __name__ == "__main__":
    main()
