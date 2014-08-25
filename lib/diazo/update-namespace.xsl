<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    >

    <!-- Update from old to new namespace -->

    <xsl:template match="*[namespace-uri() = 'http://openplans.org/deliverance']">
        <xsl:element name="{local-name()}" namespace="http://namespaces.plone.org/diazo">
            <xsl:if test="not(@if-content) and @content and (not(@nocontent) or @nocontent='theme')">
                <xsl:attribute name="if-content"></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*|node()" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="@nocontent">
        <!-- remove this -->
    </xsl:template>

    <xsl:template match="*[namespace-uri() = 'http://namespaces.plone.org/xdv']">
        <xsl:element name="{local-name()}" namespace="http://namespaces.plone.org/diazo">
            <xsl:apply-templates select="@*|node()" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="@*[namespace-uri() = 'http://namespaces.plone.org/xdv+css']">
        <xsl:attribute name="css:{local-name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="@*[namespace-uri() = 'http://namespaces.plone.org/diazo+css']">
        <xsl:attribute name="css:{local-name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
