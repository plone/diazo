<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    version="1.0"
    exclude-result-prefixes="xhtml">
    <xsl:template match="/">
    <html>
        <head>
            <title>Used response header</title>
        </head>
        <body>
            <xsl:copy-of select="//div[@id='content']" />
        </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
