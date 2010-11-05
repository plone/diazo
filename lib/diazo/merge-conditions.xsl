<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:template match="diazo:*">
        <xsl:variable name="conditions" select="ancestor-or-self::diazo:*[@condition]"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="$conditions">
                <xsl:attribute name="merged-condition">
                    <xsl:for-each select="$conditions"><xsl:value-of select="@condition"/><xsl:if test="position() != last()"> and </xsl:if></xsl:for-each>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
