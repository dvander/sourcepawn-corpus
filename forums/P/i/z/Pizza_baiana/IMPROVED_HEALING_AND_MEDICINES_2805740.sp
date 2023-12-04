#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Fast Healing",
	author = "WhatsAnName",
	description = "changes the first aid kit,pills and shot values",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2596304"
};

public void OnPluginStart()
{
	AutoExecConfig(true, "Fast Healing");
	iChangeCvars();
}

public void vCvarChanges(Handle convar, const char[] oldValue, const char[] newValue)
{
	iChangeCvars();
}

int iChangeCvars()
{
	
	{
		SetConVarString(FindConVar("first_aid_kit_use_duration"), "5");
		
		SetConVarString(FindConVar("first_aid_heal_percent"), "1.0");
		
		SetConVarString(FindConVar("adrenaline_duration"), "150");
		
		SetConVarString(FindConVar("adrenaline_health_buffer"), "100");
		
		SetConVarString(FindConVar("pain_pills_health_value"), "100");
		
		SetConVarString(FindConVar("adrenaline_revive_speedup"), "0.1");
		
		SetConVarString(FindConVar("defibrillator_use_duration"), "1");
	}
}	
