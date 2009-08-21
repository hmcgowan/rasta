<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="sheet">
    <div>
      <xsl:attribute name="class">tabbertab</xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      <xsl:attribute name="title"><xsl:value-of select="@id"/></xsl:attribute>
	  <table border="0" cellspacing="1" cellpadding="5">
	    <xsl:for-each select="row">
	      <tr>
	        <xsl:for-each select="cell">
              <td>
	
	            <!-- add class information for css -->	
  		        <xsl:attribute name="class">
				  <xsl:choose>
				  <xsl:when test="@status"><xsl:value-of select="@status"/></xsl:when>
				  <xsl:otherwise><xsl:value-of select="@class"/></xsl:otherwise>
				  </xsl:choose>
			    </xsl:attribute>

	            <!-- center elements that are single words -->	
			    <xsl:if test="contains(value,' ') = false">
	  		        <xsl:attribute name="align">center</xsl:attribute>
                </xsl:if>

	            <!-- cell value -->	
				<xsl:value-of select="value"/>

	            <!-- add tool-tip for failures -->	
	            <xsl:for-each select="detail">
		          <span><pre> <xsl:value-of select="."/> </pre></span>
	            </xsl:for-each>

	          </td>
	        </xsl:for-each> 
		  </tr>
	    </xsl:for-each>
	  </table>
    </div>	
  </xsl:template>

  <xsl:template match="summary">
    <div class="tabbertab" title="Summary">
	  <div class='summary-filename'><xsl:value-of select="@filename"/></div>
  	  <xsl:apply-templates select="totals"/>
	  <xsl:for-each select="item">
		<div>
		  <xsl:attribute name="class"><xsl:value-of select="@class"/>-title</xsl:attribute>
	      <xsl:value-of select="title"/>
		</div>
		<xsl:if test="@class != 'passed'">
		  <div>
		    <xsl:attribute name="class"><xsl:value-of select="@class"/>-description</xsl:attribute>
	        <pre><xsl:value-of select="description"/></pre>
		  </div>
		  <xsl:if test="@class = 'exception'">
			<div>
			  <xsl:attribute name="class"><xsl:value-of select="@class"/>-code</xsl:attribute>
			  <xsl:for-each select="exception/line">
			    <div>
			      <xsl:attribute name="class"><xsl:value-of select="@class"/></xsl:attribute>
	  		      <xsl:value-of select="."/>
	            </div>
		      </xsl:for-each>  
			</div>
		  </xsl:if>
		</xsl:if>
      </xsl:for-each>
    </div>	
  </xsl:template>

  <xsl:template match="totals">
	<div>
	  <xsl:choose>
	  <xsl:when test="failures = 0"><xsl:attribute name="class">totals-passed</xsl:attribute><xsl:value-of select="tests"/> tests passed</xsl:when>
	  <xsl:otherwise>
	  <xsl:attribute name="class">totals-failed</xsl:attribute><xsl:value-of select="tests"/> tests completed with <xsl:value-of select="failures"/> failures </xsl:otherwise>
	  </xsl:choose>
	  <xsl:if test="pending"><xsl:choose><xsl:when test="failures = 0">with </xsl:when><xsl:otherwise>and </xsl:otherwise></xsl:choose><xsl:value-of select="pending"/> pending</xsl:if>
	</div>
	<div class="totals-duration">Duration: <xsl:value-of select="duration"/> (s)</div>
  </xsl:template>

  <xsl:template match="/">
	<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"/>
      <title>Rasta Test Results</title>
	  <script type="text/javascript" src="file:///Users/hugh_mcgowan/git/rasta/lib/rasta/resources/tabber-minimized.js">blank</script>
	  <LINK type="text/css" href="file:///Users/hugh_mcgowan/git/rasta/lib/rasta/resources/spreadsheet.css" rel="stylesheet"/>
	</head>
    <body>
	  <div class="tabber">
        <xsl:apply-templates/>
      </div>
    </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
