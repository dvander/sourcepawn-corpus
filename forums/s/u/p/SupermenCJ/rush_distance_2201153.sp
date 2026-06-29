#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

#define DEBUG false

#define PLUGIN_VERSION		"0.01"
#define PLUGIN_CONTACT		"http://zambiland.ddns.net"
#define PLUGIN_NAME		"Rush Distance"
#define PLUGIN_DESCRIPTION	"http://zambiland.ddns.net"

new multiLanguage;

new bool:first_real_player_spawn;
new bool:gbFirstItemPickedUp;
new bool:FinaleVehicleReady;
new Float:g_MapFlowDistance;
new Handle:g_ActiveSurvivorsRequired;
new Handle:g_IgnoreDistanceTeleport;
new Handle:g_IgnoreDistanceReport;


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT,
};

public OnPluginStart()
{
	if(FileExists("addons/sourcemod/translations/zambiland.phrases.txt"))
	{
		LoadTranslations("zambiland.phrases");
		multiLanguage = 1;
	}
	else
	{
		multiLanguage = 0;
	}
	
	RegConsoleCmd("sm_myflowdist", myflowdist);
	RegConsoleCmd("sm_mydist", mydist);
	
	g_ActiveSurvivorsRequired =	CreateConVar("rd_active_survivors_required","3","The number of active survivors required for calculations to be considered.");
	g_IgnoreDistanceTeleport = CreateConVar("rd_distance_ignore_teleport","22","");
	g_IgnoreDistanceReport = CreateConVar("rd_distance_ignore_report","16","");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("item_pickup", Event_RoundStartAndItemPickup);
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
}

public OnMapStart()
{
	first_real_player_spawn = false;
	gbFirstItemPickedUp = false;
}

public Action:Event_RoundStart(Handle:Event, const String:strName[], bool:DontBroadcast)
{
	FinaleVehicleReady = false;
}

public Action:Event_FinaleVehicleReady(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	FinaleVehicleReady = true;

	return Plugin_Continue;
}

public Event_RoundStartAndItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!gbFirstItemPickedUp)
	{
		gbFirstItemPickedUp = true;
		CreateTimer(2.0, Timer_DistanceCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!first_real_player_spawn)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		{
			first_real_player_spawn = true;
			g_MapFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
		}
	}
}

public Action:myflowdist(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Clients only");
		return;
	}

	new Float:dist = L4D2Direct_GetFlowDistance(client);
	ReplyToCommand(client, "flowdist = %f", dist);
}

public Action:mydist(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Clients only");
		return;
	}

	new Float:g_PlayerDistance = (L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
	new prcnt = RoundToNearest((L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance) * 100.0);
	ReplyToCommand(client, "distance = %f (%d%%)", g_PlayerDistance, prcnt);
}

public Action:Timer_DistanceCheck(Handle:timer)
{
	if (ActiveSurvivors() < GetConVarInt(g_ActiveSurvivorsRequired)) return Plugin_Continue;
	if (FinaleVehicleReady) return Plugin_Continue;
	new l, worse;
	l = 0;
	worse = 100;
	new activator = -1;
	new target = -1;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTeamSurvivor(i) && !IsFakeClient(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i) && IsNotFalling(i))
		{
			new prcnt = RoundToNearest((L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance) * 100.0);
			
			if (prcnt > l)
			{
				l = prcnt;
				activator = i;
			}
			if (0 < prcnt < worse)
			{
				worse = prcnt;
				target = i;
			}
		}
	}
	if (activator > 0 && target > 0 && ActiveSurvivors() > GetConVarInt(g_ActiveSurvivorsRequired))
	{
		if (((l - worse) >= GetConVarInt(g_IgnoreDistanceReport)) && ((l - worse) < GetConVarInt(g_IgnoreDistanceTeleport)))
		{
			if (multiLanguage)
			{
				PrintToChat(activator, "%t", "Chat. Go back to your team!");
				PrintHintText(activator, "%t", "Hint. Go back to your team!");
			}
			else
			{
				PrintToChat(activator, "Go back to your team!");
				PrintHintText(activator, "Go back to your team!");
			}
		}
		else if ((l - worse) >= GetConVarInt(g_IgnoreDistanceTeleport))
		{
			new Float:g_Origin[3];
			GetClientAbsOrigin(target, g_Origin);
			TeleportEntity(activator, g_Origin, NULL_VECTOR, NULL_VECTOR);
		#if DEBUG
			new String:Message[512];
			new String:TempMessage[256];
			Format(TempMessage, sizeof(TempMessage), "\x01Игрок \x05%N \x01c дистанцией \x04%d%% \x01был телепортирован к игроку \x05%N \x01с дистанцией \x04%d%%", activator, l, target, worse);
			StrCat(String:Message, sizeof(Message), TempMessage);
			printToRoot(Message);
		#endif
			if (multiLanguage)
			{
				PrintToChat(activator, "%t", "Chat. Stop rushing!");
				PrintHintText(activator, "%t", "Hint. Stop rushing!");
			}
			else
			{
				PrintToChat(activator, "Stop rushing!");
				PrintHintText(activator, "Stop rushing!");
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsTeamSurvivor(client) 
{
	if (!IsValidClient(client)) return false; 
	if (GetClientTeam(client) != 2) return false; 
	return true; 
}

stock bool:IsValidClient(client) 
{
	if (client < 1 || client > MaxClients) return false; 
	if (!IsClientConnected(client)) return false; 
	if (!IsClientInGame(client)) return false; 
	return true; 
}

bool:IsNotFalling(i)
{
	return GetEntProp(i, Prop_Send, "m_isHangingFromLedge") == 0 && GetEntProp(i, Prop_Send, "m_isFallingFromLedge") == 0 && (GetEntPropFloat(i, Prop_Send, "m_flFallVelocity") == 0 || GetEntPropFloat(i, Prop_Send, "m_flFallVelocity") < -100);
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock ActiveSurvivors()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) count++;
	}
	return count;
}

#if DEBUG
stock printToRoot(const String:format[], any:...)
{
	new AdminId:adminID = INVALID_ADMIN_ID;
	decl String:buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);

	for(new i=1; i < GetMaxClients(); i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			adminID = GetUserAdmin(i);
			if (adminID != INVALID_ADMIN_ID)
			{
				if (GetAdminFlag(adminID, Admin_Root, Access_Effective))
				{
					PrintToChat(i, "\x04[\x01%s\x04]", buffer);
				}
			}
		}
	}
}
#endif