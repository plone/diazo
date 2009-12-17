<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:old="http://openplans.org/deliverance"
    xmlns:xdv="http://namespaces.plone.org/xdv"
    exclude-result-prefixes="xsl old xdv">

    <!-- Update from old to new namespace -->

    <xsl:template match="*[namespace-uri() = 'http://openplans.org/deliverance']">
        <xsl:element name="{name()}" namespace="http://namespaces.plone.org/xdv">
            <xsl:apply-templates select="@* | node()" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" />
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
