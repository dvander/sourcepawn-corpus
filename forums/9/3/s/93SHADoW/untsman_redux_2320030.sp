
#pragma semicolon 1

#include <tf2>
#undef REQUIRE_PLUGIN
#tryinclude <freak_fortress_2>
#define REQUIRE_PLUGIN

#pragma newdecls required

#undef REQUIRE_PLUGIN
#tryinclude <saxtonhale>
#define REQUIRE_PLUGIN

#include <sourcemod>


#if defined _VSH_included
bool isVSH;
#endif

#if defined _FF2_included
bool isFF2;
#endif

public Plugin myinfo = {
	name = "*untsman Redux",
	author = "SHADoW NiNE TR3S",
	description="RIP Skewer taunt",
	version="1.0",
};

public void OnPluginStart()
{	
	#if defined _VSH_included
	isVSH=LibraryExists("saxtonhale");
	#endif

	#if defined _FF2_included	
	isFF2=LibraryExists("freak_fortress_2");
	#endif
	
	AddCommandListener(CMD_Taunt, "taunt"); 
	AddCommandListener(CMD_Taunt, "+taunt");
}

public Action CMD_Taunt(int client, const char[] command, int args)
{
	if(client<=0 || client>MaxClients)
		return Plugin_Continue;

	int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEdict(weapon))
	{
		#if defined _VSH_included
		if(isVSH)
		{
			if(GetClientTeam(client)==view_as<int>(VSH_GetSaxtonHaleTeam()))
				return Plugin_Continue;
		}
		#endif
		
		#if defined _FF2_included
		if(isFF2)
		{
			if(FF2_GetBossIndex(client)>=0)
				return Plugin_Continue;
		}
		#endif
		
		char classname[64];
		GetEdictClassname(weapon, classname, 64);

		if(!StrContains(classname, "tf_weapon_compound_bow"))
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}