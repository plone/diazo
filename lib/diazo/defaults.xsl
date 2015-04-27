<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    xmlns:dv="http://namespaces.plone.org/diazo"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl str css dv dyn xhtml">

    <xsl:variable name="normalized_path"><xsl:value-of select="$path"/><xsl:if test="substring($path, string-length($path)) != '/'">/</xsl:if></xsl:variable>

    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"
        media-type="text/html" encoding="UTF-8"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
        />

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()">
        <!-- Filter out quoted &#13; -->
        <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')"/>
    </xsl:template>

    <xsl:template match="style/text()|script/text()">
        <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')" disable-output-escaping="yes"/>
    </xsl:template>

    <xsl:template match="/html/@xmlns|/html/@*[local-name()='xml:lang']">
        <!-- Filter out -->
    </xsl:template>

    <xsl:template match="*" mode="before-content"/>
    <xsl:template match="*" mode="before-content-children"/>
    <xsl:template match="*" mode="after-content"/>
    <xsl:template match="*" mode="after-content-children"/>
    <xsl:template match="*" mode="replace-content">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="." mode="before-content-children"/>
            <xsl:apply-templates select="node()"/>
            <xsl:apply-templates select="." mode="after-content-children"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
