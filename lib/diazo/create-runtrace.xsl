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

    <xsl:template match="@*[namespace-uri() != '']" mode="escaped">
        <xsl:value-of select="concat(' css-',local-name(),'=&quot;',.,'&quot;')"/>
    </xsl:template>

    <xsl:template match="@*[name() = 'if-content' or name() = 'content']" mode="escaped">
        <xsl:variable name="attr" select="."/>
        <xsl:if test="not(../@*[namespace-uri() = 'http://namespaces.plone.org/diazo/css' and local-name() = name($attr)])">
            <!-- Only include if there wasn't a matching css attribute -->
        </xsl:if>
            <xsl:value-of select="concat(' ',name($attr),'=&quot;',$attr,'&quot;')"/>
        <xsl:value-of select="concat(' runtrace-',name($attr),'=&quot;')"/>
        <xsl:element name="xsl:value-of"><xsl:attribute name="select">count(<xsl:value-of select="$attr"/>)</xsl:attribute></xsl:element>
        <xsl:text>"</xsl:text>
    </xsl:template>

    <xsl:template match="@*" mode="escaped"><xsl:value-of select="concat(' ',name(),'=&quot;',.,'&quot;')"/></xsl:template>

    <xsl:template match="node()" mode="escaped">
        <xsl:text>&#10;&lt;</xsl:text>
        <xsl:value-of select="name()"/><xsl:apply-templates select="@*" mode="escaped"/>

        <xsl:choose>
            <xsl:when test="./*">
                <xsl:text>&gt;</xsl:text>
                <xsl:apply-templates select="./*" mode="escaped"/>
                <xsl:text>&lt;/</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>&gt;&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
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

    <xsl:template match="/">
        <dv:runtrace><xsl:apply-templates mode="escaped"/><css:moo/></dv:runtrace>
    </xsl:template>

</xsl:stylesheet>
