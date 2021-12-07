#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Shoveable charger",
	author = "WhatsAnName",
	description = "simply allows charger to be shoved.",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	AutoExecConfig(true, "Shoveable charger");
	iChangeCvars();
}

public void vCvarChanges(Handle convar, const char[] oldValue, const char[] newValue)
{
	iChangeCvars();
}

int iChangeCvars()
{
	
	{
		SetConVarString(FindConVar("z_charger_allow_shove"), "1");
	}
}	
