#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 128000
#include <sdktools>
#include <sdkhooks>
#include <SteamWorks>
#include <regex>

public Plugin myinfo = 
{
	name = "Faceit Level", 
	description = "Show players faceit rank", 
	author = "Phoenix (˙·٠●Феникс●٠·˙)", 
	version = "1.0.4", 
	url = "zizt.ru hlmod.ru"
};

enum struct Player
{
	int iUserID;
	int iSkillLevel;
	bool bLoad;
}

Regex g_hSkillLevel;
Player g_Players[MAXPLAYERS + 1];
int m_nPersonaDataPublicLevel;
ConVar sm_faceit_level_api_key;
char g_szApiKey[64];


public void OnPluginStart()
{
	g_hSkillLevel = new Regex("\"csgo\":{.*?\"skill_level\":(\\d+)");
	
	sm_faceit_level_api_key = CreateConVar("sm_faceit_level_api_key", "Ваш API ключ", "Как получить API ключ - https://hlmod.ru/threads/faceit-level.52529/#post-464526");
	sm_faceit_level_api_key.AddChangeHook(ApiKeyChanged);
	
	AutoExecConfig(true, "faceit_level");
	
	char szBuf[64];
	
	//Нужно получить значение, иначе если будет загружен посреди игры то g_szApiKey будет пуст
	sm_faceit_level_api_key.GetString(szBuf, sizeof szBuf);
	ApiKeyChanged(null, NULL_STRING, szBuf);
	
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
	char szBuf[PLATFORM_MAX_PATH];
	
	for (int i = 0; i < 10; i++)
	{
		FormatEx(szBuf, sizeof szBuf, "materials/panorama/images/icons/xp/level%i.png", 5001 + i);
		
		AddFileToDownloadsTable(szBuf);
	}
	
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, Hook_OnThinkPost);
}

void ApiKeyChanged(ConVar hConvar, const char[] szOld, const char[] szNew)
{
	FormatEx(g_szApiKey, sizeof g_szApiKey, "Bearer %s", szNew);
}

//Чтобы уменьшить количество запросов к API
public void OnClientConnected(int iClient)
{
	int iUserID = GetClientUserId(iClient);
	
	if (g_Players[iClient].iUserID != iUserID)
	{
		g_Players[iClient].iUserID = iUserID;
		g_Players[iClient].iSkillLevel = 0;
		g_Players[iClient].bLoad = false;
	}
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (g_Players[iClient].bLoad || IsFakeClient(iClient))
	{
		return;
	}
	
	char szSteamID[20];
	
	GetClientAuthId(iClient, AuthId_SteamID64, szSteamID, sizeof szSteamID);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://open.faceit.com/data/v4/players");
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Authorization", g_szApiKey);
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Accept", "application/json");
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "game", "csgo");
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "game_player_id", szSteamID);
	
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));
	
	SteamWorks_SetHTTPCallbacks(hRequest, HTTPPlayerDetailsComplete);
	
	SteamWorks_SendHTTPRequest(hRequest);
}

void HTTPPlayerDetailsComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any iUserID)
{
	//Пока что игнорируем ошибки при загрузке
	if (eStatusCode == k_EHTTPStatusCode200OK || eStatusCode == k_EHTTPStatusCode404NotFound)
	{
		int iClient = GetClientOfUserId(iUserID);
		
		if (iClient)
		{
			//Если игрок играл на faceit
			if (eStatusCode == k_EHTTPStatusCode200OK)
			{
				int iSize;
				SteamWorks_GetHTTPResponseBodySize(hRequest, iSize);
				
				if (iSize > 10)
				{
					char[] szBuf = new char[iSize + 1];
					SteamWorks_GetHTTPResponseBodyData(hRequest, szBuf, iSize);
					
					if (g_hSkillLevel.Match(szBuf) == 2)
					{
						g_hSkillLevel.GetSubString(1, szBuf, 4, 0);
						
						g_Players[iClient].iSkillLevel = StringToInt(szBuf);
					}
				}
			}
			
			g_Players[iClient].bLoad = true;
		}
	}
	else if (eStatusCode == k_EHTTPStatusCode401Unauthorized || eStatusCode == k_EHTTPStatusCode403Forbidden)
	{
		LogError("Неверный API ключ");
	}
	
	delete hRequest;
}

void Hook_OnThinkPost(int iEnt)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_Players[i].iSkillLevel)
		{
			SetEntData(iEnt, m_nPersonaDataPublicLevel + i * 4, g_Players[i].iSkillLevel + 5000);
		}
	}
} 