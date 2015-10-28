<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="diazo:*[@theme]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
                <diazo:synthetic>
                    <xsl:copy-of select="node()"/>
                </diazo:synthetic>
            <diazo:matches>
                <xsl:variable name="themexpath" select="@theme"/>
                <xsl:for-each select="//diazo:theme">
                    <xsl:variable name="theme-rtf">
                        <xsl:copy-of select="node()"/>
                    </xsl:variable>
                    <xsl:variable name="theme" select="exsl:node-set($theme-rtf)"/>
                    <xsl:apply-templates mode="matches" select="$theme">
                        <xsl:with-param name="themexpath" select="$themexpath"/>
                        <xsl:with-param name="themeid" select="@xml:id"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </diazo:matches>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/" mode="matches">
        <xsl:param name="themexpath"/>
        <xsl:param name="themeid"/>
        <xsl:for-each select="dyn:evaluate($themexpath)">
            <diazo:xmlid>
                <xsl:attribute name="themeid">
                    <xsl:value-of select="$themeid"/>
                </xsl:attribute>
                <xsl:value-of select="@xml:id"/>
            </diazo:xmlid>
        </xsl:for-each>
    </xsl:template>

    <!--
        Debugging support
    -->

    <xsl:template name="error-message">
        <xsl:param name="message"/>
        <xsl:message terminate="yes">ERROR: <xsl:value-of select="$message"/>&#10;    RULE: &lt;<xsl:value-of select="name()"/><xsl:for-each select="@*">
            <xsl:value-of select="' '"/><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"</xsl:for-each>/&gt;
        </xsl:message>
    </xsl:template>


</xsl:stylesheet>
