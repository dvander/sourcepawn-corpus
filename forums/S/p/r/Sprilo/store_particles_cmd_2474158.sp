#pragma semicolon 1
#include <sourcemod> 
#include <sdktools>
#include <store> 
#include <zephstocks> 

#pragma newdecls required
enum CustomParticles
{
	String:szParticleName[PLATFORM_MAX_PATH],
	String:szEffectName[PLATFORM_MAX_PATH],
	Float:fPosition[3],
	iCacheID,
}

int g_eCustomParticles[STORE_MAX_ITEMS][CustomParticles];
int g_iCustomParticless = 0;
int g_unClientParticle[MAXPLAYERS+1]={INVALID_ENT_REFERENCE,...};
int g_unSelectedParticle[MAXPLAYERS+1]={-1,...};

bool b_Transmit[MAXPLAYERS + 1] = false;

public Plugin myinfo =
{
	name = "Custom Particles | Store Module",
	author = "ban-hammer.net",
	description = "Allow Particles/Auras to be added to store",
	version = "1.0",
	url = "http://alliedmods.net"
}

public void OnPluginStart() 
{
	Store_RegisterHandler("CustomParticles", "effectname", CustomParticlesOnMapStart, CustomParticlesReset, CustomParticlesConfig, CustomParticlesEquip, CustomParticlesRemove, true); 
	
	HookEvent("player_spawn", Particles_PlayerSpawn);
	HookEvent("player_death", Particles_PlayerDeath);	
	
	RegConsoleCmd("sm_hideauras", Command_HideAuras);
	
	g_cvarChatTag = RegisterConVar("sm_store_chat_tag", "[Store] ", "The chat tag to use for displaying messages.", TYPE_STRING);
}

public Action Command_HideAuras(int client, int args)
{
	if(!b_Transmit[client])
	{
		PrintToChat(client, " \x0B[Store]\x01 You can no longer see \x04Auras");
		b_Transmit[client] = true;
	}
	else if(b_Transmit[client])
	{
		PrintToChat(client, " \x0B[Store]\x01 You can now see \x04Auras");
		b_Transmit[client] = false;
	}
}

public Action Hook_SetTransmit(int entity, int client)
{
	setFlags(entity);
	if(b_Transmit[client])
	{
		return Plugin_Handled;	
	}
	return Plugin_Continue;
}

void setFlags(int edict)
{
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
    }
} 

public void CustomParticlesOnMapStart() 
{
	for(int i=0;i<g_iCustomParticless;++i)
	{
		g_eCustomParticles[i][iCacheID] = PrecacheGeneric(g_eCustomParticles[i][szParticleName], true);
		Downloader_AddFileToDownloadsTable(g_eCustomParticles[i][szParticleName]);
	}
} 

public void OnMapStart()
{
	if(g_iCustomParticless > 0)
	{
		for(int i=0;i<g_iCustomParticless;++i)
		{
			if(!IsModelPrecached(g_eCustomParticles[i][szParticleName]))
			{	
				g_eCustomParticles[i][iCacheID] = PrecacheGeneric(g_eCustomParticles[i][szParticleName], true);
				Downloader_AddFileToDownloadsTable(g_eCustomParticles[i][szParticleName]);
			}
		}
	}
} 

public void CustomParticlesReset() 
{ 
	g_iCustomParticless = 0; 
}

public int CustomParticlesConfig(Handle &kv, int itemid) 
{
	float m_fTemp[3];
	
	Store_SetDataIndex(itemid, g_iCustomParticless);
	KvGetString(kv, "particlename", g_eCustomParticles[g_iCustomParticless][szParticleName], PLATFORM_MAX_PATH);
	KvGetString(kv, "effectname", g_eCustomParticles[g_iCustomParticless][szEffectName], PLATFORM_MAX_PATH);
	KvGetVector(kv, "position", m_fTemp);
	
	g_eCustomParticles[g_iCustomParticless][fPosition] = m_fTemp;
	
	++g_iCustomParticless;
	
	for(int i=0;i<g_iCustomParticless;++i)
	{
		if(!IsModelPrecached(g_eCustomParticles[i][szParticleName]))
		{
			g_eCustomParticles[i][iCacheID] = PrecacheGeneric(g_eCustomParticles[i][szParticleName], true);
			Downloader_AddFileToDownloadsTable(g_eCustomParticles[i][szParticleName]);
		}
		return true;
	}

	return false;
}

