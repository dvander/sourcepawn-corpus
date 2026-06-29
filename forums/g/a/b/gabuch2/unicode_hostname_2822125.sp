#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <files>
#include <string>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME			"Unicode Hostname"
#define PLUGIN_AUTHOR		"gabuch2"
#define PLUGIN_DESCRIPTION	"Adds Unicode support to srcds hostnames"
#define PLUGIN_VERSION		"1.0.0"
#define PLUGIN_URL			"https://github.com/szGabu/UnicodeHostname"

#define DEBUG false

ConVar	g_cvHostName;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	CreateConVar("sm_unicode_hostname_version", PLUGIN_VERSION, "Version of Unicode Hostname", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_cvHostName = FindConVar("hostname");

	ApplyUnicodeName();

	g_cvHostName.AddChangeHook(OnHostNameChanged);
}

public void OnHostNameChanged(Handle cvHostName, const char[] sOldValue, const char[] sNewValue)
{
	#if DEBUG
	PrintToServer("[DEBUG] %s - OnHostNameChanged() - Called. Old Value = %s | New Value = %s", PLUGIN_NAME, sOldValue, sNewValue);
	#endif
	g_cvHostName.RemoveChangeHook(OnHostNameChanged);
	g_cvHostName.SetString(sOldValue);
	g_cvHostName.AddChangeHook(OnHostNameChanged);
}

public void OnConfigsExecuted()
{
	g_cvHostName.RemoveChangeHook(OnHostNameChanged);
}

void ApplyUnicodeName()
{	
	#if DEBUG
	PrintToServer("[DEBUG] %s - ApplyUnicodeName() - Called", PLUGIN_NAME);
	#endif	
	ConVar sCfgFile = FindConVar("servercfgfile");
	char sFileName[PLATFORM_MAX_PATH], sFilePath[PLATFORM_MAX_PATH];
	sCfgFile.GetString(sFileName, sizeof(sFileName));
	FormatEx(sFilePath, sizeof(sFilePath), "cfg/%s", sFileName);

	Handle hSomeFile = OpenFile(sFilePath, "r");

    char sLineBuffer[256];
    while(ReadFileLine(hSomeFile, sLineBuffer, sizeof(sLineBuffer)))
    {
        ReplaceString(sLineBuffer, sizeof(sLineBuffer), "\n", "", false);
		if(StrContains(sLineBuffer, "hostname") == 0)
		{
			ReplaceString(sLineBuffer, sizeof(sLineBuffer), "hostname ", "", true);
			#if DEBUG
			PrintToServer("[DEBUG] %s - ApplyUnicodeName() - Found and parsed hostname, value is: %s", PLUGIN_NAME, sLineBuffer);
			#endif
			//this is needed, otherwise if we use pcvars the server will wait until next frame
			//which will not happen if the server enters into hibernation state (happens in L4D2)
			ServerCommand("hostname %s", sLineBuffer);
			ServerExecute();
			#if DEBUG
			PrintToServer("[DEBUG] %s - ApplyUnicodeName() - Setting value to ConVar", PLUGIN_NAME);
			#endif
			break;
		}
    }
    
    CloseHandle(hSomeFile); 
}