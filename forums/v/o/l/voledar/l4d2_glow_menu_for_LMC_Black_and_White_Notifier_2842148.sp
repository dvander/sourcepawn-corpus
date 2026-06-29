#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

native int LMC_GetClientOverlayModel(int client);

enum struct ColorInfo
{
	char name[32];
	int r;
	int g;
	int b;
}

static const ColorInfo g_Colors[] = 
{
	{ "- Disable \n ",	0, 0, 0		}, // Первый всегда должен быть Disable!!!
	{ "- Green",		0, 255, 0	},
	{ "- Blue",			7, 19, 250	},
	{ "- Violet",		249, 19, 250},
	{ "- Cyan",			66, 250, 250},
	{ "- Orange",		249, 155, 84},
	{ "- Red",			255, 0, 0	},
	{ "- Gray",			50, 50, 50	},
	{ "- Yellow",		255, 255, 0	},
	{ "- Lime",			128, 255, 0	},
	{ "- Maroon",		128, 0, 0	},
	{ "- Teal",			0, 128, 128	},
	{ "- Pink",			255, 0, 150	},
	{ "- Purple",		155, 0, 255	},
	{ "- Golden",		255, 155, 0	},
	{ "- Rainbow",		0, 0, 0		} // Последний всегда должен быть Rainbow!!! 
};

int g_iSurvMaxIncapCount;
int	g_iGlowType[MAXPLAYERS+1];
Cookie g_cCookie;
bool g_bLMC_Available;

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
		g_bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "LMCCore", true) == 0)
		g_bLMC_Available = false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Glow Survivor", 
	author = "King_OXO && valedar(rework and fix)", 
	description = "", 
	version = "9.9.9v", 
	url = "https://forums.alliedmods.net/showthread.php?t=332956"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_Player_Team);
	HookEvent("player_team", Event_Player_Team);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("heal_success", Event_Heal_Success);

	RegConsoleCmd("sm_aura", Cmd_Aura, "Set your aura.");
	RegConsoleCmd("sm_glow", Cmd_Aura, "Set your aura.");
	g_cCookie = new Cookie("l4d2_glow", "cookie for aura id", CookieAccess_Private);
	
	ConVar g_hSurvMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_iSurvMaxIncapCount = g_hSurvMaxIncapCount.IntValue;
	g_hSurvMaxIncapCount.AddChangeHook(SurvMaxIncapCount_Changed);
}

void SurvMaxIncapCount_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSurvMaxIncapCount = convar.IntValue;
}

public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client))
	{
		char sCookie[4];
		g_cCookie.Get(client, sCookie, sizeof(sCookie));

		if (sCookie[0])
		{
			g_iGlowType[client] = StringToInt(sCookie);
			return;
		}

		g_iGlowType[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		char sCookie[4];
		IntToString(g_iGlowType[client], sCookie, sizeof(sCookie));
		g_cCookie.Set(client, sCookie);
	}
}

void Event_Player_Team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client) || g_iGlowType[client] == 0) return;
	DisableGlow(client);
}

void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	CreateTimer(3.5, Timer_SetAura, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_Heal_Success(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("subject");
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	CreateTimer(0.11, Timer_SetAura, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_SetAura(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (g_iGlowType[client] > 0)
		{
			SetAura(client, g_iGlowType[client]);
		}
	}
	return Plugin_Continue;
}

Action Cmd_Aura(int client, int args)
{
	if (IsValidClient(client)) ShowMenuAura(client);
	return Plugin_Handled;
}

void ShowMenuAura(int client, int pos = 0)
{
	Menu menu = new Menu(VIPAuraMenuHandler);
	menu.SetTitle("Aura Color:\n ");

	for (int i = 0; i < sizeof(g_Colors); i++)
		menu.AddItem("", g_Colors[i].name, g_iGlowType[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	menu.ExitButton = true;
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

int VIPAuraMenuHandler(Menu menu, MenuAction action, int client, int id)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			if (IsPlayerAlive(client) && GetClientTeam(client) == 2) {
				SetAura(client, id);
			}

			g_iGlowType[client] = id;
			ShowMenuAura(client, GetMenuSelectionPosition());
		}
	}
	return 0;
}

void SetAura(int client, int id)
{
	switch (id)
	{
		case 0: DisableGlow(client);
		case sizeof(g_Colors) -1:
		{
			DisableGlow(client);
			SDKHook(client, SDKHook_PreThink, RainbowPlayer);
		}
		default:
		{
			SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
			if (g_bLMC_Available)
			{
				int entity = LMC_GetClientOverlayModel(client);
				if (entity > MaxClients) SetGlow(entity, g_Colors[id].r + (g_Colors[id].g * 256) + (g_Colors[id].b * 65536), 3, 99999, 0);
				else SetGlow(client, g_Colors[id].r + (g_Colors[id].g * 256) + (g_Colors[id].b * 65536), 3, 99999, 0);
			}
			else SetGlow(client, g_Colors[id].r + (g_Colors[id].g * 256) + (g_Colors[id].b * 65536), 3, 99999, 0);
		}
	}
}

public Action RainbowPlayer(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_currentReviveCount") == g_iSurvMaxIncapCount)
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);

	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 1) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 3) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 5) * 127.5 + 127.5);
	
	if (g_bLMC_Available)
	{
		int entity = LMC_GetClientOverlayModel(client);
		if (entity > MaxClients) SetGlow(entity, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
		else SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);
	}
	else SetGlow(client, color[0] + (color[1] * 256) + (color[2] * 65536), 3, 99999, 0);

	return Plugin_Continue;
}

public void LMC_OnClientModelApplied(int client, int entity, const char model[PLATFORM_MAX_PATH], bool baseReattach)
{
	if (!IsValidClient(client) || GetClientTeam(client) != 2 || g_iGlowType[client] == 0) return;
	SetGlow
	(
			entity, 
			GetEntProp(client, Prop_Send, "m_glowColorOverride", 0), 
			GetEntProp(client, Prop_Send, "m_iGlowType", 0), 
			GetEntProp(client, Prop_Send, "m_nGlowRange", 0), 
			GetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0)
	);
	SetGlow(client, 0, 0, 0, 0);
}

public void LMC_OnClientModelDestroyed(int client, int entity)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2 
	|| !IsValidEntity(entity) || g_iGlowType[client] == 0) return;
	SetGlow
	(
			client, 
			GetEntProp(entity, Prop_Send, "m_glowColorOverride", 0), 
			GetEntProp(entity, Prop_Send, "m_iGlowType", 0), 
			GetEntProp(entity, Prop_Send, "m_nGlowRange", 0), 
			GetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0)
	);
}

void DisableGlow(int client)
{
	if (g_bLMC_Available)
	{
		int entity = LMC_GetClientOverlayModel(client);
		if (entity > MaxClients) SetGlow(entity, 0, 0, 0, 0);
		else SetGlow(client, 0, 0, 0, 0);
	}
	else SetGlow(client, 0, 0, 0, 0);
	SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
}

void SetGlow(int entity, int color, int type, int range, int rangeMin)
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", rangeMin);
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}