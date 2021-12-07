#include <sourcemod>
#include <sdktools>
/*
killingfloor perks
___________________________________________
perks:
medic
demolitions
support specialist
sharpshooter
firebug
berserker
commando
*/

/*
info:
new gun = GetPlayerWeaponSlot(client, 0);
new ammo = GetEntProp(gun, Prop_Send, "m_iClip1", 1);
new ammo_override = ammo * 2;
SetEntProp(gun, Prop_Send, "m_iClip1", ammo_override, 1); 
/*


#define KILLINGFLOOR "game: killing floor"
#define PERKS 7
#define LEVELS 6
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "killing floor perks",
	author = "gamemann",
	description = "killing floor with l4d",
	version = PLUGIN_VERSION,
	url = "http://games223.com/"
};

//handles
new Handle:AllowPerkProcess = INVALID_HANDLE;

//demolitions include
new GrenadeLauncherDamage = FindConVar();

public OnPluginStart()
{
	//convars

	//events
	
	//notify + consolecmds
	RegConsoleCmd("sm_sharpshooter", Sinfo);
	RegConsoleCmd("sm_berserker", Binfo);
	RegConsoleCmd("sm_demolitions", Dinfo);
	RegConsoleCmd("sm_firebug", Finfo);
	RegConsoleCmd("sm_medic", Minfo);
	RegConsoleCmd("sm_supportspecialist", SSinfo);
	RegConsoleCmd("sm_commando", Cinfo);
	AutoExecConfig(true, "l4d2_killingfloorperks");
}

public Action:Sinfo(client, args)
{
	PrintCenterText(client, "70% better rifle damage, 30% faster reload with rifles, spawn with scout");
	return Plugin_Handled;
}
