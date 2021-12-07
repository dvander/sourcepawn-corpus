#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Float:g_LastKeyCheckTime = 0.0;
new Handle:g_RefreshTime;

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
	g_RefreshTime = CreateConVar("da_delay", PLUGIN_VERSION, "Annotations refresh delay");
	g_LastKeyCheckTime = 0.0;
}

public OnMapStart()
	g_LastKeyCheckTime = 0.0;

public OnGameFrame()
{
	for( new iClient = 1; iClient<=MaxClients; iClient++ )
		if(IsValidClient(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient)>1)
			if(CheckElapsedTime(GetConVarFloat(g_RefreshTime)))
			{
				SpawnAnnotation(iClient);
				SaveKeyTime();
			}
}

public SpawnAnnotation(iClient)
{
	if(!IsValidEntity(iClient)) return false;
	
	new Float:fOrigin[3], String:sName[64];
	GetClientEyePosition(iClient,fOrigin);
	GetClientName(iClient,sName,sizeof(sName));
	
	if(strlen(sName)<2)
		sName = "...";
	
	new Handle:event = CreateEvent("show_annotation");
	if (event != INVALID_HANDLE)
	{
		SetEventFloat(event, "worldPosX", fOrigin[0]);
		SetEventFloat(event, "worldPosY", fOrigin[1]);
		SetEventFloat(event, "worldPosZ", fOrigin[2]);
		SetEventFloat(event, "lifetime", GetConVarFloat(g_RefreshTime));
		SetEventInt(event, "id", GetRandomInt(1,100)*GetRandomInt(1,100));
		SetEventString(event, "text", sName);
		SetEventInt(event, "visibilityBitfield", 16777215);
		FireEvent(event);
		return true;
	}
	
	return false;
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
	g_LastKeyCheckTime = GetGameTime();

stock bool:CheckElapsedTime(Float:fTime)
	if( (GetGameTime() - g_LastKeyCheckTime) >= fTime )
		return true;
	else
		return false;