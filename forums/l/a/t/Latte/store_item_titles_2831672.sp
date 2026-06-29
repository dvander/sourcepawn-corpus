#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <worldtext>
#include <tf2_stocks>
#include <store>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

char g_sChatPrefix[128];

Handle g_hTimerPreview[MAXPLAYERS + 1];
int g_PlayerWorldText[MAXPLAYERS + 1] = {-1, ...};

WorldText_Font StringToWorldTextFont(const char[] fontName) // Help me
{
    if (strcmp(fontName, "FONT_TF2_BULKY") == 0) {
        return FONT_TF2_BULKY;
    } else if (strcmp(fontName, "FONT_TF2_BULKY_NO_OUTLINE") == 0) {
        return FONT_TF2_BULKY_NO_OUTLINE;
    } else if (strcmp(fontName, "FONT_TF2") == 0) {
        return FONT_TF2;
    } else if (strcmp(fontName, "FONT_TF2_NO_OUTLINE") == 0) {
        return FONT_TF2_NO_OUTLINE;
    } else if (strcmp(fontName, "FONT_LIBERATION_SANS") == 0) {
        return FONT_LIBERATION_SANS;
    } else if (strcmp(fontName, "FONT_LIBERATION_SANS_NO_OUTLINE") == 0) {
        return FONT_LIBERATION_SANS_NO_OUTLINE;
    } else if (strcmp(fontName, "FONT_TF2_PROFESSOR") == 0) {
        return FONT_TF2_PROFESSOR;
    } else if (strcmp(fontName, "FONT_TF2_PROFESSOR_NO_OUTLINE") == 0) {
        return FONT_TF2_PROFESSOR_NO_OUTLINE;
    } else if (strcmp(fontName, "FONT_ROBOTO_MONO") == 0) {
        return FONT_ROBOTO_MONO;
    } else if (strcmp(fontName, "FONT_ROBOTO_MONO_NO_OUTLINE") == 0) {
        return FONT_ROBOTO_MONO_NO_OUTLINE;
    } else if (strcmp(fontName, "FONT_ROBOTO_MONO_SHADOW_ONLY") == 0) {
        return FONT_ROBOTO_MONO_SHADOW_ONLY;
    } else if (strcmp(fontName, "FONT_ROBOTO_MONO_GREEN_GLOW") == 0) {
        return FONT_ROBOTO_MONO_GREEN_GLOW;
    } else if (strcmp(fontName, "FONT_TF2_BULKY_SOFT_EDGES") == 0) {
        return FONT_TF2_BULKY_SOFT_EDGES;
    }
    return FONT_TF2_BULKY;
}

enum struct Titles
{
	char szTitle[PLATFORM_MAX_PATH];
	char szFontName[PLATFORM_MAX_PATH];
	WorldText_Font eFont;
	float fSize;
	float fXOffset;
	float fYOffset;
	float fZOffset;
	int iSlot;
}

enum struct TitleColors
{
	char szColor[16];
	int iColor[4];
	int iSlot;
	int iCacheID;
	bool bRainbow;
}

Titles g_eTitles[STORE_MAX_ITEMS];
TitleColors g_eColors[STORE_MAX_ITEMS];

int g_iTitles = 0;
int g_iClientTitles[MAXPLAYERS+1][STORE_MAX_SLOTS];
int g_iColors = 0;
int g_iClientColors[MAXPLAYERS+1][STORE_MAX_SLOTS];

int g_iTitleOwners[2048] = {-1};
int g_iColorOwners[2048] = {-1};

int g_iPreviewEntity[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};


public Plugin myinfo =
{
	name = "Store Titles",
	author = "Latte",
	description = "Displays player titles visible to other players, with third-person visibility",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	Store_RegisterHandler("titles", "title", titleOnMapStart, titleReset, titleConfig, titleEquip, titleRemove, true);
	Store_RegisterHandler("titlecolors", "color", colorOnMapStart, colorReset, colorConfig, colorEquip, colorRemove, true);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_changeclass", OnPlayerChangeClass, EventHookMode_PostNoCopy);
	HookEvent("post_inventory_application", EventInventoryApplicationPost, EventHookMode_PostNoCopy);

	LoadTranslations("store.phrases");
}

