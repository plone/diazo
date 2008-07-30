<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dv="http://openplans.org/deliverance" xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes="exsl dv" version="1.0">
    <xsl:template match="/">

        <!-- Pass incoming content through initial-stage filter. -->
        <xsl:variable name="initial-stage-rtf">
            <xsl:apply-templates select="/" mode="initial-stage"/>
        </xsl:variable>
        <xsl:variable name="initial-stage" select="exsl:node-set($initial-stage-rtf)"/>

        <!-- Now apply the theme to the initial-stage content -->
        <xsl:variable name="themedcontent-rtf">
            <xsl:apply-templates select="$initial-stage" mode="apply-theme"/>
        </xsl:variable>
        <xsl:variable name="content" select="exsl:node-set($themedcontent-rtf)"/>

        <!-- We're done, so generate some output by passing 
            through a final stage. -->
        <xsl:apply-templates select="$content" mode="final-stage"/>

    </xsl:template>

    <!-- 
    
        Utility templates
    -->
    <xsl:template match="none" mode="insert-drop-rules">
        <!-- The compiler looks for this and replaces 
        the @match and @mode. -->
    </xsl:template>
    <xsl:template match="node()|@*" mode="initial-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="initial-stage"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/" mode="apply-theme">
        <dv:insert/>
    </xsl:template>
    <xsl:template match="node()|@*" mode="final-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="final-stage"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
