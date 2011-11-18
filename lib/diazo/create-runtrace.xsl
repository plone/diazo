<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:dv="http://namespaces.plone.org/diazo"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:set="http://exslt.org/sets"
    xmlns:str="http://exslt.org/strings"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    exclude-result-prefixes="dv exsl xml">

    <xsl:template name="run-tests">
        <xsl:param name="attrs"/>
        <xsl:for-each select="$attrs">
            <xsl:variable name="attr" select="."/>
            <xsl:if test="not(../@*[namespace-uri() = 'http://namespaces.plone.org/diazo/css' and local-name() = name($attr)])">
                <xsl:copy-of select="."/>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$attrs">
            <xsl:variable name="attr" select="."/>
            <xsl:element name="xsl:attribute">
                <xsl:attribute name="name">runtrace:<xsl:value-of select="local-name($attr)" /></xsl:attribute>
                <xsl:element name="xsl:value-of">
                    <xsl:attribute name="select">count(<xsl:value-of select="$attr"/>)</xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*[name() != 'if-content' and name() != 'content']" />
            <xsl:call-template name="run-tests">
                <xsl:with-param name="attrs" select="@*[name() = 'if-content' or name() = 'content']" />
            </xsl:call-template>
            <xsl:apply-templates select="node()" />
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
