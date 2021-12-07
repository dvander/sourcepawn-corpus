#include <sourcemod>
#include <sdktools>

#define TEAM_ALL						1
#define TEAM_TERRORIST				2
#define TEAM_COUNTER_TERRORIST		3
#define OFFSET							64
#define COORD_X						0
#define COORD_Y						1
#define COORD_Z						2

new Handle:CVAR_vs3_anti_sitck_enable		= INVALID_HANDLE;
new Handle:CVAR_vs3_anti_stick_teams		= INVALID_HANDLE;

new g_iAntiStickEnabled;
new g_iTeamsAllowed;

public Plugin:myinfo =
{
	name = "[Vs3]Anti Stick",
	author = "Spunky",
	description = "Allows a client to unstick themselves from objects and other players.",
	version = "1.0.0.1",
	url = "http://www.vs3-clan.co.uk"
};

public OnPluginStart()
{
	/* Load translations. */
	LoadTranslations("anti_stick.phrases");

	/* Register commands. */
	RegConsoleCmd("stuck", Command_Stuck);

	/* Register console commands. */
	CVAR_vs3_anti_sitck_enable	= CreateConVar("vs3_anti_sitck_enable", "1", "Determines if anti stick is enabled. 1 = enabled, 0 = disabled.");
	CVAR_vs3_anti_stick_teams		= CreateConVar("vs3_anti_stick_teams", "1", "Determines which teams can use the anti stick command. 0 = disabled, 1 = all, 2 = terrorist, 3 = counter-terrorist.");
	
}

public OnConfigsExecuted()
{
	g_iAntiStickEnabled	= GetConVarInt(CVAR_vs3_anti_sitck_enable);
	g_iTeamsAllowed			= GetConVarInt(CVAR_vs3_anti_stick_teams);
}

public Action:Command_Stuck(client, args)
{
	if (CanUseStuck(client))
	{
		new Float:f_Origin[3];
		new Float:f_End[3];
		new Float:f_Angles[3];
		GetClientAbsOrigin(client, f_Origin);
		GetClientAbsAngles(client, f_Angles);
			
		f_End = GetEndPoint(client);
		
		/* Ensure the teleport location is valid. */
		if (IsValidLocation(client, f_Origin, f_End))
		{
			TeleportEntity(client, f_End, f_Angles, NULL_VECTOR);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

bool:IsValidLocation(client, Float:origin[3], Float:end[3])
{
	new Handle:h_TraceRay = TR_TraceRayFilterEx(origin, end, MASK_SOLID, RayType_EndPoint, TraceRayFilter, client)
	if(TR_DidHit(h_TraceRay))
	{
		PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - invalid location");
		return false;
	}
	
	CloseHandle(h_TraceRay);
	return true;
}

bool:IsStuck(client)
{
	decl Float:f_Origin[3];
	decl Float:f_End[3];
	decl Float:f_Mins[3];
	decl Float:f_Maxs[3];
	
	/* Get the start and end points for the trace hull. */
	GetClientAbsOrigin(client, f_Origin);
	f_End = GetEndPoint(client);
	
	/* Get the minimum and maximum hull sizes for this client. */
	GetEntPropVector(client, Prop_Send, "m_vecMins", f_Mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", f_Maxs);
	
	/* Perform a trace hull and ensure we filter out the client to prevent false positivies. */
	new Handle:h_TraceRay = TR_TraceHullFilterEx(f_Origin, f_End, f_Mins, f_Maxs, MASK_SOLID, TraceRayFilter, client);
	
	new i_EntityHit = TR_GetEntityIndex(h_TraceRay);
	
	/* Check if we hit anything. */
	if(TR_DidHit(h_TraceRay) && i_EntityHit != client && i_EntityHit != 0)
	{
		return true;
	}
	
	CloseHandle(h_TraceRay);
	return false;
}

public bool:TraceRayFilter(entity, mask, any:client)
{
	if (entity == client || entity == 0)
	{
		return false;
	}
	return true;
}

Float:GetEndPoint(client)
{
	new Float:f_End[3];
	GetClientAbsOrigin(client, f_End);
	
	new i_Rand = GetRandomInt(1, 8);
	switch (i_Rand)
	{
		case 1:
			f_End[COORD_X] += OFFSET;
		case 2:
			f_End[COORD_X] -= OFFSET;
		case 3:
			f_End[COORD_Y] += OFFSET;
		case 4:
			f_End[COORD_Y] -= OFFSET;
		case 5:
		{
			f_End[COORD_X] += OFFSET;
			f_End[COORD_Y] += OFFSET;
		}
		case 6:
		{
			f_End[COORD_X] += OFFSET;
			f_End[COORD_Y] -= OFFSET;
		}
		case 7:
		{
			f_End[COORD_X] -= OFFSET;
			f_End[COORD_Y] += OFFSET;
		}
		case 8:
		{
			f_End[COORD_X] -= OFFSET;
			f_End[COORD_Y] -= OFFSET;
		}
	}
	
	return f_End;
}

bool:CanUseStuck(client)
{	
	/* Ensure the client is valid. */
	if (!IsValidClient(client))
	{
		return false;
	}
	
	if (!g_iAntiStickEnabled)
	{
		PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - disabled");
		return false;
	}
	
	if (GetClientTeam(client) < TEAM_TERRORIST)
	{
		PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - spectating");
		return false;
	}
	
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - dead");
		return false;
	}
	
	if (!IsStuck(client))
	{
		PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - not stuck");
		return false;
	}
	
	/* Get the client's team. */
	new i_Team = GetClientTeam(client);
	
	/* Check which teams spawn protection should be applied to. */
	switch (g_iTeamsAllowed)
	{
		case TEAM_ALL:
		{
			if (i_Team < TEAM_TERRORIST)
			{
				return false;
			}
		}
		case TEAM_TERRORIST:
		{
			/* Check if this client is on the terrorist team. */
			if (i_Team != TEAM_TERRORIST)
			{
				PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - terrorist only");
				return false;
			}
		}
		case TEAM_COUNTER_TERRORIST:
		{
			/* Check if this client is on the counter_terrorist team. */
			if (i_Team != TEAM_COUNTER_TERRORIST)
			{
				PrintToChat(client, "\x01[\x03Vs3 Info:\x01] %t", "anti stick failed - counter terrorist only");
				return false;
			}
		}
	}
	
	return true;
}

bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}