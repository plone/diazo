<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:str="http://exslt.org/strings"
    >

    <xsl:param name="includemode">document</xsl:param>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="diazo:rules | //diazo:rules/diazo:*">
        <xsl:element name="diazo:{local-name()}">
            <xsl:if test="@href and not(@method) and local-name() != 'theme'">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="@content-children and not(local-name() = 'replace' and not(@theme))">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/diazo:rules">
        <xsl:element name="diazo:{local-name()}">
            <xsl:attribute name="css:dummy"/>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xhtml:* | diazo:*">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:before[@theme-children]">
        <xsl:element name="diazo:prepend">
            <xsl:if test="@href and not(@method)">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="theme"><xsl:value-of select="@theme-children"/></xsl:attribute>
            <xsl:if test="@content-children">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:after[@theme-children]">
        <xsl:element name="diazo:append">
            <xsl:if test="@href and not(@method)">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="theme"><xsl:value-of select="@theme-children"/></xsl:attribute>
            <xsl:if test="@content-children">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:replace[@theme-children]|//diazo:rules/diazo:drop[@theme-children]">
        <xsl:element name="diazo:copy">
            <xsl:if test="@href and not(@method)">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="theme"><xsl:value-of select="@theme-children"/></xsl:attribute>
            <xsl:if test="@content-children">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:drop[@theme-children]">
        <xsl:element name="diazo:copy">
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="action">drop-theme-children</xsl:attribute>
            <xsl:attribute name="theme"><xsl:value-of select="@theme-children"/></xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:*[@attributes]">
        <xsl:element name="diazo:attributes">
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="action"><xsl:value-of select="local-name()"/></xsl:attribute>
            <xsl:attribute name="attributes"><xsl:value-of select="concat(' ', normalize-space(@attributes), ' ')"/></xsl:attribute>
            <xsl:if test="local-name() = 'merge' and not(@separator)">
              <xsl:attribute name="separator"><xsl:text> </xsl:text></xsl:attribute>
            </xsl:if>
            <xsl:if test="@href and not(@method)">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:drop[@attributes and @content]">
        <xsl:variable name="attributes" select="concat(' ', normalize-space(@attributes), ' ')"/>
        <xsl:variable name="content" select="@content"/>
        <xsl:for-each select="str:tokenize(normalize-space(@attributes), ' ')">
            <xsl:element name="diazo:drop">
                <xsl:apply-templates select="@*"/>
                <xsl:attribute name="content"><xsl:value-of select="$content"/><xsl:choose>
                    <xsl:when test="contains($attributes, ' * ')">/@*</xsl:when>
                    <xsl:otherwise>/@*[contains('<xsl:value-of select="$attributes"/>', concat(' ', name(), ' '))]</xsl:otherwise>
                </xsl:choose></xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:*[not(@href) and @method = 'raw']/@method">
        <xsl:if test="../@mode">
            <xsl:call-template name="error-message" select="..">
                <xsl:with-param name="message">@mode and @method="raw" not allowed in same rule.</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:attribute name="mode">raw</xsl:attribute>
    </xsl:template>

    <!--
        Debugging support
    -->

    <xsl:template name="error-message">
        <xsl:param name="message"/>
        <xsl:message terminate="yes">ERROR: <xsl:value-of select="$message"/>&#10;    RULE: &lt;<xsl:value-of select="name()"/><xsl:for-each select="@*">
            <xsl:value-of select="' '"/><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"</xsl:for-each>/&gt;
        </xsl:message>
    </xsl:template>

</xsl:stylesheet>
