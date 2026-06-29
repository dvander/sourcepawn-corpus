#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define CONVAR_COUNT 15
#define SM_NOPARTYPOOPER_VERSION 0
#define SM_NOPARTYPOOPER_ENABLED 1
#define SM_NOPARTYPOOPER_XMIN 2
#define SM_NOPARTYPOOPER_XMAX 3
#define SM_NOPARTYPOOPER_YMIN 4
#define SM_NOPARTYPOOPER_YMAX 5
#define SM_NOPARTYPOOPER_ZMIN 6
#define SM_NOPARTYPOOPER_ZMAX 7
#define SM_NOPARTYPOOPER_INVISIBLE 8
#define SM_NOPARTYPOOPER_STUNNED 9
#define SM_NOPARTYPOOPER_SPEED 10
#define SM_NOPARTYPOOPER_KICKMSG 11
#define SM_NOPARTYPOOPER_WARNMSG 12
#define SM_NOPARTYPOOPER_KILLMSG 13
#define SM_NOPARTYPOOPER_DOMMSG 14

#define MAX_SUPPORTED_PLAYERS 32
#define PLUGIN_VERSION	"0.1"     

public Plugin:myinfo = {
	name = "No party pooper",
	author = "Syranolic",
	description = "Induces a slight penalty for killing from or into the party room.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/Sy7an0lic"
};

new Handle:g_hConVars[CONVAR_COUNT] = {INVALID_HANDLE, ...};

new bool:g_bEnabled = true;
new Float:g_vFreeZone[3][2];
new Float:g_vSentriesPos[MAX_SUPPORTED_PLAYERS+1][3];
new bool:g_bSentriesActive[MAX_SUPPORTED_PLAYERS+1] = {false, ...};
new Handle:g_hInvisibleTimers[MAX_SUPPORTED_PLAYERS+1] = {INVALID_HANDLE, ...};
new Float:g_fInvisible = 4.0;
new Float:g_fStunned = 15.0;
new Float:g_fSpeed = 0.25;
new String:g_sKickMessage[128];
new String:g_sWarnMessage[128];
new String:g_sKillMessage[128];
new String:g_sDomMessage[128];

public OnPluginStart()
{
	g_hConVars[SM_NOPARTYPOOPER_VERSION] = CreateConVar("sm_nopartypooper_version", PLUGIN_VERSION, "No party pooper on my server, by Syranolic", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hConVars[SM_NOPARTYPOOPER_ENABLED] = CreateConVar("sm_nopartypooper_enabled", "1.0", "Set to 0 to disable nopartypooper", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hConVars[SM_NOPARTYPOOPER_XMIN] = CreateConVar("sm_nopartypooper_xmin", "0.0", "Minimum coordinate of the cube along X", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_XMAX] = CreateConVar("sm_nopartypooper_xmax", "0.0", "Maximum coordinate of the cube along X", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_YMIN] = CreateConVar("sm_nopartypooper_ymin", "0.0", "Minimum coordinate of the cube along Y", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_YMAX] = CreateConVar("sm_nopartypooper_ymax", "0.0", "Maximum coordinate of the cube along Y", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_ZMIN] = CreateConVar("sm_nopartypooper_zmin", "0.0", "Minimum coordinate of the cube along Z", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_ZMAX] = CreateConVar("sm_nopartypooper_zmax", "0.0", "Maximum coordinate of the cube along Z", FCVAR_NONE);
	g_hConVars[SM_NOPARTYPOOPER_INVISIBLE] = CreateConVar("sm_nopartypooper_invisible", "4.0", "How long should the victim be invisible to sentries after a hit (in seconds)", FCVAR_NONE, true, 0.5, true, 10.0);
	g_hConVars[SM_NOPARTYPOOPER_STUNNED] = CreateConVar("sm_nopartypooper_stunned", "15.0", "How long should the attacker be stunned after a kill (in seconds)", FCVAR_NONE, true, 0.5, true, 60.0);
	g_hConVars[SM_NOPARTYPOOPER_SPEED] = CreateConVar("sm_nopartypooper_speed", "0.25", "How much slower should the attacker be after a kill (nominal speed factor deduction)", FCVAR_NONE, true, 0.0, true, 1.0);
	strcopy(g_sKickMessage, sizeof(g_sKickMessage), "Don't kill in party room!");
	g_hConVars[SM_NOPARTYPOOPER_KICKMSG] = CreateConVar("sm_nopartypooper_kickmsg", g_sKickMessage, "Message to display as a kick reason", FCVAR_NONE);
	strcopy(g_sWarnMessage, sizeof(g_sWarnMessage), "Don't kill in party room!");
	g_hConVars[SM_NOPARTYPOOPER_WARNMSG] = CreateConVar("sm_nopartypooper_warnmsg", g_sWarnMessage, "Message to display as a warning", FCVAR_NONE);
	strcopy(g_sKillMessage, sizeof(g_sKillMessage), "You got killed in the party room, your opponent will be stunned.");
	g_hConVars[SM_NOPARTYPOOPER_KILLMSG] = CreateConVar("sm_nopartypooper_killmsg", g_sKillMessage, "Hint to display to a killed player", FCVAR_NONE);
	strcopy(g_sDomMessage, sizeof(g_sDomMessage), "You got dominated in the party room, your opponent will be kicked.");
	g_hConVars[SM_NOPARTYPOOPER_DOMMSG] = CreateConVar("sm_nopartypooper_dommsg", g_sDomMessage, "Hint to display to a dominated player", FCVAR_NONE);

	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_ENABLED], conVar_Enabled_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_XMIN], conVar_Xmin_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_XMAX], conVar_Xmax_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_YMIN], conVar_Ymin_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_YMAX], conVar_Ymax_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_ZMIN], conVar_Zmin_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_ZMAX], conVar_Zmax_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_INVISIBLE], conVar_invisible_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_STUNNED], conVar_stunned_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_SPEED], conVar_speed_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_KICKMSG], conVar_kickMsg_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_WARNMSG], conVar_warnMsg_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_KILLMSG], conVar_killMsg_changed);
	HookConVarChange(g_hConVars[SM_NOPARTYPOOPER_DOMMSG], conVar_domMsg_changed);
	
	HookEvent("player_death", event_player_death, EventHookMode_Pre);
	HookEvent("player_hurt", event_player_hurt, EventHookMode_Post);
	HookEvent("player_builtobject", event_player_build, EventHookMode_Post);
	HookEvent("object_removed", event_object_destroyedOrRemoved, EventHookMode_Post);
	HookEvent("object_destroyed", event_object_destroyedOrRemoved, EventHookMode_Post);
}

