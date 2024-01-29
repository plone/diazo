<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:str="http://exslt.org/strings"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:template match="diazo:*[@if-content or @if-not-content or @if-path or @if-not-path or @if or @if-not]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="condition">
                <xsl:choose>
                    <xsl:when test="@if-content = ''"><xsl:value-of select="@content"/></xsl:when>
                    <xsl:when test="@if-content">(<xsl:value-of select="@if-content"/>)</xsl:when>
                </xsl:choose>
                <xsl:if test="@if-content and (@if-not-content or @if-path or @if-not-path or @if or @if-not)"> and </xsl:if>
                <xsl:choose>
                    <xsl:when test="@if-not-content = ''">not(<xsl:value-of select="@content"/>)</xsl:when>
                    <xsl:when test="@if-not-content">not(<xsl:value-of select="@if-not-content"/>)</xsl:when>
                </xsl:choose>
                <xsl:if test="@if-not-content and (@if-path or @if-not-path or @if or @if-not)"> and </xsl:if>
                <xsl:if test="@if-path">
                    <xsl:variable name="paths" select="str:tokenize(@if-path)"/>
                    <xsl:if test="count($paths) > 1">(</xsl:if>
                    <xsl:for-each select="$paths">
                        <xsl:variable name="path" select="text()"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($path, '/') and substring($path, string-length($path)) = '/'"
                                >$normalized_path = '<xsl:value-of select="$path"/>'</xsl:when>
                            <xsl:when test="substring($path, string-length($path)) = '/'"
                                >substring($normalized_path, string-length($normalized_path) - <xsl:value-of select="string-length($path)"/>) = '/<xsl:value-of select="$path"/>'</xsl:when>
                            <xsl:when test="starts-with($path, '/')"
                                >starts-with($normalized_path, '<xsl:value-of select="$path"/>/')</xsl:when>
                            <xsl:otherwise
                                >contains($normalized_path, '/<xsl:value-of select="$path"/>/')</xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count($paths) > 1 and position() != last()"> or </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count($paths) > 1">)</xsl:if>
                </xsl:if>
                <xsl:if test="@if-path and (@if-not-path or @if or @if-not)"> and </xsl:if>
                <xsl:if test="@if-not-path">
                    <xsl:variable name="paths" select="str:tokenize(@if-not-path)"/>
                    <xsl:text>not(</xsl:text>
                    <xsl:for-each select="$paths">
                        <xsl:variable name="path" select="text()"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($path, '/') and substring($path, string-length($path)) = '/'"
                                >$normalized_path = '<xsl:value-of select="$path"/>'</xsl:when>
                            <xsl:when test="substring($path, string-length($path)) = '/'"
                                >substring($normalized_path, string-length($normalized_path) - <xsl:value-of select="string-length($path)"/>) = '/<xsl:value-of select="$path"/>'</xsl:when>
                            <xsl:when test="starts-with($path, '/')"
                                >starts-with($normalized_path, '<xsl:value-of select="$path"/>/')</xsl:when>
                            <xsl:otherwise
                                >contains($normalized_path, '/<xsl:value-of select="$path"/>/')</xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count($paths) > 1 and position() != last()"> or </xsl:if>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:if test="@if-not-path and (@if or @if-not)"> and </xsl:if>
                <xsl:if test="@if">(<xsl:value-of select="@if"/>)</xsl:if>
                <xsl:if test="@if and (@if-not)"> and </xsl:if>
                <xsl:if test="@if-not">not(<xsl:value-of select="@if-not"/>)</xsl:if>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
