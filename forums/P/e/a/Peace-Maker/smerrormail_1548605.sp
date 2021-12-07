#pragma semicolon 1
#include <sourcemod>
#include <base64>
#include <socket>

#define PLUGIN_VERSION "1.0"

enum SMTPStatus
{
	SMTP_CONNECT = 0,
	SMTP_EHLO,
	SMTP_AUTH,
	SMTP_USER,
	SMTP_PASSWD,
	SMTP_MAILFROM,
	SMTP_RCPTTO,
	SMTP_ANNOUNCEDATA,
	SMTP_CONTENT,
	SMTP_QUIT
}

new Handle:g_hCVSMTPHost;
new Handle:g_hCVSMTPPort;
new Handle:g_hCVSMTPUser;
new Handle:g_hCVSMTPPass;
new Handle:g_hCVSMTPFrom;
new Handle:g_hCVSMTPTo;

new Handle:g_hErrorLog;
new Handle:g_hSocket = INVALID_HANDLE;
new SMTPStatus:g_iSendPhase = SMTP_CONNECT;
new String:g_sCurrentReceiver[64];
new g_iReceiversAdded;
new g_iNumReceivers;

new String:g_sTouchFile[PLATFORM_MAX_PATH];
new g_iLastLine = 0;
new String:g_sLogs[PLATFORM_MAX_PATH];
new g_iHostIPLong;
new String:g_sHostIP[32];
new g_iHostPort;
new Handle:g_hHostname;

