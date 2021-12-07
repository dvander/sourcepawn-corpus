#include <sdkhooks>
#include <store>
#include <zephstocks>
#include <clientprefs>

#define MAX_EFFECT_NAME_LENGTH 64

enum Aura
{
	String:effect[MAX_EFFECT_NAME_LENGTH],
	String:file[PLATFORM_MAX_PATH],
	String:material[PLATFORM_MAX_PATH],
	String:material2[PLATFORM_MAX_PATH]
}

new g_eAuras[STORE_MAX_ITEMS][Aura];
new g_iAuraCount = 0;
new g_unClientAura[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
new g_unSelectedAura[MAXPLAYERS+1]={-1,...};

Handle g_hAurasCookie;
int g_iAurasCookie[MAXPLAYERS+1] = {1, 0};

public OnPluginStart()
{
	new String:m_szGameDir[32];
	GetGameFolderName(m_szGameDir, sizeof(m_szGameDir));
	
	Store_RegisterHandler("aura", "effect", Auras_OnMapStart, Auras_Reset, Auras_Config, Auras_Equip, Auras_Remove, true);
	
	HookEvent("player_spawn", Auras_PlayerSpawn);
	HookEvent("player_death", Auras_PlayerDeath);
	HookEvent("player_team", Auras_PlayerTeam);
	
	g_hAurasCookie = RegClientCookie("store_auras_enabled", "Allows players to enable/disable store auras", CookieAccess_Protected);
	SetCookieMenuItem(OnUseCookie, 0, "Aura Visibility");
	RegConsoleCmd("sm_auras", Command_AuraVisibility, "Shows a menu aura visibility options");
}

public Action Command_AuraVisibility(int iClient, int iArgs)
{
	Menu hMenu = new Menu(Menu_AuraVisibility);
	hMenu.SetTitle("Aura Visibility");
	hMenu.AddItem("0", "None Visible");
	hMenu.AddItem("1", "All Visible");
	hMenu.AddItem("2", "Show Only Own Aura");
	hMenu.Display(iClient, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_AuraVisibility(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			char sDisplay[64], sSet[4];
			hMenu.GetItem(iParam2, sSet, sizeof(sSet), _, sDisplay, sizeof(sDisplay));
			switch (StringToInt(sSet))
			{
				case 0:
				{
					SetClientCookie(iParam1, g_hAurasCookie, sSet);
					g_iAurasCookie[iParam1] = 0;
					PrintToChat(iParam1, "Auras will no longer be shown.");
				}
				case 1:
				{
					SetClientCookie(iParam1, g_hAurasCookie, sSet);
					g_iAurasCookie[iParam1] = 1;
					PrintToChat(iParam1, "Auras will now always be shown.");
				}
				case 2:
				{
					SetClientCookie(iParam1, g_hAurasCookie, sSet);
					g_iAurasCookie[iParam1] = 2;
					PrintToChat(iParam1, "Only your own aura will be visible to you.");
				}
			}
		}
	}
}

public void OnUseCookie(int iClient, CookieMenuAction action, any cookie, char[] sBuffer, int iMaxLen)
{
	if(action == CookieMenuAction_SelectOption)
		FakeClientCommand(iClient, "sm_auras");
}

public void OnClientCookiesCached(int iClient)
{
	char sTemp[4];
	GetClientCookie(iClient, g_hAurasCookie, sTemp, sizeof(sTemp));
	
	if(sTemp[0] == '\0')
	{
		sTemp = "1";
		SetClientCookie(iClient, g_hAurasCookie, sTemp);
	}
	
	g_iAurasCookie[iClient] = StringToInt(sTemp);
}

public Auras_Equip(client, id)
{
	if (!IsClientInGame(client))
		return 0;
		
	g_unSelectedAura[client]=Store_GetDataIndex(id);
	
	if (IsPlayerAlive(client))
	{
		RemoveParticlesFromPlayer(client);
		AddParticlesToPlayer(client);
	}
	
	return 0;
}

public Auras_Remove(client)
{
	RemoveParticlesFromPlayer(client);
	return 0;
}

public Auras_OnClientConnected(client)
{
	g_unSelectedAura[client]=-1;
}

public Auras_OnClientDisconnect(client)
{
	g_unSelectedAura[client]=-1;
}

public Auras_OnMapStart()
{
	for(new i = 0; i < g_iAuraCount; i++)
	{
		if(strlen(g_eAuras[i][file]) != 0)
		{
			char sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "particles/%s", g_eAuras[i][file]);
			Downloader_AddFileToDownloadsTable(sPath);
			PrecacheParticle(sPath);
		}
	}
	
	for(new i = 0; i < g_iAuraCount; i++)
	{
		if(strlen(g_eAuras[i][material]) != 0)
		{
			char sBuffer[PLATFORM_MAX_PATH];
			strcopy(sBuffer, PLATFORM_MAX_PATH, g_eAuras[i][material]);
		
			Downloader_AddFileToDownloadsTable(sBuffer);
		
			ReplaceString(sBuffer, sizeof(sBuffer), ".vmt", ".vtf", false);
			Downloader_AddFileToDownloadsTable(sBuffer);
		}
		
		if(strlen(g_eAuras[i][material2]) != 0)
		{
			char sBuffer[PLATFORM_MAX_PATH];
			strcopy(sBuffer, PLATFORM_MAX_PATH, g_eAuras[i][material2]);
		
			Downloader_AddFileToDownloadsTable(sBuffer);
		
			ReplaceString(sBuffer, sizeof(sBuffer), ".vmt", ".vtf", false);
			Downloader_AddFileToDownloadsTable(sBuffer);
		}
	}
}

