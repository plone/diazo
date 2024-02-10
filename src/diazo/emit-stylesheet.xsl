<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:dv="http://namespaces.plone.org/diazo"
    xmlns:dyn="http://exslt.org/dynamic"
    xmlns:esi="http://www.edge-delivery.org/esi/1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:set="http://exslt.org/sets"
    xmlns:str="http://exslt.org/strings"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="dv exsl xml">

    <xsl:param name="defaultsurl">defaults.xsl</xsl:param>
    <xsl:param name="usebase"/>
    <xsl:param name="indent"/>
    <xsl:param name="known_params_url">file:///__diazo_known_params__</xsl:param>
    <xsl:param name="runtrace">0</xsl:param>

    <xsl:variable name="rules" select="//dv:*[@theme]"/>
    <xsl:variable name="usedocument" select="boolean(//xsl:*[@select and contains(@select, 'document(')])"/>
    <xsl:variable name="drop-content-rules" select="//dv:drop[@content]"/>
    <xsl:variable name="strip-content-rules" select="//dv:strip[@content]"/>
    <xsl:variable name="before-replace-after-content-selectors" select="//dv:*[local-name()='before' or local-name()='replace' or local-name()='after'][@content and not(@theme) and not(@content-children)]/@content|//dv:*[local-name()='before' or local-name()='replace' or local-name()='after'][@content and not(@theme) and @content-children]/@content-children"/>
    <xsl:variable name="replace-content-children-rules" select="//dv:replace[@content-children and not(@theme)]"/>
    <xsl:variable name="inline-xsl" select="/dv:rules/xsl:*"/>
    <xsl:variable name="themes" select="//dv:theme"/>
    <xsl:variable name="conditional-theme" select="//dv:theme[@merged-condition]"/>
    <xsl:variable name="conditional-notheme" select="//dv:notheme[@merged-condition]"/>
    <xsl:variable name="conditional" select="$conditional-theme|$conditional-notheme"/>
    <xsl:variable name="unconditional-theme" select="//dv:theme[not(@merged-condition)]"/>
    <xsl:variable name="defaults" select="document($defaultsurl)"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/">
        <xsl:apply-templates select="$defaults/xsl:stylesheet"/>
    </xsl:template>

    <xsl:template match="xsl:output/@indent">
        <xsl:choose>
            <xsl:when test="$indent">
                <xsl:attribute name="indent"><xsl:value-of select="$indent"/></xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Boilerplate
    -->

    <xsl:template match="xsl:stylesheet">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>

            <xsl:text>&#10;&#10;</xsl:text>
            <xsl:apply-templates select="document($known_params_url)/xsl:stylesheet/node()" />

            <xsl:if test="$usedocument">
                <xsl:choose>
                    <xsl:when test="$usebase">
                        <!-- When usebase is true, document() includes are resolved internally using the base tag -->
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:variable">
                            <xsl:attribute name="name">diazo-base-document</xsl:attribute>
                            <xsl:text>/</xsl:text>
                        </xsl:element>
                        <xsl:text>&#10;</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- otherwise use a hack to ensure the relative path is used -->
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:variable">
                            <xsl:attribute name="name">diazo-base-document-rtf</xsl:attribute>
                        </xsl:element>
                        <xsl:text>&#10;</xsl:text>
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:variable">
                            <xsl:attribute name="name">diazo-base-document</xsl:attribute>
                            <xsl:attribute name="select">exsl:node-set($diazo-base-document-rtf)</xsl:attribute>
                        </xsl:element>
                        <xsl:text>&#10;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
            <xsl:if test="$themes">
                <xsl:text>&#10;    </xsl:text>
                <xsl:element name="xsl:template">
                    <xsl:attribute name="match">/</xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="$conditional">
                            <xsl:element name="xsl:choose">
                                <xsl:for-each select="$conditional-notheme">
                                    <xsl:variable name="themeid" select="@xml:id"/>
                                    <xsl:text>&#10;</xsl:text>
                                    <xsl:element name="xsl:when">
                                        <xsl:attribute name="test">
                                            <xsl:value-of select="@merged-condition"/>
                                        </xsl:attribute>
                                        <xsl:element name="xsl:apply-templates">
                                            <xsl:attribute name="select">@*|node()</xsl:attribute>
                                        </xsl:element>
                                    </xsl:element>
                                    <xsl:text>&#10;</xsl:text>
                                </xsl:for-each>
                                <xsl:for-each select="$conditional-theme">
                                    <xsl:variable name="themeid" select="@xml:id"/>
                                    <xsl:text>&#10;</xsl:text>
                                    <xsl:element name="xsl:when">
                                        <xsl:attribute name="test">
                                            <xsl:value-of select="@merged-condition"/>
                                        </xsl:attribute>
                                        <xsl:element name="xsl:apply-templates">
                                            <xsl:attribute name="select">.</xsl:attribute>
                                            <xsl:attribute name="mode">
                                                <xsl:value-of select="$themeid"/>
                                            </xsl:attribute>
                                        </xsl:element>
                                    </xsl:element>
                                    <xsl:text>&#10;</xsl:text>
                                </xsl:for-each>
                                <xsl:text>&#10;</xsl:text>
                                <xsl:element name="xsl:otherwise">
                                    <xsl:choose>
                                        <xsl:when test="$unconditional-theme">
                                            <xsl:for-each select="$unconditional-theme">
                                                <xsl:variable name="themeid" select="@xml:id"/>
                                                <xsl:element name="xsl:apply-templates">
                                                    <xsl:attribute name="select">.</xsl:attribute>
                                                    <xsl:attribute name="mode">
                                                        <xsl:value-of select="$themeid"/>
                                                    </xsl:attribute>
                                                </xsl:element>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:element name="xsl:apply-templates">
                                                <xsl:attribute name="select">@*|node()</xsl:attribute>
                                            </xsl:element>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:element>
                                <xsl:text>&#10;</xsl:text>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$unconditional-theme"> <!-- assert length unconditional-theme = 1 -->
                            <xsl:for-each select="$unconditional-theme">
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
            </xsl:if>
            <xsl:text>&#10;</xsl:text>
            <xsl:for-each select="$themes">
                <xsl:variable name="themeid" select="@xml:id"/>
                <xsl:text>&#10;    </xsl:text>
                <xsl:comment>THEME <xsl:value-of select="$themeid"/>: <xsl:choose>
                        <xsl:when test="@href"><xsl:value-of select="@href"/></xsl:when>
                        <xsl:otherwise>(inline)</xsl:otherwise>
                    </xsl:choose>
                </xsl:comment>
                <!-- template for this theme -->
                <xsl:text>&#10;    </xsl:text>
                <xsl:element name="xsl:template">
                    <xsl:attribute name="match">/</xsl:attribute>
                    <xsl:attribute name="mode">
                        <xsl:value-of select="$themeid"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="./*" mode="include-template" />
                    <xsl:text>&#10;</xsl:text>
                    <xsl:if test="$runtrace">
                        <xsl:apply-templates mode="generate-runtrace" select="/dv:rules">
                            <xsl:with-param name="themeid" select="$themeid"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:element>
                <xsl:text>&#10;</xsl:text>
            </xsl:for-each>
            <!-- If there are any <drop @content> rules, put it in
            here. -->
            <xsl:call-template name="drop-content"/>
            <!-- If there are any <strip @content> rules, put it in
            here. -->
            <xsl:call-template name="strip-content"/>
            <!-- If there are any <replace @content> rules, put it in
            here. -->
            <xsl:call-template name="before-replace-after-content"/>
            <!-- If there are any <replace @content-children> rules, put it in
            here. -->
            <xsl:call-template name="replace-content-children"/>
            <!-- Copy the inline xsl from rules (usually xsl:output) -->
            <xsl:for-each select="$inline-xsl">
                <xsl:text>&#10;    </xsl:text>
                <xsl:copy-of select="."/>
                <xsl:text>&#10;</xsl:text>
            </xsl:for-each>
            <!-- Make a copy of default templates for raw mode. -->
            <xsl:for-each select="$defaults/xsl:stylesheet/xsl:template[not(@mode)]">
                <xsl:text>&#10;    </xsl:text>
                <xsl:apply-templates select="." mode="rewrite-mode">
                    <xsl:with-param name="mode" select="'raw'"/>
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:text>&#10;</xsl:text>
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
            <xsl:when test="$rules[@method='esi']">
                <xsl:copy/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="exclude-result-prefixes"><xsl:value-of select="."/> esi</xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@*|node()" mode="include-template">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="include-template"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xsl:*/text() | body/text()" mode="include-template" priority="5">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="include-template"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template
        match="text()[. and not(normalize-space(substring(., 1, 1))) and not(normalize-space(substring(., string-length(.))))]"
        mode="include-template">
            <xsl:element name="xsl:text"><xsl:value-of select="."/></xsl:element>
    </xsl:template>

    <!-- Rule templates -->

    <xsl:template name="drop-content">
        <xsl:for-each select="$drop-content-rules">
            <xsl:text>&#10;    </xsl:text>
            <xsl:call-template name="debug-comment" select="."/>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:template">
                <xsl:attribute name="match">
                    <xsl:value-of select="@content"/>
                    <xsl:if test="@merged-condition">
                        <xsl:text>[</xsl:text>
                        <xsl:choose>
                            <xsl:when test="contains(@merged-condition, '$')">
                                <!-- variable references are not allowed in template match patterns -->
                                <xsl:text>dyn:evaluate(</xsl:text>
                                <xsl:call-template name="escape-string">
                                    <xsl:with-param name="string" select="@merged-condition"/>
                                </xsl:call-template>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="@merged-condition"/></xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:text>&#10;    </xsl:text>
            </xsl:element>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="strip-content">
        <xsl:for-each select="$strip-content-rules">
            <xsl:text>&#10;    </xsl:text>
            <xsl:call-template name="debug-comment" select="."/>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:template">
                <xsl:attribute name="match">
                    <xsl:value-of select="@content"/>
                    <xsl:if test="@merged-condition">
                        <xsl:text>[</xsl:text>
                        <xsl:choose>
                            <xsl:when test="contains(@merged-condition, '$')">
                                <!-- variable references are not allowed in template match patterns -->
                                <xsl:text>dyn:evaluate(</xsl:text>
                                <xsl:call-template name="escape-string">
                                    <xsl:with-param name="string" select="@merged-condition"/>
                                </xsl:call-template>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="@merged-condition"/></xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:text>&#10;        </xsl:text>
                <xsl:element name="xsl:apply-templates">
                    <xsl:attribute name="select">node()</xsl:attribute>
                </xsl:element>
            <xsl:text>&#10;    </xsl:text>
            </xsl:element>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="before-replace-after-content">
        <xsl:if test="$before-replace-after-content-selectors">

            <xsl:for-each select="$before-replace-after-content-selectors">
                <xsl:variable name="current" select="."/>
                <xsl:variable name="matching-before" select="//dv:before[@content=$current and not(@theme)]"/>
                <xsl:variable name="matching-before-children" select="//dv:before[@content-children=$current and not(@theme)]"/>
                <xsl:variable name="matching-replace" select="//dv:replace[(@content=$current or @content-children=$current) and not(@theme)]"/>
                <xsl:variable name="matching-after" select="//dv:after[@content=$current and not(@theme)]"/>
                <xsl:variable name="matching-after-children" select="//dv:after[@content-children=$current and not(@theme)]"/>

                <!-- filter so we get each selector only once -->
                <xsl:if test="generate-id() = generate-id($before-replace-after-content-selectors[. = $current][1])">
                    <xsl:text>&#10;</xsl:text>
                    <xsl:element name="xsl:template">
                        <xsl:attribute name="match">
                            <xsl:value-of select="$current"/>
                        </xsl:attribute>
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:apply-templates">
                            <xsl:attribute name="select">.</xsl:attribute>
                            <xsl:attribute name="mode">before-content</xsl:attribute>
                        </xsl:element>
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:apply-templates">
                            <xsl:attribute name="select">.</xsl:attribute>
                            <xsl:attribute name="mode">replace-content</xsl:attribute>
                        </xsl:element>
                        <xsl:text>&#10;    </xsl:text>
                        <xsl:element name="xsl:apply-templates">
                            <xsl:attribute name="select">.</xsl:attribute>
                            <xsl:attribute name="mode">after-content</xsl:attribute>
                        </xsl:element>
                        <xsl:text>&#10;</xsl:text>
                    </xsl:element>
                    <xsl:text>&#10;</xsl:text>
                </xsl:if>
            </xsl:for-each>

            <xsl:for-each select="$before-replace-after-content-selectors">
                <xsl:variable name="current" select="."/>
                <xsl:variable name="matching-before" select="//dv:before[@content=$current and not(@theme)]"/>
                <xsl:variable name="matching-before-children" select="//dv:before[@content-children=$current and not(@theme)]"/>
                <xsl:variable name="matching-replace" select="//dv:replace[(@content=$current or @content-children=$current) and not(@theme)]"/>
                <xsl:variable name="matching-after" select="//dv:after[@content=$current and not(@theme)]"/>
                <xsl:variable name="matching-after-children" select="//dv:after[@content-children=$current and not(@theme)]"/>

                <!-- filter so we get each selector only once -->
                <xsl:if test="generate-id() = generate-id($before-replace-after-content-selectors[. = $current][1])">
                    <xsl:if test="$matching-before">
                        <xsl:text>&#10;</xsl:text>
                        <xsl:element name="xsl:template">
                            <xsl:attribute name="match">
                                <xsl:value-of select="$current"/>
                            </xsl:attribute>
                            <xsl:attribute name="mode">before-content</xsl:attribute>
                            <xsl:call-template name="include-all-with-condition">
                                <xsl:with-param name="matching-rules" select="$matching-before" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:if test="$matching-before-children">
                        <xsl:text>&#10;</xsl:text>
                        <xsl:element name="xsl:template">
                            <xsl:attribute name="match">
                                <xsl:value-of select="$current"/>
                            </xsl:attribute>
                            <xsl:attribute name="mode">before-content-children</xsl:attribute>
                            <xsl:call-template name="include-all-with-condition">
                                <xsl:with-param name="matching-rules" select="$matching-before-children" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                    <xsl:text>&#10;</xsl:text>

                    <xsl:if test="$matching-replace">
                        <xsl:text>&#10;</xsl:text>
                        <xsl:element name="xsl:template">
                            <xsl:attribute name="match">
                                <xsl:value-of select="$current"/>
                            </xsl:attribute>
                            <xsl:attribute name="mode">replace-content</xsl:attribute>
                            <xsl:choose>
                                <xsl:when test="$matching-replace[@merged-condition]">
                                    <xsl:element name="xsl:choose">
                                        <xsl:for-each select="$matching-replace">
                                            <xsl:text>&#10;    </xsl:text>
                                            <xsl:choose>
                                                <xsl:when test="@merged-condition">
                                                    <xsl:element name="xsl:when">
                                                        <xsl:attribute name="test">
                                                            <xsl:choose>
                                                                <xsl:when test="contains(@merged-condition, '$')">
                                                                    <!-- variable references are not allowed in template match patterns -->
                                                                    <xsl:text>dyn:evaluate(</xsl:text>
                                                                    <xsl:call-template name="escape-string">
                                                                        <xsl:with-param name="string" select="@merged-condition"/>
                                                                    </xsl:call-template>
                                                                    <xsl:text>)</xsl:text>
                                                                </xsl:when>
                                                                <xsl:otherwise><xsl:value-of select="@merged-condition"/></xsl:otherwise>
                                                            </xsl:choose>
                                                        </xsl:attribute>
                                                        <xsl:copy-of select="node()"/>
                                                    </xsl:element>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:copy-of select="node()"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:for-each>
                                        <xsl:element name="xsl:otherwise">
                                            <xsl:call-template name="include-content-with-children-rules" />
                                        </xsl:element>
                                        <xsl:text>&#10;</xsl:text>
                                    </xsl:element>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="$matching-replace">
                                        <xsl:copy-of select="node()"/>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                        <xsl:text>&#10;</xsl:text>
                    </xsl:if>

                    <xsl:if test="$matching-after">
                        <xsl:text>&#10;</xsl:text>
                        <xsl:element name="xsl:template">
                            <xsl:attribute name="match">
                                <xsl:value-of select="$current"/>
                            </xsl:attribute>
                            <xsl:attribute name="mode">after-content</xsl:attribute>
                            <xsl:call-template name="include-all-with-condition">
                                <xsl:with-param name="matching-rules" select="$matching-after" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:if test="$matching-after-children">
                        <xsl:text>&#10;</xsl:text>
                        <xsl:element name="xsl:template">
                            <xsl:attribute name="match">
                                <xsl:value-of select="$current"/>
                            </xsl:attribute>
                            <xsl:attribute name="mode">after-content-children</xsl:attribute>
                            <xsl:call-template name="include-all-with-condition">
                                <xsl:with-param name="matching-rules" select="$matching-after-children" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:if>
                    <xsl:text>&#10;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="include-all-with-condition">
        <xsl:param name="matching-rules"/>
        <xsl:for-each select="$matching-rules">
            <xsl:choose>
                <xsl:when test="@merged-condition">
                    <xsl:element name="xsl:if">
                        <xsl:attribute name="test">
                            <xsl:choose>
                                <xsl:when test="contains(@merged-condition, '$')">
                                    <!-- variable references are not allowed in template match patterns -->
                                    <xsl:text>dyn:evaluate(</xsl:text>
                                    <xsl:call-template name="escape-string">
                                        <xsl:with-param name="string" select="@merged-condition"/>
                                    </xsl:call-template>
                                    <xsl:text>)</xsl:text>
                                </xsl:when>
                                <xsl:otherwise><xsl:value-of select="@merged-condition"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:copy-of select="node()"/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="replace-content-children">
        <xsl:for-each select="$replace-content-children-rules">
            <xsl:text>&#10;    </xsl:text>
            <xsl:call-template name="debug-comment" select="."/>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:template">
                <xsl:attribute name="match">
                    <xsl:value-of select="@content-children"/>
                    <xsl:if test="@merged-condition">
                        <xsl:text>[</xsl:text>
                        <xsl:choose>
                            <!-- variable references are not allowed in template match patterns -->
                            <xsl:when test="contains(@merged-condition, '$')">
                                <xsl:text>dyn:evaluate(</xsl:text>
                                <xsl:call-template name="escape-string">
                                    <xsl:with-param name="string" select="@merged-condition"/>
                                </xsl:call-template>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="@merged-condition"/></xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:element name="xsl:copy">
                    <xsl:element name="xsl:apply-templates">
                        <xsl:attribute name="select">@*</xsl:attribute>
                    </xsl:element>
                    <xsl:copy-of select="node()"/>
                </xsl:element>
            </xsl:element>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="include-content">
        <xsl:text>&#10;    </xsl:text>
        <xsl:element name="xsl:copy">
            <xsl:text>&#10;        </xsl:text>
            <xsl:element name="xsl:apply-templates">
                <xsl:attribute name="select">@*|node()</xsl:attribute>
            </xsl:element>
            <xsl:text>&#10;    </xsl:text>
        </xsl:element>
    </xsl:template>

    <xsl:template name="include-content-with-children-rules">
        <xsl:text>&#10;</xsl:text>
        <xsl:element name="xsl:copy">
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:apply-templates">
                <xsl:attribute name="select">@*</xsl:attribute>
            </xsl:element>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:apply-templates">
                <xsl:attribute name="select">.</xsl:attribute>
                <xsl:attribute name="mode">before-content-children</xsl:attribute>
            </xsl:element>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:apply-templates">
                <xsl:attribute name="select">node()</xsl:attribute>
            </xsl:element>
            <xsl:text>&#10;    </xsl:text>
            <xsl:element name="xsl:apply-templates">
                <xsl:attribute name="select">.</xsl:attribute>
                <xsl:attribute name="mode">after-content-children</xsl:attribute>
            </xsl:element>
            <xsl:text>&#10;</xsl:text>
        </xsl:element>
    </xsl:template>

    <xsl:template name="escape-string">
        <xsl:param name="string"/>
        <xsl:param name="concat" select="true()"/>
        <xsl:variable name="quote">"</xsl:variable>
        <xsl:variable name="apos">'</xsl:variable>
        <xsl:choose>
            <xsl:when test="not(contains($string, $apos))">'<xsl:value-of select="$string"/>'</xsl:when>
            <xsl:when test="not(contains($string, $quote))">"<xsl:value-of select="$string"/>"</xsl:when>
            <xsl:otherwise>
                <xsl:if test="$concat">concat(</xsl:if>
                <xsl:call-template name="escape-string">
                    <xsl:with-param name="string" select="substring-before($string, $apos)"/>
                    <xsl:with-param name="concat" select="false()"/>
                </xsl:call-template>
                <xsl:text>, "'", </xsl:text>
                <xsl:call-template name="escape-string">
                    <xsl:with-param name="string" select="substring-after($string, $apos)"/>
                    <xsl:with-param name="concat" select="false()"/>
                </xsl:call-template>
                <xsl:if test="$concat">)</xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Debugging support
    -->

    <xsl:template name="debug-comment">
        <xsl:comment>RULE: &lt;<xsl:value-of select="name()"/><xsl:for-each select="@*">
            <xsl:value-of select="' '"/><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"</xsl:for-each>/&gt;</xsl:comment>
    </xsl:template>

    <xsl:template match="*" mode="generate-runtrace"><xsl:param name="themeid"/>
        <xsl:if test="namespace-uri() = 'http://namespaces.plone.org/diazo'">
            <!-- For content conditions, generate code to evaluate and count matches -->
            <xsl:for-each select="@if-not-content|@if-content|@content|@content-children|@merged-condition">
               <xsl:variable name="attr" select="."/>
               <xsl:element name="xsl:message">
                 <xsl:text>&lt;runtrace</xsl:text>
                 <xsl:text> theme_xmlid=&quot;</xsl:text>
                 <xsl:call-template name="replace-string"><xsl:with-param name="string" select="../@xml:id"/></xsl:call-template>
                 <xsl:text>&quot;</xsl:text>
                 <xsl:for-each select=".|../@*[namespace-uri() = 'http://namespaces.plone.org/diazo/css' and local-name() = name($attr)]">
                     <xsl:value-of select="concat(' ',name(),'=&quot;')"/>
                     <xsl:call-template name="replace-string"><xsl:with-param name="string" select="."/></xsl:call-template>
                     <xsl:text>&quot;</xsl:text>
                 </xsl:for-each>
                 <xsl:text>&gt;</xsl:text>
                 <xsl:choose>
                     <xsl:when test="string($attr) and contains('content,content-children', name($attr))">
                         <xsl:element name="xsl:value-of"><xsl:attribute name="select">count(<xsl:value-of select="$attr"/>)</xsl:attribute></xsl:element>
                     </xsl:when>
                     <xsl:when test="string($attr) and name($attr) = 'if-not-content'">
                         <xsl:element name="xsl:value-of"><xsl:attribute name="select">not(<xsl:value-of select="$attr"/>)</xsl:attribute></xsl:element>
                     </xsl:when>
                     <xsl:when test="string($attr)">
                         <xsl:element name="xsl:value-of"><xsl:attribute name="select">boolean(<xsl:value-of select="$attr"/>)</xsl:attribute></xsl:element>
                     </xsl:when>
                 </xsl:choose>
                 <xsl:text>&lt;/runtrace&gt;</xsl:text>
               </xsl:element>
               <xsl:text>&#10;</xsl:text>
            </xsl:for-each>

            <!-- For theme conditions, count matches in document relevant to current theme -->
            <xsl:for-each select="@if-theme|@theme|@theme-children">
               <xsl:variable name="attr" select="."/>
               <xsl:element name="xsl:message">
                 <xsl:text>&lt;runtrace</xsl:text>
                 <xsl:text> theme_xmlid=&quot;</xsl:text>
                 <xsl:call-template name="replace-string"><xsl:with-param name="string" select="../@xml:id"/></xsl:call-template>
                 <xsl:text>&quot;</xsl:text>
                 <xsl:for-each select=".|../@*[namespace-uri() = 'http://namespaces.plone.org/diazo/css' and local-name() = name($attr)]">
                     <xsl:value-of select="concat(' ',name(),'=&quot;')"/>
                     <xsl:call-template name="replace-string"><xsl:with-param name="string" select="."/></xsl:call-template>
                     <xsl:text>&quot;</xsl:text>
                 </xsl:for-each>
                 <xsl:text>&gt;</xsl:text>
                 <xsl:value-of select="count(../dv:matches/dv:xmlid[@themeid = $themeid])"/>
                 <xsl:text>&lt;/runtrace&gt;</xsl:text>
               </xsl:element>
            </xsl:for-each>
        </xsl:if>

        <!-- Recurse through all nodes -->
        <xsl:apply-templates select="./*" mode="generate-runtrace">
            <xsl:with-param name="themeid" select="$themeid"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="replace-string">
        <xsl:param name="string"/>
        <xsl:param name="from">"</xsl:param>
        <xsl:param name="to">&amp;quot;</xsl:param>
        <xsl:choose>
            <xsl:when test="contains($string,$from)">
              <xsl:call-template name="replace-string">
                  <xsl:with-param name="string" select="substring-before($string,$from)"/>
                  <xsl:with-param name="from" select="$from" />
                  <xsl:with-param name="to" select="$to" />
              </xsl:call-template>
              <xsl:value-of select="$to"/>
              <xsl:call-template name="replace-string">
                  <xsl:with-param name="string" select="substring-after($string,$from)"/>
                  <xsl:with-param name="from" select="$from" />
                  <xsl:with-param name="to" select="$to" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
