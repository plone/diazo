<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    >
    <xsl:param name="docurl"/>
    <xsl:variable name="doc" select="document($docurl)"/>

    <xsl:template match="/">
        <xsl:apply-templates select="$doc" mode="identity"/>
    </xsl:template>

    <xsl:template match="@*|node()" mode="identity">
       <xsl:copy>
          <xsl:apply-templates select="@*|node()" mode="identity"/>
       </xsl:copy>
    </xsl:template>

</xsl:stylesheet>