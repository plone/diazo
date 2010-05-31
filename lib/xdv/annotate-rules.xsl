<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:xdv="http://namespaces.plone.org/xdv"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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

    <xsl:template match="xdv:*/@if-content[. = '']">
        <!-- if-content="" shortcut -->
        <xsl:attribute name="if-content"><xsl:value-of select="../@content"/></xsl:attribute>
    </xsl:template>

    <xsl:template match="xdv:drop[@content]">
        <xsl:if test="@theme">
            <xsl:message terminate="yes">
                ERROR: @theme and @content attributes not allowed in same drop rule
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:attribute name="xml:id">r<xsl:value-of select="position()"/></xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xdv:*[@theme]">
        <xsl:copy>
            <xsl:attribute name="xml:id">r<xsl:value-of select="position()"/></xsl:attribute>
            <xsl:apply-templates select="@*"/>
            <xdv:synthetic>
                <xsl:choose>
                    <xsl:when test="node()">
                        <xsl:if test="@content">
                            <xsl:message terminate="yes">
                                ERROR: @content attribute and inline content not allowed in same rule
                            </xsl:message>
                        </xsl:if>
                        <xsl:if test="@href">
                            <xsl:message terminate="yes">
                                ERROR: @href attribute and inline content not allowed in same rule
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of select="node()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="include"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xdv:synthetic>
            <xdv:matches>
                <xsl:variable name="themexpath" select="@theme"/>
                <xsl:for-each select="//xdv:theme">
                    <xsl:variable name="theme-rtf">
                        <xsl:copy-of select="node()"/>
                    </xsl:variable>
                    <xsl:variable name="theme" select="exsl:node-set($theme-rtf)"/>
                    <xsl:apply-templates mode="matches" select="$theme">
                        <xsl:with-param name="themexpath" select="$themexpath"/>
                        <xsl:with-param name="themeid" select="@xml:id"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xdv:matches>
        </xsl:copy>
    </xsl:template>

    <xsl:template  match="/" mode="matches">
        <xsl:param name="themexpath"/>
        <xsl:param name="themeid"/>
        <xsl:for-each select="dyn:evaluate($themexpath)">
            <xdv:xmlid>
                <xsl:attribute name="themeid">
                    <xsl:value-of select="$themeid"/>
                </xsl:attribute>
                <xsl:value-of select="@xml:id"/>
            </xdv:xmlid>
        </xsl:for-each>
    </xsl:template>        

    <xsl:template match="*[not(@href)]" mode="include" priority="5">
        <xsl:element name="xsl:apply-templates">
            <xsl:attribute name="select">
                <xsl:value-of select="@content"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="*[@method = 'document']" mode="include">
        <xsl:element name="xsl:copy-of">
            <xsl:attribute name="select">document('<xsl:value-of select="@href"/>', .)<xsl:value-of select="@content"/></xsl:attribute>
        </xsl:element>
    </xsl:template>
    
    <xsl:template test="*[@method = 'ssi']" mode="include">
        <!-- Assumptions:
            * When using ssiprefix, @href should be an absolute local path (i.e.  /foo/bar)
        -->
        <xsl:variable name="content_quoted" select="str:encode-uri(@content, false())"/>
        <xsl:element name="xsl:comment"># include  virtual="<xsl:value-of select="$ssiprefix"/><xsl:choose>
            <xsl:when test="not(@content)"><xsl:value-of select="@href"/></xsl:when>
            <xsl:when test="contains(@href, '?')"><xsl:value-of select="concat(str:replace(@href, '?', concat($ssisuffix, '?')), $ssiquerysuffix, $content_quoted)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat(@href, $ssisuffix, '?', $ssiquerysuffix, $content_quoted)"/></xsl:otherwise>
            </xsl:choose>" wait="yes" </xsl:element>
    </xsl:template>
    
    <xsl:template test="*[@method = 'esi']" mode="include">
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
    
    <xsl:template test="*" mode="include">
        <xsl:message terminate="yes">
            ERROR: Unknown includemode or @method attribute
        </xsl:message>
    </xsl:template>

</xsl:stylesheet>
