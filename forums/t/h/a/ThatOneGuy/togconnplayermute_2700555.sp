/*

*/

#pragma semicolon 1
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define LoopValidPlayers(%1)		for(int %1 = 1; %1 <= MaxClients; %1++)	if(IsValidClient(%1))

ConVar g_cImmunityFlags = null;
char g_sImmunityFlags[100];
ConVar g_cMuteDuration = null;

public Plugin myinfo =
{
	name = "TOG Connecting Players Mute",
	author = "That One Guy",
	description = "Mutes connecting players for a specified length of time unless they have immunity flags.",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togconnplayermute");
	AutoExecConfig_CreateConVar("togconnplayermute_version", PLUGIN_VERSION, "TOG Connecting Players Mute - Version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cImmunityFlags = AutoExecConfig_CreateConVar("togconnplayermute_flags", "ab", "Defines admin flag(s) for mute immunity.", FCVAR_NONE);
	g_cImmunityFlags.GetString(g_sImmunityFlags, sizeof(g_sImmunityFlags));
	g_cImmunityFlags.AddChangeHook(OnCVarChange);
	
	g_cMuteDuration = AutoExecConfig_CreateConVar("togconnplayermute_time", "30", "Number of seconds to mute players when they connect (-1 = Disabled, 0 = Dont unmute).", FCVAR_NONE, true, -1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnCVarChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hCVar == g_cImmunityFlags)
	{
		g_cImmunityFlags.GetString(g_sImmunityFlags, sizeof(g_sImmunityFlags));
	}
}

public void OnClientPutInServer(int client)
{
	if(IsClientAuthorized(client))
	{
		if(HasFlags(client, g_sImmunityFlags))
		{
			return;
		}
	}
	
	switch(g_cMuteDuration.IntValue)
	{
		case -1:
		{
			return;
		}
		case 0:
		{
			//Do Nothing
		}
		default:
		{
			CreateTimer(g_cMuteDuration.FloatValue, TimerCB_Unmute, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	LoopValidPlayers(i)
	{
		SetListenOverride(i, client, Listen_No);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(HasFlags(client, g_sImmunityFlags))
	{
		LoopValidPlayers(i)
		{
			SetListenOverride(i, client, Listen_Yes);
		}
	}
}

public Action TimerCB_Unmute(Handle hTimer, any iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if(!IsValidClient(client))
	{
		return;
	}
	
	LoopValidPlayers(i)
	{
		SetListenOverride(i, client, Listen_Yes);
	}
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}

bool HasFlags(int client, char[] sFlags)	//TOG Flag System
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	else if(StrEqual(sFlags, "none", false))	//useful for some plugins
	{
		return false;
	}
	else if(!client)	//if rcon
	{
		return true;
	}
	else if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	
	AdminId id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	int flags, clientflags;
	clientflags = GetUserFlagBits(client);
	
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		int i = 0, iStrCount = 0;
		while(sFlags[i] != '\0')
		{
			if(sFlags[i++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for stuff after last comma
		
		char[][] a_sTempArray = new char[iStrCount][30];
		ExplodeString(sFlags, ";", a_sTempArray, iStrCount, 30);
		bool bMatching = true;
		
		for(i = 0; i < iStrCount; i++)
		{
			bMatching = true;
			flags = ReadFlagString(a_sTempArray[i]);
			for(int j = 0; j <= 20; j++)
			{
				if(bMatching)	//if still matching, continue loop
				{
					if(flags & (1<<j))
					{
						if(!(clientflags & (1<<j)))
						{
							bMatching = false;
						}
					}
				}
			}
			if(bMatching)
			{
				return true;
			}
		}
		return false;
	}
	else
	{
		flags = ReadFlagString(sFlags);
		for(int i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				if(!(clientflags & (1<<i)))
				{
					return false;
				}
			}
		}
		return true;
	}
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
		
*/