public int CustomParticlesEquip(int client, int id)
{
	g_unSelectedParticle[client]=Store_GetDataIndex(id);
	
	RemoveCustomParticle(client);
	CreateCustomParticle(client);	
	
	return 0;
}

public Action Timer_CreateParticle(Handle timer, any client)
{
	if(IsValidClient(client))
		CreateCustomParticle(client);		
}

public int CustomParticlesRemove(int client, int id) 
{	
	g_unSelectedParticle[client]=-1;	
	RemoveCustomParticle(client);
	return 0;
}

public void OnClientPutInServer(int client)
{
	g_unSelectedParticle[client]=-1;
}

public void OnClientDisconnect(int client)
{
	g_unSelectedParticle[client]=-1;
}

void CreateCustomParticle(int client)
{	
	if(!IsValidClient(client))
		return;
		
	if(g_unSelectedParticle[client] == -1)
		return;	
	
	RemoveCustomParticle(client);
	
	if(!IsPlayerAlive(client))
		return;
	
	if(g_unClientParticle[client] != INVALID_ENT_REFERENCE)
		return;	
			
	int m_iData = g_unSelectedParticle[client];
	
	int m_unEnt = CreateEntityByName("info_particle_system");
	if (IsValidEntity(m_unEnt))
	{
		DispatchKeyValue(m_unEnt, "start_active", "1");
		DispatchKeyValue(m_unEnt, "effect_name", g_eCustomParticles[m_iData][szEffectName]);
		DispatchSpawn(m_unEnt);	
		
		float m_flPosition[3];
		GetClientAbsOrigin(client, m_flPosition);
		float m_fOffset[3];
		m_fOffset[0] = g_eCustomParticles[m_iData][fPosition][0];
		m_fOffset[1] = g_eCustomParticles[m_iData][fPosition][1];
		m_fOffset[2] = g_eCustomParticles[m_iData][fPosition][2];
		m_flPosition[0] = (m_flPosition[0] + m_fOffset[0]);
		m_flPosition[1] = (m_flPosition[1] + m_fOffset[1]);
		m_flPosition[2] = (m_flPosition[2] + m_fOffset[2]);

		TeleportEntity(m_unEnt, m_flPosition, NULL_VECTOR, NULL_VECTOR);
	   
		SetVariantString("!activator");
		AcceptEntityInput(m_unEnt, "SetParent", client, m_unEnt, 0);		
		
		ActivateEntity(m_unEnt);
		
		g_unClientParticle[client] = EntIndexToEntRef(m_unEnt);
		
		SetEdictFlags(m_unEnt, GetEdictFlags(m_unEnt)&(~FL_EDICT_ALWAYS) ); // allow settransmit hooks
		SDKHookEx(m_unEnt, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

void RemoveCustomParticle(int client)
{
	if(g_unClientParticle[client] == INVALID_ENT_REFERENCE)
		return;

	int m_unEnt = EntRefToEntIndex(g_unClientParticle[client]);
	g_unClientParticle[client] = INVALID_ENT_REFERENCE;
	if(m_unEnt == INVALID_ENT_REFERENCE)
		return;

	AcceptEntityInput(m_unEnt, "Kill");	
}

public Action Particles_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Continue;
	
	if(IsValidClient(client))
		CreateTimer(3.0, Timer_CreateParticle, client);

	return Plugin_Continue;		
}
public Action Particles_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
		RemoveCustomParticle(client);
	
	return Plugin_Continue;
}

bool IsValidClient(int client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client)) 
        return false; 
     
    return true; 
} 