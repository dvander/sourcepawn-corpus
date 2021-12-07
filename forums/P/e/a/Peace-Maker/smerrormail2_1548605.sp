#pragma semicolon 1
#include <sourcemod>
#include <curl>

#pragma newdecls required
#define PLUGIN_VERSION "2.0"

enum {
	Security_None,
	Security_STARTTLS,
	Security_SSL
};

ConVar g_hCVSMTPHost;
ConVar g_hCVSMTPPort;
ConVar g_hCVSMTPSecure;
ConVar g_hCVSMTPVerifyHost;
ConVar g_hCVSMTPVerifyPeer;
ConVar g_hCVSMTPVerbose;
ConVar g_hCVSMTPUser;
ConVar g_hCVSMTPPass;
ConVar g_hCVSMTPFrom;
ConVar g_hCVSMTPTo;

ArrayList g_hMailContents;
// List of Recipients email addresses.
ArrayList g_hRecipients;

// Path to our state file.
char g_sMemoryFile[PLATFORM_MAX_PATH];
// SourceMod log folder path
char g_sLogs[PLATFORM_MAX_PATH];

// Keep info about the server sending the mail.
char g_sHostIP[32];
int g_iHostPort;
ConVar g_hHostname;

// State
int g_iLastMailSent;
int g_iLastSentLine;
char g_sNewestFileRead[PLATFORM_MAX_PATH];

// Which line we're currently sending in the email body.
int g_iCurrentLine;

