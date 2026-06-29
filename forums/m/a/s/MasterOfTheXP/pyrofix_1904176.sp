#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Thirdperson Pyro Nope-if-ier",
	author = "MasterOfTheXP",
	description = "Cause it's broken.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new bool:FlamethrowerActive[MAXPLAYERS + 1];

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}
public OnClientPutInServer(client)
{
	if (IsFakeClient(client)) return;
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
	if (!IsValidEntity(weapon))
	{
		FlamethrowerActive[client] = false;
		return;
	}
	new String:cls[35];
	GetEntityClassname(weapon, cls, sizeof(cls));
	if (StrEqual(cls, "tf_weapon_flamethrower", false))
	{
		FlamethrowerActive[client] = true;
		if (GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
			ClientCommand(client, "firstperson"); // Probably faster than AcceptEntityInput(client, "SetForcedTauntCam");
	}
	else FlamethrowerActive[client] = false;
}

public Action:OnClientCommand(client, args)
{
	if (!client) return Plugin_Continue;
	if (!FlamethrowerActive[client]) return Plugin_Continue;
	new String:arg[25];
	GetCmdArg(0, arg, sizeof(arg));
	return (!StrEqual("tp", arg) && !StrEqual("sm_thirdperson", arg)) ? Plugin_Continue : Plugin_Stop;
}