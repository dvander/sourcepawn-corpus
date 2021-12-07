#include <sourcemod>
#include <cstrike>
#include <regex>


#pragma semicolon 1



#define PLUGIN_VERSION "1.2.0"



// Version Cvar
new Handle:g_hVersionCvar;


// AdtArray
new Handle:g_Adt;


// Invert Cvar
new Handle:g_hInvertCvar;
new bool:g_Invert;


// Adminimmunity
new Handle:g_hAdminImmune;
new bool:g_AdminImmune;


// Adminflag
new Handle:g_hAdminFlag;
new String:g_AdminFlag[2];


// Spamprotection, Kind of...
new g_ClientSpamTime[MAXPLAYERS+1];


// Case sensitive
new Handle:g_hCaseSensitive;
new bool:g_CaseSensitive;


// Regexfilter
new Handle:g_Regex;



// ChangeTag
new Handle:g_hChangeTag;
new String:g_ChangeTag[MAX_NAME_LENGTH];



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
	g_Regex = CompileRegex("^#\\.[0-9]+$");
	g_Adt = CreateArray(32);
	
	
	g_hVersionCvar   = CreateConVar("sm_tagblocker_version", PLUGIN_VERSION, "TagBlocker Version (Not changeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hInvertCvar    = CreateConVar("sm_tagblocker_invert", "0", "0 = All players wearing a tag in the list gets them removed 1 = All players don't wearing one of the tags in the list gets them removed", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAdminImmune   = CreateConVar("sm_tagblocker_adminimmunity", "1", "Whether or not admins should be immune to tagstripping", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAdminFlag     = CreateConVar("sm_tagblocker_adminflag", "b", "Which flag an admin needs to have to be immune to tagstripping", FCVAR_PLUGIN);
	g_hCaseSensitive = CreateConVar("sm_tagblocker_casesensitive", "1", "Whether or not searches to tagstripping should be case sensitive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hChangeTag     = CreateConVar("sm_tagblocker_changetag", "", "Which tag gets set on players who are not allowed to wear their own", FCVAR_PLUGIN);
	
	RegServerCmd("sm_tagblocker_addtag", Command_AddTag, "Add's a tag to the list");
	RegServerCmd("sm_tagblocker_deltag", Command_DelTag, "Removes a tag from the list");
	RegServerCmd("sm_tagblocker_listtags", Command_ListTags, "List's all tags");
	
	
	AutoExecConfig(true, "plugin.tagblocker");
	
	
	g_Invert        = GetConVarBool(g_hInvertCvar);
	g_AdminImmune   = GetConVarBool(g_hAdminImmune);
	g_CaseSensitive = GetConVarBool(g_hCaseSensitive);
	GetConVarString(g_hAdminFlag, g_AdminFlag, sizeof(g_AdminFlag));
	
	
	HookConVarChange(g_hInvertCvar, OnCvarChanged);
	HookConVarChange(g_hAdminImmune, OnCvarChanged);
	HookConVarChange(g_hAdminFlag, OnCvarChanged);
	HookConVarChange(g_hVersionCvar, OnCvarChanged);
	HookConVarChange(g_hCaseSensitive, OnCvarChanged);
	HookConVarChange(g_hChangeTag, OnCvarChanged);
}




public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	g_Invert        = GetConVarBool(g_hInvertCvar);
	g_AdminImmune   = GetConVarBool(g_hAdminImmune);
	g_CaseSensitive = GetConVarBool(g_hCaseSensitive);
	
	GetConVarString(g_hAdminFlag, g_AdminFlag, sizeof(g_AdminFlag));
	SetConVarString(g_hVersionCvar, PLUGIN_VERSION, true, false);
	
	GetConVarString(g_hChangeTag, g_ChangeTag, sizeof(g_ChangeTag));
	
	if(!IsCharAlpha(g_AdminFlag[0]) || g_AdminFlag[0] == '\0')
	{
		SetConVarString(g_hAdminFlag, "b", true, false);
		ThrowError("AdminFlag Convar must be Alpha");
	}
}




public OnClientSettingsChanged(client) 
{
	if(g_ClientSpamTime[client] == 0 || g_ClientSpamTime[client] <= (GetTime() -1))
	{
		g_ClientSpamTime[client] == GetTime();
		CheckClient(client);
	}
}




public Action:OnClientCommand(client, args)
{
	if(g_ClientSpamTime[client] == 0 || g_ClientSpamTime[client] <= (GetTime() -1))
	{
		g_ClientSpamTime[client] == GetTime();
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

			if(MatchRegex(g_Regex, arg1) == 1)
			{
				new StrIndex;
				
				ReplaceString(arg1, sizeof(arg1), "#.", "", g_CaseSensitive);
				
				StrIndex = StringToInt(arg1);
				
				if(StrIndex < ArraySize)
				{
					RemoveFromArray(g_Adt, StrIndex);
					PrintToServer("Tag: %d: was removed from the list", StrIndex);
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
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		// If no immunity active, or immunity is active and user is no admin
		if(!g_AdminImmune || g_AdminImmune && !CheckCommandAccess(client, "sm_tagblocker_immune", ReadFlagString(g_AdminFlag)))
		{
			new String:ClanTag[32];
			new String:TempTag[32];
			new ArraySize = GetArraySize(g_Adt);
			
			CS_GetClientClanTag(client, ClanTag, sizeof(ClanTag));
			
			if(strlen(ClanTag) > 0)
			{
				new bool:rename;
				
				if(g_Invert)
				{
					rename = true;
					for(new i; i < ArraySize; i++)
					{
						GetArrayString(g_Adt, i, TempTag, sizeof(TempTag));
						
						if(StrEqual(ClanTag, TempTag, g_CaseSensitive))
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
						
						if(StrEqual(ClanTag, TempTag, g_CaseSensitive))
						{
							rename = true;
							break;
						}
					}
				}
				
				if(rename) 
				{
					CS_SetClientClanTag(client, g_ChangeTag);
				}
			}
		}
	}
}
	