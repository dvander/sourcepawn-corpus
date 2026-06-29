#include <sourcemod>
#include <cstrike>
#include <regex>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN


#pragma semicolon 1



#define PLUGIN_VERSION "1.2.7"



// Version Cvar
new Handle:g_hVersion;


// AdtArray
new Handle:g_Adt;


// Invert Cvar
new Handle:g_hInvert;
new bool:g_bInvert;


// Adminimmunity
new Handle:g_hAdminImmune;
new bool:g_bAdminImmune;


// Spamprotection, Kind of...
new g_iClientSpamTime[MAXPLAYERS+1];


// Case sensitive
new Handle:g_hCaseSensitive;
new bool:g_bCaseSensitive;


// Regexfilter
new Handle:g_hRegex;


// ChangeTag
new Handle:g_hChangeTag;
new String:g_sChangeTag[MAX_NAME_LENGTH];


// ChangeTagEmpty
new Handle:g_hChangeTagEmpty;
new bool:g_bChangeTagEmpty;


// LateLoaded Cvar
new bool:g_bLateLoaded;


// Configfile
new String:g_sConfigFile[PLATFORM_MAX_PATH];



public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}




public Plugin:myinfo = 
{
	name = "TagBlocker",
	author = "Impact",
	description = "Block certain tag's from being used",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}




public OnPluginStart() 
{
	g_hRegex = CompileRegex("^#\\.[0-9]+$");
	g_Adt = CreateArray(32);
	
	
	AutoExecConfig_SetFile("plugin.tagblocker");
	g_hVersion        = AutoExecConfig_CreateConVar("sm_tagblocker_version", PLUGIN_VERSION, "TagBlocker Version (Not changeable)", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hInvert         = AutoExecConfig_CreateConVar("sm_tagblocker_invert", "0", "0 = All players wearing a tag in the list gets them removed 1 = All players don't wearing one of the tags in the list gets them removed", _, true, 0.0, true, 1.0);
	g_hAdminImmune    = AutoExecConfig_CreateConVar("sm_tagblocker_adminimmunity", "1", "Whether or not admins should be immune to tagstripping", _, true, 0.0, true, 1.0);
	g_hCaseSensitive  = AutoExecConfig_CreateConVar("sm_tagblocker_casesensitive", "1", "Whether or not searches to tagstripping should be case sensitive", _, true, 0.0, true, 1.0);
	g_hChangeTag      = AutoExecConfig_CreateConVar("sm_tagblocker_changetag", "", "Which tag gets set on players who are not allowed to wear their own", _);
	g_hChangeTagEmpty = AutoExecConfig_CreateConVar("sm_tagblocker_changetag_empty", "1", "Whether or not empty tags will be replaced by changetag (has no effect if changetag isn't set)", _, true, 0.0, true, 1.0);
	
	
	RegServerCmd("sm_tagblocker_addtag", Command_AddTag, "Add's a tag to the list");
	RegServerCmd("sm_tagblocker_deltag", Command_DelTag, "Removes a tag from the list");
	RegServerCmd("sm_tagblocker_listtags", Command_ListTags, "List's all tags");
	
	
	AutoExecConfig(true, "plugin.tagblocker");
	AutoExecConfig_CleanFile();
	
	
	SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	g_bInvert        = GetConVarBool(g_hInvert);
	g_bAdminImmune   = GetConVarBool(g_hAdminImmune);
	
			
	g_bCaseSensitive = GetConVarBool(g_hCaseSensitive);
	GetConVarString(g_hChangeTag, g_sChangeTag, sizeof(g_sChangeTag));
	
	g_bChangeTagEmpty = GetConVarBool(g_hChangeTagEmpty);
	

	HookConVarChange(g_hVersion, OnCvarChanged);
	HookConVarChange(g_hInvert, OnCvarChanged);
	HookConVarChange(g_hAdminImmune, OnCvarChanged);
	HookConVarChange(g_hCaseSensitive, OnCvarChanged);
	HookConVarChange(g_hChangeTag, OnCvarChanged);
	HookConVarChange(g_hChangeTagEmpty, OnCvarChanged);
	
	
	// Format the configfilepath and load the config
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/%s.%s", "tagblocker_tags", "cfg");
	LoadConfig();
	
	
	// LateLoad;
	if(g_bLateLoaded)
	{
		CheckAllClients();
	}
}





LoadConfig()
{
	// File doesn't exist
	if(!FileExists(g_sConfigFile))
	{
		return;
	}
	
	new Handle:hFile;
	
	hFile = OpenFile(g_sConfigFile, "r");
	
	
	// Failed to open
	if(hFile == INVALID_HANDLE)
	{
		return;
	}
	
	// Buffer must be a little bit bigger to have enouth room for comments
	decl String:sReadBuffer[128];
	
	new len;
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sReadBuffer, sizeof(sReadBuffer)))
	{
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\n", "");
		
		len = strlen(sReadBuffer);
		
		// Add to adt if not already in
		if(len > 0 && len <= 32 && !IsCharSpace(sReadBuffer[0]) && sReadBuffer[0] != '/')
		{
			if(FindStringInArray(g_Adt, sReadBuffer) == -1)
			{
				PushArrayString(g_Adt, sReadBuffer);
			}
		}
	}
	
	CloseHandle(hFile);
}





