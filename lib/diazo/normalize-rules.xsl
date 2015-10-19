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

    <xsl:template match="//diazo:rules/diazo:rules | //diazo:rules/diazo:theme">
        <xsl:element name="diazo:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:include">
        <xsl:element name="diazo:{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:if test="@href and not(@method)">
                <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="@content-children">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:if test="@method = 'raw'">
                <xsl:if test="@mode">
                    <xsl:call-template name="error-message" select="..">
                        <xsl:with-param name="message">@mode and @method="raw" not allowed in same rule.</xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
                <xsl:attribute name="mode">raw</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:replace[not(@theme) and not(@theme-children)]">
        <xsl:element name="diazo:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:*[not(@theme) and not(@theme-children)]">
        <xsl:element name="diazo:{local-name()}">
            <xsl:if test="@content-children">
                <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:*[@theme]">
        <xsl:element name="diazo:{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="@content or @content-children or @href">
                    <xsl:if test="node()">
                        <xsl:call-template name="error-message" select=".">
                            <xsl:with-param name="message">inline content not allowed in same rule as @content/@content-children/@href</xsl:with-param>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:element name="diazo:include">
                        <xsl:apply-templates select="@content|@href|@mode|@method"/>
                        <xsl:if test="@href and not(@method)">
                            <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
                        </xsl:if>
                        <xsl:if test="@content-children">
                            <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
                        </xsl:if>
                        <xsl:if test="@method = 'raw'">
                            <xsl:if test="@mode">
                                <xsl:call-template name="error-message" select="..">
                                    <xsl:with-param name="message">@mode and @method="raw" not allowed in same rule.</xsl:with-param>
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:attribute name="mode">raw</xsl:attribute>
                        </xsl:if>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
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

    <xsl:template match="//diazo:rules/diazo:*[@theme-children]">
        <xsl:variable name="elem-name">
            <xsl:choose>
                <xsl:when test="local-name() = 'before'">prepend</xsl:when>
                <xsl:when test="local-name() = 'after'">append</xsl:when>
                <xsl:when test="local-name() = 'replace'">copy</xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="error-message" select=".">
                        <xsl:with-param name="message">@theme-children not allowed here</xsl:with-param>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="diazo:{$elem-name}">
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="theme"><xsl:value-of select="@theme-children"/></xsl:attribute>
            <xsl:choose>
                <xsl:when test="@content or @content-children or @href">
                    <xsl:if test="node()">
                        <xsl:call-template name="error-message" select=".">
                            <xsl:with-param name="message">inline content not allowed in same rule as @content/@content-children/@href</xsl:with-param>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:element name="diazo:include">
                        <xsl:apply-templates select="@content|@href|@mode|@method"/>
                        <xsl:if test="@href and not(@method)">
                            <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
                        </xsl:if>
                        <xsl:if test="@content-children">
                            <xsl:attribute name="content"><xsl:value-of select="@content-children"/>/node()</xsl:attribute>
                        </xsl:if>
                        <xsl:if test="@method = 'raw'">
                            <xsl:if test="@mode">
                                <xsl:call-template name="error-message" select="..">
                                    <xsl:with-param name="message">@mode and @method="raw" not allowed in same rule.</xsl:with-param>
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:attribute name="mode">raw</xsl:attribute>
                        </xsl:if>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
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
            <xsl:if test="@href">
                <xsl:if test="(not(@method) and $includemode != 'document') or @method != 'document'">
                    <xsl:call-template name="error-message" select=".">
                        <xsl:with-param name="message">Attributes may only be included from external documents with 'document' include mode.</xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
                <xsl:attribute name="content">document('<xsl:value-of select="@href"/>', $diazo-base-document)<xsl:if test="not(starts-with(@content, '/'))">/</xsl:if><xsl:value-of select="@content"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//diazo:rules/diazo:drop[@attributes and @content]">
        <xsl:variable name="attributes" select="concat(' ', normalize-space(@attributes), ' ')"/>
        <xsl:variable name="content" select="@content"/>
        <xsl:variable name="node_attrs" select="@*"/>
        <xsl:for-each select="str:tokenize(normalize-space(@attributes), ' ')">
            <xsl:element name="diazo:drop">
                <xsl:apply-templates select="$node_attrs"/>
                <xsl:attribute name="content"><xsl:value-of select="$content"/><xsl:choose>
                    <xsl:when test="contains($attributes, ' * ')">/@*</xsl:when>
                    <xsl:otherwise>/@*[contains('<xsl:value-of select="$attributes"/>', concat(' ', name(), ' '))]</xsl:otherwise>
                </xsl:choose></xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="diazo:drop[(@content or @content-children) and (@theme or @theme-children)] | diazo:strip[(@content or @content-children) and (@theme or @theme-children)]" priority="10">
        <xsl:call-template name="error-message" select=".">
            <xsl:with-param name="message">@theme and @content attributes not allowed in same <xsl:value-of select="local-name()"/> rule</xsl:with-param>
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
