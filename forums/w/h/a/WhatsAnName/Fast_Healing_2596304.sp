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
		SetConVarString(FindConVar("first_aid_kit_use_duration"), "1");
		SetConVarString(FindConVar("first_aid_heal_percent"), "0.99");
		SetConVarString(FindConVar("adrenaline_duration"), "60");
		SetConVarString(FindConVar("adrenaline_health_buffer"), "45");
		SetConVarString(FindConVar("pain_pills_health_value"), "99");
	}
}	