SaveConfig()
{
	new ArraySize;
	ArraySize = GetArraySize(g_Adt);
	
	
	if(ArraySize == 0)
	{
		return;
	}
	
	
	decl String:sBuffer[32];
	new Handle:hFile;
	
	hFile = OpenFile(g_sConfigFile, "w");
	
	
	// Failed to open
	if(hFile == INVALID_HANDLE)
	{
		return;
	}
	
	
	for(new i; i < ArraySize; i++)
	{
		GetArrayString(g_Adt, i, sBuffer, sizeof(sBuffer));
		WriteFileLine(hFile, "%s", sBuffer);
	}
	
	CloseHandle(hFile);
}





public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == g_hVersion)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	}
	else if(convar == g_hInvert)
	{
		g_bInvert = GetConVarBool(g_hInvert);
		
		// Important cvar changed, check clients
		CheckAllClients();
	}
	else if(convar == g_hAdminImmune)
	{
		g_bAdminImmune = GetConVarBool(g_hAdminImmune);
		
		// Important cvar changed, check clients
		CheckAllClients();
	}
	else if(convar == g_hCaseSensitive)
	{
		g_bCaseSensitive = GetConVarBool(g_hCaseSensitive);
		
		// Important cvar changed, check clients
		CheckAllClients();
	}
	else if(convar == g_hChangeTag)
	{
		GetConVarString(g_hChangeTag, g_sChangeTag, sizeof(g_sChangeTag));
		
		// Important cvar changed, check clients
		CheckAllClients();
	}
	else if(convar == g_hChangeTagEmpty)
	{
		g_bChangeTagEmpty = GetConVarBool(g_hChangeTagEmpty);
		
		// Important cvar changed, check clients
		CheckAllClients();
	}
}





public OnClientSettingsChanged(client) 
{
	if(g_iClientSpamTime[client] == 0 || g_iClientSpamTime[client] <= (GetTime() -1))
	{
		g_iClientSpamTime[client] == GetTime();
		CheckClient(client);
	}
}




public Action:OnClientCommand(client, args)
{
	if(g_iClientSpamTime[client] == 0 || g_iClientSpamTime[client] <= (GetTime() -1))
	{
		g_iClientSpamTime[client] == GetTime();
		CheckClient(client);
	}
	
	return Plugin_Continue;
}