public Plugin myinfo = 
{
	name = "SM:Error Mail",
	author = "Peace-Maker",
	description = "Sends an email with error logs to an admin",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public void OnPluginStart()
{
	ConVar hVersion = CreateConVar("sm_errormail_version", PLUGIN_VERSION, "SM:Error Mail version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if(hVersion != null)
		hVersion.SetString(PLUGIN_VERSION);
	
	g_hMailContents = new ArrayList(ByteCountToCells(512));
	g_hRecipients = new ArrayList(ByteCountToCells(64));
	
	g_hCVSMTPHost = CreateConVar("sm_errormail_host", "", "SMTP server hostname/IP (without http://!)", FCVAR_PROTECTED);
	g_hCVSMTPPort = CreateConVar("sm_errormail_port", "25", "SMTP server port", FCVAR_PROTECTED, true, 0.0);
	g_hCVSMTPSecure = CreateConVar("sm_errormail_secure", "0", "Set to 0 for no encryption, 1 for STARTTLS and 2 for SSL/TLS", _, true, 0.0, true, 2.0);
	g_hCVSMTPVerifyHost = CreateConVar("sm_errormail_verifyhost", "1", "If encryption is enabled, verify that the host in the certificate is the one you connect to?", _, true, 0.0, true, 1.0);
	g_hCVSMTPVerifyPeer = CreateConVar("sm_errormail_verifypeer", "1", "If encryption is enabled, verify the host's certificate?", _, true, 0.0, true, 1.0);
	g_hCVSMTPVerbose = CreateConVar("sm_errormail_verbose", "0", "Verbosity of curl communication logging. For debugging.", _, true, 0.0);
	g_hCVSMTPUser = CreateConVar("sm_errormail_user", "", "SMTP username to login as", FCVAR_PROTECTED);
	g_hCVSMTPPass = CreateConVar("sm_errormail_pass", "", "SMTP user password", FCVAR_PROTECTED);
	g_hCVSMTPFrom = CreateConVar("sm_errormail_from", "", "E-Mail address to send mails from", FCVAR_PROTECTED);
	g_hCVSMTPTo = CreateConVar("sm_errormail_to", "", "E-Mail address(es) to send error logs to. Seperate multiple ones with a ;", FCVAR_PROTECTED);
	g_hCVSMTPTo.AddChangeHook(ConVar_RecipientsChanged);
	ParseRecipients();
	
	BuildPath(Path_SM, g_sLogs, sizeof(g_sLogs), "logs");
	BuildPath(Path_SM, g_sMemoryFile, sizeof(g_sMemoryFile), "data/error_mail.data");
	
	ConVar hHostIP = FindConVar("hostip");
	int iHostIPLong = hHostIP.IntValue;
	Format(g_sHostIP, sizeof(g_sHostIP), "%d.%d.%d.%d", (iHostIPLong >> 24) & 0x000000FF, (iHostIPLong >> 16) & 0x000000FF, (iHostIPLong >> 8) & 0x000000FF, iHostIPLong & 0x000000FF);
	
	g_hHostname = FindConVar("hostname");
	
	ConVar hHostPort = FindConVar("hostport");
	g_iHostPort = hHostPort.IntValue;
	
	AutoExecConfig(true, "plugin.smerrormail");
}

public void ConVar_RecipientsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ParseRecipients();
}

public void OnMapEnd()
{
	// Wait a bit so the error session can be closed first in the file.
	CreateTimer(0.5, Timer_AfterMapEnd);
}

public Action Timer_AfterMapEnd(Handle timer)
{
	// Stop if something isn't configured yet.
	VerifyConfiguration();
	
	// Currently sending a mail.. wait.
	if (g_hMailContents.Length > 0)
		return;
	
	int iLastMailSent = -1, iLastLineSent = -1;
	char sLastErrorFileSent[PLATFORM_MAX_PATH];
	// Read the last state from the memory file.
	// First line is the last line in the error file we sent,
	// second line is the filename of the file we last sent from,
	// third line is timestamp when the last mail was sent.
	File hMemoryFile = OpenFile(g_sMemoryFile, "r");
	if (hMemoryFile)
	{
		char sBuffer[32];
		hMemoryFile.ReadLine(sBuffer, sizeof(sBuffer));
		iLastLineSent = StringToInt(sBuffer);
		hMemoryFile.ReadLine(sLastErrorFileSent, sizeof(sLastErrorFileSent));
		hMemoryFile.ReadLine(sBuffer, sizeof(sBuffer));
		iLastMailSent = StringToInt(sBuffer);
	}
	delete hMemoryFile;
	
	// Try to open the logs directory.
	DirectoryListing hDir = OpenDirectory(g_sLogs);
	if (!hDir)
	{
		LogError("Failed to open %s directory.", g_sLogs);
		return;
	}
	
	// Setup mail headers first.
	char sHeader[512];
	
	// Start with the time this mail was sent.
	char sTime[64];
	FormatTime(sTime, sizeof(sTime), "%a, %d %b %Y %H:%M:%S %z");
	Format(sHeader, sizeof(sHeader), "Date: %s", sTime);
	g_hMailContents.PushString(sHeader);
	
	// Add Recipients in the header. This is in addition to the 
	// curl_slist below!
	int iNumRecipients = g_hRecipients.Length;
	char sRecipient[64];
	for (int i=0; i<iNumRecipients; i++)
	{
		g_hRecipients.GetString(i, sRecipient, sizeof(sRecipient));
		Format(sHeader, sizeof(sHeader), "To: <%s>", sRecipient);
		g_hMailContents.PushString(sHeader);
	}
	
	// Set sender.
	char sFrom[128];
	g_hCVSMTPFrom.GetString(sFrom, sizeof(sFrom));
	Format(sHeader, sizeof(sHeader), "From: <%s>", sFrom);
	g_hMailContents.PushString(sHeader);
	
	// Set subject
	char sHostname[64];
	g_hHostname.GetString(sHostname, sizeof(sHostname));
	Format(sHeader, sizeof(sHeader), "Subject: New SourceMod errors on %s", sHostname);
	g_hMailContents.PushString(sHeader);
	// End the header here.
	g_hMailContents.PushString("");
	
	// Add some nice introductionary text.
	g_hMailContents.PushString("Hello Admin,");
	g_hMailContents.PushString("");
	Format(sHeader, sizeof(sHeader), "There are new SourceMod errors on server \"%s\" (%s:%d)", sHostname, g_sHostIP, g_iHostPort);
	g_hMailContents.PushString(sHeader);
	
	// Loop through SourceMod's logs directory
	char sFile[64], sFilePath[PLATFORM_MAX_PATH], sLine[512];
	FileType iFileType;
	int iCurrentLine, iTimeLastChanged;
	int iCurrentTime = GetTime();
	bool bLinesAdded;
	File hLogFile;
	while (hDir.GetNext(sFile, sizeof(sFile), iFileType))
	{
		// Only care for files right now.
		// TODO: recursive?
		if (iFileType != FileType_File)
			continue;
		
		// Only care for error logs.
		if (StrContains(sFile, "errors_") != 0)
			continue;
		
		// Get full path to the file so we can open it.
		Format(sFilePath, sizeof(sFilePath), "%s/%s", g_sLogs, sFile);
		
		// See if we already sent all of this file before.
		iTimeLastChanged = GetFileTime(sFilePath, FileTime_LastChange);
		if(iTimeLastChanged < iLastMailSent)
			continue;
			
		// Don't spam all the error files, if the plugin was just installed.
		// Only print error files that changed in the last 6 hours.
		if (iLastMailSent == -1 && iTimeLastChanged < iCurrentTime - (60*60*6))
			continue;
		
		// Start looking at the file from the beginning.
		iCurrentLine = 1;
		
		// This file is completely new. Send it all!
		
		hLogFile = OpenFile(sFilePath, "r");
		if (!hLogFile)
		{
			LogError("Failed to open error log in %s", sFilePath);
			continue;
		}
		
		// Put log filename on top.
		g_hMailContents.PushString("");
		// This file is completely new.
		if (StrContains(sLastErrorFileSent, sFile) != 0)
			Format(sLine, sizeof(sLine), "Errorlog: %s", sFile);
		// There are new errors in that file.
		else
			Format(sLine, sizeof(sLine), "New errors in: %s", sFile);
		
		g_hMailContents.PushString(sLine);
		g_hMailContents.PushString("");
		
		while (!hLogFile.EndOfFile())
		{
			sLine[0] = 0;
			hLogFile.ReadLine(sLine, sizeof(sLine));
			// Remove the new line at the end.
			ReplaceString(sLine, sizeof(sLine), "\r", "");
			ReplaceString(sLine, sizeof(sLine), "\n", "");
			// Only sent new lines if this is the file we stopped in last.
			if (iCurrentLine > iLastLineSent || StrContains(sLastErrorFileSent, sFile) != 0)
			{
				g_hMailContents.PushString(sLine);
				bLinesAdded = true;
			}
			iCurrentLine++;
		}
		delete hLogFile;
		
		// We send the rest of the last error file.
		// Send all of the next ones, if there are more already.
		if (!StrContains(sLastErrorFileSent, sFile))
			iLastLineSent = -1;
		
		// Save which file was the newest one.
		// We want to store the sent lines # in the memory file
		// That way we only send new errors.
		// This relies on the filesystem giving us the list of files 
		// ordered alphabetically ascending and the error_X.log file names
		// being ascending too.
		// Could use FileTime_Created, but that doesn't seem to be supported
		// by all filesystems. (Thanks wyrda)
		g_iLastSentLine = iCurrentLine-1;
		strcopy(g_sNewestFileRead, sizeof(g_sNewestFileRead), sFile);
	}
	delete hDir;
	
	// We checked the files now.
	g_iLastMailSent = GetTime();
	
	// No new errors! Yay!
	if (!bLinesAdded)
	{
		g_hMailContents.Clear();
		return;
	}
	
	// Add a footer and tell the Recipient it's a generated mail from this script.
	g_hMailContents.PushString("");
	g_hMailContents.PushString("Sent by SM:Error Mail.");
	
	Handle hcURL = curl_easy_init();
	if (!hcURL)
	{
		g_hMailContents.Clear();
		LogError("Failed to send mail. curl_easy_init() == null");
		return;
	}
	
	// Setup default options (from self_test plugin)
	int iCURLDefaultOptions[][2] = {
		{view_as<int>(CURLOPT_NOSIGNAL), 1},
		{view_as<int>(CURLOPT_NOPROGRESS), 1},
		{view_as<int>(CURLOPT_TIMEOUT), 30},
		{view_as<int>(CURLOPT_CONNECTTIMEOUT), 60}
	};
	curl_easy_setopt_int_array(hcURL, iCURLDefaultOptions, sizeof(iCURLDefaultOptions));
	
	// Setup verbosity for debugging.
	curl_easy_setopt_int(hcURL, CURLOPT_VERBOSE, g_hCVSMTPVerbose.IntValue);
	
	// Set username and password
	char sUsername[64];
	g_hCVSMTPUser.GetString(sUsername, sizeof(sUsername));
	curl_easy_setopt_string(hcURL, CURLOPT_USERNAME, sUsername);
	char sPassword[64];
	g_hCVSMTPPass.GetString(sPassword, sizeof(sPassword));
	curl_easy_setopt_string(hcURL, CURLOPT_PASSWORD, sPassword);
	
	// Set the server endpoint
	char sURI[512];
	int iSecurityLevel = g_hCVSMTPSecure.IntValue;
	if (iSecurityLevel == Security_SSL)
		strcopy(sURI, sizeof(sURI), "smtps://");
	else
		strcopy(sURI, sizeof(sURI), "smtp://");
	
	// Upgrade the connection to STARTTLS
	if (iSecurityLevel == Security_STARTTLS)
		curl_easy_setopt_int(hcURL, CURLOPT_USE_SSL, CURLUSESSL_ALL);
	
	// Only set the SSL options if we want encryption at all.
	if (iSecurityLevel > Security_None)
	{
		if (!g_hCVSMTPVerifyHost.BoolValue)
			curl_easy_setopt_int(hcURL, CURLOPT_SSL_VERIFYHOST, 0);
		if (!g_hCVSMTPVerifyPeer.BoolValue)
			curl_easy_setopt_int(hcURL, CURLOPT_SSL_VERIFYPEER, 0);
	}
	
	char sHost[512];
	g_hCVSMTPHost.GetString(sHost, sizeof(sHost));
	// Some smtp servers require a valid fully qualified hostname in the EHLO request.
	// Just set the server's hostname itself here.
	Format(sURI, sizeof(sURI), "%s%s/%s", sURI, sHost, sHost);
	curl_easy_setopt_string(hcURL, CURLOPT_URL, sURI);
	
	// Set port too
	curl_easy_setopt_int(hcURL, CURLOPT_PORT, g_hCVSMTPPort.IntValue);
	
	// Set sender
	curl_easy_setopt_string(hcURL, CURLOPT_MAIL_FROM, sFrom);
	
	// Setup Recipients
	Handle hRecipients = curl_slist();
	if (!hRecipients)
	{
		g_hMailContents.Clear();
		LogError("Error setting up recipients list. curl_slist() == null");
		delete hcURL;
		return;
	}
	
	// Add recipients to the list.
	for (int i=0; i<iNumRecipients; i++)
	{
		g_hRecipients.GetString(i, sRecipient, sizeof(sRecipient));
		curl_slist_append(hRecipients, sRecipient);
	}
	curl_easy_setopt_handle(hcURL, CURLOPT_MAIL_RCPT, hRecipients);
	
	// Setup a callback function to read the mail contents.
	curl_easy_setopt_function(hcURL, CURLOPT_READFUNCTION, CURL_ReadPayload);
	curl_easy_setopt_int(hcURL, CURLOPT_UPLOAD, 1);
	
	// Send the mail.
	g_iCurrentLine = 0;
	curl_easy_perform_thread(hcURL, CURL_OnComplete);
}

public int CURL_OnComplete(Handle hndl, CURLcode code)
{
	// This is sent. Clear it out.
	g_iCurrentLine = 0;
	g_hMailContents.Clear();
	delete hndl;
	
	// Something went wrong..
	if (code != CURLE_OK)
	{
		char sError[256];
		curl_easy_strerror(code, sError, sizeof(sError));
		LogError("Error sending mail: %s", sError);
		return;
	}
	
	// Did it! Save state into file.
	File hMemoryFile = OpenFile(g_sMemoryFile, "w");
	if (!hMemoryFile)
	{
		LogError("Failed to write mail state to %s", g_sMemoryFile);
	}
	else
	{
		char sBuffer[PLATFORM_MAX_PATH];
		Format(sBuffer, sizeof(sBuffer), "%d", g_iLastSentLine);
		hMemoryFile.WriteLine(sBuffer);
		hMemoryFile.WriteLine(g_sNewestFileRead);
		Format(sBuffer, sizeof(sBuffer), "%d", g_iLastMailSent);
		hMemoryFile.WriteLine(sBuffer);
		delete hMemoryFile;
	}
	
	g_iLastMailSent = 0;
	g_iLastSentLine = 0;
	g_sNewestFileRead[0] = 0;
	
	char sRecipients[512];
	g_hCVSMTPTo.GetString(sRecipients, sizeof(sRecipients));
	LogMessage("Error log mail sent to %s!", sRecipients);
}

// Send the mail content.
public int CURL_ReadPayload(Handle hndl, const int bytes, const int nmemb)
{
	// Nothing requested? Don't give anything.
	if(bytes == 0 || nmemb == 0 || (bytes*nmemb) < 1)
    return 0;
	
	// Feed it line by line
	int iNumLines = g_hMailContents.Length;
	if (g_iCurrentLine >= iNumLines)
		return 0;
	
	int iBufferSize = bytes*nmemb;
	char[] sBuffer = new char[iBufferSize];
	
	// Add as much full lines as fit in the buffer.
	char sLine[520];
	for (; g_iCurrentLine<iNumLines; g_iCurrentLine++)
	{
		g_hMailContents.GetString(g_iCurrentLine, sLine, sizeof(sLine));
		// SMTP requires proper \r\n new lines.
		StrCat(sLine, sizeof(sLine), "\r\n");
		
		// Don't put more lines in here than fit.
		// Only put whole lines.
		if (strlen(sBuffer) + strlen(sLine) >= iBufferSize)
			break;
		
		StrCat(sBuffer, iBufferSize, sLine);
	}
	curl_set_send_buffer(hndl, sBuffer);
	
	return strlen(sBuffer);
}

// Make sure we have something in every convar.
void VerifyConfiguration()
{
	char sBuffer[64];
	g_hCVSMTPHost.GetString(sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_host unset.");
		
	g_hCVSMTPPort.GetString(sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_port unset.");
		
	g_hCVSMTPUser.GetString(sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_user unset.");
		
	g_hCVSMTPPass.GetString(sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_pass unset.");
		
	g_hCVSMTPFrom.GetString(sBuffer, sizeof(sBuffer));
	TrimString(sBuffer);
	if(strlen(sBuffer) == 0)
		SetFailState("sm_errormail_from unset.");
		
	if(g_hRecipients.Length == 0)
		SetFailState("sm_errormail_to unset.");
}

void ParseRecipients()
{
	// Remove previous mail addresses first.
	g_hRecipients.Clear();
	
	char sEmails[512];
	g_hCVSMTPTo.GetString(sEmails, sizeof(sEmails));
	int iLen = strlen(sEmails);
	char sEmail[64];
	
	// Split the string at ';' and save all the email addresses.
	for (int i=0; i<iLen; i++)
	{
		// Start of a new mail address.
		if (sEmails[i] == ';')
		{
			// Random ;
			if (sEmail[0] == 0)
				continue;
			
			g_hRecipients.PushString(sEmail);
			sEmail[0] = 0;
			// Skip the ';'
			continue;
		}
		
		// Help readability and ignore whitespace.
		if (sEmails[i] == ' ' || sEmails[i] == '\t')
			continue;
		
		Format(sEmail, sizeof(sEmail), "%s%c", sEmail, sEmails[i]);
	}
	
	if (strlen(sEmail) > 0)
		g_hRecipients.PushString(sEmail);
}