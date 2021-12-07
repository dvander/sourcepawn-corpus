#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Fast Healing KitDur only",
	author = "WhatsAnName",
	description = "changes the first aid kit,pills and shot values",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2596304"
};

public void OnPluginStart()
{
	AutoExecConfig(true, "Fast Healing KitDur only");
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
	}
}	
