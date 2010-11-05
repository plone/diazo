<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes" media-type="text/html" encoding="utf-8"/>
    <!-- Filter document by xpath -->
    <xsl:param name="xpath">/</xsl:param>
    <xsl:template match="/">
        <xsl:apply-templates select="$xpath"/>
        <xsl:if test="not($xpath)">
            <!-- Make sure we at least return something to avoid errors -->
            <xsl:comment>WARNING: No content found</xsl:comment>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*[not(node())]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!--
                Make this valid html.
                We are unable to trigger xhtml output mode as we cannot set the doctype.
                This does the trick but oddly does not render an actual comment.
            -->
            <xsl:comment> </xsl:comment>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
