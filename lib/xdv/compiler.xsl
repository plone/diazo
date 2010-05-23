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
    <xsl:output indent="yes" media-type="text/xml"/>

    <xsl:param name="rulesuri">rules.xml</xsl:param>
    <xsl:param name="boilerplateurl">boilerplate.xsl</xsl:param>
    <xsl:param name="extraurl"/>
    <xsl:param name="trace"/>
    <xsl:param name="includemode">document</xsl:param>
    <xsl:param name="ssiprefix"></xsl:param>
    <xsl:param name="ssisuffix"></xsl:param>
    <xsl:param name="ssiquerysuffix">;filter_xpath=</xsl:param>
    <xsl:param name="esiprefix"></xsl:param>
    <xsl:param name="esisuffix"></xsl:param>
    <xsl:param name="esiquerysuffix">;filter_xpath=</xsl:param>
    <xsl:variable name="theme" select="/"/>

    <!--
        Multi-stage theme compiler
    -->

    <xsl:template match="/">

        <!-- Put unique xml:id values on all the theme html -->
        <xsl:variable name="themehtml-rtf">
            <xsl:apply-templates select="/html" mode="annotate-html"/>
        </xsl:variable>
        <xsl:variable name="themehtml" select="exsl:node-set($themehtml-rtf)"/>

        <!-- Include the rules file, adding @xml:id attributes as it is included -->
        <xsl:variable name="rules-rtf">
            <xsl:apply-templates select="document($rulesuri, $theme)/*" mode="annotate-rules">
                <xsl:with-param name="themehtml" select="$themehtml"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="rules" select="exsl:node-set($rules-rtf)"/>

        <!-- Make a pass through all the theme html, filtering 
            as we go. This is where rule generation happens. -->
        <xsl:variable name="stage1-rtf">
            <xsl:apply-templates select="$themehtml" mode="apply-rules">
                <xsl:with-param name="rules" select="$rules"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="stage1" select="exsl:node-set($stage1-rtf)"/>

        <!-- Stage 2, include the boilerplate and make a compiled
            XSLT. -->
        <xsl:variable name="stage2-rtf">
            <xsl:apply-templates select="document($boilerplateurl)" mode="include-boilerplate">
                <xsl:with-param name="stage1" select="$stage1"/>
                <xsl:with-param name="rules" select="$rules"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="stage2" select="exsl:node-set($stage2-rtf)"/>

        <!-- We're done, so generate some output -->
        <xsl:copy-of select="$stage2"/>

    </xsl:template>

    <!--
        Boilerplate
    -->

    <xsl:template match="node()|@*" mode="include-boilerplate">
        <xsl:param name="stage1"/>
        <xsl:param name="rules"/>
        <xsl:choose>
            <xsl:when test="@mode='insert-drop-rules'">
                <!-- If there are any <drop @content> rules, put it in 
                here. -->
                <xsl:for-each select="$rules/dv:rules/dv:drop[@content]">
                    <xsl:element name="xsl:template">
                        <xsl:attribute name="match">
                            <xsl:value-of select="@content"/>
                        </xsl:attribute>
                        <xsl:attribute name="mode">initial-stage</xsl:attribute>
                        <xsl:comment>Do nothing, skip these nodes</xsl:comment>
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="name()='dv:insert'">
                <!-- Put the compiled theme in at this spot of the boilerplate -->
                <xsl:apply-templates select="$stage1" mode="include-boilerplate">
                    <xsl:with-param name="stage1" select="$stage1"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="name()='dv:insert-extra'">
                <!-- Put the extra templates in at this spot of the boilerplate -->
                <xsl:if test="$extraurl">
                    <xsl:copy-of select="document($extraurl, $theme)/xsl:stylesheet/node()" />
                </xsl:if>
                <xsl:copy-of select="$rules/dv:rules/xsl:*" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="include-boilerplate">
                        <xsl:with-param name="stage1" select="$stage1"/>
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="/xsl:stylesheet/@exclude-result-prefixes" mode="include-boilerplate">
        <xsl:param name="stage1"/>
        <xsl:param name="rules"/>
        <xsl:choose>
            <xsl:when test="$includemode='esi' or $rules//*[@method='esi']">
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="include-boilerplate">
                        <xsl:with-param name="stage1" select="$stage1"/>
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="exclude-result-prefixes"><xsl:value-of select="."/> esi</xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Annotate the rules for stage1
    -->

    <xsl:template match="dv:rules" mode="annotate-rules">
        <xsl:param name="themehtml"/>
        <xsl:copy>
            <xsl:for-each select="//dv:rules/dv:*[local-name() != 'rules']">
                <xsl:copy>
                    <xsl:attribute name="xml:id">r<xsl:value-of select="position()"/></xsl:attribute>
                    <xsl:copy-of select="@*[local-name() != 'if-content']"/>
                    <xsl:choose>
                        <xsl:when test="@if-content = ''">
                            <xsl:attribute name="if-content"><xsl:value-of select="@content"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="@if-content"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@href and not(@method)">
                        <xsl:attribute name="method"><xsl:value-of select="$includemode"/></xsl:attribute>
                    </xsl:if>
                    <xsl:if test="node()">
                        <dv:synthetic><xsl:apply-templates select="node()" mode="filter-synthetic"/></dv:synthetic>
                    </xsl:if>
                    <dv:matches>
                        <xsl:variable name="themexpath" select="@theme"/>
                        <xsl:for-each select="$themehtml">
                            <xsl:for-each select="dyn:evaluate($themexpath)">
                                <dv:xmlid>
                                    <xsl:value-of select="@xml:id"/>
                                </dv:xmlid>
                            </xsl:for-each>
                        </xsl:for-each>
                    </dv:matches>
                </xsl:copy>
            </xsl:for-each>
            <xsl:copy-of select="xsl:*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node()|@*" mode="filter-synthetic">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="filter-synthetic"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match='//*[namespace-uri() = "http://www.w3.org/1999/xhtml"]' mode="filter-synthetic">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()" mode="filter-synthetic"/>
        </xsl:element>
    </xsl:template>


    <!--
        Annotate the theme html
    -->

    <xsl:template match="comment()" mode="annotate-html">
        <xsl:element name="xsl:comment"><xsl:value-of select="."/></xsl:element>
    </xsl:template>

    <xsl:template match="node()|@*" mode="annotate-html">
        <xsl:copy>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()|@*" mode="annotate-html"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/html/@xmlns" mode="annotate-html" priority="5">
        <!-- setting the namespace to xhtml mucks up the included namespaces, so cheat -->
        <xsl:if test="document($rulesuri, $theme)//*/@method='esi' or $includemode='esi'">
            <!-- when we have another namespace defined, libxml2/xmlsave.c will not magically add the xhtml ns for us -->
            <xsl:element name="xsl:attribute">
                <xsl:attribute name="name">xmlns</xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="pre/text()" mode="annotate-html">
        <!-- Filter out quoted &#13; -->
        <xsl:value-of select="str:replace(., '&#13;&#10;', '&#10;')"/>
    </xsl:template>

    <!--
        Apply the rules
    -->

    <xsl:template match="node()|@*" mode="apply-rules">
        <xsl:param name="rules"/>
        <xsl:variable name="thisxmlid" select="@xml:id"/>
        <xsl:variable name="matching-rules" select="$rules//*[dv:matches/dv:xmlid=$thisxmlid]"/>
        <xsl:choose>
            <xsl:when test="$matching-rules">
                <xsl:call-template name="trace-path"/>
                <!-- Before -->
                <xsl:call-template name="trace"><xsl:with-param name="rule-name">before</xsl:with-param><xsl:with-param name="matching" select="$matching-rules[local-name()='before']"/></xsl:call-template>
                <xsl:apply-templates select="$matching-rules[local-name()='before']" mode="conditional-include"/>
                <!--
                    Pass control to first rule template
                -->
                <xsl:call-template name="drop">
                    <xsl:with-param name="matching-rules" select="$matching-rules"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
                <!-- After -->
                <xsl:call-template name="trace"><xsl:with-param name="rule-name">after</xsl:with-param><xsl:with-param name="matching" select="$matching-rules[local-name()='after']"/></xsl:call-template>
                <xsl:apply-templates select="$matching-rules[local-name()='after']" mode="conditional-include"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="apply-rules">
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@xml:id" mode="apply-rules" priority="5">
        <!-- Filter this out -->
    </xsl:template>

    <xsl:template mode="apply-rules" priority="5"
        match="text()[parent::style|parent::script|parent::xhtml:style|parent::xhtml:script]">
        <!-- Emit xsl that avoids escaping -->
        <xsl:element name="xsl:variable">
            <xsl:attribute name="name">tag_text</xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
        <xsl:element name="xsl:value-of">
            <xsl:attribute name="select">$tag_text</xsl:attribute>
            <xsl:attribute name="disable-output-escaping">yes</xsl:attribute>
        </xsl:element>
    </xsl:template>

    <!--
        Rule templates
    -->
    <xsl:template name="drop">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">drop</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[local-name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="trace"><xsl:with-param name="rule-name" select="$rule-name"/><xsl:with-param name="matching" select="$matching-this"/></xsl:call-template>
        <xsl:choose>
            <xsl:when test="$matching-this[not(@if-content)]">
                <!--
                    Do nothing.  We want to get rid of this node
                    in the theme. Next rule is `after`.
                -->
            </xsl:when>
            <xsl:when test="$matching-this/@if-content">
                <!--
                    <drop condition="content" ...
                    When the rule matches, toss out the theme node.
                    Otherwise keep theme node.
                -->
                <xsl:element name="xsl:choose">
                    <xsl:element name="xsl:when">
                        <xsl:attribute name="test">
                            <xsl:for-each select="$matching-this/@if-content">
                                <xsl:text>(</xsl:text><xsl:value-of select="."/><xsl:text>)</xsl:text>
                                <xsl:if test="position() != last()">
                                    <xsl:text> or </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:attribute>
                        <!--
                            Do nothing.  We want to get rid of this node
                            in the theme.
                        -->
                    </xsl:element>
                    <xsl:element name="xsl:otherwise">
                        <xsl:call-template name="replace">
                            <xsl:with-param name="matching-rules" select="$matching-other"/>
                            <xsl:with-param name="rules" select="$rules"/>
                        </xsl:call-template>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="replace">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="replace">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">replace</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[local-name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="trace"><xsl:with-param name="rule-name" select="$rule-name"/><xsl:with-param name="matching" select="$matching-this"/></xsl:call-template>

        <xsl:variable name="unconditional" select="$matching-this[not(@if-content)]"/>
        <xsl:variable name="conditional" select="$matching-this[@if-content]"/>
        <xsl:if test="count($unconditional) > 1">
            <xsl:message terminate="yes">
                ERROR: Multiple unconditional replace rules may not match a single theme node.
            </xsl:message>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="$conditional">
                <!-- conditional <replace ...
                When the rule matches, toss out the theme node and
                include the @content. Otherwise keep theme node. -->
                <xsl:element name="xsl:choose">
                    <xsl:for-each select="$conditional">
                        <xsl:element name="xsl:when">
                            <xsl:attribute name="test">
                                <xsl:value-of select="@if-content"/>
                            </xsl:attribute>
                            <xsl:call-template name="include">
                                <xsl:with-param name="rule" select="."/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:for-each>
                    <xsl:choose>
                        <xsl:when test="$unconditional">
                            <xsl:element name="xsl:otherwise">
                                <!-- unconditional <replace.
                                Toss out the theme node.  Simply include the @content. -->
                                <xsl:call-template name="include">
                                    <xsl:with-param name="rule" select="$unconditional"/>
                                </xsl:call-template>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:element name="xsl:otherwise">
                                <xsl:call-template name="prepend-copy-append">
                                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                                    <xsl:with-param name="rules" select="$rules"/>
                                </xsl:call-template>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$unconditional">
                <!-- unconditional <replace.
                Toss out the theme node.  Simply include the @content. -->
                <xsl:call-template name="include">
                    <xsl:with-param name="rule" select="$unconditional"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="prepend-copy-append">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="prepend-copy-append">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">prepend-copy-append</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[local-name()='prepend' or local-name()='copy' or local-name()='append']"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="trace"><xsl:with-param name="rule-name" select="$rule-name"/><xsl:with-param name="matching" select="$matching-this"/></xsl:call-template>

                <xsl:copy>
                    <!-- Theme attributes -->
                    <xsl:apply-templates select="@*" mode="apply-rules">
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>

                    <!-- Prepend -->
                    <xsl:apply-templates select="$matching-this[local-name()='prepend']" mode="conditional-include"/>

                    <!-- Copy -->
                    <xsl:variable name="unconditional" select="$matching-this[local-name()='copy' and not(@if-content)]"/>
                    <xsl:variable name="conditional" select="$matching-this[local-name()='copy' and @if-content]"/>
                    <xsl:if test="count($unconditional) > 1">
                        <xsl:message terminate="yes">
                            ERROR: Multiple unconditional copy rules may not match a single theme node.
                        </xsl:message>
                    </xsl:if>

                    <xsl:choose>
                        <xsl:when test="$conditional">
                            <!-- conditional <copy ...
                            When the rule matches, copy the node and its attributes,
                            but clear the children and text, just include the @content.
                            Otherwise keep theme node. -->
                            <xsl:element name="xsl:choose">
                                <xsl:for-each select="$conditional">
                                    <xsl:element name="xsl:when">
                                        <xsl:attribute name="test">
                                            <xsl:value-of select="@if-content"/>
                                        </xsl:attribute>
                                        <xsl:call-template name="include">
                                            <xsl:with-param name="rule" select="."/>
                                        </xsl:call-template>
                                    </xsl:element>
                                </xsl:for-each>
                                <xsl:choose>
                                    <xsl:when test="$unconditional">
                                        <xsl:element name="xsl:otherwise">
                                            <!-- unconditional <copy. Simply include the @content. -->
                                            <xsl:call-template name="include">
                                                <xsl:with-param name="rule" select="$unconditional"/>
                                            </xsl:call-template>
                                        </xsl:element>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:element name="xsl:otherwise">
                                            <xsl:apply-templates select="node()" mode="apply-rules">
                                                <xsl:with-param name="rules" select="$rules"/>
                                            </xsl:apply-templates>
                                        </xsl:element>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$unconditional">
                            <!-- unconditional <copy. Simply include the @content. -->
                            <xsl:call-template name="include">
                                <xsl:with-param name="rule" select="$unconditional"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="node()" mode="apply-rules">
                                <xsl:with-param name="rules" select="$rules"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>

                    <!-- Append -->
                    <xsl:apply-templates select="$matching-rules[local-name()='append']" mode="conditional-include"/>

                </xsl:copy>

    </xsl:template>


    <!--
        Content inclusion
    -->

    <xsl:template match="@*|node()" mode="conditional-include">
        <xsl:choose>
            <xsl:when test="@if-content">
                <xsl:element name="xsl:if">
                    <xsl:attribute name="test">
                        <xsl:value-of select="@if-content"/>
                    </xsl:attribute>
                    <xsl:call-template name="include">
                        <xsl:with-param name="rule" select="."/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="include">
                    <xsl:with-param name="rule" select="."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="include">
        <xsl:param name="rule"/>
        <xsl:variable name="href" select="$rule/@href"/>
        <xsl:variable name="content" select="$rule/@content"/>
        <xsl:variable name="content_quoted" select="str:encode-uri($content, false())"/>
        <xsl:variable name="method" select="$rule/@method"/>
        <xsl:choose>
            <xsl:when test="$rule/dv:synthetic">
                <xsl:if test="$content">
                    <xsl:message terminate="yes">
                        ERROR: @content attribute and inline content not allowed in same rule
                    </xsl:message>
                </xsl:if>
                <xsl:if test="$href">
                    <xsl:message terminate="yes">
                        ERROR: @href attribute and inline content not allowed in same rule
                    </xsl:message>
                </xsl:if>
                <xsl:apply-templates mode="include-synthetic" select="$rule/dv:synthetic/node()"/>
            </xsl:when>
            <xsl:when test="not($href)">
                <xsl:element name="xsl:copy-of">
                    <xsl:attribute name="select">
                        <xsl:value-of select="$content"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$method = 'document'">
                <xsl:element name="xsl:copy-of">
                    <xsl:attribute name="select">document('<xsl:value-of select="$href"/>', .)<xsl:value-of select="$content"/></xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$method = 'ssi'">
                <!-- Assumptions:
                    * When using ssiprefix, $href should be an absolute local path (i.e.  /foo/bar)
                -->
                <xsl:element name="xsl:comment"># include  virtual="<xsl:value-of select="$ssiprefix"/><xsl:choose>
                    <xsl:when test="not($content)"><xsl:value-of select="$href"/></xsl:when>
                    <xsl:when test="contains($href, '?')"><xsl:value-of select="concat(str:replace($href, '?', concat($ssisuffix, '?')), $ssiquerysuffix, $content_quoted)"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="concat($href, $ssisuffix, '?', $ssiquerysuffix, $content_quoted)"/></xsl:otherwise>
                    </xsl:choose>" wait="yes" </xsl:element>
            </xsl:when>
            <xsl:when test="$method = 'esi'">
                <!-- Assumptions:
                    * When using esiprefix, $href should be an absolute local path (i.e.  /foo/bar)
                -->
                <esi:include><xsl:attribute name="src"><xsl:choose>
                    <xsl:when test="not($content)"><xsl:value-of select="$href"/></xsl:when>
                    <xsl:when test="contains($href, '?')"><xsl:value-of select="concat(str:replace($href, '?', concat($esisuffix, '?')), $esiquerysuffix, $content_quoted)"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="concat($href, $esisuffix, '?', $esiquerysuffix, $content_quoted)"/></xsl:otherwise>
                    </xsl:choose></xsl:attribute></esi:include>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">
                    ERROR: Unknown includemode or @method attribute
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="comment()" mode="include-synthetic">
        <xsl:element name="xsl:comment"><xsl:value-of select="."/></xsl:element>
    </xsl:template>

    <xsl:template mode="include-synthetic"
        match="text()[parent::style|parent::script|parent::xhtml:style|parent::xhtml:script]">
        <!-- Emit xsl that avoids escaping -->
        <xsl:element name="xsl:variable">
            <xsl:attribute name="name">tag_text</xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
        <xsl:element name="xsl:value-of">
            <xsl:attribute name="select">$tag_text</xsl:attribute>
            <xsl:attribute name="disable-output-escaping">yes</xsl:attribute>
        </xsl:element>        
    </xsl:template>

    <xsl:template match="@*|node()" mode="include-synthetic">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" mode="include-synthetic"/>
        </xsl:copy>
    </xsl:template>

    <!--
        Debugging support
    -->

    <xsl:template name="trace">
        <xsl:param name="rule-name"/>
        <xsl:param name="matching" select="/.."/>
        <xsl:if test="$trace">
            <xsl:if test="not($matching)"><xsl:message>TRACE: (<xsl:value-of select="$rule-name"/>)</xsl:message></xsl:if>
            <xsl:for-each select="$matching">
                <xsl:message>RULE: &lt;<xsl:value-of select="name()"/><xsl:for-each select="@*">
                    <xsl:value-of select="' '"/><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"</xsl:for-each>/&gt;</xsl:message>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="trace-path">
        <xsl:if test="$trace">
            <xsl:message>THEME: <xsl:for-each select="ancestor-or-self::*"><xsl:variable name="this" select="."
                />/<xsl:value-of select="name()"/><xsl:choose><xsl:when test="@id">[@id='<xsl:value-of select="@id"/>']</xsl:when><xsl:when test="preceding-sibling::*[name()=name($this)]|following-sibling::*[name()=name($this)]">[<xsl:number/>]</xsl:when></xsl:choose></xsl:for-each></xsl:message>
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
