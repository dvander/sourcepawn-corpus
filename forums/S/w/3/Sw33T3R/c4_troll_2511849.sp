#include <PTaH>
#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo =
{
	name = "C4 Troll",
	author = "Nevvy",
	description = "As ADMFLAG_ROOT you can plant and pickup C4 as CT",
	version = "1.0.0",
	url = "http://nevvy.pl http://steamcommunity.com/id/Sw33T3R/"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_c4on", on);
	RegConsoleCmd("sm_c4off", off);
	RegConsoleCmd("sm_c4", c4_give);
}

public Action:c4_give(client, args)
{
	if(client != 0 && !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_c4")
	}
	return Plugin_Handled;
}

public Action:on(client, args)
{
	if(client != 0 && !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(CheckCommandAccess(client, "c4", ADMFLAG_ROOT))
	{
		PrintToChat(client, "[SM] C4 Pickuping is ENABLED");
		PTaH(PTaH_WeaponCanUse, Hook, WeaponCanUse);
	}
	else
	{
		PrintToChat(client, "[SM] You don not have permissions to this command.");
	}

	return Plugin_Handled;
}

public Action:off(client, args)
{
	if(client != 0 && !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(CheckCommandAccess(client, "c4", ADMFLAG_ROOT))
	{
		PrintToChat(client, "[SM] C4 Pickuping is DISABLED");
		PTaH(PTaH_WeaponCanUse, UnHook, WeaponCanUse);
	}
	else
	{
		PrintToChat(client, "[SM] You do not have permissions to this command.");
	}

	return Plugin_Handled;
}

public bool WeaponCanUse(int client, int iEnt, bool CanUse)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		static char sClassname[64];
		GetEdictClassname(iEnt, sClassname, sizeof(sClassname));
		if(StrEqual(sClassname, "weapon_c4"))
		{
			return true;
		}
		return CanUse;
	}
	
	if(CheckCommandAccess(client, "c4", ADMFLAG_ROOT) && (GetClientTeam(client) == CS_TEAM_CT))
	{
		static char sClassname[64];
		GetEdictClassname(iEnt, sClassname, sizeof(sClassname));
		if(StrEqual(sClassname, "weapon_c4"))
		{
			return true;
		}
		return CanUse;
	}
	
	static char sClassname[64];
	GetEdictClassname(iEnt, sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "weapon_c4"))
	{
		return false;
	}
	return CanUse;
}