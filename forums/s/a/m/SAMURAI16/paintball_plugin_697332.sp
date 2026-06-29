/*
* 
* 						Paintball SourceMOD Plugin
* 						Copyright (c) 2008  SAMURAI
* 						
* 						If you don't have what to do visit http://www.cs-utilz.net
*/

#include <sourcemod>
#include <sdktools>


public Plugin:myinfo = 
{
	name = "PaintBall",
	author = "SAMURAI",
	description = "",
	version = "0.2b",
	url = "www.cs-utilz.net"
}

#define SPRITE_SIZE 0.2
#define SPRITE_BRGH 200

#define CS_TEAM_T  2
#define CS_TEAM_CT 3

new Handle:g_iCvarActive = INVALID_HANDLE;
new Handle:g_iConvarColor = INVALID_HANDLE;
new Handle:g_iConvarLife = INVALID_HANDLE;


stock const String:PrimarySprites[][] = 
{ 
	"decals/concrete/SHOT1_paint.vmt", // 0 - red
	"decals/concrete/SHOT2_paint.vmt", // 1 - blue
	"decals/concrete/SHOT3_paint.vmt", // 2 - green
	"decals/concrete/SHOT5_paint.vmt" // 3 - yellow
}

new String:gSpriteIndex[sizeof PrimarySprites];

stock const String:SecondarySprites[][] =
{
	"decals/concrete/SHOT1_paint.vtf",
	"decals/concrete/SHOT1norm_paint.vtf",
	"decals/concrete/SHOT2_paint.vtf", 
	"decals/concrete/SHOT2norm_paint.vtf", 
	"decals/concrete/SHOT3_paint.vtf",
	"decals/concrete/SHOT3norm_paint.vtf",
	"decals/concrete/SHOT5_paint.vtf",
	"decals/concrete/SHOT5norm_paint.vtf"
}

// fixed barrels bug from *_dust* maps
stock const String:g_szBarrelModel[] = "models/props_c17/oildrum001.mdl";

public OnPluginStart()
{
	HookEvent("bullet_impact",event_bullet_impact);
}

	
public OnMapStart()
{
	g_iCvarActive = CreateConVar("paintball_active","1"); // 1 - enable plugin ; 2 - disable plugin
	g_iConvarColor = CreateConVar("paintball_color","random");
	g_iConvarLife  = CreateConVar("paintball_life","10"); // seconds
	
	static String:PrimaryDecals[256], String:SecondaryDecals[256];
	
	for(new i = 0 ; i < sizeof(PrimarySprites); i++)
	{
		gSpriteIndex[i] = PrecacheModel(PrimarySprites[i])
		
		Format(PrimaryDecals,sizeof(PrimaryDecals),"materials/%s",PrimarySprites[i]);
		AddFileToDownloadsTable(PrimaryDecals);
	}
	
	for(new j = 0; j < sizeof(SecondarySprites); j++)
	{
		PrecacheModel(SecondarySprites[j]);
		
		Format(SecondaryDecals,sizeof(SecondaryDecals),"materials/%s",SecondarySprites[j]);
		AddFileToDownloadsTable(SecondaryDecals);
	}
	
}


public Action:event_bullet_impact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(!is_ok(client))
		return;
	
	if(!GetConVarInt(g_iCvarActive))
		return;
	
	static String:color[10];
	GetConVarString(g_iConvarColor,color,sizeof(color));
	
	static Float:fAimOrigin[3], iSprite;

	if(GetAimOrigin(client,fAimOrigin) )
	{
		if(TR_GetPointContents(fAimOrigin) == CONTENTS_WATER)
			return;
		
		if(StrEqual(color,"red"))
			iSprite = gSpriteIndex[0];
		
		else if(StrEqual(color,"blue"))
			iSprite = gSpriteIndex[1];
		
		else if(StrEqual(color,"green"))
			iSprite = gSpriteIndex[2];
			
		else if(StrEqual(color,"yellow"))
			iSprite = gSpriteIndex[3];
		
		else if(StrEqual(color,"teamcolor"))
		{
			switch(GetClientTeam(client))
			{
				case CS_TEAM_T:  iSprite = gSpriteIndex[0];
				case CS_TEAM_CT: iSprite = gSpriteIndex[1];
			}
		}
			
		else if(StrEqual(color,"random"))
			iSprite = gSpriteIndex[GetRandomInt(0,sizeof(PrimarySprites)-1)];
		
		TE_SetupGlowSprite(fAimOrigin,iSprite,float(GetConVarInt(g_iConvarLife)),SPRITE_SIZE,SPRITE_BRGH);
		TE_SendToAll();
	}
}


/* 	  Util Functions 		*/
stock GetAimOrigin(client, Float:hOrigin[3]) 
{
	new Float:vAngles[3], Float:fOrigin[3];
	GetClientEyePosition(client,fOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(hOrigin, trace);
		
		new entity = TR_GetEntityIndex(trace);
		
		if(!IsValidEdict(entity))
		{
			CloseHandle(trace);
			return 0;
		}
		
		new String:modelname[128];
		GetEntityModel(entity,modelname);
		
		if(StrEqual(modelname,g_szBarrelModel))
		{
			CloseHandle(trace);
			return 0;
		}
			
		CloseHandle(trace);
		return 1;
	}

	CloseHandle(trace);
	return 0;
}


public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
 	return entity > GetMaxClients();
}


stock is_ok(client)
{
	return (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
}

stock GetEntityModel(entity,String:model[128])
{
	return GetEntPropString(entity, Prop_Data, "m_ModelName", model,sizeof(model));
}
		