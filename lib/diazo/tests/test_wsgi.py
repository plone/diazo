import sys
import os.path

try:
    import unittest2 as unittest
except ImportError:
    import unittest

if __name__ == '__main__':
    __file__ = sys.argv[0]


def testfile(filename):
    return '/'.join(('file://',) + os.path.split(os.path.abspath(
        os.path.dirname(__file__))) + ('test_wsgi_files', filename,))

HTML = b"""\
<html>
    <body>
        <h1>Content title</h1>
        <div id="content">Content content</div>
    </body>
</html>
"""

HTML_ALTERNATIVE = b"""\
<html>
    <body>
        <h1>Content title</h1>
        <div id="content">Alternative content</div>
    </body>
</html>
"""

XSLT = b"""\
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
    <xsl:template match="/">
    <html>
        <head>
            <title>Transformed</title>
        </head>
        <body>
            <xsl:copy-of select="//div[@id='content']" />
        </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
"""

XSLT_XHTML = b"""\
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes"
    media-type="application/xhtml+xml" encoding="UTF-8"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
  <xsl:template match="/">
    <html>
      <head>
        <title>Transformed</title>
      </head>
      <body>
        <xsl:copy-of select="//div[@id='content']" />
        <br/>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
"""

XSLT_HTML = b"""\
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
  <xsl:output method="html" indent="no" omit-xml-declaration="yes"
      media-type="text/html" encoding="UTF-8"
      doctype-public="-//W3C//DTD HTML 4.01//EN"
      doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>
  <xsl:template match="/">
    <html>
        <head>
            <title>Transformed</title>
        </head>
        <body>
            <xsl:copy-of select="//div[@id='content']" />
            <br/>
        </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
"""

# Note that this can only work with an html output method. Setting the doctype
# on the middleware along with the xml output method and an XHTML 1.0 doctype
# in the stylesheet is required for XHTML compatible output.
XSLT_HTML5 = b"""\
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
    <xsl:template match="/">
    <xsl:text
      disable-output-escaping="yes">&lt;!DOCTYPE html&gt;&#10;</xsl:text>
    <html>
        <head>
            <title>Transformed</title>
        </head>
        <body>
            <xsl:copy-of select="//div[@id='content']" />
            <br/>
        </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
"""

XSLT_PARAM = b"""\
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
    <xsl:param name="someparam">defaultvalue</xsl:param>
    <xsl:template match="/">
    <html>
        <head>
            <title>Transformed</title>
        </head>
        <body>
            <xsl:copy-of select="//div[@id='content']" />
            <p><xsl:value-of select="$someparam" /></p>
        </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
"""


