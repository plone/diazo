<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    >

    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"
        media-type="text/html" encoding="UTF-8"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
        />

    <!-- Filter document by xpath -->
    <xsl:param name="xpath">/</xsl:param>

    <xsl:template match="/">
        <xsl:apply-templates select="$xpath"/>
        <xsl:if test="not($xpath)">
            <!-- Make sure we at least return something to avoid errors -->
            <xsl:comment>WARNING: No content found</xsl:comment>
        </xsl:if>
    </xsl:template>

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

</xsl:stylesheet>
