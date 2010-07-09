<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xdv="http://namespaces.plone.org/xdv"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:template match="xdv:*[@if-content]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="condition">
                <xsl:choose>
                    <xsl:when test="@if-content = ''">
                        <xsl:value-of select="@content"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@if-content"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