class TestXSLTMiddleware(unittest.TestCase):

    def test_transform_filename(self):
        import tempfile
        import os

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        _, filename = tempfile.mkstemp()
        with open(filename, 'wb') as fp:
            fp.write(XSLT)

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, filename=filename)
        os.unlink(filename)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Type'],
                         'text/html; charset=UTF-8')
        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_transform_tree(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Type'],
                         'text/html; charset=UTF-8')
        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_head_request(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Length', str(len(HTML)))]
            start_response(status, response_headers)
            return ['']  # Empty response for HEAD request

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        env = dict(REQUEST_METHOD='HEAD')
        request = Request.blank('/', environ=env)
        # The *real* test is whether or not an exception is raised here.
        response = request.get_response(app)

        # Response headers for HEAD request must be updated.
        self.assertEqual(response.headers['Content-Type'],
                         'text/html; charset=UTF-8')
        self.assertEqual(response.headers.get('Content-Length'), None)
        self.assertFalse(response.body)

    def test_update_content_length(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Length', str(len(HTML)))]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT),
                             update_content_length=True)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Length'], '178')

    def test_dont_update_content_length(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Length', '1')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers.get('Content-Length'), None)

    def test_content_length_zero(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Length', '0')]
            start_response(status, response_headers)
            return ['']

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT),
                             update_content_length=True)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Length'], '0')

    def test_content_empty(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-MD5',
                                    'd41d8cd98f00b204e9800998ecf8427e')]
            start_response(status, response_headers)
            return [b'']

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT),
                             update_content_length=True)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-MD5'],
                         'd41d8cd98f00b204e9800998ecf8427e')

    def test_content_range(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            content_length = len(HTML)
            content_range = 'bytes %d-%d/%d' % (0,
                                                content_length - 1,
                                                content_length)
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Range', content_range),
                                ('Content-Length', str(content_length))]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertFalse('Content-Range' in response.headers)

    def test_no_content_length(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT),
                             set_content_length=False)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertFalse('Content-Length' in response.headers)

    def test_doctype_html(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Type'],
                         'text/html; charset=UTF-8')

    def test_doctype_xhtml(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_XHTML))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.headers['Content-Type'],
                         'application/xhtml+xml; charset=UTF-8')

    def test_doctype_html5(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_XHTML),
                             doctype="<!DOCTYPE html>")

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(response.body.startswith(b"<!DOCTYPE html>\n<html"))

    def test_ignored_extension(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT),
                             ignored_extensions=('html',))

        request = Request.blank('/index.html')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_diazo_off_request_header(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        request.headers['X-Diazo-Off'] = 'yes'
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        request = Request.blank('/')
        request.headers['X-Diazo-Off'] = 'no'
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_diazo_off_response_header(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('X-Diazo-Off', 'yes')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('X-Diazo-Off', 'no')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_non_html_content_type(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/plain')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_content_encoding(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html'),
                                ('Content-Encoding', 'zip')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_301(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '301 MOVED PERMANENTLY'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_302(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '302 MOVED'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_304(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '304 NOT MODIFIED'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_204(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '204 NO CONTENT'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_401(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application1(environ, start_response):
            status = '401 UNAUTHORIZED'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application1, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertEqual(response.body, HTML)

        def application2(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application2, {}, tree=etree.fromstring(XSLT))

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_html_serialization(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {}, tree=etree.fromstring(XSLT_HTML))
        request = Request.blank('/')
        response = request.get_response(app)

        # HTML serialisation
        self.assertTrue(
            b'<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" '
            b'"http://www.w3.org/TR/html4/strict.dtd">' in response.body)
        self.assertTrue(b'<br>' in response.body)

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_XHTML))
        request = Request.blank('/')
        response = request.get_response(app)

        # XHTML serialisation
        self.assertTrue(
            b'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" '
            b'"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
            in response.body)
        self.assertTrue(b'<br />' in response.body)

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_HTML5))
        request = Request.blank('/')
        response = request.get_response(app)

        # HTML 5 serialisation
        self.assertTrue(b'<!DOCTYPE html>' in response.body)
        self.assertTrue(b'<br/>' in response.body)

    def test_environ_param(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(
            application, {}, tree=etree.fromstring(XSLT_PARAM),
            environ_param_map={'test.param1': 'someparam'})

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(b'<p>defaultvalue</p>' in response.body)

        request = Request.blank('/')
        request.environ['test.param1'] = 'value1'
        response = request.get_response(app)

        self.assertTrue(b'<p>value1</p>' in response.body)

    def test_params(self):
        from lxml import etree

        from diazo.wsgi import XSLTMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_PARAM))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(b'<p>defaultvalue</p>' in response.body)

        app = XSLTMiddleware(application, {},
                             tree=etree.fromstring(XSLT_PARAM),
                             someparam='value1')
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(b'<p>value1</p>' in response.body)


class TestDiazoMiddleware(unittest.TestCase):

    def test_simple_transform(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {},
                              testfile('simple_transform.xml'))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_doctype_html5(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {},
                              testfile('simple_transform.xml'),
                              doctype="<!DOCTYPE html>")
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(response.body.startswith(b"<!DOCTYPE html>\n<html"))

    def test_with_theme(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {}, testfile('explicit_theme.xml'),
                              theme=testfile('theme.html'))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_absolute_prefix(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {},
                              testfile('simple_transform.xml'))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)
        self.assertTrue(
            b'<link rel="stylesheet" href="./theme.css" />' in response.body)

        app = DiazoMiddleware(application, {},
                              testfile('simple_transform.xml'),
                              prefix='/static')
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)
        self.assertTrue(
            b'<link rel="stylesheet" href="/static/theme.css" />'
            in response.body)

    def test_path_param(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {}, testfile('path_param.xml'))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertFalse(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

        request = Request.blank('/index.html')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_custom_environ_param(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {}, testfile('custom_param.xml'),
                              environ_param_map={'test.param1': 'someparam'})

        request = Request.blank('/')
        response = request.get_response(app)

        self.assertFalse(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

        request = Request.blank('/')
        request.environ['test.param1'] = 'value1'
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

        request = Request.blank('/')
        request.environ['test.param1'] = 'value2'
        response = request.get_response(app)

        self.assertFalse(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_custom_param(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)
            return [HTML]

        app = DiazoMiddleware(application, {}, testfile('custom_param.xml'),
                              someparam='value1')
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Content content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

        app = DiazoMiddleware(application, {}, testfile('custom_param.xml'),
                              someparam='value2')
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertFalse(
            b'<div id="content">Content content</div>' in response.body)
        self.assertTrue(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_subrequest(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)

            request = Request(environ)
            if request.path.endswith('/other.html'):
                return [HTML_ALTERNATIVE]
            else:
                return [HTML]

        app = DiazoMiddleware(application, {}, testfile('subrequest.xml'))
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(
            b'<div id="content">Alternative content</div>' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

    def test_esi(self):
        from diazo.wsgi import DiazoMiddleware
        from webob import Request

        def application(environ, start_response):
            status = '200 OK'
            response_headers = [('Content-Type', 'text/html')]
            start_response(status, response_headers)

            request = Request(environ)
            if request.path.endswith('/other.html'):
                return [HTML_ALTERNATIVE]
            else:
                return [HTML]

        app = DiazoMiddleware(application, {}, testfile('esi.xml'),
                              filter_xpath=True)
        request = Request.blank('/')
        response = request.get_response(app)

        self.assertTrue(b'''<esi:include src="/other.html?;'''
                        b'''filter_xpath=//*[@id%20=%20'content']">'''
                        b'''</esi:include>''' in response.body)
        self.assertFalse(
            b'<div id="content">Theme content</div>' in response.body)
        self.assertTrue(b'<title>Transformed</title>' in response.body)

        request = Request.blank(
            '''/other.html?;filter_xpath=//*[@id%20=%20'content']''')
        response = request.get_response(app)
        # Strip response body in this test due too
        # https://bugzilla.gnome.org/show_bug.cgi?id=652766
        self.assertEqual(b'<div id="content">Alternative content</div>',
                         response.body.strip())


def test_suite():
    return unittest.defaultTestLoader.loadTestsFromName(__name__)
