/*

*/

#pragma semicolon 1
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

ConVar g_cAccessFlag = null;
char g_sAccessFlag[50];
ConVar g_cBlockByDefault = null;

bool ga_bBlockKnife[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
	name = "TOG Knife Blocker",
	author = "That One Guy",
	description = "Allows players with configurable access to turn off knife damage against them.",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togknifeblocker");
	AutoExecConfig_CreateConVar("version_togknifeblocker", PLUGIN_VERSION, "FILENAME - Version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cAccessFlag = AutoExecConfig_CreateConVar("togknifeblocker_access", "a", "Defines admin flag(s) required to toggle knife damage.", FCVAR_NONE);
	g_cAccessFlag.GetString(g_sAccessFlag, sizeof(g_sAccessFlag));
	g_cAccessFlag.AddChangeHook(OnCVarChange);
	
	g_cBlockByDefault = AutoExecConfig_CreateConVar("togknifeblocker_default", "0", "1 = Block damage by default. 0 = Dont block by default.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("sm_knifedmg", Cmd_ToggleKnifeDmg, "Toggle knife damage if you have access per CVar togknifeblocker_access.");
	RegConsoleCmd("sm_knifedamage", Cmd_ToggleKnifeDmg, "Toggle knife damage if you have access per CVar togknifeblocker_access.");
	RegConsoleCmd("sm_blockknife", Cmd_ToggleKnifeDmg, "Toggle knife damage if you have access per CVar togknifeblocker_access.");
}

public void OnCVarChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hCVar == g_cAccessFlag)
	{
		g_cAccessFlag.GetString(g_sAccessFlag, sizeof(g_sAccessFlag));
	}
}

public void OnClientConnected(int client)
{
	ga_bBlockKnife[client] = g_cBlockByDefault.BoolValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client))
	{
		return;
	}
	
	if(HasFlags(client, g_sAccessFlag))
	{
		ga_bBlockKnife[client] = true;
		PrintToChat(client, " \x01\x04Knife damage against you has been blocked! You can enable knife damage with chat command: !knifedmg");
	}
}

public Action Cmd_ToggleKnifeDmg(int client, int iArgs)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "You must be in game to use this command!");
		return Plugin_Handled;
	}
	
	if(!HasFlags(client, g_sAccessFlag))
	{
		ReplyToCommand(client, "You do not have access to this command!");
		return Plugin_Handled;
	}
	
	ga_bBlockKnife[client] = !ga_bBlockKnife[client];
	if(ga_bBlockKnife[client])
	{
		PrintToChat(client, " \x01\x04Knife damage against you has been DISABLED!");
	}
	else
	{
		PrintToChat(client, " \x01\x04Knife damage against you has been ENABLED!");
	}
	return Plugin_Handled;
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &fDamage, int &damagetype, int &weapon, float a_fDmgForce[3], float a_fDmgPosition[3]/*, int damagecustom*/)
{
	if(!IsValidClient(victim))
	{
		return Plugin_Continue;
	}
	
	if(!ga_bBlockKnife[victim])
	{
		return Plugin_Continue;
	}
	
	if(!HasFlags(victim, g_sAccessFlag))
	{
		return Plugin_Continue;
	}
	
	int iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"); 
	if(iWeapon != -1) 
	{ 
		char sWeaponClass[20]; 
		GetEntityClassname(iWeapon, sWeaponClass, sizeof(sWeaponClass)); 
		if(StrContains(sWeaponClass, "knife", false) != -1) 
		{ 
			fDamage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client, bool bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || (IsFakeClient(client) && !bAllowBots))
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

stock void Log(char[] sPath, const char[] sMsg, any ...)		//TOG logging function - path is relative to logs folder.
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[1500];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
		
*/