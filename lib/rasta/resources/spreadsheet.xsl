<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="sheet">
    <div class="tabbertab">
	  <h2><xsl:value-of select="@id"/></h2>
	  <table border="1">
	    <xsl:for-each select="row">
	      <tr>
	        <xsl:for-each select="cell">
              <td><xsl:value-of select="."/></td>
	        </xsl:for-each> 
		  </tr>
	    </xsl:for-each>
	  </table>
    </div>	
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
