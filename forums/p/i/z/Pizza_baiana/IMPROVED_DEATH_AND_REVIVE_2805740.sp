#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Quick Revive",
	author = "WhatsAnName",
	description = "quickly revive teamates",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2596793#post2596793"
};

public void OnPluginStart()
{
	AutoExecConfig(true, "Quick Revive");
	iChangeCvars();
}

public void vCvarChanges(Handle convar, const char[] oldValue, const char[] newValue)
{
	iChangeCvars();
}

int iChangeCvars()
{
	
	{
		SetConVarString(FindConVar("survivor_revive_duration"), "5");
		
		SetConVarString(FindConVar("survivor_revive_health"), "100");
		
		SetConVarString(FindConVar("survivor_respawn_with_guns"), "2");
		
		SetConVarString(FindConVar("survivor_incapacitated_accuracy_penalty"), "0");
		
		SetConVarString(FindConVar("survivor_incapacitated_reload_multiplier"), "0.2");
		
		SetConVarString(FindConVar("survivor_incapacitated_cycle_time"), "0.1");
		
		SetConVarString(FindConVar("survivor_incap_health"), "600");
		
		SetConVarString(FindConVar("survivor_max_incapacitated_count"), "5");
	}
}	
