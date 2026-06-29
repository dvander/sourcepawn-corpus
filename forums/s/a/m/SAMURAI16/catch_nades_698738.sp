/*
* 
* 						Catch Nades SourceMOD Plugin
* 						Copyright (c) 2008  SAMURAI
* 						hmm .. ? Visit http://www.cs-utilz.net
* 
*/

#include <sourcemod>
#include <sdktools>
#include <hooker>

public Plugin:myinfo = 
{
	name = "Cath Nades",
	author = "SAMURAI",
	description = "Catch grenades while them are on air",
	version = "0.1",
	url = "www.cs-utilz.net"
}

// convar
new Handle:g_iConVar = INVALID_HANDLE;

// store maxclients
new g_iMaxClients;

// nades edicts classnames
stock const String:nadesClasses[][] =
{
	"hegrenade_projectile",
	"flashbang_projectile",
	"smokegrenade_projectile"
}

// nades names
stock const String:nadesNames[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
}

// user message
new UserMsg:g_userMsg;
stock const String:nade_message_override[] = "Radio.FireInTheHole";


public OnPluginStart()
{
	// hooks
	RegisterHook(HK_Touch, call_OnTouch, false);
	
	// hook user message
	g_userMsg = GetUserMessageId("SendAudio");
	HookUserMessage(g_userMsg,Msg_SendAudio,true);
	
	// cvars
	g_iConVar = CreateConVar("catch_nades","1");
	
	// get maxclients
	g_iMaxClients = GetMaxClients();
}


public Action:Msg_SendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(!GetConVarInt(g_iConVar))
		return;
	
	static String:MsgName[256];
	BfReadString(bf, MsgName, sizeof(MsgName));
    
	// is sound sended by nades ?
	if(StrEqual(MsgName,nade_message_override) )
	{
		new he = -1, flash = -1, smoke = -1;
		
		// he nades
		while( ( he = FindEntityByClassname(he,nadesClasses[0])) > 0 )
		{
			if(IsValidEdict(he))
				HookEntity(HKE_CBaseEntity,he);
		}
		
		// flashbags
		while( ( flash = FindEntityByClassname(flash,nadesClasses[1])) > 0 )
		{
			if(IsValidEdict(flash))
				HookEntity(HKE_CBaseEntity,flash);
			
		}
		
		// smoke nades
		while( ( smoke = FindEntityByClassname(smoke,nadesClasses[2])) > 0 )
		{
			if(IsValidEdict(smoke))
			{
				//PrintToChatAll("am prins smoke");
				HookEntity(HKE_CBaseEntity,smoke);
			}
		}
	}
}

public Action:call_OnTouch(entity,client)
{
	// is cvar on ?
	if(!GetConVarInt(g_iConVar))
		return;
	
	// touched is a valid edict and toucher is a player ?
	if(IsValidEdict(entity) && ISPlayerEx(client))
	{
		// get edict classname
		decl String:entityClass[64];
		GetEdictClassname(entity,entityClass,sizeof(entityClass));
		
		// is he grenade ?
		if(StrEqual(entityClass,nadesClasses[0]))
			GivePlayerItem(client,nadesNames[0]);
		
		// flashbang ?
		if(StrEqual(entityClass,nadesClasses[1]))
			GivePlayerItem(client,nadesNames[1]);
		
		// smoke ?
		if(StrEqual(entityClass,nadesClasses[2]))
			GivePlayerItem(client,nadesNames[2]);
		
		CreateTimer(0.1,remove_nade,entity);
		
	}
	
}

public Action:remove_nade(Handle:timer,any:entity)
{
	if(IsValidEdict(entity))
		RemoveEdict(entity);
}

stock ISPlayerEx(entity)
{
	return (entity > 0 && entity <= g_iMaxClients 
	&& IsClientInGame(entity) && IsPlayerAlive(entity)) ? 1 : 0;
}
	
	