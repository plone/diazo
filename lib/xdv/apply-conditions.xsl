<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xdv="http://namespaces.plone.org/xdv"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:template match="xdv:*[@if-content or @if-path]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="condition">
                <xsl:choose>
                    <xsl:when test="@if-content = ''"><xsl:value-of select="@content"/></xsl:when>
                    <xsl:when test="@if-content">(<xsl:value-of select="@if-content"/>)</xsl:when>
                </xsl:choose>
                <xsl:if test="@if-content and @if-path"> and </xsl:if>
                <xsl:choose>
                    <xsl:when test="@if-path and starts-with(@if-path, '/') and substring(@if-path, string-length(@if-path)) = '/'"
                        >$normalized_path = '<xsl:value-of select="@if-path"/>'</xsl:when>
                    <xsl:when test="@if-path and substring(@if-path, string-length(@if-path)) = '/'"
                        >substring($normalized_path, string-length($normalized_path) - <xsl:value-of select="string-length(@if-path)"/>) = '/<xsl:value-of select="@if-path"/>'</xsl:when>
                    <xsl:when test="@if-path and starts-with(@if-path, '/')"
                        >starts-with($normalized_path, '<xsl:value-of select="@if-path"/>/')</xsl:when>
                    <xsl:when test="@if-path"
                        >contains($normalized_path, '/<xsl:value-of select="@if-path"/>/')</xsl:when>
                </xsl:choose>
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