public OnPluginEnd()
{
}

static resetClientData(client)
{
	g_bSentriesActive[client] = false;
	if (g_hInvisibleTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hInvisibleTimers[client]);
		g_hInvisibleTimers[client] = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	for (new i = 0; i < MAX_SUPPORTED_PLAYERS; i++)
	{
		resetClientData(i);
	}
}

public OnMapEnd()
{
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client) && client <= MaxClients)
	{
		resetClientData(client-1);
	}
}

public conVar_killMsg_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sKillMessage, sizeof(g_sKillMessage), newValue);
}

public conVar_domMsg_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sDomMessage, sizeof(g_sDomMessage), newValue);
}

public conVar_kickMsg_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sKickMessage, sizeof(g_sKickMessage), newValue);
}

public conVar_warnMsg_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sWarnMessage, sizeof(g_sWarnMessage), newValue);
}

public conVar_invisible_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fInvisible = StringToFloat(newValue);
}

public conVar_stunned_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fStunned = StringToFloat(newValue);
}

public conVar_speed_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fSpeed = StringToFloat(newValue);
}

public conVar_Enabled_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = bool:StringToInt(newValue);
	if (g_bEnabled && MaxClients > 32)
	{
		g_bEnabled = false;
		PrintToServer("[NPP] This plugin only supports up to 32 players.");
		return;
	}
}

public conVar_Xmin_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[0][0] = StringToFloat(newValue);
}

public conVar_Xmax_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[0][1] = StringToFloat(newValue);
}

public conVar_Ymin_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[1][0] = StringToFloat(newValue);
}

public conVar_Ymax_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[1][1] = StringToFloat(newValue);
}

public conVar_Zmin_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[2][0] = StringToFloat(newValue);
}

public conVar_Zmax_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_vFreeZone[2][1] = StringToFloat(newValue);
}

static bool:isInPartyRoom(const Float:vPos[3])
{
	for (new i = 0; i < 3; i++)
	{
 		if (vPos[i]<g_vFreeZone[i][0] || vPos[i]>g_vFreeZone[i][1])
			return false;
	}
	return true;
}

static bool:assessPlayerStatus(client_id, &client, &bool:clientInPartyRoom)
{
	client = GetClientOfUserId(client_id);
	if (client < 1 || client > MaxClients)
	{
		//PrintToServer("[NPP] no client");
		return false;
	}
	if (IsFakeClient(client) || !IsClientConnected(client) || !IsClientInGame(client))
	{
		return false;
	}

	decl Float:vecEyePos[3];
	GetClientEyePosition(client, vecEyePos);
	//PrintToServer("[NPP] client \"%L\" eyes %f; %f; %f", client, vecEyePos[0], vecEyePos[1], vecEyePos[2]);
	clientInPartyRoom = isInPartyRoom(vecEyePos);
	
	return true;
}

