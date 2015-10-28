<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:diazo="http://namespaces.plone.org/diazo"
    xmlns:css="http://namespaces.plone.org/diazo/css"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:str="http://exslt.org/strings"
    >

    <xsl:param name="ssiprefix"></xsl:param>
    <xsl:param name="ssisuffix"></xsl:param>
    <xsl:param name="ssiquerysuffix">;filter_xpath=</xsl:param>
    <xsl:param name="esiprefix"></xsl:param>
    <xsl:param name="esisuffix"></xsl:param>
    <xsl:param name="esiquerysuffix">;filter_xpath=</xsl:param>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="diazo:include">
        <xsl:choose>
            <xsl:when test="@condition">
                <xsl:element name="xsl:if">
                    <xsl:attribute name="test">
                        <xsl:value-of select="@condition"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="include" select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="include" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="diazo:include[not(@href)]" priority="5" mode="include">
        <xsl:element name="xsl:apply-templates">
            <xsl:attribute name="select">
                <xsl:value-of select="@content"/>
            </xsl:attribute>
            <xsl:if test="@mode">
                <xsl:attribute name="mode"><xsl:value-of select="@mode"/></xsl:attribute>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="diazo:include[@method = 'document']" mode="include">
        <xsl:element name="xsl:apply-templates">
            <xsl:attribute name="select">document('<xsl:value-of select="@href"/>', $diazo-base-document)<xsl:if test="not(starts-with(@content, '/'))">/</xsl:if><xsl:value-of select="@content"/></xsl:attribute>
            <xsl:choose>
                <xsl:when test="@mode">
                    <xsl:attribute name="mode"><xsl:value-of select="@mode"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="mode">raw</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="diazo:include[@method = 'transform']" mode="include">
        <xsl:element name="xsl:apply-templates">
            <xsl:attribute name="select">document('<xsl:value-of select="@href"/>', $diazo-base-document)<xsl:if test="not(starts-with(@content, '/'))">/</xsl:if><xsl:value-of select="@content"/></xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="diazo:include[@method = 'ssi' or @method = 'ssiwait']" mode="include">
        <!-- Assumptions:
            * When using ssiprefix, @href should be an absolute local path (i.e.  /foo/bar)
        -->
        <xsl:variable name="content_quoted" select="str:encode-uri(@content, false())"/>
        <xsl:element name="xsl:comment">#include  virtual="<xsl:value-of select="$ssiprefix"/><xsl:choose>
            <xsl:when test="not(@content)"><xsl:value-of select="@href"/></xsl:when>
            <xsl:when test="contains(@href, '?')"><xsl:value-of select="concat(str:replace(@href, '?', concat($ssisuffix, '?')), $ssiquerysuffix, $content_quoted)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat(@href, $ssisuffix, '?', $ssiquerysuffix, $content_quoted)"/></xsl:otherwise>
            </xsl:choose>"<xsl:if test="@method = 'ssiwait'"> wait="yes"</xsl:if></xsl:element>
    </xsl:template>

    <xsl:template match="diazo:include[@method = 'esi']" mode="include">
        <!-- Assumptions:
            * When using esiprefix, @href should be an absolute local path (i.e.  /foo/bar)
        -->
        <xsl:variable name="content_quoted" select="str:encode-uri(@content, false())"/>
        <esi:include><xsl:attribute name="src"><xsl:choose>
            <xsl:when test="not(@content)"><xsl:value-of select="@href"/></xsl:when>
            <xsl:when test="contains(@href, '?')"><xsl:value-of select="concat(str:replace(@href, '?', concat($esisuffix, '?')), $esiquerysuffix, $content_quoted)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat(@href, $esisuffix, '?', $esiquerysuffix, $content_quoted)"/></xsl:otherwise>
            </xsl:choose></xsl:attribute></esi:include>
    </xsl:template>

    <xsl:template match="diazo:include" priority="-1" mode="include">
        <xsl:call-template name="error-message" select=".">
            <xsl:with-param name="message">Unknown includemode or @method attribute</xsl:with-param>
        </xsl:call-template>
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
