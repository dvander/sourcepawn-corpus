//Includes:
#include <sourcemod>

#define PLUGIN_VERSION "1.3.0"

new Handle:g_blockonlyinspawn
new bool:removingdemageactive = true
new Handle:CV_silentmode = INVALID_HANDLE
new bool:silentmode = false

new bool:hasLeftSafeArea = false;
new bool:hasLeftCheckPT = false;
new bool:hasOpenedDoor = false;


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
	CreateConVar("sm_l4d_ff_dmgrmv_version", PLUGIN_VERSION, "L4D TA Blocker", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_blockonlyinspawn = CreateConVar("l4dtk_blockonlyinspawn", "1", "Remove Demage only in the Spawnroom")

	HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre)

	HookEvent("player_left_start_area", Event_player_left_start_area)
	HookEvent("round_start", Event_round_start)
	HookEvent("player_left_checkpoint", Event_player_left_checkpoint)
	HookEvent("door_open", Event_DoorOpen)
	HookEvent("round_end", Event_round_end)
	
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
			if (IsClientInGame(victim))
			{
				if (IsClientInGame(attacker))
				{
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
			CreateTimer(4.5, PrintMessegeSafe);
		}
		CreateTimer(0.5, CheckAreaStats);
	}
	
	
}

public Action:PrintMessegeSafe(Handle:timer)
{
	PrintToChatAll("\x03[FFannouce]\x01 Warm-Up Stage, \x04Remove Friendly Fire.")
	removingdemageactive = true;
	return Plugin_Handled;
}

/*public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (removingdemageactive)
	{
		if (GetConVarBool(g_blockonlyinspawn))
		{
			removingdemageactive = false
			if (!silentmode)
			{
				CreateTimer(0.5, PrintMessegeStart);
			}
		}
	}
}*/

public Action:PrintMessegeStart(Handle:timer)
{
	PrintToChatAll("\x03[FFannouce]\x01 Game is on, \x04Fire with caution\x01!")
	return Plugin_Handled;
}

public Action:CheckAreaStats(Handle:timer) {
	if (LeftStartArea()) {
		EnableFF();
	} else if (hasOpenedDoor && hasLeftCheckPT) { 
		EnableFF();
	} else {
		CreateTimer(1.0, CheckAreaStats);
	}
}

public EnableFF(){
	if (removingdemageactive)
	{
		if (GetConVarBool(g_blockonlyinspawn))
		{
			removingdemageactive = false
			if (!silentmode) CreateTimer(0.5, PrintMessegeStart);
		}
	}
}

// Safe Area Checking

public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !hasLeftSafeArea )
	{	
		hasLeftSafeArea = true;
	}
}

public Action:Event_player_left_checkpoint(Handle:event, const String:name[], bool:dontBroadcast)
{

	if ( !hasLeftCheckPT )
	{		
		hasLeftCheckPT = true;		
	}
}

public Action:Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !hasOpenedDoor )
	{		
		hasOpenedDoor = true;
	}
}

public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	hasLeftSafeArea = false;
	hasOpenedDoor = false;
	hasLeftCheckPT = false;
}

bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			hasLeftSafeArea = true;
			return true;
		}
	}
	hasLeftSafeArea = false;
	return false;
}

public OnCVChangenotasilent(Handle:convar, const String:oldValue[], const String:newValue[])
{
	silentmode = GetConVarBool(CV_silentmode)
}

public OnConfigsExecuted()
{
	silentmode = GetConVarBool(CV_silentmode)
}