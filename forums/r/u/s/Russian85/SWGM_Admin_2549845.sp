#pragma semicolon 1
#pragma newdecls required

#include <swgm>

public Plugin myinfo = 
{
	name 		= 		"[SWGM] Admin",
	author 		= 		"Someone",
	version	 	= 		"1.1",
	url 		= 		"http://hlmod.ru"
}

int g_iFlags, g_iPlayerFlags[MAXPLAYERS+1];
bool g_bMode;
	
char g_sGroup[64];

public void OnPluginStart()
{
	ConVar CVAR;
	
	(CVAR = CreateConVar("sm_swgm_admin_mode", "1", "Mode. 0 - Group | 1 - Flags.")).AddChangeHook(ChangeCvar_Mode);
	g_bMode = CVAR.BoolValue;
	
	char sBuffer[22];
	
	(CVAR = CreateConVar("sm_swgm_admin_flags", "a", "Admin flags.")).AddChangeHook(ChangeCvar_Flags);
	CVAR.GetString(sBuffer, sizeof(sBuffer));
	g_iFlags = ReadFlagString(sBuffer);
	
	(CVAR = CreateConVar("sm_swgm_admin_group", "Steam", "Admin group.")).AddChangeHook(ChangeCvar_Group);
	CVAR.GetString(g_sGroup, sizeof(g_sGroup));
	
	AutoExecConfig(true, "swgm_admin");
}

public void ChangeCvar_Mode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMode = convar.BoolValue;
}

public void ChangeCvar_Flags(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char sBuffer[22];
	convar.GetString(sBuffer, sizeof(sBuffer));
	g_iFlags = ReadFlagString(sBuffer);
}

public void ChangeCvar_Group(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sGroup, sizeof(g_sGroup));
}

public void SWGM_OnJoinGroup(int iClient, bool IsOfficer)
{
	if(!IsFakeClient(iClient))
	{
		if(g_bMode)
		{
			g_iPlayerFlags[iClient] = GetUserFlagBits(iClient);
			SetUserFlagBits(iClient, g_iPlayerFlags[iClient] & g_iFlags);
		}
		else
		{
			AdminId id = CreateAdmin();
			id.InheritGroup(FindAdmGroup(g_sGroup));
			SetUserAdmin(iClient, id, true);
		}
	}
}

public void SWGM_OnLeaveGroup(int iClient)
{
	if(g_bMode)	SetUserFlagBits(iClient, g_iPlayerFlags[iClient]);
	else
	{
		AdminId id = GetUserAdmin(iClient);
		RemoveAdmin(id);
	}
}




