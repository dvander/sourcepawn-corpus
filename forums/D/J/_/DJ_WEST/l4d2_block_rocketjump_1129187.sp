/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "Block Rocket Jump Exploit",
	author = "DJ_WEST",
	description = "Block rocket jump exploit (with grenade launcher/vomitjar/pipebomb/molotov)",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

public OnPluginStart()
{
	decl String:s_Game[12], Handle:h_Version
	
	GetGameFolderName(s_Game, sizeof(s_Game))
	if (!StrEqual(s_Game, "left4dead") && !StrEqual(s_Game, "left4dead2"))
		SetFailState("Block Rocket Jump Exploit supports Left 4 Dead and Left 4 Dead 2 only!")
	
	h_Version = CreateConVar("block_rocketjump_version", PLUGIN_VERSION, "Block Rocket Jump Exploit version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(h_Version, PLUGIN_VERSION)
}

public OnEntityCreated(i_Ent, const String:s_ClassName[])
{
	if (StrEqual(s_ClassName, "vomitjar_projectile") || StrEqual(s_ClassName, "molotov_projectile") || StrEqual(s_ClassName, "pipe_bomb_projectile") || StrEqual(s_ClassName, "grenade_launcher_projectile"))
		SDKHook(i_Ent, SDKHook_Touch, OnEntityTouch)
}

public OnEntityTouch(i_Ent, i_Touched)
{
	if (1 <= i_Touched <= MaxClients && !IsFakeClient(i_Touched))
	{
		if (GetEntPropEnt(i_Touched, Prop_Data, "m_hGroundEntity") == i_Ent)
		{
			decl Float:f_Velocity[3]
	
			GetEntPropVector(i_Touched, Prop_Data, "m_vecVelocity", f_Velocity)
			TeleportEntity(i_Touched, NULL_VECTOR, NULL_VECTOR, f_Velocity)
		}
	}
}