public void Store_OnConfigExecuted(char[] prefix)
{
	strcopy(g_sChatPrefix, sizeof(g_sChatPrefix), prefix);
}

public Action EventInventoryApplicationPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));


	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	ApplyPlayerTitle(client);

	return Plugin_Continue;
}


public Action OnPlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (g_PlayerWorldText[client] != -1)
	{
		killEntityIn(g_PlayerWorldText[client], 0.1);
		g_PlayerWorldText[client] = -1;
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_PlayerWorldText[client] != -1)
	{
		killEntityIn(g_PlayerWorldText[client], 0.1);
		
		g_PlayerWorldText[client] = -1;
	}
	
	return Plugin_Continue;
}

public void titleOnMapStart()
{
	for (int a = 0; a <= MaxClients; ++a)
	{
		for(int b = 0; b < STORE_MAX_SLOTS; ++b)
		{
			g_iClientTitles[a][b] = 0;
		}
	}
}

public void titleReset()
{
	g_iTitles = 0;
}

public bool titleConfig(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iTitles);

	KvGetString(kv, "title", g_eTitles[g_iTitles].szTitle, PLATFORM_MAX_PATH);
	KvGetString(kv, "font", g_eTitles[g_iTitles].szFontName, PLATFORM_MAX_PATH, "FONT_TF2_BULKY");
	g_eTitles[g_iTitles].eFont = StringToWorldTextFont(g_eTitles[g_iTitles].szFontName);


	g_eTitles[g_iTitles].fSize = KvGetFloat(kv, "size", 10.0);
	g_eTitles[g_iTitles].fXOffset = KvGetFloat(kv, "x_offset", 0.0);
	g_eTitles[g_iTitles].fYOffset = KvGetFloat(kv, "y_offset", 0.0);
	g_eTitles[g_iTitles].fZOffset = KvGetFloat(kv, "z_offset", 0.0);
	g_eTitles[g_iTitles].iSlot = KvGetNum(kv, "slot");

	if (strlen(g_eTitles[g_iTitles].szTitle) == 0)
	{
		return false;
	}
	
	g_iTitles++;

	return true;
}

public int titleEquip(int client, int id)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return -1;
	
	int m_iData = Store_GetDataIndex(id);
	g_iClientTitles[client][g_eTitles[m_iData].iSlot] = id;
	g_iTitleOwners[id] = client;

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateTimer(0.0, Timer_UpdateTitle, GetClientUserId(client));
	}
	
	return g_eTitles[m_iData].iSlot;
}

public int titleRemove(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	g_iClientTitles[client][g_eTitles[m_iData].iSlot] = 0;
	g_iTitleOwners[id] = -1;

	if (g_PlayerWorldText[client] != -1)
	{
		killEntityIn(g_PlayerWorldText[client], 0.1);
		g_PlayerWorldText[client] = -1;
	}
	
	return g_eTitles[m_iData].iSlot;
}

// Colors

public void colorOnMapStart()
{
	for (int a=0;a<=MaxClients;++a)
	{
		for(int b=0;b<STORE_MAX_SLOTS;++b)
		{
			g_iClientColors[a][b] = 0;
		}
	}
}

public void colorReset()
{
	g_iColors = 0;
}

public bool colorConfig(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iColors);
	KvGetString(kv, "color", g_eColors[g_iColors].szColor, 16, "255 255 255 255");
	KvGetColor(kv, "color", g_eColors[g_iColors].iColor[0], g_eColors[g_iColors].iColor[1], g_eColors[g_iColors].iColor[2], g_eColors[g_iColors].iColor[3]);
	g_eColors[g_iColors].bRainbow = (KvGetNum(kv, "rainbow", 0) == 1);
	g_eColors[g_iColors].iSlot = KvGetNum(kv, "slot");

	g_iColors++;

	return true;
}

