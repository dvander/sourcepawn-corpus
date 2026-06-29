#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PL_VERSION "1.0"
public Plugin:myinfo = 
{
	name = "Razorback Crash Fix",
	author = "MikeJS",
	description = "Fixes razorback crashing server",
	version = PL_VERSION,
	url = "http://www.mikejsavage.com/"
}
public OnPluginStart() {
	CreateConVar("sm_razorbackfix", PL_VERSION, "Razorback Crash Fix version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_OnAnimationBegun);
}
public EntityOutput_OnAnimationBegun(const String:output[], caller, activator, Float:delay) {
	for(new i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && TF2_GetPlayerClass(i)==TFClass_Sniper && GetEntProp(i, Prop_Send, "m_hActiveWeapon")==-1)
			ClientCommand(i, "slot1");
}