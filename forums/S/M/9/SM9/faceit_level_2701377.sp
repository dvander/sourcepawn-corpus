#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <sdkhooks>
#include <SteamWorks>

public Plugin myinfo =
{
	name = "Faceit Level",
	description = "Show players faceit rank",
	author = "Phoenix (˙·٠●Феникс●٠·˙)",
	version = "1.0.3",
	url = "zizt.ru hlmod.ru"
};

enum struct Player
{
	int iUserID;
	int iSkillLevel;
	bool bLoad;
}

Player g_Players[MAXPLAYERS+1];
int m_nPersonaDataPublicLevel;
ConVar sm_faceit_level_api_key;
char g_sApiKey[64];


public void OnPluginStart()
{
	sm_faceit_level_api_key = CreateConVar("sm_faceit_level_api_key", "Ваш API ключ", "Как получить API ключ - https://hlmod.ru/threads/faceit-level.52529/#post-464526");
	sm_faceit_level_api_key.AddChangeHook(ApiKeyChanged);
	
	AutoExecConfig(true, "faceit_level");
	
	char sBuf[64];
	
	//Нужно получить значение, иначе если будет загружен посреди игры то g_sApiKey будет пуст
	sm_faceit_level_api_key.GetString(sBuf, sizeof sBuf);
	ApiKeyChanged(null, NULL_STRING, sBuf);
	
	m_nPersonaDataPublicLevel = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientAuthorized(i) && !IsFakeClient(i))
		{
			OnClientAuthorized(i, NULL_STRING);
		}
	}
}

public void OnMapStart()
{
	char sBuf[PLATFORM_MAX_PATH];
	
	for(int i = 0; i < 10; i++)
	{
		FormatEx(sBuf, sizeof sBuf, "materials/panorama/images/icons/xp/level%i.png", 5001 + i);
		
		AddFileToDownloadsTable(sBuf);
	}
	
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, Hook_OnThinkPost);
}

void ApiKeyChanged(ConVar hConvar, const char[] oldValue, const char[] newValue)
{
	FormatEx(g_sApiKey, sizeof g_sApiKey, "Bearer %s", newValue);
}

//Чтобы уменьшить количество запросов к API
public void OnClientConnected(int iClient)
{
	int iUserID = GetClientUserId(iClient);
	
	if(g_Players[iClient].iUserID != iUserID)
	{
		g_Players[iClient].iUserID = iUserID;
		g_Players[iClient].iSkillLevel = 0;
		g_Players[iClient].bLoad = false;
	}
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if(g_Players[iClient].bLoad || IsFakeClient(iClient))
	{
		return;
	}
	
	char sBuf[20];
	
	GetClientAuthId(iClient, AuthId_SteamID64, sBuf, sizeof sBuf);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://open.faceit.com/data/v4/players");
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Authorization", g_sApiKey);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "game", "csgo");
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "game_player_id", sBuf);
	
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));
	
	SteamWorks_SetHTTPCallbacks(hRequest, HTTPPlayerDetailsComplete);
	
	SteamWorks_SendHTTPRequest(hRequest);
}

void HTTPPlayerDetailsComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any iUserID)
{
	//Пока что игнорируем ошибки при загрузке
	if(eStatusCode == k_EHTTPStatusCode200OK || eStatusCode == k_EHTTPStatusCode404NotFound)
	{
		int iClient = GetClientOfUserId(iUserID);
		
		if(iClient)
		{
			//Если игрок играл на faceit
			if(eStatusCode == k_EHTTPStatusCode200OK)
			{
				SteamWorks_GetHTTPResponseBodyCallback(hRequest, HTTPPlayerDetailsCompleteData, iUserID);
			}
			else
			{
				g_Players[iClient].bLoad = true;
			}
		}
	}
	
	delete hRequest;
}

void HTTPPlayerDetailsCompleteData(const char[] sData, any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(iClient)
	{
		int iPos = StrContains(sData, "\"csgo\":{\"game_profile_id\":");
		
		if(iPos != -1)
		{
			iPos += 26;
			
			iPos = StrContains(sData[iPos], "skill_level\":") + iPos + 13;
			
			int i = 0;
			char sBuf[4];
			
			do
			{
				sBuf[i] = sData[iPos+i];
			}
			while(sData[iPos + ++i] != ',');
			
			g_Players[iClient].iSkillLevel = StringToInt(sBuf);
		}
		
		g_Players[iClient].bLoad = true;
	}
}

void Hook_OnThinkPost(int iEnt)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if(g_Players[i].iSkillLevel)
        {
            SetEntData(iEnt, m_nPersonaDataPublicLevel + i * 4, g_Players[i].iSkillLevel + 5000);
        }
    }
}