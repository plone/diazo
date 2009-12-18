<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dv="http://namespaces.plone.org/xdv" xmlns:exsl="http://exslt.org/common" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0" exclude-result-prefixes="exsl dv xhtml">
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes" media-type="text/html" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

    <xsl:template match="/">

        <!-- Pass incoming content through initial-stage filter. -->
        <xsl:variable name="initial-stage-rtf">
            <xsl:apply-templates select="/" mode="initial-stage"/>
        </xsl:variable>
        <xsl:variable name="initial-stage" select="exsl:node-set($initial-stage-rtf)"/>

        <!-- Now apply the theme to the initial-stage content -->
        <xsl:variable name="themedcontent-rtf">
            <xsl:apply-templates select="$initial-stage" mode="apply-theme"/>
        </xsl:variable>
        <xsl:variable name="content" select="exsl:node-set($themedcontent-rtf)"/>

        <!-- We're done, so generate some output by passing 
            through a final stage. -->
        <xsl:apply-templates select="$content" mode="final-stage"/>

    </xsl:template>

    <!-- 
    
        Utility templates
    -->
    <xsl:template match="//*[@id = 'byline']" mode="initial-stage"><!--Do nothing, skip these nodes--></xsl:template>
    <xsl:template match="node()|@*" mode="initial-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="initial-stage"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/" mode="apply-theme">
        <html><head><xsl:choose><xsl:when test="/html/head/title"><xsl:copy-of select="/html/head/title"/></xsl:when><xsl:otherwise><title>Theme Page Title</title></xsl:otherwise></xsl:choose></head><body>
        <h1 class="somethemeclass"><xsl:choose><xsl:when test="/html/head/title/text()"><xsl:copy-of select="/html/head/title/text()"/></xsl:when><xsl:otherwise>Theme Page Heading</xsl:otherwise></xsl:choose></h1>
        <table border="0" height="300" cellpadding="20"><tr><td width="200" bgcolor="gray" valign="top" id="nav">
                    <h2 align="center">Navigation</h2>
                <xsl:if test="not(/html/body/div[@id='content'])"><xsl:copy-of select="//pre"/></xsl:if></td>
                <td valign="top">
                    <h1 id="pageheading"><xsl:choose><xsl:when test="/html/head/title/text()"><xsl:copy-of select="/html/head/title/text()"/></xsl:when><xsl:otherwise>Theme Page Heading</xsl:otherwise></xsl:choose></h1>
                    <div id="pagecontent"><xsl:choose><xsl:when test="/html/body/div[@id='content']/*"><xsl:copy-of select="/html/body/div[@id='content']/*"/></xsl:when><xsl:otherwise>Theme content to replace.</xsl:otherwise></xsl:choose></div>
                </td>
            </tr></table></body></html>
    </xsl:template>
    <xsl:template match="style|script|xhtml:style|xhtml:script" priority="5" mode="final-stage">
        <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="@*" mode="final-stage"/>
            <xsl:value-of select="text()" disable-output-escaping="yes"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*" priority="3" mode="final-stage">
        <!-- Move elements without a namespace into 
        the xhtml namespace. -->
        <xsl:choose>
            <xsl:when test="namespace-uri(.)">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()" mode="final-stage"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:apply-templates select="@*|node()" mode="final-stage"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node()|@*" priority="1" mode="final-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="final-stage"/>
        </xsl:copy>
    </xsl:template>

    <!-- 
    
        Extra templates
    -->
    
</xsl:stylesheet>