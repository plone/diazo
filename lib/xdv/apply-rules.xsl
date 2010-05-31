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
    >

    <xsl:param name="trace"/>
    <xsl:variable name="rules" select="//dv:*[@theme]"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>


    <!--
        Apply the rules
    -->

    <xsl:template match="//dv:theme//*">
        <xsl:variable name="thisxmlid" select="@xml:id"/>
        <xsl:variable name="matching-rules" select="$rules[./dv:matches/dv:xmlid=$thisxmlid]"/>
        <xsl:message><xsl:value-of select="$thisxmlid"/></xsl:message>
        <xsl:message><xsl:value-of select="count($matching-rules)"/></xsl:message>
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
                    
                </xsl:call-template>
                <!-- After -->
                <xsl:call-template name="trace"><xsl:with-param name="rule-name">after</xsl:with-param><xsl:with-param name="matching" select="$matching-rules[local-name()='after']"/></xsl:call-template>
                <xsl:apply-templates select="$matching-rules[local-name()='after']" mode="conditional-include"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="//dv:theme/*//@xml:id" priority="5">
        <!-- Filter this out -->
    </xsl:template>
<!--
    <xsl:template priority="5"
        match="text()[parent::style|parent::script|parent::xhtml:style|parent::xhtml:script]">
        <! Emit xsl that avoids escaping >
        <xsl:element name="xsl:variable">
            <xsl:attribute name="name">tag_text</xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
        <xsl:element name="xsl:value-of">
            <xsl:attribute name="select">$tag_text</xsl:attribute>
            <xsl:attribute name="disable-output-escaping">yes</xsl:attribute>
        </xsl:element>
    </xsl:template>
-->
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
                            
                        </xsl:call-template>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="replace">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    
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
                            <xsl:apply-templates select="." mode="include"/>
                        </xsl:element>
                    </xsl:for-each>
                    <xsl:choose>
                        <xsl:when test="$unconditional">
                            <xsl:element name="xsl:otherwise">
                                <!-- unconditional <replace.
                                Toss out the theme node.  Simply include the @content. -->
                                <xsl:apply-templates select="$unconditional" mode="include"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:element name="xsl:otherwise">
                                <xsl:call-template name="prepend-copy-append">
                                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                                    
                                </xsl:call-template>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$unconditional">
                <!-- unconditional <replace.
                Toss out the theme node.  Simply include the @content. -->
                <xsl:apply-templates select="$unconditional" mode="include"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="prepend-copy-append">
                    <xsl:with-param name="matching-rules" select="$matching-other"/>
                    
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
                    <xsl:apply-templates select="@*">
                        
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
                                        <xsl:apply-templates select="." mode="include"/>
                                    </xsl:element>
                                </xsl:for-each>
                                <xsl:choose>
                                    <xsl:when test="$unconditional">
                                        <xsl:element name="xsl:otherwise">
                                            <!-- unconditional <copy. Simply include the @content. -->
                                            <xsl:apply-templates select="$unconditional" mode="include"/>
                                        </xsl:element>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:element name="xsl:otherwise">
                                            <xsl:apply-templates select="node()">
                                                
                                            </xsl:apply-templates>
                                        </xsl:element>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$unconditional">
                            <!-- unconditional <copy. Simply include the @content. -->
                            <xsl:apply-templates select="$unconditional" mode="include"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="node()">
                                
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

    <xsl:template match="*" mode="conditional-include">
        <xsl:choose>
            <xsl:when test="@if-content">
                <xsl:element name="xsl:if">
                    <xsl:attribute name="test">
                        <xsl:value-of select="@if-content"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="include" select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="include" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="include">
        <!-- apply-templates mode="include-synthetic" -->
        <xsl:copy-of select="dv:synthetic/node()"/>
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