public Action:Command_AddTag(args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if(strlen(arg1) > 0 && !IsCharSpace(arg1[0]))
		{
			if(FindStringInArray(g_Adt, arg1) == -1)
			{
				PushArrayString(g_Adt, arg1);
				PrintToServer("Tag: %s was added to the list", arg1);
				
				// Call the check since we added a new tag
				CheckAllClients();
				
				// Save the config
				SaveConfig();
			}
			else
			{
				PrintToServer("Tag: %s is already in the list", arg1);
			}
		}
	}
	else
	{
		PrintToServer("sm_tagblocker_addtag <tag>");
	}
	
	return Plugin_Handled;
}




public Action:Command_ListTags(args)
{
	new String:Buffer[32];
	new ArraySize = GetArraySize(g_Adt);
	
	if(ArraySize == 0)
	{
		PrintToServer("No tags added yet");
	}
	else
	{
		for(new i; i < ArraySize; i++)
		{
			GetArrayString(g_Adt, i, Buffer, sizeof(Buffer));
			PrintToServer("Tag %d: \"%s\"",i, Buffer);
		}
	}
	
	return Plugin_Handled;
}




public Action:Command_DelTag(args)
{
	if(args == 1)
	{
		new ArraySize = GetArraySize(g_Adt);
		
		if(ArraySize == 0)
		{
			PrintToServer("No tags added yet");
		}
		else
		{
			new String:arg1[32];
			new index;
			
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if(MatchRegex(g_hRegex, arg1) == 1)
			{
				new StrIndex;
				
				ReplaceString(arg1, sizeof(arg1), "#.", "", g_bCaseSensitive);
				
				StrIndex = StringToInt(arg1);
				
				if(StrIndex < ArraySize)
				{
					RemoveFromArray(g_Adt, StrIndex);
					PrintToServer("Tag: %d: was removed from the list", StrIndex);
					
					// Save the config
					SaveConfig();
				}
				else
				{
					PrintToServer("Tag: %d doesn't exist on the list", StrIndex);
				}
			}
			else if( (index = FindStringInArray(g_Adt, arg1)) != -1)
			{
				RemoveFromArray(g_Adt, index);
				PrintToServer("Tag: %s was removed from the list", arg1);
			}
			else
			{
				PrintToServer("Tag: %s doesn't exist on the list", arg1);
			}
		}
	}
	else
	{
		PrintToServer("sm_tagblocker_deltag <tag> | <#.tagnumber>");
	}
	
	return Plugin_Handled;
}




CheckClient(client)
{
	if(IsClientValid(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		// If no immunity active, or immunity is active and user is no admin
		if(!g_bAdminImmune || g_bAdminImmune && !CheckCommandAccess(client, "sm_tagblocker_immune", ADMFLAG_GENERIC))
		{
			new String:ClanTag[32];
			new String:TempTag[32];
			new ArraySize = GetArraySize(g_Adt);
			
			CS_GetClientClanTag(client, ClanTag, sizeof(ClanTag));
			
			if(strlen(ClanTag) > 0)
			{
				new bool:rename;
				
				if(g_bInvert)
				{
					rename = true;
					for(new i; i < ArraySize; i++)
					{
						GetArrayString(g_Adt, i, TempTag, sizeof(TempTag));
						
						if(StrEqual(ClanTag, TempTag, g_bCaseSensitive))
						{
							rename = false;
							break;
						}
					}
				}
				else
				{
					rename = false;
					for(new i; i < ArraySize; i++)
					{
						GetArrayString(g_Adt, i, TempTag, sizeof(TempTag));
						
						if(StrEqual(ClanTag, TempTag, g_bCaseSensitive))
						{
							rename = true;
							break;
						}
					}
				}
				
				if(rename) 
				{
					CS_SetClientClanTag(client, g_sChangeTag);
				}
			}
			else if(g_bChangeTagEmpty && strlen(g_sChangeTag) > 0)
			{
				CS_SetClientClanTag(client, g_sChangeTag);
			}
		}
	}
}




stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}




CheckAllClients()
{
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			OnClientSettingsChanged(i);
		}
	}
}