public int colorEquip(int client, int id)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return -1;
	
	int m_iData = Store_GetDataIndex(id);
	g_iClientColors[client][g_eColors[m_iData].iSlot] = id;
	g_iColorOwners[id] = client;

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateTimer(0.0, Timer_UpdateTitle, GetClientUserId(client));
	}
	
	return g_eColors[m_iData].iSlot;
}

public int colorRemove(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	g_iClientColors[client][g_eColors[m_iData].iSlot] = 0;
	g_iColorOwners[id] = -1;

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateTimer(0.0, Timer_UpdateTitle, GetClientUserId(client));
	}
	
	return g_eColors[m_iData].iSlot;
}

void ApplyPlayerTitle(int client)
{
	TF2_AddCondition(client, TFCond_FreezeInput, 0.2); // Lazy method to prevent the player from moving their head, ensuring the text spawns in the correct position.
	bool useRainbow = false;

	if (g_PlayerWorldText[client] != -1)
	{
		killEntityIn(g_PlayerWorldText[client], 0.1);
		g_PlayerWorldText[client] = -1;
	}

	float eyePos[3], eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);

	int equippedTitle = Store_GetEquippedItem(client, "titles", 0);
	if (equippedTitle < 0)
		return;

	int titleIndex = Store_GetDataIndex(equippedTitle);
	if (titleIndex < 0 || titleIndex >= g_iTitles)
		return;

	// Default to white if no color is equipped.
	int r = 255, g = 255, b = 255, a = 255;

	// Check if player has a color equipped and use it.
	int equippedColor = Store_GetEquippedItem(client, "titlecolors", 0);
	if (equippedColor >= 0)
	{
		int colorIndex = Store_GetDataIndex(equippedColor);
		useRainbow = g_eColors[colorIndex].bRainbow;
		r = g_eColors[colorIndex].iColor[0];
		g = g_eColors[colorIndex].iColor[1];
		b = g_eColors[colorIndex].iColor[2];
		a = g_eColors[colorIndex].iColor[3];
	}

	g_PlayerWorldText[client] = WorldText_Create(eyePos, eyeAng, g_eTitles[titleIndex].szTitle, g_eTitles[titleIndex].fSize, _, _, g_eTitles[titleIndex].eFont, r, g, b, a, useRainbow, _);

	WorldText_AttachToEntity(g_PlayerWorldText[client], client, "head", g_eTitles[titleIndex].fXOffset, g_eTitles[titleIndex].fYOffset, g_eTitles[titleIndex].fZOffset);

	SetEntityRenderMode(g_PlayerWorldText[client], RENDER_TRANSCOLOR);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SDKHook(g_PlayerWorldText[client], SDKHook_SetTransmit, Hook_ShouldTransmitText);
		}
	}
}

public Action Hook_ShouldTransmitText(int entity, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_PlayerWorldText[i] == entity)
        {
            bool isCloaked = TF2_IsPlayerInCondition(i, TFCond_Cloaked);
            
            if (isCloaked)
            {
                return Plugin_Handled;
            }

            if (i == client)
            {
                int forcedTauntCam = GetEntProp(client, Prop_Send, "m_nForceTauntCam");
                bool isTaunting = TF2_IsPlayerInCondition(i, TFCond_Taunting);
               
                return (forcedTauntCam == 0 && !isTaunting) ? Plugin_Handled : Plugin_Continue;
            }
            break;
        }
    }
    return Plugin_Continue;
}

public Action Timer_UpdateTitle(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return Plugin_Stop;
		
	ApplyPlayerTitle(client);
	return Plugin_Stop;
}

