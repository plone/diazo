<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:str="http://exslt.org/strings"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <!--
        Fixup the theme's html
    -->

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="html/@xmlns" priority="5">
        <!-- setting the namespace to xhtml mucks up the included namespaces, so cheat -->
        <xsl:if test="//diazo:*/@method='esi'">
            <!-- when we have another namespace defined, libxml2/xmlsave.c will not magically add the xhtml ns for us -->
            <xsl:element name="xsl:attribute">
                <xsl:attribute name="name">xmlns</xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="html/@*[name() = 'xml:lang']" priority="5">
        <!-- Filter it out, rely on lang attribute -->
    </xsl:template>

    <xsl:template match="text()">
        <!-- Filter out quoted &#13; -->
        <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')"/>
    </xsl:template>

    <xsl:template match="style/text()|script/text()">
        <xsl:element name="xsl:variable">
            <xsl:attribute name="name">tag_text</xsl:attribute>
            <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')"/>
        </xsl:element>
        <xsl:element name="xsl:value-of">
            <xsl:attribute name="select">$tag_text</xsl:attribute>
            <xsl:attribute name="disable-output-escaping">yes</xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:theme//comment() | //diazo:*[@theme]//comment()">
        <xsl:element name="xsl:comment"><xsl:value-of select="."/></xsl:element>
    </xsl:template>

</xsl:stylesheet>
