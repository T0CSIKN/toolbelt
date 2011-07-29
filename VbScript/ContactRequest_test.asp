<%@ LANGUAGE="VBSCRIPT"%>
<%Option Explicit '*** This must be the FIRST statement ***%>
<%Response.Buffer = true%>

<!-- #includes FILE="../inc/Config.inc" -->
<!-- #includes FILE="../UserManagement/inc/A_UserManagement.inc" -->
<!-- #includes FILE="../inc/const.inc" -->
<!-- #includes FILE="../inc/util.inc" -->
<!-- #includes FILE="../inc/UrlParams.inc" -->
<!-- #includes FILE="../inc/adovbs.inc" -->
<!-- #includes FILE="../inc/db.inc" -->
<!-- #includes FILE="../inc/Campingboerse.inc" -->
<!-- #includes FILE="../inc/Sendmail.inc" -->
<!-- #includes FILE="../inc/globalVars.inc" -->

<%
dim rubrik
dim tmp, message, infoMsg, errMsg, sysMsg
dim messageNewsletter, headerNewsletter
dim x_from, x_to
dim rc : rc = 0
dim rc2 : rc2 = 0
dim rc3 : rc3 = 0
dim anfrage, strValid, i, j, tmpChar, ok, abort

trace formatvars

rubrik = Request("Rubrik")
x_from = Request("EMail")
x_to   = Request("MAIL_TO")
anfrage = Request("Anfrage")
strValid = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz����������������������������������������������������������������������0123456789-�!""�%&()=?�`@$*+#',.-_;: " &_
			vbTab & vbCrLf & vbCr & vbLf & vbNewLine
ok = false
abort = false

if UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" then

   trace "processing POST request ..."
   
	
	i = 1
    j = 1
    While abort = false And i < Len(anfrage)
		tmpChar = Mid(anfrage, i, 1)
        While ok = false And j < Len(strValid)
            If (tmpChar = Mid(strValid, j, 1)) Then
                ok = True
            End If
			j = j + 1
        Wend
        
        If ok = False Then
			abort = true
        Else
            i = i + 1
            j = 1
            ok = False
        End If
    Wend
   
   If abort = false Then
   
	   message = "Anfrage via Campingboerse betreffend: " & Request("Modell_Titel") & ", id=" & Request("eintrag_id") & "" & vbcrlf &_
													 vbcrlf &_
				 "Name = "    & Request("Name")    & vbcrlf &_
				 "EMail = "   & Request("EMail")   & vbcrlf &_
				 "Telefon = " & Request("Telefon") & vbcrlf &_
				 "Fax = "     & Request("Fax")     & vbcrlf &_
				 "Mobil = "   & Request("Mobil")   & vbcrlf &_
				 "Anfrage = " & Request("Anfrage") & vbcrlf &_
													 vbcrlf &_
				 "Antworten senden Sie bitte nur an folgende Adresse: "  & Request("EMail") & vbcrlf &_
				 "Benutzen Sie bitte nicht die Funktion 'Antworten' Ihres Mail-Programmes!" & vbcrlf &_ 
				 "Vorsicht bei Anfragen von Personen welche ohne vorherigen pers�nlichen Kontakt um �bermittlung Ihrer Bank-Daten bitten. Hierbei k�nnte es sich um Missbrauch handeln. Senden Sie in einem solchen Fall bitte einen Hinweis an unsere Redaktion." & vbcrlf &_
													 vbcrlf &_
				 "Ein Service von www.campingfuehrer.at" & vbcrlf &_
				 "Ein Produkt der Camping.Info GmbH" & vbcrlf &_
													 vbcrlf &_
				 "Unser Tipp: Jetzt Campingpl�tze bewerten auf www.camping.info"
				 

	   '-------------------------------------------------------------------------------
	   rc = DO_Sendmail(x_from, x_to, MAIL_SUBJECT_CONTACT_REQUEST, message, sysMsg)
	   '-------------------------------------------------------------------------------
		  
	   tmp = "from=" & MAIL_FROM & ", to=" & x_to & ", subject=" & MAIL_SUBJECT_CONTACT_REQUEST &_
			 ", message=" & message & ", sysMsg=" & sysMsg 
	   call DB_Write2EventLog(EVENT_SENDMAIL_2, rc, "n/a", tmp)
		  
	   
	   ' send a copy of this mail to MAIL_CAMPSITE_ADMIN
	   '-----------------------------------------------------------------------------
	   rc2 = DO_Sendmail(MAIL_FROM, MAIL_CAMPSITE_ADMIN, MAIL_SUBJECT_CONTACT_REQUEST, message, sysMsg)
	   '-----------------------------------------------------------------------------
		  
	   tmp = "from=" & MAIL_FROM & ", to=" & x_to & ", subject=" & MAIL_SUBJECT_CONTACT_REQUEST &_
			 ", message=" & message & ", sysMsg=" & sysMsg 
	   call DB_Write2EventLog(EVENT_SENDMAIL_2, rc2, "n/a", tmp)      
	   ' now we ignore rc2 !!!      

	   ' Aenderung AZ: Falls der Newsletter gewuenscht wird, sende eine weitere E-Mail
	   

	   if Request("Newsletter") = "on" then

		 headerNewsletter = "Camping-Newsletter - Bitte bestaetigen"
		 messageNewsletter = "Lieber Campingfreund!" & vbcrlf & vbcrlf &_
			"Vielen Dank f�r die Anmeldung zu unserem Newsletter. Damit Ihre E-Mail-Adresse " & vbcrlf &_
			"in unserem Newsletterverteiler aufgenommen wird, best�tigen Sie" & vbcrlf &_
			"bitte Ihre Anmeldung, in dem Sie auf den folgenden Link klicken:" & vbcrlf & vbcrlf &_
			"http://www.campingfuehrer.at/Service/Automaticnewsletter/Deutsch/newsletter.asp?" &_
			"Action=confirmation&EMail=" & Server.URLEncode( Request("EMail") ) & "&Name=" &_
				Server.URLEncode(Request("Name")) & vbcrlf & vbcrlf & vbcrlf &_
			"Sollte der Link nicht anklickbar sein, dann kopieren Sie bitte den" & vbcrlf &_
			"Link-Text und f�gen Sie diesen in die Adresszeile Ihres Browsers ein. " & vbcrlf & vbcrlf &_
			"Mit freundlichen Gr��en, " & vbcrlf & vbcrlf &_
			"Ihr Team von" & vbcrlf &_
			"Campingfuehrer.at" & vbcrlf &_
			"Das Camping-Netzwerk �sterreich" & vbcrlf &_
			"ein Produkt der" & vbcrlf &_
			"camping.info gmbh" & vbcrlf &_
			"5211 Friedburg - �sterreich" & vbcrlf

		 '-----------------------------------------------------------------------------
		 rc3 = DO_Sendmail(MAIL_FROM, x_from, headerNewsletter, messageNewsletter, sysMsg)
		 '-----------------------------------------------------------------------------
		
	   end if
		  
	   if rc = 0 then
		  
		  trace "success!"
		  infoMsg = "Ihre Anfrage wurde an den Anbieter �bersendet!"
			 
	   else
		  
		  ' sendmail error
		  errMsg = "Server Fehler: Beim Versenden Ihrer EMail ist ein Fehler aufgetreten!"
			 
	   end if
   
   Else
      trace """Anfrage"" contained unallowed characters - not sending mail" 
	  errMsg = "ACHTUNG: Ihre Anfrage konnte leider nicht abgesendet werden. Bitte verwenden Sie im Textfeld keine der folgenden Zeichen: / < > [ ]  Bitte rufen Sie das Inserat nochmal auf und senden Sie die Anfrage erneut ab. Vielen Dank. (" & tmpChar & "-" & Asc(tmpChar) & ")"
   End If

end if

%>

<html>

<head>
<meta http-equiv="Content-Language" content="de">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>Contact Request</title>
<meta name="description" content="Gebrauchte Reisemobile, Wohnwagen und Zubeh�r mit H�ndleradressen.">
<meta name="keywords" content="Reisemobil, Wohnmobil, Motorhome, RV, Motorcaravan, Mobil, Freizeitmobil, Recreation Vehicle, Camper, Campingbus, Camping Car, Camping, Freizeit, Urlaub, Reisen, Vehicle, Roulotte, Van, Fun Cars, Autocaravan, Kampeerauto, Zwerfauto, Gebrauchte, Gebrauchtfahrzeuge, B�rse, Automarkt, Gebrauchmarkt, Schn�ppchen, Alkoven, Integrierte, Teilintegrierte, Kastenwagen, Pickup, Sonderfahrzeug">
<link rel="stylesheet" type="text/css" href="../css/boerse_standard.css">
<style>
</style>

<!-- rc=<%=rc%> -->
<!-- sysMsg=<%=sysMsg%> -->
<link rel="P3Pv1" href="http://www.campingboerse.at/service/w3c/p3p.xml">
</head>

<body>

<div align="center">
  <center>
  <table border="0" cellpadding="2" cellspacing="1" width="98%">
    <tr>
      <td width="100%">
      
<%'================================================================================%>
<%if matchString(Rubrik, RUBRIK_WOHNMOBIL) then%>
<%'================================================================================%>

  <center>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td width="90%" align="left"><a href="Start.asp?<%=urlParams%>">Campingb�rse</a> |
        <a href="Filter.asp?<%=urlParams%>">Reisemobilsuche</a> | <a href="Liste.asp?<%=urlParams%>">Liste</a>
        | <a href="Details.asp?<%=urlParams%>"> Details</a> | Kontaktaufnahme</td>
      <td width="10%" align="right">
      </td>
    </tr>
  </table>
  </center>

<%'================================================================================%>
<%elseif matchString(Rubrik, RUBRIK_WOHNWAGEN) then%>
<%'================================================================================%>

  <center>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td width="90%" align="left"><a href="Start.asp">Campingb�rse</a> | <a href="Filter.asp?<%=urlParams%>">Wohnwagensuche</a>
        | <a href="Liste.asp?<%=urlParams%>"> Liste</a> | <a href="Details.asp?<%=urlParams%>">Details</a>
        |
        Kontaktaufnahme</td>
      <td width="10%" align="right">
      </td>
    </tr>
  </table>
  </center>

<%'================================================================================%>
<%elseif matchString(Rubrik, RUBRIK_KLAPPZELT) then%>
<%'================================================================================%>

  <center>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td width="90%" align="left"><a href="Start.asp?<%=urlParams%>">Campingb�rse</a> |
        <a href="Filter.asp?<%=urlParams%>">Klappzeltanh�gersuche</a> | <a href="Liste.asp?<%=urlParams%>"> Liste</a>
        | <a href="Details.asp?<%=urlParams%>">Details</a> | Kontaktaufnahme</td>
      <td width="10%" align="right">
      </td>
    </tr>
  </table>
  </center>

<%'================================================================================%>
<%elseif matchString(Rubrik, RUBRIK_ZUBEHOER) then%>
<%'================================================================================%>

  <center>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td width="90%" align="left"><a href="Start.asp?<%=urlParams%>">Campingb�rse</a> |
        <a href="Filter.asp?<%=urlParams%>">Zubeh�rsuche</a> | <a href="Liste.asp?<%=urlParams%>"> Liste</a>
        | <a href="Details.asp?<%=urlParams%>">Details</a> | Kontaktaufnahme</td>
      <td width="10%" align="right">
      </td>
    </tr>
  </table>
  </center>

<%'================================================================================%>
<%end if%>
<%'================================================================================%>


<!--webbot bot="Include" U-Include="../incHTML/inc_space_hnav_content.htm" TAG="BODY" startspan -->
<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td width="100%" colspan="2"><img border="0" src="../UserManagement/images/1x1.gif" WIDTH="10" HEIGHT="20"></td>
  </tr>
</table>

<!--webbot bot="Include" i-checksum="50745" endspan --><p><b><font color="#FF0000"><%=ErrMsg%><%=infoMsg%></font></b></p>


  <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td width="100%">
		<!--webbot bot="Include" U-Include="../incHTML/inc_footer.htm" TAG="BODY" startspan -->
<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td width="100%" colspan="2"><img border="0" src="../UserManagement/images/1x1.gif" WIDTH="10" HEIGHT="20"></td>
  </tr>
  <tr>
    <td width="90%">� <a href="http://www.campsite.at" target="_blank">Campingfuehrer.at</a>
      &amp; <a target="_blank" href="http://www.camping.info">camping.info</a>&nbsp;-&nbsp;<a href="Impressum.asp" target="_blank">Impressum</a>
      - Alle Rechte vorbehalten. Alle Angaben ohne Gew�hr.<%if not gTrader_ContentSharing then%>&nbsp;<a href="nutzungsbedingungen.asp" target="_blank">Nutzungsbedingungen</a>.<%end if%></td>
    <td width="10%" align="right"><a href="#top"><img border="0" src="../images/Misc/top_grey.gif" width="24" height="24"></a></td>
  </tr>
  <tr>
    <td width="100%" colspan="2"><img border="0" src="../UserManagement/images/1x1.gif" WIDTH="10" HEIGHT="5"></td>
  </tr>  
</table>

<!--webbot bot="Include" i-checksum="2526" endspan --></td>
    </tr>
  </table>
      
      </td>
    </tr>
  </table>
  </center>
</div>
 
</body>

</html>















































