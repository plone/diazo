<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dv="http://namespaces.plone.org/xdv" xmlns:exsl="http://exslt.org/common" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0" exclude-result-prefixes="exsl dv xhtml">
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes" media-type="text/html" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

    <xsl:template match="/">

        <!-- Pass incoming content through initial-stage filter. -->
        <xsl:variable name="initial-stage-rtf">
            <xsl:apply-templates select="/" mode="initial-stage"/>
        </xsl:variable>
        <xsl:variable name="initial-stage" select="exsl:node-set($initial-stage-rtf)"/>

        <!-- Now apply the theme to the initial-stage content -->
        <xsl:variable name="themedcontent-rtf">
            <xsl:apply-templates select="$initial-stage" mode="apply-theme"/>
        </xsl:variable>
        <xsl:variable name="content" select="exsl:node-set($themedcontent-rtf)"/>

        <!-- We're done, so generate some output by passing 
            through a final stage. -->
        <xsl:apply-templates select="$content" mode="final-stage"/>

    </xsl:template>

    <!-- 
    
        Utility templates
    -->
    <xsl:template match="//*[@id=&quot;user-name&quot;]/img" mode="initial-stage"><!--Do nothing, skip these nodes--></xsl:template><xsl:template match="//*[@id=&quot;plone-contentmenu-factories&quot;]/dd/ul/li/a/img" mode="initial-stage"><!--Do nothing, skip these nodes--></xsl:template>
    <xsl:template match="node()|@*" mode="initial-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="initial-stage"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/" mode="apply-theme">
        <html xml:lang="en" lang="en"><head><meta http-equiv="Content-type" content="text/html; charset=utf-8"/><xsl:choose><xsl:when test="/html/head/title"><xsl:copy-of select="/html/head/title"/></xsl:when><xsl:otherwise><title>plone.org</title></xsl:otherwise></xsl:choose><xsl:choose><xsl:when test="/html/head/base"><xsl:copy-of select="/html/head/base"/></xsl:when><xsl:otherwise><base href="http://plone.org/"/></xsl:otherwise></xsl:choose><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/plonenews" title="Plone News"/><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/plonereleases" title="Plone Releases"/><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/ploneevents" title="Upcoming Plone Events"/><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/ploneaddons" title="Latest Plone &amp; Add-on Releases"/><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/plonetraining" title="Upcoming Plone Training"/><link rel="alternate" type="application/rss+xml" href="http://feeds.plone.org/ploneblogs" title="Plone Blogs"/><link rel="stylesheet" href="/plone.css" type="text/css" media="screen"/><xsl:comment>[if IE]&gt;&lt;style type="text/css" media="all"&gt;@import url(/ie.css);&lt;/style&gt;&lt;![endif]</xsl:comment><xsl:comment>[if lte IE 6]&gt;&lt;script src="/ie6warn.js" type="text/javascript"&gt;&lt;/script&gt;&lt;![endif]</xsl:comment><xsl:copy-of select="/html/head/script"/><xsl:copy-of select="/html/head/style"/></head><body><xsl:copy-of select="/html/body/@class"/><xsl:copy-of select="/html/body/@id"/>

<div id="outer-wrapper"><div id="inner-wrapper">

<div id="nav">

	<form id="search" name="searchform" action="http://plone.org/search"> 
		<input id="search-site" name="SearchableText" type="search" title="Search this site&#x2026;" accesskey="4" class="inputLabel" size="15"/></form>
	
	<div id="user">
		<xsl:choose><xsl:when test="//*[@id=&quot;user-name&quot;]"><xsl:copy-of select="//*[@id=&quot;user-name&quot;]"/></xsl:when><xsl:otherwise><a href="login">Log in</a></xsl:otherwise></xsl:choose>
	</div>
	
	<ul id="main-nav" class="navigation"><xsl:choose><xsl:when test="//*[@id=&quot;portal-globalnav&quot;]/li"><xsl:copy-of select="//*[@id=&quot;portal-globalnav&quot;]/li"/></xsl:when><xsl:otherwise><li><a href=".">Home</a></li><li><a href="/products">Downloads</a></li><li><a href="/documentation">Documentation</a></li><li><a href="/contribute">Get Involved</a></li><li><a href="/foundation">Plone Foundation</a></li><li><a href="/support">Support</a></li>
	</xsl:otherwise></xsl:choose></ul></div>



<div id="edit-bar">
	<div id="action-menu"><xsl:choose><xsl:when test="//*[@id=&quot;contentActionMenus&quot;]"><xsl:copy-of select="//*[@id=&quot;contentActionMenus&quot;]"/></xsl:when><xsl:otherwise/></xsl:choose></div>
	<div id="edit-menu"><xsl:choose><xsl:when test="//*[@id=&quot;content-views&quot;]"><xsl:copy-of select="//*[@id=&quot;content-views&quot;]"/></xsl:when><xsl:otherwise/></xsl:choose></div>
</div>



<div id="content-wrapper">
	<div class="grid-row">
		<div class="grid-cell position-leftmost width-two-thirds">
			<xsl:choose><xsl:when test="//*[@id=&quot;region-content&quot;]"><xsl:copy-of select="//*[@id=&quot;region-content&quot;]"/></xsl:when><xsl:otherwise><div id="region-content">

				<xsl:comment> Content goes here </xsl:comment>

			</div></xsl:otherwise></xsl:choose>
		</div> <xsl:comment> End cell </xsl:comment>

		<div class="grid-cell position-two-thirds width-third">
			<div id="sidebar">
			<xsl:copy-of select="//*[@id=&quot;portal-column-one&quot;]/div"/><xsl:copy-of select="//*[@id=&quot;portal-column-two&quot;]/div"/></div>
		</div>
		
	</div> <xsl:comment> End row </xsl:comment>
