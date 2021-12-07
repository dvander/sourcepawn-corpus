//Includes:
#include <sourcemod>

#define PLUGIN_VERSION "1.3.0"

new Handle:g_blockonlyinspawn
new bool:removingdemageactive = true
new Handle:CV_silentmode = INVALID_HANDLE
new bool:silentmode = false
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
	g_blockonlyinspawn = CreateConVar("l4dtk_blockonlyinspawn", "1", "Remove Demage only in the Spawnroom")

	HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre)

	HookEvent("player_left_start_area", Event_player_left_start_area)
	HookEvent("round_start", Event_round_start)
	
	CV_silentmode = CreateConVar("sm_nota_silent","0","0 = Not Silent, 1 = No Chat Status Messages");
	HookConVarChange(CV_silentmode,OnCVChangenotasilent)

}

	public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (removingdemageactive)
{
	new victimId = GetEventInt(event, "userid")
	new attackerId = GetEventInt(event, "attacker")
	if ((victimId != 0) && (attackerId != 0))
    {
	new victim = GetClientOfUserId(victimId)
	new attacker = GetClientOfUserId(attackerId)
	if (IsClientInGame(victim)){
	if (IsClientInGame(attacker)){
	if (GetClientTeam(victim) == GetClientTeam(attacker))
	{
	SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")))
	}
	}
	}
	}
}
	return Plugin_Continue	
	
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (GetConVarBool(g_blockonlyinspawn))
	{
	removingdemageactive = true
	if (!silentmode)
	{
	PrintToChatAll("\x04[\x03L4D-TA-BLOCK\x04]\x01 Blocking Active")
	}
	}
}
public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (removingdemageactive)
	{
	if (GetConVarBool(g_blockonlyinspawn))
	{
	removingdemageactive = false
	if (!silentmode)
	{
	PrintToChatAll("\x04[\x03L4D-TA-BLOCK\x04]\x01 Blocking Inactive")
	}
	}
	}
}
public OnCVChangenotasilent(Handle:convar, const String:oldValue[], const String:newValue[])
{
	silentmode = GetConVarBool(CV_silentmode)
}
public OnConfigsExecuted()
{
	silentmode = GetConVarBool(CV_silentmode)
}