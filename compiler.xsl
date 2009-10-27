<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dv="http://openplans.org/deliverance" xmlns:exsl="http://exslt.org/common"
    xmlns:set="http://exslt.org/sets" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:dyn="http://exslt.org/dynamic" xmlns:xml="http://www.w3.org/XML/1998/namespace"
    exclude-result-prefixes="dv dyn exsl xml" version="1.0">
    <xsl:output indent="yes" media-type="text/xml"/>
    <xsl:param name="rulesuri">rules.xml</xsl:param>
    <xsl:param name="boilerplateurl">boilerplate.xsl</xsl:param>
    <xsl:param name="extraurl"/>
    <xsl:param name="debug"/>
    <!-- Multi-stage theme compiler -->
    <xsl:template match="/">

        <!-- Put unique xml:id values on all the theme html -->
        <xsl:variable name="themehtml-rtf">
            <xsl:apply-templates select="/html" mode="annotate-html"/>
        </xsl:variable>
        <xsl:variable name="themehtml" select="exsl:node-set($themehtml-rtf)"/>

        <!-- Include the rules file, adding @xml:id attributes as it is included -->
        <xsl:variable name="rules-rtf">
            <xsl:apply-templates select="document($rulesuri)/*" mode="annotate-rules">
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
        
        All the utility rules

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
                    <xsl:copy-of select="document($extraurl)/xsl:stylesheet/*" />
                </xsl:if>
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
    <!-- 
        Annotate the rules for stage1
    -->
    <xsl:template match="dv:rules" mode="annotate-rules">
        <xsl:param name="themehtml"/>
        <xsl:copy>
            <xsl:for-each select="*">
                <xsl:copy>
                    <xsl:attribute name="xml:id">r<xsl:value-of select="position()"/></xsl:attribute>
                    <xsl:copy-of select="@*"/>
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
        </xsl:copy>
    </xsl:template>
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
    <!--
        Apply the rules
    -->
    <xsl:template match="node()|@*" mode="apply-rules">
        <xsl:param name="rules"/>
        <xsl:variable name="thisxmlid" select="@xml:id"/>
        <xsl:variable name="matching-rules" select="$rules//*[dv:matches/dv:xmlid=$thisxmlid]"/>
        <xsl:choose>
            <xsl:when test="$matching-rules">
                <!--
                    Pass control to first rule template
                -->
                <xsl:call-template name="before">
                    <xsl:with-param name="matching-rules" select="$matching-rules"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
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
    <xsl:template name="before">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">before</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <!--
            Always copy all content matching before rules
        -->
        <xsl:for-each select="$matching-this">
            <xsl:choose>
                <xsl:when test="@if-content">
                    <xsl:element name="xsl:if">
                        <xsl:attribute name="test">
                            <xsl:value-of select="@if-content"/>
                        </xsl:attribute>
                        <xsl:element name="xsl:copy-of">
                            <xsl:attribute name="select">
                                <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                ><xsl:value-of select="@content"/>
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="xsl:copy-of">
                        <xsl:attribute name="select">
                            <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                            ><xsl:value-of select="@content"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:call-template name="drop">
            <xsl:with-param name="matching-rules" select="$matching-other"/>
            <xsl:with-param name="rules" select="$rules"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="drop">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">drop</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <xsl:choose>
            <xsl:when test="$matching-this[not(@if-content)]">
                <!--
                    Do nothing.  We want to get rid of this node
                    in the theme.
                -->
                <!-- jump to after rules -->
                <xsl:call-template name="after">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
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
        <xsl:variable name="matching-this" select="$matching-rules[name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <xsl:choose>
            <xsl:when test="count($matching-this) > 1">
                <xsl:message terminate="yes">
                    ERROR: Multiple replace rules may not match a single theme node.
                </xsl:message>
            </xsl:when>
            <xsl:when test="$matching-this/@nocontent='drop'">
                <!-- <replace nocontent="drop" ...
                Toss out the theme node.  Simply 
                <xsl:copy-of the @content. -->
                <xsl:element name="xsl:copy-of">
                    <xsl:attribute name="select">
                        <xsl:if test="$matching-this/@href">document('<xsl:value-of select="$matching-this/@href"/>')</xsl:if
                        ><xsl:value-of select="$matching-this/@content"/>
                    </xsl:attribute>
                </xsl:element>
                <!-- jump to after rules -->
                <xsl:call-template name="after">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$matching-this">
                <!-- <replace nocontent="theme" ...
                When the rule matches, toss out the theme node and
                <xsl:copy-of the @content. Otherwise keep theme node. -->
                <xsl:element name="xsl:choose">
                    <xsl:element name="xsl:when">
                        <xsl:attribute name="test">
                            <xsl:if test="$matching-this/@href">document('<xsl:value-of select="$matching-this/@href"/>')</xsl:if><xsl:choose>
                                <xsl:when test="$matching-this/@if-condition"><xsl:value-of select="$matching-this/@if-condition"/></xsl:when>
                                <xsl:otherwise><xsl:value-of select="$matching-this/@content"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:element name="xsl:copy-of">
                            <xsl:attribute name="select">
                                <xsl:if test="$matching-this/@href">document('<xsl:value-of select="$matching-this/@href"/>')</xsl:if
                                ><xsl:value-of select="$matching-this/@content"/>
                            </xsl:attribute>
                        </xsl:element>
                        <!-- jump to after rules -->
                        <xsl:call-template name="after">
                            <xsl:with-param name="matching-rules" select="$matching-other"/>
                            <xsl:with-param name="rules" select="$rules"/>
                        </xsl:call-template>
                    </xsl:element>
                    <xsl:element name="xsl:otherwise">
                        <xsl:call-template name="prepend-copy-append">
                            <xsl:with-param name="matching-rules" select="$matching-other"/>
                            <xsl:with-param name="rules" select="$rules"/>
                        </xsl:call-template>
                    </xsl:element>
                </xsl:element>
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
        <xsl:variable name="matching-this" select="$matching-rules[name()='prepend' or name()='copy' or name()='append']"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <xsl:choose>
            <xsl:when test="$matching-this">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="apply-rules">
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>
                    <xsl:for-each select="$matching-this[name()='prepend']">
                        <xsl:choose>
                            <xsl:when test="@if-content">
                                <xsl:element name="xsl:if">
                                    <xsl:attribute name="test">
                                        <xsl:value-of select="@if-content"/>
                                    </xsl:attribute>
                                    <xsl:element name="xsl:copy-of">
                                        <xsl:attribute name="select">
                                            <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                            ><xsl:value-of select="@content"/>
                                        </xsl:attribute>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="xsl:copy-of">
                                    <xsl:attribute name="select">
                                        <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                        ><xsl:value-of select="@content"/>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:choose>
                        <xsl:when test="count($matching-this[name()='copy']) > 1">
                            <xsl:message terminate="yes">
                                ERROR: Multiple copy rules may not match a single theme node.
                            </xsl:message>
                        </xsl:when>
                        <xsl:when test="$matching-this[name()='copy']">
                            <xsl:variable name="this" select="$matching-this[name()='copy']"/>
                            <xsl:choose>
                                <xsl:when test="$this/@nocontent='empty'">
                                    <!-- Copy the node and its attributes, but clear 
                                        the children and content.  Just have an 
                                        <xsl:copy-of> for the @content -->
                                    <xsl:element name="xsl:copy-of">
                                        <xsl:attribute name="select">
                                            <xsl:if test="$this/@href">document('<xsl:value-of select="$this/@href"/>')</xsl:if
                                            ><xsl:value-of select="$this/@content"/>
                                        </xsl:attribute>
                                    </xsl:element>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- When the rule matches, copy the node and its attributes,
                                    but clear the children and text, just have an <xsl:copy-of> 
                                    for the @content. Otherwise keep theme node. -->
                                    <xsl:element name="xsl:choose">
                                        <xsl:element name="xsl:when">
                                            <xsl:attribute name="test">
                                                <xsl:if test="$this/@href">document('<xsl:value-of select="$this/@href"/>')</xsl:if><xsl:choose>
                                                    <xsl:when test="$this/@if-condition"><xsl:value-of select="$this/@if-condition"/></xsl:when>
                                                    <xsl:otherwise><xsl:value-of select="$this/@content"/></xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:attribute>
                                            <xsl:element name="xsl:copy-of">
                                                <xsl:attribute name="select">
                                                    <xsl:if test="$this/@href">document('<xsl:value-of select="$this/@href"/>')</xsl:if
                                                    ><xsl:value-of select="$this/@content"/>
                                                </xsl:attribute>
                                            </xsl:element>
                                        </xsl:element>
                                        <xsl:element name="xsl:otherwise">
                                            <xsl:apply-templates select="node()" mode="apply-rules">
                                                <xsl:with-param name="rules" select="$rules"/>
                                            </xsl:apply-templates>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="node()" mode="apply-rules">
                                <xsl:with-param name="rules" select="$rules"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="$matching-rules[name()='append']">
                        <xsl:choose>
                            <xsl:when test="@if-content">
                                <xsl:element name="xsl:if">
                                    <xsl:attribute name="test">
                                        <xsl:value-of select="@if-content"/>
                                    </xsl:attribute>
                                    <xsl:element name="xsl:copy-of">
                                        <xsl:attribute name="select">
                                            <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                            ><xsl:value-of select="@content"/>
                                        </xsl:attribute>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="xsl:copy-of">
                                    <xsl:attribute name="select">
                                        <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                        ><xsl:value-of select="@content"/>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="pass" select="node()|@*">
                    <xsl:with-param name="rules" select="$rules"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="after">
            <xsl:with-param name="matching-rules" select="$matching-rules"/>
            <xsl:with-param name="rules" select="$rules"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="after">
        <xsl:param name="matching-rules"/>
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">after</xsl:variable>
        <xsl:variable name="matching-this" select="$matching-rules[name()=$rule-name]"/>
        <xsl:variable name="matching-other" select="set:difference($matching-rules, $matching-this)"/>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <!--
            Always copy all content matching after rules
        -->
        <xsl:for-each select="$matching-this">
            <xsl:choose>
                <xsl:when test="@if-content">
                    <xsl:element name="xsl:if">
                        <xsl:attribute name="test">
                            <xsl:value-of select="@if-content"/>
                        </xsl:attribute>
                        <xsl:element name="xsl:copy-of">
                            <xsl:attribute name="select">
                                <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                                ><xsl:value-of select="@content"/>
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="xsl:copy-of">
                        <xsl:attribute name="select">
                            <xsl:if test="@href">document('<xsl:value-of select="@href"/>')</xsl:if
                            ><xsl:value-of select="@content"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <!--
            Last rule template
        -->
    </xsl:template>
    <xsl:template name="pass">
        <xsl:param name="rules"/>
        <xsl:variable name="rule-name">pass</xsl:variable>
        <xsl:call-template name="debug"><xsl:with-param name="rule-name" select="$rule-name"/></xsl:call-template>
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="apply-rules">
                <xsl:with-param name="rules" select="$rules"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="debug">
        <xsl:param name="rule-name"/>
        <xsl:if test="$debug">
            <xsl:message>DEBUG: <xsl:call-template name="printpath"/> - <xsl:value-of select="$rule-name"/></xsl:message>
        </xsl:if>
    </xsl:template>
    <xsl:template name="printpath"
        ><xsl:for-each select="ancestor::*">/<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:for-each
        >/<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:template>
</xsl:stylesheet>
