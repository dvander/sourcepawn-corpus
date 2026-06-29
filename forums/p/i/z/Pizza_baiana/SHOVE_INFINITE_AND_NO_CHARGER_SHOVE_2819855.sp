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
		SetConVarString(FindConVar("z_gun_swing_vs_cooldown"), "0");
	}
}	
