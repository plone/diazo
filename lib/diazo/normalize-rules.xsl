<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:css="http://namespaces.plone.org/diazo+css"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    >

    <xsl:param name="includemode">document</xsl:param>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="diazo:rules | //diazo:rules/diazo:*">
        <xsl:element name="diazo:{local-name()}">
            <xsl:if test="@href and not(@method) and local-name() != 'theme'">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xhtml:* | diazo:*">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