static bool:assessPlayersStatus(Handle:event, &victim, &bool:victimInPartyRoom, &attacker, &bool:attackerInPartyRoom)
{
	new victim_id = GetEventInt( event, "userid" );
	new attacker_id = GetEventInt( event, "attacker" );
	if (victim_id == attacker_id)
	{
		return false;
	}

	if (!assessPlayerStatus(victim_id, victim, victimInPartyRoom))
	{
		return false;
	}

	if (!assessPlayerStatus(attacker_id, attacker, attackerInPartyRoom))
	{
		return false;
	}

	return true;
}

public Action:event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	
	new victim;
	new bool:victimInPartyRoom;
	new attacker;
	new bool:attackerInPartyRoom;
	if (!assessPlayersStatus( event, victim, victimInPartyRoom, attacker, attackerInPartyRoom))
	{
		return Plugin_Continue;
	}

	new bool:sentryInPartyRoom = false;
	new TFClassType:class = TF2_GetPlayerClass(attacker); 
	if(class == TFClass_Engineer && g_bSentriesActive[attacker-1])
	{
		sentryInPartyRoom = isInPartyRoom(g_vSentriesPos[attacker-1]);
	}

	if (attackerInPartyRoom || victimInPartyRoom || sentryInPartyRoom)
	{
		if (strlen(g_sWarnMessage)>0)
		{
			PrintCenterText(attacker, g_sWarnMessage);
		}
		if (g_hInvisibleTimers[victim] != INVALID_HANDLE)
		{
			KillTimer(g_hInvisibleTimers[victim]);
		}
		new flags = GetEntityFlags(victim)|FL_NOTARGET;
		SetEntityFlags(victim, flags);
		g_hInvisibleTimers[victim] = CreateTimer(g_fInvisible, TargetPlayer, victim);
	}

	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}

	new victim;
	new bool:victimInPartyRoom;
	new attacker;
	new bool:attackerInPartyRoom;
	if (!assessPlayersStatus( event, victim, victimInPartyRoom, attacker, attackerInPartyRoom))
	{
		return Plugin_Continue;
	}
	
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		if (attackerInPartyRoom || victimInPartyRoom)
		{
			if (strlen(g_sWarnMessage)>0)
			{
				PrintCenterText(attacker, g_sWarnMessage);
			}
			if (g_hInvisibleTimers[victim] != INVALID_HANDLE)
			{
				KillTimer(g_hInvisibleTimers[victim]);
			}
			new flags = GetEntityFlags(victim)|FL_NOTARGET;
			SetEntityFlags(victim, flags);
			g_hInvisibleTimers[victim] = CreateTimer(g_fInvisible, TargetPlayer, victim);
		}
		return Plugin_Continue;
	}

	new bool:sentryInPartyRoom = false;
	new TFClassType:class = TF2_GetPlayerClass(attacker); 
	if(class == TFClass_Engineer && g_bSentriesActive[attacker-1])
	{
		sentryInPartyRoom = isInPartyRoom(g_vSentriesPos[attacker-1]);
	}

	if (attackerInPartyRoom || victimInPartyRoom || sentryInPartyRoom)
	{
		new bool:dom = (GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERDOMINATION)!=0;
		if (dom)
		{
			if (strlen(g_sDomMessage)>0)
			{
				PrintHintText(victim, g_sDomMessage);
			}
			CreateTimer(0.5, KickPlayer, attacker);
		}
		else
		{
			if (IsPlayerAlive(attacker))
			{
				if (strlen(g_sKillMessage)>0)
				{
					PrintHintText(victim, g_sKillMessage);
				}
				TF2_StunPlayer(attacker, g_fStunned, g_fSpeed, TF_STUNFLAGS_LOSERSTATE, 0);
			}
		}
	}

	return Plugin_Continue;
}

public Action:event_player_build(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new object = GetEventInt(event, "object");
		new index = GetEventInt(event, "index");
		if(object > 1 && index > MaxClients && IsValidEntity(index))
		{
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", g_vSentriesPos[client-1]);
			g_bSentriesActive[client-1] = true;
			//PrintToServer("[NPP] \"%L\" built a %d at %f; %f; %f", client, object, g_vSentriesPos[client-1][0], g_vSentriesPos[client-1][1], g_vSentriesPos[client-1][2]);
		}
	}
	return Plugin_Continue;
}

public Action:event_object_destroyedOrRemoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new object = GetEventInt(event, "objecttype");
		new index = GetEventInt(event, "index");
		if(object > 1 && index > MaxClients && IsValidEntity(index))
		{
			g_bSentriesActive[client-1] = false;
			//PrintToServer("[NPP] \"%L\" lost/removed a %d", client, object);
		}
	}
	return Plugin_Continue;
}

public Action:KickPlayer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		KickClient(client, g_sKickMessage);
	}
	return Plugin_Handled;
}

public Action:TargetPlayer(Handle:timer, any:client)
{
	g_hInvisibleTimers[client] = INVALID_HANDLE;
	if (IsClientInGame(client))
	{
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	return Plugin_Handled;
}
