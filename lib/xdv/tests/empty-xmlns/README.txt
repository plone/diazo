UPDATE: The problems with xpath="" are now fixed. The duplicate xmlns seemed to be an artefact of the test runner.

This test demonstrates the problem with xmlns="" and incidentally an issue with 
the way test_nodes.py works vis-a-vis xsltproc / mod_transform / dv.xdvserver.

xdv$ xsltproc --nonet --html --stringparam rulesuri tests/008/rules.xml compiler.xsl tests/008/theme.html | xsltproc --nonet --html - tests/008/content.html 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title xmlns="">A Deeper Look At xdv</title>
  </head>
  <body>
    <div xmlns="" id="wrapper" class="foo">
            <div id="content">
                <p>boo bar baz</p>
            </div>
        </div>
  </body>
</html>


xdv/tests$ python test_nodes.py 008
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>A Deeper Look At xdv</title>
  </head>
  <body>
    <div id="wrapper" class="foo">
            <div id="content">
                <p>boo bar baz</p>
            </div>
        </div>
  </body>
</html>


Note the double xmlns="http://www.w3.org/1999/xhtml" on the html node of the test_nodes.py version and no xmlns="" anywhere.
