#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:KnifeSpeed = INVALID_HANDLE;
new Handle:KnifeGravity = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "CustomSpeed&Gravity",
	author = "apocalyptic",
	description = "gives player your custom speed and gravity when he is holding a knife",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_csg_version", PLUGIN_VERSION, "Custom Speed & Gravity Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	KnifeSpeed = CreateConVar("sm_knifespeed", "1.2", "Knife speed value", FCVAR_PLUGIN);
	KnifeGravity = CreateConVar("sm_knifegravity", "0.8", "Knife gravity value", FCVAR_PLUGIN);

	AutoExecConfig(true);
}

public OnClientPutInServer(client)
{ 
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
} 

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}  

public OnWeaponSwitchPost(client, weapon)
{
	new String:Wpn[24];
	GetClientWeapon(client,Wpn,24);

	if (StrEqual(Wpn,"weapon_knife")){
		SetClientSpeed(client, GetConVarFloat(KnifeSpeed));
		SetEntityGravity(client, GetConVarFloat(KnifeGravity));
	}else{
		SetClientSpeed(client, 1.0);
		SetEntityGravity(client, 1.0);
	}
}

public SetClientSpeed(client,Float:speed) 
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}


