<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dv="http://openplans.org/deliverance" xmlns:exsl="http://exslt.org/common"
    xmlns:dyn="http://exslt.org/dynamic" xmlns:xml="http://www.w3.org/XML/1998/namespace"
    exclude-result-prefixes="dv dyn exsl xml" version="1.0">
    <xsl:output indent="yes"/>
    <xsl:param name="rulesuri">tests/rules-01.xml</xsl:param>
    <xsl:param name="boilerplateurl">boilerplate.xsl</xsl:param>
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
            as we go. -->
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
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="stage2" select="exsl:node-set($stage2-rtf)"/>

        <!-- We're done, so generate some output -->
        <xsl:copy-of select="$stage2"/>
    </xsl:template>
    <xsl:template match="node()|@*" mode="include-boilerplate">
        <xsl:param name="stage1"/>
        <xsl:choose>
            <xsl:when test="@insert='insert'">
                <xsl:apply-templates select="$stage1" mode="include-boilerplate">
                    <xsl:with-param name="stage1" select="$stage1"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="include-boilerplate">
                        <xsl:with-param name="stage1" select="$stage1"/>
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
    <xsl:template match="node()|@*" mode="annotate-html">
        <xsl:copy>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()|@*" mode="annotate-html"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node()|@*" mode="apply-rules">
        <xsl:param name="rules"/>
        <xsl:variable name="thisxmlid" select="@xml:id"/>
        <xsl:variable name="matching-rule" select="$rules//*[dv:matches/dv:xmlid=$thisxmlid]"/>
        <xsl:choose>
            <xsl:when test="name($matching-rule)='copy'">
                <!-- Copy the node and its attributes, but clear 
                    the children and content.  Just have an 
                    <xsl:copy-of> for the @content -->
                <xsl:copy>
                    <xsl:copy-of select="@*[name()!='xml:id']"/>
                    <xsl:element name="xsl:copy-of">
                        <xsl:attribute name="select">
                            <xsl:value-of select="$matching-rule/@content"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="name($matching-rule)='replace'">
                <!-- Toss out the theme node.  Simply 
                <xsl:copy-of the @content. -->
                <xsl:element name="xsl:copy-of">
                    <xsl:attribute name="select">
                        <xsl:value-of select="$matching-rule/@content"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="name($matching-rule)='append'">
                <!-- Make the node and all its children, then 
                    copy in the @content. -->
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="apply-rules">
                        <xsl:with-param name="rules" select="$rules"/>
                    </xsl:apply-templates>
                    <xsl:element name="xsl:copy-of">
                        <xsl:attribute name="select">
                            <xsl:value-of select="$matching-rule/@content"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:copy>
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
</xsl:stylesheet>