</div>

<div style="clear:both"> </div>

</div><xsl:comment> end inner-wrapper </xsl:comment>
<div id="push"/>
</div> <xsl:comment> end outer-wrapper </xsl:comment>

<div id="footer-wrapper">
	<div id="footer-gradient"/>
	<div id="footer">
		<a id="footer-logo" href="http://plone.org" title="Plone CMS, the open source content management system"/>
		<p>The Plone<sup>®</sup> Content Management System is copyright © 2000–2009 the Plone Foundation and friends.</p>
		<p>Plone<sup>®</sup> and the Plone logo are registered trademarks of the Plone Foundation. You’re looking good today.</p>
	    <p>Hosting by <a href="http://www.sixfeetup.com">Six Feet Up</a>.</p> 
		<div id="sitemap">
			<xsl:comment> &lt;dl&gt;
				&lt;dt&gt;&lt;a href=""&gt;Plone for…&lt;/a&gt;&lt;/dt&gt;
				&lt;dd&gt;&lt;a href=""&gt;Small/Medium Business &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Enterprise            &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Non-profits           &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Government            &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Education             &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Science               &lt;/a&gt;&lt;/dd&gt;
				&lt;dd&gt;&lt;a href=""&gt;Media &amp;amp; Publishing&lt;/a&gt;&lt;/dd&gt;
			&lt;/dl&gt; </xsl:comment>

			<dl><dt><a href="/products">Downloads</a></dt>
				<dd><a href="/download">Get Plone</a></dd>
				<dd><a href="/products?getCategories=themes">Themes</a></dd>
				<dd><a href="/products?getCategories=dev">Development tools</a></dd>
				<dd><a href="/products?getCategories=auth">Authentication</a></dd>
				<dd><a href="/products">…and more.</a></dd>
			</dl><dl><dt><a href="/documentation">Documentation</a></dt>
				<dd><a href="/documentation/faq/">FAQs</a></dd>
				<dd><a href="/documentation/movies/">Tutorial videos</a></dd>
				<dd><a href="/documentation/manual">Manuals</a></dd>
				<dd><a href="/documentation/books">Books</a></dd>
				<xsl:comment> &lt;dd&gt;&lt;a href=""&gt;Knowledge Base&lt;/a&gt;&lt;/dd&gt; </xsl:comment>
				<dd><a href="/documentation/error">Error Reference</a></dd>
				<xsl:comment> &lt;dd&gt;&lt;a href=""&gt;Module documentation&lt;/a&gt;&lt;/dd&gt; </xsl:comment>
				<dd><a href="http://plone.net/sites">Sites using Plone</a></dd>
			</dl><dl><dt><a href="http://dev.plone.org/plone">Developers</a></dt>
				<dd><a href="http://dev.plone.org/plone/roadmap">Roadmap</a></dd>
				<dd><a href="http://dev.plone.org/plone">Report bugs in Plone</a></dd>
				<dd><a href="http://dev.plone.org/plone.org">Report website issues</a></dd>
				<dd><a href="http://dev.plone.org/plone/timeline">Latest changes</a></dd>
				<dd><a href="http://dev.plone.org/plone/browser">Browse source</a></dd>
				<dd><a href="http://dev.plone.org/plone">Contribute to Plone</a></dd>
				<dd><a href="http://planet.plone.org">Community blogs</a></dd>
			</dl><dl><dt><a href="/foundation">Plone Foundation</a></dt>
				<dd><a href="/foundation/foundation-donations">Donate</a></dd>
				<dd><a href="/foundation/donors">Sponsors</a></dd>
				<dd><a href="/foundation/meetings/minutes">Meeting minutes</a></dd>
				<dd><a href="/team/FoundationBoard">Current board</a></dd>
				<dd><a href="/foundation/members">Foundation members</a></dd>
				<dd><a href="/foundation/membership">Apply for membership</a></dd>
				<dd><a href="/foundation#contact">Contact</a></dd>
			</dl><dl><dt><a href="/support">Support</a></dt>
				<dd><a href="http://plone.net/providers">Commercial services</a></dd>
				<dd><a href="/support/chat">Chat room</a></dd>
				<dd><a href="/support/forums">Forums</a></dd>
				<dd><a href="/support/for">Sector-specific forums</a></dd>
				<dd><a href="/support/region">Region-specific forums</a></dd>
				<dd><a href="/support/local-user-groups">Local user groups</a></dd>
				<dd><a href="/events/training">Training</a></dd>
			</dl></div>

	</div>
</div>


<script type="text/javascript"><xsl:variable name="tag_text"> 
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</xsl:variable><xsl:value-of select="$tag_text" disable-output-escaping="yes"/></script><script type="text/javascript"><xsl:variable name="tag_text"> 
var pageTracker = _gat._getTracker("UA-1907133-2");
pageTracker._trackPageview();
</xsl:variable><xsl:value-of select="$tag_text" disable-output-escaping="yes"/></script></body></html>
    </xsl:template>
    <xsl:template match="style|script|xhtml:style|xhtml:script" priority="5" mode="final-stage">
        <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="@*" mode="final-stage"/>
            <xsl:value-of select="text()" disable-output-escaping="yes"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*" priority="3" mode="final-stage">
        <!-- Move elements without a namespace into 
        the xhtml namespace. -->
        <xsl:choose>
            <xsl:when test="namespace-uri(.)">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()" mode="final-stage"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:apply-templates select="@*|node()" mode="final-stage"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node()|@*" priority="1" mode="final-stage">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="final-stage"/>
        </xsl:copy>
    </xsl:template>

    <!-- 
    
        Extra templates
    -->
    
    <!-- extra xsl:templates go here -->
    <xsl:strip-space elements="*"/>

</xsl:stylesheet>