public Plugin:myinfo = 
{
	name = "SM:Error Mail",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Sends an email with error logs to an admin",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_errormail_version", PLUGIN_VERSION, "SM:Error Mail version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	g_hCVSMTPHost = CreateConVar("sm_errormail_host", "", "SMTP server hostname/IP (without http://!)", FCVAR_PLUGIN);
	g_hCVSMTPPort = CreateConVar("sm_errormail_port", "25", "SMTP server port", FCVAR_PLUGIN);
	g_hCVSMTPUser = CreateConVar("sm_errormail_user", "", "SMTP username to login as", FCVAR_PLUGIN);
	g_hCVSMTPPass = CreateConVar("sm_errormail_pass", "", "SMTP user password", FCVAR_PLUGIN);
	g_hCVSMTPFrom = CreateConVar("sm_errormail_from", "", "E-Mail address to send mails from", FCVAR_PLUGIN);
	g_hCVSMTPTo = CreateConVar("sm_errormail_to", "", "E-Mail address(es) to send error logs to. Seperate multiple ones with a ;", FCVAR_PLUGIN);
	
	BuildPath(Path_SM, g_sLogs, sizeof(g_sLogs), "logs");
	BuildPath(Path_SM, g_sTouchFile, sizeof(g_sTouchFile), "data/error_mail.data");
	// Create the file on first run
	if(!FileExists(g_sTouchFile))
	{
		new Handle:hFile = OpenFile(g_sTouchFile, "w");
		if(hFile == INVALID_HANDLE)
		{
			SetFailState("Unable to create memory file: %s", g_sTouchFile);
		}
		WriteFileLine(hFile, "0");
		CloseHandle(hFile);
	}
	
	g_hErrorLog = CreateArray(ByteCountToCells(512));
	
	new Handle:hHandle = FindConVar("hostip");
	g_iHostIPLong = GetConVarInt(hHandle);
	Format(g_sHostIP, sizeof(g_sHostIP), "%d.%d.%d.%d", (g_iHostIPLong >> 24) & 0x000000FF, (g_iHostIPLong >> 16) & 0x000000FF, (g_iHostIPLong >> 8) & 0x000000FF, g_iHostIPLong & 0x000000FF);
	
	g_hHostname = FindConVar("hostname");
	
	hHandle = FindConVar("hostport");
	g_iHostPort = GetConVarInt(hHandle);
	
	AutoExecConfig(true);
}

public OnMapEnd()
{
	decl String:sBuffer[64];
	GetConVarString(g_hCVSMTPHost, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_host unset.");
	GetConVarString(g_hCVSMTPPort, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_port unset.");
	GetConVarString(g_hCVSMTPUser, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_user unset.");
	GetConVarString(g_hCVSMTPPass, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_pass unset.");
	GetConVarString(g_hCVSMTPFrom, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_from unset.");
	GetConVarString(g_hCVSMTPTo, sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_to unset.");
	
	// Create the file on first run
	if(!FileExists(g_sTouchFile))
	{
		new Handle:hFile = OpenFile(g_sTouchFile, "w");
		if(hFile == INVALID_HANDLE)
		{
			SetFailState("Unable to create memory file: %s", g_sTouchFile);
		}
		WriteFileLine(hFile, "0");
		CloseHandle(hFile);
		return;
	}
	
	if(g_iSendPhase > SMTP_CONNECT)
	{
		LogError("Sendmail already in progress");
		return;
	}
	
	new iLastMailSent = GetFileTime(g_sTouchFile, FileTime_LastChange);
	
	new Handle:hDir = OpenDirectory(g_sLogs);
	if(hDir == INVALID_HANDLE)
	{
		SetFailState("No logs dir?! O_o");
	}
	
	new FileType:iFileType, iCreated, iLastCreated, iLastChange, Handle:hFile, iLine;
	decl String:sFile[64], String:sLine[512], String:sFilePath[PLATFORM_MAX_PATH];
	// Loop the logs directory
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iFileType))
	{
		// Only care for files
		if(iFileType != FileType_File)
			continue;
		
		// Only care for error logs
		if(StrContains(sFile, "errors_") != 0)
			continue;
		
		Format(sFilePath, sizeof(sFilePath), "%s/%s", g_sLogs, sFile);
		
		iCreated = GetFileTime(sFilePath, FileTime_Created);
		iLastChange = GetFileTime(sFilePath, FileTime_LastChange);
		
		// We already sent this file
		// Not sure about LastChange result if it hasn't been changed yet, so better save than sorry
		if(iCreated < iLastMailSent && (iLastChange <= 0 || iLastChange < iLastMailSent))
			continue;
		
		iLine = 0;
		// This file is completely new. Send it all!
		if(iCreated > iLastMailSent)
		{
			hFile = OpenFile(sFilePath, "r");
			// Fuck you!
			if(hFile == INVALID_HANDLE)
				continue;
			
			PushArrayString(g_hErrorLog, "");
			Format(sFile, sizeof(sFile), "Errorlog: %s", sFile);
			PushArrayString(g_hErrorLog, sFile);
			PushArrayString(g_hErrorLog, "");
			while(!IsEndOfFile(hFile))
			{
				Format(sLine, sizeof(sLine), "");
				ReadFileLine(hFile, sLine, sizeof(sLine));
				ReplaceString(sLine, sizeof(sLine), "\n", "");
				PushArrayString(g_hErrorLog, sLine);
				iLine++;
			}
			CloseHandle(hFile);
		}
		// There are new errors in that file.
		else if(iLastChange > iLastMailSent)
		{
			hFile = OpenFile(g_sTouchFile, "r");
			ReadFileLine(hFile, sLine, sizeof(sLine));
			CloseHandle(hFile);
			
			// We stored the last line number we sent until
			new iLastSentLine = StringToInt(sLine);
			
			hFile = OpenFile(sFilePath, "r");
			// Fuck you!
			if(hFile == INVALID_HANDLE)
				continue;
			
			PushArrayString(g_hErrorLog, "");
			Format(sFile, sizeof(sFile), "New errorlog in: %s", sFile);
			PushArrayString(g_hErrorLog, sFile);
			PushArrayString(g_hErrorLog, "");
			
			while(!IsEndOfFile(hFile))
			{
				Format(sLine, sizeof(sLine), "");
				ReadFileLine(hFile, sLine, sizeof(sLine));
				ReplaceString(sLine, sizeof(sLine), "\n", "");
				if(iLine >= iLastSentLine)
				{
					PushArrayString(g_hErrorLog, sLine);
				}
				iLine++;
			}
			CloseHandle(hFile);
		}
		
		// Save which file was the latest one.
		// We want to store the sent lines in the memory file
		// That way we only send new errors.
		if(iCreated > iLastCreated)
		{
			iLastCreated = iCreated;
			g_iLastLine = iLine+1;
		}
	}
	
	// No errors! Yay!
	if(GetArraySize(g_hErrorLog) == 0)
		return;
	
	// Find the amount of emails in the convar
	decl String:sEmails[256];
	new String:sEmail[64];
	g_iNumReceivers = 0;
	GetConVarString(g_hCVSMTPTo, sEmails, sizeof(sEmails));
	new iStrLen = strlen(sEmails);
	for(new i=0;i<iStrLen;i++)
	{
		if(sEmails[i] == ';')
		{
			if(strlen(sEmail) == 0)
				continue;
			g_iNumReceivers++;
			Format(sEmail, sizeof(sEmail), "");
		}
		else
			Format(sEmail, sizeof(sEmail), "%s%c", sEmail, sEmails[i]);
	}
	if(strlen(sEmail) > 0)
		g_iNumReceivers++;
	
	// Start sending the mail
	g_hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetOption(g_hSocket, SocketSendTimeout, 10000);
	GetConVarString(g_hCVSMTPHost, sLine, sizeof(sLine));
	iLine = GetConVarInt(g_hCVSMTPPort);
	SocketConnect(g_hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sLine, iLine);
}

public OnSocketConnected(Handle:socket, any:arg)
{
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	decl String:sBuffer[512];
	Format(sBuffer, 4, receiveData);
	new h_ret = StringToInt(sBuffer);
	decl String:sRequest[4096];
	
	switch (g_iSendPhase)
	{
		case SMTP_CONNECT:
		{
			if(h_ret != 220)
			{
				SMTPError(h_ret);
				return;
			}
			Format(sRequest, sizeof(sRequest), "EHLO %d\r\n", g_iHostIPLong);
			g_iSendPhase = SMTP_EHLO;
			SocketSend(socket, sRequest);
		}
		case SMTP_EHLO:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			Format(sRequest, sizeof(sRequest), "AUTH LOGIN\r\n");
			g_iSendPhase = SMTP_AUTH;
			SocketSend(socket, sRequest);
		}
		case SMTP_AUTH:
		{
			if(h_ret != 334)
			{
				SMTPError(h_ret);
				return;
			}
			GetConVarString(g_hCVSMTPUser, sRequest, sizeof(sRequest));
			EncodeBase64(sBuffer, sizeof(sBuffer), sRequest);
			Format(sRequest, sizeof(sRequest), "%s\r\n", sBuffer);
			g_iSendPhase = SMTP_USER;
			SocketSend(socket, sRequest);
		}
		case SMTP_USER:
		{
			if(h_ret != 334)
			{
				SMTPError(h_ret);
				return;
			}
			GetConVarString(g_hCVSMTPPass, sRequest, sizeof(sRequest));
			EncodeBase64(sBuffer, sizeof(sBuffer), sRequest);
			Format(sRequest, sizeof(sRequest), "%s\r\n", sBuffer);
			g_iSendPhase = SMTP_PASSWD;
			SocketSend(socket, sRequest);
		}
		case SMTP_PASSWD:
		{
			if(h_ret != 235)
			{
				SMTPError(h_ret);
				return;
			}
			GetConVarString(g_hCVSMTPFrom, sBuffer, sizeof(sBuffer));
			Format(sRequest, sizeof(sRequest), "MAIL FROM: <%s>\r\n", sBuffer);
			g_iSendPhase = SMTP_MAILFROM;
			SocketSend(socket, sRequest);
		}
		case SMTP_MAILFROM:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			
			SetNextReceiver();
			g_iReceiversAdded++;
			
			Format(sRequest, sizeof(sRequest), "RCPT TO: <%s>\r\n", g_sCurrentReceiver);
			if(g_iReceiversAdded >= g_iNumReceivers)
				g_iSendPhase = SMTP_RCPTTO;
			SocketSend(socket, sRequest);
		}
		case SMTP_RCPTTO:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			Format(sRequest, sizeof(sRequest), "DATA\r\n");
			g_iSendPhase = SMTP_ANNOUNCEDATA;
			SocketSend(socket, sRequest);
		}
		case SMTP_ANNOUNCEDATA:
		{
			if(h_ret != 354)
			{
				SMTPError(h_ret);
				return;
			}
			
			// Setup header options
			GetConVarString(g_hCVSMTPFrom, sBuffer, sizeof(sBuffer));
			new iStrLen = Format(sRequest, sizeof(sRequest), "FROM: <%s>\r\n", sBuffer);
			for(g_iReceiversAdded=0;g_iReceiversAdded<g_iNumReceivers;g_iReceiversAdded++)
			{
				SetNextReceiver();
				iStrLen += Format(sRequest, sizeof(sRequest), "%sTo: <%s>\r\n", sRequest, g_sCurrentReceiver);
			}
			
			GetConVarString(g_hHostname, sBuffer, sizeof(sBuffer));
			iStrLen += Format(sBuffer, sizeof(sBuffer), "New SourceMod errors on %s", sBuffer);
			iStrLen += Format(sRequest, sizeof(sRequest), "%sSubject: %s\r\n\r\n", sRequest, sBuffer);
			
			GetConVarString(g_hHostname, sBuffer, sizeof(sBuffer));
			iStrLen += Format(sRequest, sizeof(sRequest), "%sHello Admin,\r\n\r\nthere are new SourceMod errors on server \"%s\" (%s:%d):\r\n", sRequest, sBuffer, g_sHostIP, g_iHostPort);
			
			// Add the error log content up until the string is full
			new iSize = GetArraySize(g_hErrorLog);
			for(new i=0;i<iSize;i++)
			{
				Format(sBuffer, sizeof(sBuffer), "");
				iStrLen += GetArrayString(g_hErrorLog, i, sBuffer, sizeof(sBuffer)) + 2;
				if((iStrLen+108) > sizeof(sRequest))
				{
					Format(sRequest, sizeof(sRequest), "%s\r\n\r\nThere are still more errors in the logs. Go check them out!\r\n", sRequest);
					break;
				}
				Format(sRequest, sizeof(sRequest), "%s%s\r\n", sRequest, sBuffer);
			}
			
			Format(sRequest, sizeof(sRequest), "%s\r\nSent by SM:Error Mail.", sRequest);
			
			Format(sRequest, sizeof(sRequest), "%s\r\n.\r\n", sRequest);
			g_iSendPhase = SMTP_CONTENT;
			SocketSend(socket, sRequest);
		}
		case SMTP_CONTENT:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			
			Format(sRequest, sizeof(sRequest), "QUIT\r\n");
			g_iSendPhase = SMTP_QUIT;
			SocketSend(socket, sRequest);
		}
		case SMTP_QUIT:
		{
			Finish();
			GetConVarString(g_hCVSMTPTo, sRequest, sizeof(sRequest));
			LogMessage("Error log mail sent to %s!", sRequest);
		}
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	Finish();
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	LogError("Error sending mail: socket error %d (errno %d)", errorType, errorNum);
	Finish(true);
}

Finish(bool:bError=false)
{
	g_iSendPhase = SMTP_CONNECT;
	CloseHandle(g_hSocket);
	ClearArray(g_hErrorLog);
	Format(g_sCurrentReceiver, sizeof(g_sCurrentReceiver), "");
	g_iNumReceivers = 0;
	g_iReceiversAdded = 0;
	
	if(!bError)
	{
		// Save the last sent line to the memory file
		new Handle:hFile = OpenFile(g_sTouchFile, "w");
		WriteFileLine(hFile, "%d", g_iLastLine);
		CloseHandle(hFile);
	}
	
	g_iLastLine = 0;
}

SetNextReceiver()
{
	decl String:sEmails[256];
	new String:sEmail[64];
	GetConVarString(g_hCVSMTPTo, sEmails, sizeof(sEmails));
	new iStrLen = strlen(sEmails);
	new iMails;
	for(new i=0;i<iStrLen;i++)
	{
		if(sEmails[i] == ';')
		{
			if(strlen(sEmail) == 0)
				continue;
			iMails++;
			if(g_iReceiversAdded < iMails)
			{
				Format(g_sCurrentReceiver, sizeof(g_sCurrentReceiver), "%s", sEmail);
				return;
			}
			Format(sEmail, sizeof(sEmail), "");
		}
		else
			Format(sEmail, sizeof(sEmail), "%s%c", sEmail, sEmails[i]);
	}
	
	if(strlen(sEmail) > 0)
		Format(g_sCurrentReceiver, sizeof(g_sCurrentReceiver), "%s", sEmail);
}

SMTPError(errnum)
{
	LogError("Error sending mail: %d", errnum);
	Finish(true);
}