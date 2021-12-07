#include <sourcemod>
#include <sdktools>

new g_iMaxClients	= 0;
new g_iAlliesCount	= 0;
new g_iAxisCount	= 0;

// Entities
new g_iObjectiveResource	= 0;
new g_iCaptureAreas[8]		= {0,...};

// Offsets
new g_iAlliesReqCappers	= -1;	// CDODObjectiveResource::m_iAlliesReqCappers
new g_iAxisReqCappers	= -1;	// CDODObjectiveResource::m_iAxisReqCappers
new g_iAlliesNumCap		= -1;	// CAreaCapture::m_nAlliesNumCap
new g_iAxisNumCap		= -1;	// CAreaCapture::m_nAxisNumCap

// Default Values
new g_iAlliesDefCappers[8]	= {0,...};
new g_iAxisDefCappers[8]	= {0,...};
new g_iAlliesDefCap[8]		= {0,...};
new g_iAxisDefCap[8]		= {0,...};

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Required Cappers Changer",
	author = "Knagg0",
	description = "Changes the required cappers of an area for the team that doesn't have enough players to cap it",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public OnPluginStart()
{
	CreateConVar("rcc_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_iAlliesReqCappers = FindSendPropOffs("CDODObjectiveResource", "m_iAlliesReqCappers");
	g_iAxisReqCappers = FindSendPropOffs("CDODObjectiveResource", "m_iAxisReqCappers");
	
	HookEvent("dod_round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_team", PlayerTeam, EventHookMode_Post);
}

public OnMapStart()
{
	g_iMaxClients = GetMaxClients();
	
	g_iObjectiveResource = 0;
	
	for(new i = 0; i < sizeof(g_iCaptureAreas); i++)
	{
		g_iCaptureAreas[i]		= 0;
		g_iAlliesDefCappers[i]	= 0;
		g_iAxisDefCappers[i]	= 0;
		g_iAlliesDefCap[i]		= 0;
		g_iAxisDefCap[i]		= 0;
	}
	
	new iArea = 0;
	new iEntities = GetEntityCount();
	new String:szBuffer[100];
	
	for(new i = g_iMaxClients + 1; i < iEntities; i++)
	{
		if(!IsValidEdict(i) || !GetEdictClassname(i, szBuffer, sizeof(szBuffer)))
			continue;
			
		if(StrEqual("dod_objective_resource", szBuffer))
			g_iObjectiveResource = i;
		else if(StrEqual("dod_capture_area", szBuffer) && iArea < sizeof(g_iCaptureAreas))
			g_iCaptureAreas[iArea++] = i;
	}
	
	g_iAlliesCount	= 0;
	g_iAxisCount	= 0;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iObjectiveResource == 0 || g_iAlliesReqCappers == -1 || g_iAxisReqCappers == -1)
		return Plugin_Continue;
		
	for(new i = 0; i < sizeof(g_iCaptureAreas); i++)
	{
		g_iAlliesDefCappers[i]	= GetEntData(g_iObjectiveResource, g_iAlliesReqCappers + (i * 4));
		g_iAxisDefCappers[i]	= GetEntData(g_iObjectiveResource, g_iAxisReqCappers + (i * 4));
		
		if(g_iCaptureAreas[i] != 0)
		{
			g_iAlliesDefCap[i] = GetReqCappers(g_iCaptureAreas[i], 2);
			g_iAxisDefCap[i] = GetReqCappers(g_iCaptureAreas[i], 3);
		}
	}
	
	CheckReqCappers();

	return Plugin_Continue;
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iTeam		= GetEventInt(event, "team");
	new iOldTeam	= GetEventInt(event, "oldteam");
	
	if(iOldTeam == 2) g_iAlliesCount--;
	else if(iOldTeam == 3) g_iAxisCount--;
	
	if(iTeam == 2) g_iAlliesCount++;
	else if(iTeam == 3) g_iAxisCount++;
	
	CheckReqCappers();

	return Plugin_Continue;
}

CheckReqCappers()
{
	if(g_iObjectiveResource == 0 || g_iAlliesReqCappers == -1 || g_iAxisReqCappers == -1)
		return;

	new iTmpReqCappers = 0;
	
	for(new i = 0; i < sizeof(g_iCaptureAreas); i++)
	{
		if(g_iAlliesCount > 0)
		{
			if((iTmpReqCappers = GetNewReqCappers(GetEntData(g_iObjectiveResource, g_iAlliesReqCappers + (i * 4)), g_iAlliesDefCappers[i], 2)) != 0)
				SetEntData(g_iObjectiveResource, g_iAlliesReqCappers + (i * 4), iTmpReqCappers);

			if(g_iCaptureAreas[i] != 0 && (iTmpReqCappers = GetNewReqCappers(GetReqCappers(g_iCaptureAreas[i], 2), g_iAlliesDefCap[i], 2)) != 0)
				SetReqCappers(g_iCaptureAreas[i], iTmpReqCappers, 2);
		}
		
		if(g_iAxisCount > 0)
		{
			if((iTmpReqCappers = GetNewReqCappers(GetEntData(g_iObjectiveResource, g_iAxisReqCappers + (i * 4)), g_iAxisDefCappers[i], 3)) != 0)
				SetEntData(g_iObjectiveResource, g_iAxisReqCappers + (i * 4), iTmpReqCappers);

			if(g_iCaptureAreas[i] != 0 && (iTmpReqCappers = GetNewReqCappers(GetReqCappers(g_iCaptureAreas[i], 3), g_iAxisDefCap[i], 3)) != 0)
				SetReqCappers(g_iCaptureAreas[i], iTmpReqCappers, 3);
		}
	}
}

GetReqCappers(area, team)
{
	if(team == 2 && (g_iAlliesNumCap != -1 || (g_iAlliesNumCap = FindDataMapOffs(area, "m_nAlliesNumCap")) != -1))
		return GetEntData(area, g_iAlliesNumCap);
	else if(team == 3 && (g_iAxisNumCap != -1 || (g_iAxisNumCap = FindDataMapOffs(area, "m_nAxisNumCap")) != -1))
		return GetEntData(area, g_iAxisNumCap);
	
	return 0;	
}

SetReqCappers(area, count, team)
{
	if(team == 2 && (g_iAlliesNumCap != -1 || (g_iAlliesNumCap = FindDataMapOffs(area, "m_nAlliesNumCap")) != -1))
		SetEntData(area, g_iAlliesNumCap, count);
	else if(team == 3 && (g_iAxisNumCap != -1 || (g_iAxisNumCap = FindDataMapOffs(area, "m_nAxisNumCap")) != -1))
		SetEntData(area, g_iAxisNumCap, count);	
}

GetNewReqCappers(now, def, team)
{
	if(team == 2)
	{
		if(now > g_iAlliesCount)
			return g_iAlliesCount;
		else if(g_iAlliesCount > now && now != def)
			return (g_iAlliesCount > def) ? def : g_iAlliesCount;
	}
	else if(team == 3)
	{
		if(now > g_iAxisCount)
			return g_iAxisCount;
		else if(g_iAxisCount > now && now != def)
			return (g_iAxisCount > def) ? def : g_iAxisCount;
	}

	return 0;
}
