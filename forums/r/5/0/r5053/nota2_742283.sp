//Includes:
#include <sourcemod>

#define PLUGIN_VERSION "2.0.0"

new Handle:CV_blockonlyinspawn
new bool:G_blockonlyinspawn = true
new bool:removingdemageactive = true

new Handle:CV_surv_fff_normal = INVALID_HANDLE
new Handle:CV_surv_fff_hard = INVALID_HANDLE
new Handle:CV_surv_fff_expert = INVALID_HANDLE

new g_cvarbuffer_normal = 0
new g_cvarbuffer_hard = 0
new g_cvarbuffer_expert = 0

public Plugin:myinfo = 
{
	name = "L4D Friendly Fire damage remover",
	author = "R-Hehl",
	description = "L4D TA Blocker",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	CreateConVar("sm_l4d_ff_dmgrmv_version", PLUGIN_VERSION, "L4D TA Blocker", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CV_blockonlyinspawn = CreateConVar("l4dtk_blockonlyinspawn", "1", "Remove Demage only in the Spawnroom")

	HookEvent("player_left_start_area", Event_player_left_start_area)
	HookEvent("round_start", Event_round_start)
	HookConVarChange(CV_blockonlyinspawn,OnConVarChangebis)
	CV_surv_fff_normal = FindConVar("survivor_friendly_fire_factor_normal")
	CV_surv_fff_hard = FindConVar("survivor_friendly_fire_factor_hard")
	CV_surv_fff_expert = FindConVar("survivor_friendly_fire_factor_expert")
}

	
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (G_blockonlyinspawn)
	{
	removingdemageactive = true
	SetConVarInt(CV_surv_fff_normal,0)
	SetConVarInt(CV_surv_fff_hard,0)
	SetConVarInt(CV_surv_fff_expert,0)
	PrintToChatAll("\x04[\x03L4D-TA-BLOCK\x04]\x01 Blocking Active")
	}
}
public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (removingdemageactive)
	{
	if (G_blockonlyinspawn)
	{
	removingdemageactive = false
	SetConVarInt(CV_surv_fff_normal,g_cvarbuffer_normal)
	SetConVarInt(CV_surv_fff_hard,g_cvarbuffer_hard)
	SetConVarInt(CV_surv_fff_expert,g_cvarbuffer_expert)
	PrintToChatAll("\x04[\x03L4D-TA-BLOCK\x04]\x01 Blocking Inactive")
	}
	}
}
public OnConVarChangebis(Handle:convar, const String:oldValue[], const String:newValue[])
{
	G_blockonlyinspawn = GetConVarBool(CV_blockonlyinspawn)
}
public OnConfigsExecuted()
{
	G_blockonlyinspawn = GetConVarBool(CV_blockonlyinspawn)
	g_cvarbuffer_normal = GetConVarInt(CV_surv_fff_normal)
	g_cvarbuffer_hard = GetConVarInt(CV_surv_fff_hard)
	g_cvarbuffer_hard = GetConVarInt(CV_surv_fff_expert)
}