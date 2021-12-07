/*
 * [Orange Box+] Name Filter
 * 
 * Author:  Grognak
 * Version: 1.0
 * Date:    5/25/12
 *
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME         "Name Filter"
#define PLUGIN_AUTHOR       "Grognak, raziEiL [disawar1]"
#define PLUGIN_DESCRIPTION  "Prevents 'bad word' names."
#define PLUGIN_VERSION      "1.1"
#define PLUGIN_CONTACT      "grognak.tf2@gmail.com"

#define MODE_KICK   0
#define MODE_RENAME 1

new Handle:cvarWarning = INVALID_HANDLE;
new Handle:cvarMode    = INVALID_HANDLE;
new Handle:cvarName    = INVALID_HANDLE;

new Handle:hFile       = INVALID_HANDLE;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/badnames.txt");
	
	hFile = OpenFile(sPath, "r"); // Open the file for reading

	if (hFile == INVALID_HANDLE)
	{
		LogMessage("[ERROR] badnames.txt couldn't be found in /configs. Name Filter cannot load.");
		return APLRes_Failure; 
	}

	return APLRes_Success; // Load the plugin	
}

public OnPluginStart()
{
	CreateConVar("namefilter_version", PLUGIN_VERSION, "Name Filter version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);

	cvarMode = CreateConVar("namefilter_mode", "1", "Set to 0 to kick inappropriate names, set to 1 to rename.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarName = CreateConVar("namefilter_name", "Player ", "New name to switch player to (with numbers appended.)", FCVAR_PLUGIN);	
	cvarWarning = CreateConVar("namefilter_warning", "Please don't use offensive names on this server", "Warning to give players who are renamed or kicked.", FCVAR_PLUGIN);

	AutoExecConfig(true, PLUGIN_NAME);
}

public OnPluginEnd()
{
	CloseHandle(hFile);
}

public bool:OnClientConnect(iClient, String:rejectmsg[], iLength)
{
	if(iClient && !IsFakeClient(iClient) && !IsNameClean(iClient))
	{
		new iMode = GetConVarInt(cvarMode);
		
		if (iMode == MODE_KICK)
		{
			decl String:sKickReason[iLength];
		
			GetConVarString(cvarWarning, sKickReason, iLength);
			Format(rejectmsg, iLength, sKickReason);
			return false; // Kick the player
		}
		else if (iMode == MODE_RENAME)
		{
			if (IsValidEntity(iClient))
				RenameClient(iClient);
		}
	}

	return true; // Don't kick the player
}

public OnClientSettingsChanged(iClient)
{
	if(!IsNameClean(iClient))
	{
		new iMode = GetConVarInt(cvarMode);

		if (iMode == MODE_KICK)
		{
			decl String:sKickReason[128];
		
			GetConVarString(cvarWarning, sKickReason, sizeof(sKickReason));
			KickClient(iClient, sKickReason);
		}
		else if (iMode == MODE_RENAME)
		{
			CreateTimer(0.1, tCheckClient, iClient); // Weird timing spam issues without timer
		}
	}
}

public Action:tCheckClient(Handle:hTimer, any:iClient)
{
	if (!IsClientInGame(iClient))
		return Plugin_Handled;

	if (!IsNameClean(iClient))
	{
		decl String:sWarning[512];

		GetConVarString(cvarWarning, sWarning, sizeof(sWarning));
		PrintToChat(iClient, "\x04%s", sWarning);
			
		RenameClient(iClient);
	}

	return Plugin_Handled;
}

bool:IsNameClean(iClient)
{
	decl String:ClientName[MAX_NAME_LENGTH], String:sLine[128];

	// I forgot: the following two lines don't work before postadmincheck (oops)
	// TODO at some point, admin immunity that works
	//if(GetUserAdmin(iClient) != INVALID_ADMIN_ID)
	//	return true; // Generic Admin Immunity
	
	GetClientName(iClient, ClientName, sizeof(ClientName)); 

	FileSeek(hFile, 0, SEEK_SET); // Reset File Position
	
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, sizeof(sLine)))
	{
		TrimString(sLine); // Necessary?

		if (StrContains(ClientName, sLine, false) != -1)
		{
			LogMessage("Player found with badword in his name: %s", ClientName);
			return false;
		}
	}

	return true;
}

RenameClient(iClient)
{
	decl String:sNewName[MAX_NAME_LENGTH], String:sNumber[6];

	IntToString(GetRandomInt(1, 99999), sNumber, sizeof(sNumber));
	GetConVarString(cvarName, sNewName, sizeof(sNewName));
	
	StrCat(sNewName, sizeof(sNewName), sNumber); // Appends a number to the name

	SetClientInfo(iClient, "name", sNewName);
	SetEntPropString(iClient, Prop_Data, "m_szNetname", sNewName);
}
