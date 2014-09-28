<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="xsl str"
    >

    <xsl:output method="html" indent="no" omit-xml-declaration="yes"
        media-type="text/html" encoding="UTF-8"
        />

    <xsl:template match="/">
        <pre class="runtrace"><xsl:apply-templates select="/*"/></pre>
    </xsl:template>

    <xsl:template match="node()">
        <span>
            <xsl:attribute name="class">
                <xsl:text>node</xsl:text>
                <xsl:choose>
                    <xsl:when test="@*[starts-with(local-name(),'runtrace-')][contains('false,0',.)]">
                        <!-- At least one runtrace node didn't match -->
                        <xsl:text> no-match</xsl:text>
                    </xsl:when>
                    <xsl:when test="@*[starts-with(local-name(),'runtrace-')]">
                        <!-- All of the runtrace nodes matched -->
                        <xsl:text> match</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Weren't any in the first place -->
                        <xsl:text> unrelated</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>

            <xsl:if test="@*[starts-with(local-name(),'runtrace-')]">
                <xsl:attribute name="title">
                    <xsl:text>Matches: </xsl:text>
                    <xsl:for-each select="@*[starts-with(local-name(),'runtrace-')]">
                        <xsl:value-of select="concat(substring-after(local-name(),'runtrace-'),':',.,' ')"/>
                    </xsl:for-each>
                </xsl:attribute>
            </xsl:if>

            <!-- Escaped tag itself, processing attributes to go along with it -->
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(node())">
                <!-- No children, so it's a singleton tag -->
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:text>&gt;</xsl:text>
        </span>

        <xsl:if test="node()">
            <xsl:apply-templates select="node()"/>
            <span class="closing"><xsl:text>&lt;/</xsl:text><xsl:value-of select="name()"/><xsl:text>&gt;</xsl:text></span>
        </xsl:if>
    </xsl:template>

    <xsl:template match="@*[starts-with(local-name(),'runtrace-')]">
        <!-- Don't need to see these in output -->
    </xsl:template>

    <xsl:template match="@*">
        <xsl:variable name="attr" select="."/>
        <xsl:text> </xsl:text>
        <span class="attr">
            <xsl:attribute name="class">
                <xsl:text>attr</xsl:text>
                <xsl:for-each select="../@*[local-name() = concat('runtrace-',local-name($attr))]"><xsl:choose>
                    <xsl:when test="contains('false,0',.)">
                        <xsl:text> no-match</xsl:text>
                    </xsl:when><xsl:otherwise>
                        <xsl:text> match</xsl:text>
                    </xsl:otherwise>
                </xsl:choose></xsl:for-each>
            </xsl:attribute>

            <xsl:value-of select="concat(name(),'=&quot;',.,'&quot;')"/>
        </span>
    </xsl:template>

    <xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="comment()">
        <!-- Still want to see comments, so escape the markup -->
        <span class="comment"><xsl:text>&lt;!--</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>--&gt;</xsl:text></span>
    </xsl:template>

</xsl:stylesheet>
