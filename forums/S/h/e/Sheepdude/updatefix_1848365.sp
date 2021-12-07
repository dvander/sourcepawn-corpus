#include <sourcemod>

#pragma semicolon 1

new Handle:h_cvarSPTime;
new Handle:h_cvarDmgToKick;
new Handle:h_cvarDmgToWarn;
new Handle:h_cvarSpawnDmg;

public OnPluginStart()
{
	h_cvarSPTime = FindConVar("mp_spawnprotectiontime");
	h_cvarDmgToKick = FindConVar("mp_td_dmgtokick");
	h_cvarDmgToWarn = FindConVar("mp_td_dmgtowarn");
	h_cvarSpawnDmg = FindConVar("mp_td_spawndmgthreshold");
}

public OnMapStart()
{
	CreateTimer(15.0, SetStats);
}

public Action:SetStats(Handle:timer, any:data)
{
	SetConVarInt(h_cvarSPTime, 0);
	SetConVarInt(h_cvarDmgToKick, 100000);
	SetConVarInt(h_cvarDmgToWarn, 100000);
	SetConVarInt(h_cvarSpawnDmg, 100000);
}