#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION  "0.1.5"


public Plugin:myinfo = 
{
	name = "Hide Players",
	author = "[GNC] Matt",
	description = "Adds commands to show/hide other players.",
	version = PLUGIN_VERSION,
	url = "http://www.mattsfiles.com"
}

new bool:g_bHide[MAXPLAYERS + 1];
new g_Team[MAXPLAYERS + 1];
new Handle:g_Entities;

new Handle:g_hExplosions = INVALID_HANDLE;
new bool:g_bExplosions = true;

new String:g_saHidable[][] = {
									"tf_projectile_arrow",
									"tf_projectile_flare",
									"tf_projectile_jar",
									"tf_projectile_pipe",
									"tf_projectile_rocket",
									"tf_projectile_sentryrocket",
									"tf_projectile_stun_ball",
									"tf_projectile_syringe",
									"tf_projectile_pipe_remote"
								};

public OnPluginStart()
{
	CreateConVar("sm_hide_version", PLUGIN_VERSION, "Hide Players Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_hide", cmdHide, "Show/Hide Other Players");
	RegAdminCmd("sm_hide_reload", cmdReload, ADMFLAG_SLAY, "Execute if reloading plugin with players on server.");
	HookEvent("player_team", eventChangeTeam);
	g_Entities = CreateTrie();
	
	g_hExplosions = CreateConVar("sm_hide_explosions", "1", "Enable/Disalbe hiding explosions.", FCVAR_PLUGIN);
	HookConVarChange(g_hExplosions, cvarExplosions);
	
	AddNormalSoundHook(NormalSHook:SoundHook);
	AddTempEntHook("TFExplosion", TEHook:TEHookTest);
}

public cvarExplosions(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bExplosions = bool:StringToInt(newVal);
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new Action:toreturn = Plugin_Continue;
	
	for(new i = 0; i < numClients; i++)
	{
		if(i <= MAXPLAYERS && clients[i] > 0 && clients[i] <= MAXPLAYERS)
		{
			if(g_bHide[clients[i]] && g_Team[clients[i]] != 1)
			{
				clients[i] = -1;
				toreturn = Plugin_Changed;
			}
		}
	}
	return toreturn;
}

public Action:TEHookTest(const String:te_name[], const Players[], numClients, Float:delay)
{
	if(g_bExplosions)
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action:cmdHide(client, args)
{
	g_bHide[client] = !g_bHide[client];
	
	if(g_bHide[client])
	{
		ReplyToCommand(client, "\x05[Hide]\x01 Other players are now hidden.");
	}
	else
	{
		ReplyToCommand(client, "\x05[Hide]\x01 Other players are now visible.");
	}
}

public Action:eventChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	
	g_Team[client] = team;
}

public OnEntityCreated(entity, const String:classname[])
{
	for(new i = 0; i < sizeof(g_saHidable); i++)
	{
		if(StrEqual(classname, g_saHidable[i]))
		{
			SDKHook(entity, SDKHook_Spawn, OnHidableSpawned);
			return;
		}
	}
}

public OnEntityDestroyed(entity)
{
	new String:sEntity[10];
	IntToString(entity, sEntity, sizeof(sEntity));
	
	SDKUnhook(entity, SDKHook_SetTransmit, Hook_Entity_SetTransmit);
	RemoveFromTrie(g_Entities, sEntity);
}

public OnHidableSpawned(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner < 1 || owner > MaxClients)
		return;
	
	new String:sEntity[10];
	IntToString(entity, sEntity, sizeof(sEntity));
	
	SetTrieValue(g_Entities, sEntity, owner);
	SDKHook(entity, SDKHook_SetTransmit, Hook_Entity_SetTransmit);
}

public Action:Hook_Entity_SetTransmit(entity, client)
{
	new String:sEntity[10];
	IntToString(entity, sEntity, sizeof(sEntity));
	
	new owner;
	if(!GetTrieValue(g_Entities, sEntity, owner))
		return Plugin_Continue;
	
	if(owner == client || !g_bHide[client] || g_Team[client] == 1)
		return Plugin_Continue;
	else
		return Plugin_Handled;
}


public Action:cmdReload(client, args)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bHide[i] = false;
		SDKUnhook(i, SDKHook_SetTransmit, Hook_Client_SetTransmit); 
		SDKHook(i, SDKHook_SetTransmit, Hook_Client_SetTransmit);
	}
	ReplyToCommand(client, "\x05[Hide]\x01 Reloaded");
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	g_bHide[client] = false;
	SDKHook(client, SDKHook_SetTransmit, Hook_Client_SetTransmit);
}

public Action:Hook_Client_SetTransmit(entity, client)
{
	if(entity == client || !g_bHide[client] || g_Team[client] == 1)
		return Plugin_Continue;
	else
		return Plugin_Handled;
}