public Action:Auras_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Continue;
	
	//If they had one equipped but didn't die, kill it
	RemoveParticlesFromPlayer(client);
	
	AddParticlesToPlayer(client);

	return Plugin_Continue;
}

public Action:Auras_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	
	//Kill the particle system when the player dies
	RemoveParticlesFromPlayer(client);

	return Plugin_Continue;
}

public Action:Auras_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	
	//Kill the particle system when the player dies
	RemoveParticlesFromPlayer(client);

	return Plugin_Continue;
}

public Auras_Reset()
{
	g_iAuraCount = 0;
}

public Auras_Config(&Handle:kv, itemid)
{
	//unique_id = item name
	Store_SetDataIndex(itemid, g_iAuraCount);
	
	KvGetString(kv, "effect", g_eAuras[g_iAuraCount][effect], MAX_EFFECT_NAME_LENGTH);
	KvGetString(kv, "file", g_eAuras[g_iAuraCount][file], PLATFORM_MAX_PATH);
	KvGetString(kv, "material", g_eAuras[g_iAuraCount][material], PLATFORM_MAX_PATH);
	KvGetString(kv, "material2", g_eAuras[g_iAuraCount][material2], PLATFORM_MAX_PATH);
	
	g_iAuraCount++;
	return true;
}

public void RemoveParticlesFromPlayer(int iClient)
{
	if(g_unClientAura[iClient] == INVALID_ENT_REFERENCE)
		return;
		
	new m_unEnt = EntRefToEntIndex(g_unClientAura[iClient]);
	g_unClientAura[iClient] = INVALID_ENT_REFERENCE;
	
	if(m_unEnt == INVALID_ENT_REFERENCE || !IsEntParticleSystem(m_unEnt))
		return;
	
	AcceptEntityInput(m_unEnt, "Kill");
}

stock bool IsEntParticleSystem(int iEntity)
{
	if (IsValidEdict(iEntity))
	{
		char sBuffer[128];
		GetEdictClassname(iEntity, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "info_particle_system", false))
		{
			return true;
		}
	}
	return false;
}

public void AddParticlesToPlayer(int iClient)
{
	if(g_unClientAura[iClient] != INVALID_ENT_REFERENCE)
		return;
	
	if(g_unSelectedAura[iClient] < 0)
		return;
	
	int iEntity = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iEntity) && (iClient > 0))
	{
		if (IsPlayerAlive(iClient))
		{
			// Get players current position
			new Float:vPosition[3];
			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPosition);
			
			// Move particle to player
			TeleportEntity(iEntity, vPosition, NULL_VECTOR, NULL_VECTOR);
			
			// Set entity name
			DispatchKeyValue(iEntity, "targetname", "particle");
			
			// Get player entity name
			decl String:szParentName[64];
			GetEntPropString(iClient, Prop_Data, "m_iName", szParentName, sizeof(szParentName));
			
			// Set the effect name
			DispatchKeyValue(iEntity, "effect_name", g_eAuras[g_unSelectedAura[iClient]][effect]);
			
			// Spawn the particle
			DispatchSpawn(iEntity);
			
			// Target the particle
			SetVariantString("!activator");
			
			// Set particle parent name
			DispatchKeyValue(iEntity, "parentname", szParentName);
			
			// Set client to parent of particle
			AcceptEntityInput(iEntity, "SetParent", iClient, iEntity, 0);
			
			// Activate the entity (starts animation)
			ActivateEntity(iEntity);
			AcceptEntityInput(iEntity, "Start");
			
			// Attach to parent model
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", iClient);
			
			SetFlags(iEntity);
			SDKHook(iEntity, SDKHook_SetTransmit, OnSetTransmit);
			g_unClientAura[iClient] = EntIndexToEntRef(iEntity);
		}
	}
}

public void SetFlags(int iEdict) 
{ 
    if (GetEdictFlags(iEdict) & FL_EDICT_ALWAYS) 
    { 
        SetEdictFlags(iEdict, (GetEdictFlags(iEdict) ^ FL_EDICT_ALWAYS)); 
    } 
}

public Action OnSetTransmit(int iEnt, int iClient)
{
	int iOwner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	SetFlags(iEnt);
	if(iOwner && IsClientInGame(iOwner))
	{
		if(g_iAurasCookie[iClient] == 0)
			return Plugin_Stop;
		if(g_iAurasCookie[iClient] == 2 && iOwner != iClient)
			return Plugin_Stop;
		
	}
	
	return Plugin_Continue;
}

public PrecacheParticle(const String:path[])
{
	if(!FileExists(path, true, NULL_STRING))
	{
		//PrintToServer("\nParticle file \'%s\' not found.", path);
		//return;
	}

	PrecacheGeneric(path, true);
}