public void Store_OnPreviewItem(int client, char[] type, int index)
{
	if (g_hTimerPreview[client] != null)
	{
		TriggerTimer(g_hTimerPreview[client], false);
	}

	float eyePos[3], eyeAng[3], position[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);

	GetAngleVectors(eyeAng, position, NULL_VECTOR, NULL_VECTOR);
	eyePos[0] += position[0] * 50.0;
	eyePos[1] += position[1] * 50.0;
	eyePos[2] += position[2] * 50.0;

	int r = 255, g = 255, b = 255, a = 255;
	bool useRainbow = false;

	if (StrEqual(type, "titles"))
	{
		int equippedColor = Store_GetEquippedItem(client, "titlecolors", 0);
		if (equippedColor >= 0)
		{
			int colorIndex = Store_GetDataIndex(equippedColor);
			useRainbow = g_eColors[colorIndex].bRainbow;
			r = g_eColors[colorIndex].iColor[0];
			g = g_eColors[colorIndex].iColor[1];
			b = g_eColors[colorIndex].iColor[2];
			a = g_eColors[colorIndex].iColor[3];
		}

		int iPreview = WorldText_Create(eyePos, eyeAng, g_eTitles[index].szTitle, g_eTitles[index].fSize, _, _, g_eTitles[index].eFont, r, g, b, a, useRainbow, _);

		g_iPreviewEntity[client] = EntIndexToEntRef(iPreview);

		SDKHook(iPreview, SDKHook_SetTransmit, Hook_SetTransmit_Preview);

		g_hTimerPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);

		CPrintToChat(client, "%s%t", g_sChatPrefix, "Spawn Preview", client);
	}
	else if (StrEqual(type, "titlecolors"))
	{
		useRainbow = g_eColors[index].bRainbow;
		r = g_eColors[index].iColor[0];
		g = g_eColors[index].iColor[1];
		b = g_eColors[index].iColor[2];
		a = g_eColors[index].iColor[3];

		int equippedTitle = Store_GetEquippedItem(client, "titles", 0);
		if (equippedTitle >= 0)
		{
			int titleIndex = Store_GetDataIndex(equippedTitle);
			int iPreview = WorldText_Create(eyePos, eyeAng, g_eTitles[titleIndex].szTitle, g_eTitles[titleIndex].fSize, _, _, g_eTitles[titleIndex].eFont, r, g, b, a, useRainbow, _);
			g_iPreviewEntity[client] = EntIndexToEntRef(iPreview);
			SDKHook(iPreview, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
			g_hTimerPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);

			CPrintToChat(client, "%s%t", g_sChatPrefix, "Spawn Preview", client);
		}
		else
		{
			int iPreview = WorldText_Create(eyePos, eyeAng, "Preview Text", 10.0, _, _, _, r, g, b, a, false, _);

			g_iPreviewEntity[client] = EntIndexToEntRef(iPreview);

			SDKHook(iPreview, SDKHook_SetTransmit, Hook_SetTransmit_Preview);

			g_hTimerPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);

			CPrintToChat(client, "%s%t", g_sChatPrefix, "Spawn Preview", client);
		}
	}
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
	if (g_iPreviewEntity[client] == INVALID_ENT_REFERENCE)
		return Plugin_Handled;
	
	if (ent == EntRefToEntIndex(g_iPreviewEntity[client]))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
	g_hTimerPreview[client] = null;

	if (g_iPreviewEntity[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(g_iPreviewEntity[client]);

		if (entity > 0 && IsValidEdict(entity))
		{
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
			AcceptEntityInput(entity, "Kill");
		}
	}
	g_iPreviewEntity[client] = INVALID_ENT_REFERENCE;

	return Plugin_Stop;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client < 1 || client > MaxClients)
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;
	
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

void killEntityIn(int iEnt, float flSeconds)
{
	if (!IsValidEntity(iEnt))
	{
		return;
	}

	char szAddOutput[32];
	Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
	SetVariantString(szAddOutput);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}