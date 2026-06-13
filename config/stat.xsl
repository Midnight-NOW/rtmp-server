<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <html>
            <head>
                <title>RTMP Server Statistics</title>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        margin: 20px;
                        background: #f5f5f5;
                    }
                    .container {
                        background: white;
                        padding: 20px;
                        border-radius: 5px;
                        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                        max-width: 1200px;
                        margin: 0 auto;
                    }
                    h1 {
                        color: #333;
                        border-bottom: 3px solid #667eea;
                        padding-bottom: 10px;
                    }
                    h2 {
                        color: #666;
                        margin-top: 30px;
                    }
                    table {
                        width: 100%;
                        border-collapse: collapse;
                        margin-top: 10px;
                    }
                    th {
                        background: #667eea;
                        color: white;
                        padding: 12px;
                        text-align: left;
                    }
                    td {
                        padding: 12px;
                        border-bottom: 1px solid #ddd;
                    }
                    tr:hover {
                        background: #f9f9f9;
                    }
                    .stat-item {
                        display: inline-block;
                        margin: 10px 20px 10px 0;
                        padding: 10px 20px;
                        background: #f0f0f0;
                        border-radius: 5px;
                    }
                    .stat-label {
                        font-weight: bold;
                        color: #667eea;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🎬 RTMP Server Statistics</h1>
                    
                    <div>
                        <div class="stat-item">
                            <span class="stat-label">Server Start Time:</span>
                            <xsl:value-of select="rtmp/@start"/>
                        </div>
                        <div class="stat-item">
                            <span class="stat-label">Uptime (seconds):</span>
                            <xsl:value-of select="rtmp/uptime"/>
                        </div>
                        <div class="stat-item">
                            <span class="stat-label">Total Bytes In:</span>
                            <xsl:value-of select="format-number(rtmp/bytes_in div 1024 div 1024, '0.00')"/> MB
                        </div>
                        <div class="stat-item">
                            <span class="stat-label">Total Bytes Out:</span>
                            <xsl:value-of select="format-number(rtmp/bytes_out div 1024 div 1024, '0.00')"/> MB
                        </div>
                    </div>

                    <h2>Applications</h2>
                    <xsl:apply-templates select="rtmp/server/application"/>
                </div>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="application">
        <h3>
            <xsl:value-of select="name"/>
        </h3>
        
        <table>
            <tr>
                <th>Stream Name</th>
                <th>Publisher</th>
                <th>Bytes In</th>
                <th>Bytes Out</th>
                <th>Subscribers</th>
                <th>Video Codec</th>
                <th>Audio Codec</th>
                <th>Video Data Rate</th>
            </tr>
            <xsl:apply-templates select="live/stream"/>
        </table>
    </xsl:template>

    <xsl:template match="stream">
        <tr>
            <td>
                <xsl:value-of select="name"/>
            </td>
            <td>
                <xsl:choose>
                    <xsl:when test="publisher/name">
                        <xsl:value-of select="publisher/name"/>
                    </xsl:when>
                    <xsl:otherwise>None</xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <xsl:value-of select="format-number(bytes_in div 1024, '0.00')"/> KB
            </td>
            <td>
                <xsl:value-of select="format-number(bytes_out div 1024, '0.00')"/> KB
            </td>
            <td>
                <xsl:value-of select="nclients - 1"/>
            </td>
            <td>
                <xsl:value-of select="video/codec"/>
            </td>
            <td>
                <xsl:value-of select="audio/codec"/>
            </td>
            <td>
                <xsl:value-of select="video/data_rate"/> kbps
            </td>
        </tr>
    </xsl:template>
</xsl:stylesheet>
