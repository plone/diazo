<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:dv="http://namespaces.plone.org/xdv"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:set="http://exslt.org/sets"
    xmlns:str="http://exslt.org/strings"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="dv dyn exsl xml">

    <xsl:param name="defaultsurl">defaults.xsl</xsl:param>
    <xsl:variable name="rules" select="//dv:*[@theme]"/>
    <xsl:variable name="themes" select="//dv:theme"/>
    <xsl:variable name="conditional" select="//dv:theme[@if-content]"/>
    <xsl:variable name="unconditional" select="//dv:theme[not(@if-content)]"/>
    <xsl:variable name="defaults" select="document($defaultsurl)"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/">
        <xsl:apply-templates select="$defaults/xsl:stylesheet"/>
    </xsl:template>

    <!--
        Boilerplate
    -->

    <xsl:template match="xsl:stylesheet">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:element name="xsl:template">
                <xsl:attribute name="match">/</xsl:attribute>
                <xsl:choose>
                    <xsl:when test="$conditional">
                        <xsl:element name="xsl:choose">
                            <xsl:for-each select="$conditional">
                                <xsl:variable name="themeid" select="@xml:id"/>
                                <xsl:element name="xsl:when">
                                    <xsl:attribute name="test">
                                        <xsl:value-of select="@if-content"/>
                                    </xsl:attribute>
                                    <xsl:element name="xsl:apply-templates">
                                        <xsl:attribute name="select">.</xsl:attribute>
                                        <xsl:attribute name="mode">
                                            <xsl:value-of select="$themeid"/>
                                        </xsl:attribute>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:for-each>
                            <xsl:element name="xsl:otherwise">
                                <xsl:element name="xsl:apply-templates">
                                    <xsl:attribute name="select">.</xsl:attribute>
                                    <xsl:if test="$unconditional">
                                        <xsl:for-each select="$unconditional">
                                            <xsl:variable name="themeid" select="@xml:id"/>
                                            <xsl:attribute name="mode">
                                                <xsl:value-of select="$themeid"/>
                                            </xsl:attribute>
                                        </xsl:for-each>
                                    </xsl:if>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$unconditional"> <!-- assert unconditional = 1 -->
                        <xsl:for-each select="$unconditional">
                            <xsl:variable name="themeid" select="@xml:id"/>
                            <xsl:element name="xsl:apply-templates">
                                <xsl:attribute name="select">.</xsl:attribute>
                                <xsl:attribute name="mode">
                                    <xsl:value-of select="$themeid"/>
                                </xsl:attribute>
                            </xsl:element>
                        </xsl:for-each>
                    </xsl:when>
                </xsl:choose>
            </xsl:element>
            <xsl:for-each select="$themes">
                <xsl:variable name="themeid" select="@xml:id"/>
                <xsl:message>THEME <xsl:value-of select="$themeid"/></xsl:message>
                <!-- If there are any <drop @content> rules, put it in 
                here. -->
                <xsl:for-each select="$rules/dv:rules/dv:drop[@content]">
                    <xsl:element name="xsl:template">
                        <xsl:attribute name="match">
                            <xsl:value-of select="@content"/>
                        </xsl:attribute>
                        <xsl:attribute name="mode">
                            <xsl:value-of select="$themeid"/>
                        </xsl:attribute>
                        <xsl:comment>Do nothing, skip these nodes</xsl:comment>
                    </xsl:element>
                </xsl:for-each>
                <!-- template for this theme -->
                <xsl:element name="xsl:template">
                    <xsl:attribute name="match">/</xsl:attribute>
                    <xsl:attribute name="mode">
                        <xsl:value-of select="$themeid"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="./*" mode="rewrite-mode">
                        <xsl:with-param name="mode" select="$themeid"/>
                    </xsl:apply-templates>
                </xsl:element>
                <!-- Copy the default templates into this theme's mode -->
                <xsl:apply-templates select="$defaults/xsl:stylesheet/xsl:template[not(@mode)]" mode="rewrite-mode">
                    <xsl:with-param name="mode" select="$themeid"/>
                </xsl:apply-templates>
            </xsl:for-each>
            <!-- XXX extra xsl in rules -->
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()" mode="rewrite-mode">
        <xsl:param name="mode"/>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="rewrite-mode">
                <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xsl:template[not(@mode)] | xsl:apply-templates[not(@mode)]" mode="rewrite-mode">
        <xsl:param name="mode"/>
        <xsl:copy>
            <xsl:attribute name="mode">
                <xsl:value-of select="$mode"/>
            </xsl:attribute>
            <xsl:apply-templates select="@*|node()" mode="rewrite-mode">
                <xsl:with-param name="mode" select="$mode"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xsl:stylesheet/@exclude-result-prefixes">
        <xsl:choose>
            <xsl:when test="$rules//*[@method='esi']">
                <xsl:copy/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="exclude-result-prefixes"><xsl:value-of select="."/> esi</xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
