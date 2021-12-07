#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"
#define DEBUG

new g_Annotations[MAXPLAYERS+1] = 0;
new bool:g_Players[MAXPLAYERS+1];
new Float:g_LastKeyCheckTime = 0.0;

new Handle:g_RefreshTime;
new Handle:g_LifeTime;

public Plugin:myinfo = 
{
	name = "[TF2] Dynamic Annotate",
	author = "Leonardo",
	description = "Spawn annotations where you are.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("da_version", PLUGIN_VERSION, "Dynamic Annotate Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_RefreshTime = CreateConVar("da_delay", "0.2", "Annotation's refresh delay", 0, true, 0.01, true, 0.5);
	g_LifeTime = CreateConVar("da_lifetime", "1.0", "Annotation's life time", 0, true, 0.1, true, 10.0);
	
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		g_Annotations[cell] = 0;
		g_Players[cell] = false;
	}
	g_LastKeyCheckTime = 0.0;
}

public OnMapStart()
{
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		g_Annotations[cell] = 0;
		g_Players[cell] = false;
	}
	g_LastKeyCheckTime = 0.0;
}

public OnGameFrame()
{
	for( new iClient = 1; iClient<=MAXPLAYERS; iClient++ )
		if(IsValidClient(iClient))
			if(IsPlayerAlive(iClient) && GetClientTeam(iClient)>1)
			{
				if(CheckElapsedTime(GetConVarFloat(g_RefreshTime)))
				{
					if(g_Annotations[iClient]==0)
					{
						decl Handle:event;
						event = CreateEvent("show_annotation");
						
						// set event's id
						g_Annotations[iClient] = GetClientUserId(iClient)*GetRandomInt(2,10)*GetRandomInt(1,10); // randomize
						SetEventInt(event, "id", g_Annotations[iClient]);
						
						// set position
						decl Float:fOrigin[3];
						GetClientEyePosition(iClient,fOrigin);
						SetEventFloat(event, "worldPosX", fOrigin[0]);
						SetEventFloat(event, "worldPosY", fOrigin[1]);
						SetEventFloat(event, "worldPosZ", fOrigin[2]);
						
						// set lifetime
						SetEventFloat(event, "lifetime", GetConVarFloat(g_LifeTime));
						
						// set text
						decl String:sName[64];
						GetClientName(iClient,sName,sizeof(sName));
						SetEventString(event, "text", sName);
						
						// set flags
						SetEventInt(event, "visibilityBitfield", 16777215);
						
						// fire event
						FireEvent(event);
						
#if defined DEBUG
						PrintToServer("%f: [DA] Event show_annotation created for %N (client:%d) (userid:%d).", GetEngineTime(), iClient, iClient, GetClientOfUserId(iClient));
#endif
					}
				}
			}
			else
				g_Annotations[iClient] = 0;
	if(CheckElapsedTime(GetConVarFloat(g_RefreshTime)))
	{
		HookEvent("show_annotation", UpdateAnnotations, EventHookMode_Post);
		SaveKeyTime();
	}
}

public Action:UpdateAnnotations(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("%f: [DA] Event show_annotation triggered and hooked!", GetEngineTime());
#endif
	for(new iClient = 1; iClient<=MAXPLAYERS; iClient++ )
		if(IsValidClient(iClient) && g_Annotations[iClient]>0)
			if(GetEventInt(hEvent,"id") == g_Annotations[iClient])
			{
				// update position
				decl Float:fOrigin[3];
				GetClientEyePosition(iClient,fOrigin);
				SetEventFloat(hEvent, "worldPosX", fOrigin[0]);
				SetEventFloat(hEvent, "worldPosY", fOrigin[1]);
				SetEventFloat(hEvent, "worldPosZ", fOrigin[2]);
				
				// update text
				decl String:sName[64];
				GetClientName(iClient,sName,sizeof(sName));
				SetEventString(hEvent, "text", sName);
				
				// update lifetime
				SetEventFloat(hEvent,"lifetime",(GetEventFloat(hEvent,"lifetime")+GetConVarFloat(g_LifeTime)));
			}
	UnhookEvent("show_annotation", UpdateAnnotations, EventHookMode_Post);
	return Plugin_Continue;
}

stock bool:IsValidClient(any:iClient, bool:idOnly=false)
{
	if (iClient <= 0)
		return false;
	if (iClient > MaxClients)
		return false;
	if (!idOnly)
		return IsClientInGame(iClient);
	return true;
}

stock SaveKeyTime()
{
	g_LastKeyCheckTime = GetEngineTime();
#if defined DEBUG
	PrintToServer("%f: [DA] Timer touched.",GetEngineTime());
#endif
}

stock bool:CheckElapsedTime(Float:fTime)
	if( (GetEngineTime() - g_LastKeyCheckTime) >= fTime )
		return true;
	else
		return false;