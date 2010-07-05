<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dv="http://namespaces.plone.org/xdv"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl str dv xhtml">
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes"
      media-type="text/html" encoding="utf-8"
      doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
      doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
    
    <xsl:template match="/">
        <dv:insert/>
        <xsl:choose>
            <xsl:when test="use-theme1">
                <xsl:apply-templates select="." mode="theme1-id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="none" mode="insert-drop-rules">
        <!-- The compiler looks for this and replaces 
        the @match and @mode. -->
    </xsl:template>

    <!-- 
    
        Utility templates
    -->
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="pre/text()">
        <!-- Filter out quoted &#13; -->
        <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')"/>
    </xsl:template>

    <xsl:template match="style/text()|script/text()">
        <xsl:value-of select="." disable-output-escaping="yes"/>
    </xsl:template>

    <!-- 
    
        Extra templates
    -->
    <dv:insert-extra/>
</xsl:stylesheet>
