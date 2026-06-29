#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "v1.2.1"


public Plugin:myinfo =
{
	name = "SM Franug Soccer Ball",
	author = "Franc1sco Steam: franug",
	description = "To play football on any map",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_Soccer-Ball", PLUGIN_VERSION, "version del plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	RegAdminCmd("sm_ball", Bola, ADMFLAG_ROOT);
	RegAdminCmd("sm_noball", NoBola, ADMFLAG_ROOT);

	LoadTranslations("common.phrases");
}



public Action:Bola(client,args)
{ 
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}

	decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3]; 
	GetClientEyePosition(client, start); 
	GetClientEyeAngles(client, angle); 
     
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, RayDontHitSelf, client); 
	if (TR_DidHit(INVALID_HANDLE)) 
	{ 
		TR_GetEndPosition(end, INVALID_HANDLE); 
		TR_GetPlaneNormal(INVALID_HANDLE, normal); 
		GetVectorAngles(normal, normal); 
		normal[0] += 90.0; 
     
		new ent = CreateEntityByName("prop_physics_override"); 
			
		if(ent == -1)
			return Plugin_Handled;
			
		SetEntityModel(ent, "models/forlix/soccer/soccerball.mdl"); 
		DispatchKeyValue(ent, "StartDisabled", "false"); 
		DispatchKeyValue(ent, "Solid", "6"); 
		DispatchKeyValue(ent, "spawnflags", "1026"); 
		DispatchKeyValue(ent, "classname", "models/forlix/soccer/soccerball.mdl");
		DispatchSpawn(ent); 
		AcceptEntityInput(ent, "TurnOn", ent, ent, 0); 
		AcceptEntityInput(ent, "EnableCollision"); 
		TeleportEntity(ent, end, normal, NULL_VECTOR); 
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5); 
        	//SetEntProp(ent, Prop_Data, "m_usSolidFlags", 16); 
        	//SetEntProp(ent, Prop_Data, "m_nSolidType", 6); 

        	//SetEntityMoveType(ent, MOVETYPE_NONE); 
        	//DispatchKeyValue(ent, "StartDisabled", "false"); 
		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeBallDamage);

	} 


	PrintToChat(client, "\x04[SM_Soccer-Ball] \x01You have created a Soccer Ball"); // english

	return Plugin_Handled;
}  

public bool:RayDontHitSelf(entity, contentsMask, any:data) 
{ 
	return (entity != data); 
} 

public OnMapStart()
{
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.dx80.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.dx90.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.mdl");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.phy");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.sw.vtx");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.vvd");
	AddFileToDownloadsTable("models/forlix/soccer/soccerball.xbox.vtx");
	AddFileToDownloadsTable("materials/models/forlix/soccer/soccerball.vmt");
	AddFileToDownloadsTable("materials/models/forlix/soccer/soccerball.vtf");

	PrecacheModel("models/forlix/soccer/soccerball.mdl");
}

public Action:NoBola(client,args)
{ 
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}

	new index2 = -1;
	while ((index2 = FindEntityByClassname2(index2, "models/forlix/soccer/soccerball.mdl")) != -1)
	AcceptEntityInput(index2, "Kill");

	PrintToChat(client, "\x04[SM_Soccer-Ball] \x01You have deleted all soccer balls created"); // english


	return Plugin_Handled;
}

// Thanks to exvel for the function below. Exvel posted that in the FindEntityByClassname API.
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;

	return FindEntityByClassname(startEnt, classname);
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:OnTakeBallDamage(entity, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!IsValidClient(attacker)) return Plugin_Continue;
	
	if(damage > 40.0)
	{
		Elevar(entity);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Elevar(bola)
{
	decl Float:normal[3], Float:velocidad[3];
	GetVectorAngles(normal, normal); 
	normal[0] += 90.0; 
	velocidad[2] = 550.0;
	//PrintToChatAll("la bola %i ha sido mullada con mas de 40 damage", bola);
	TeleportEntity(bola, NULL_VECTOR, normal, velocidad);
}
		

   