#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

Handle cookie;

int GlowType[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D2] Glow Survivor", 
	author = "King_OXO (edited, now have cookie) and also i am valedar added translation, menu and chat support.", 
	description = "", 
	version = "5.0.0", 
	url = "https://forums.alliedmods.net/showthread.php?t=332956"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2");
		
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_team", Event_Player_Death, EventHookMode_Pre);
	
	RegConsoleCmd("sm_aura", SetAura, "Set your aura.");
	RegConsoleCmd("sm_glow", SetAura, "Set your aura.");
	cookie = RegClientCookie("l4d2_glow", "cookie for aura id", CookieAccess_Private);
	LoadTranslations("l4d2_glow_menu.phrases");
}

public void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(client) == 3)
	{
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	}
	else if (GetClientTeam(client) == 2)
	{
		ReadCookies(client);
	}
}

public void Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	}
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

public void ReadCookies(int client)
{
	if (!ValidClient(client))
		return;
	
	char str[4];
	
	GetClientCookie(client, cookie, str, 4);
	if (strcmp(str, "") != 0)GetAura(client, StringToInt(str));
}

stock bool ValidClient(int client, bool noBots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientAuthorized(client) || (noBots && IsFakeClient(client)))
		return false;
	
	return IsClientInGame(client);
}

public Action SetAura(int client, int args)
{	
	if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
	{
		CPrintToChat(client, "%t", "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	SetGlobalTransTarget(client);
	
	Menu menu = new Menu(VIPAuraMenuHandler);
	
	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t", "AURA MENU");
	menu.SetTitle(buffer);	
	FormatEx(buffer, sizeof(buffer), "%t", "Inactive");
	menu.AddItem("option0", buffer, GlowType[client] == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Green");
	menu.AddItem("option1", buffer, GlowType[client] == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Blue");
	menu.AddItem("option2", buffer, GlowType[client] == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "Violet");
	menu.AddItem("option3", buffer, GlowType[client] == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Cyan");
	menu.AddItem("option4", buffer, GlowType[client] == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Orange");
	menu.AddItem("option5", buffer, GlowType[client] == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Red");
	menu.AddItem("option6", buffer, GlowType[client] == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Gray");
	menu.AddItem("option7", buffer, GlowType[client] == 7 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Yellow");
	menu.AddItem("option8", buffer, GlowType[client] == 8 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);		
	FormatEx(buffer, sizeof(buffer), "%t", "Lime");
	menu.AddItem("option9", buffer, GlowType[client] == 9 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Maroon");
	menu.AddItem("option10", buffer, GlowType[client] == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "Teal");
	menu.AddItem("option11", buffer, GlowType[client] == 11 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(buffer, sizeof(buffer), "%t", "Pink");
	menu.AddItem("option12", buffer, GlowType[client] == 12 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "Purple");
	menu.AddItem("option13", buffer, GlowType[client] == 13 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "White");
	menu.AddItem("option14", buffer, GlowType[client] == 14 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "Golden");
	menu.AddItem("option15", buffer, GlowType[client] == 15 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	
	FormatEx(buffer, sizeof(buffer), "%t", "Rainbow");
	menu.AddItem("option16", buffer, GlowType[client] == 16 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int VIPAuraMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		delete menu;
		case MenuAction_Select:
		{
			if (!IsPlayerAlive(param1))
			{
				PrintToChat(param1, "%t", "You must be alive to set your aura.");
				
				return 0;
			}
			
			GetAura(param1, param2);
			SetCookie(param1, cookie, param2);
			
		}
	}
	
	return 0;
}


public void SetCookie(int client, Handle hCookie, int n)
{
	char[] strCookie = new char[4];
	
	IntToString(n, strCookie, 4);
	SetClientCookie(client, hCookie, strCookie);
}

void GetAura(int client, int id)
{
	switch (id)
	{
		case 0:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			CPrintToChat(client, "%t", "Aura Disabled");
		}
		case 1:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
			CPrintToChat(client, "%t", "You Changed Color: Green!");
		}
		case 2:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Blue!");
		}
		case 3:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Violet!");
		}
		case 4:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Cyan!");
		}
		case 5:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Orange!");
		}
		case 6:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Red!");
		}
		case 7:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Gray!");
		}
		case 8:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Yellow!");
		}
		case 9:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Lime!");
		}
		case 10:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Maroon!");
		}
		case 11:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Teal!");
		}
		case 12:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Pink!");
		}
		case 13:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Purple!");
		}
		case 14:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: White!");
		}
		case 15:
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (155 * 256) + (0 * 65536));
			
			CPrintToChat(client, "%t", "You Changed Color: Golden!");
		}
		case 16:
		{
			SDKHook(client, SDKHook_PreThink, RainbowPlayer);
			CPrintToChat(client, "%t", "You Changed Color: Rainbow!");
		}
	}
	
	if (0 <= id <= 15)
	{
		
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		
		SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
		
		SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
		
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	}
	
	GlowType[client] = id;
}
public Action RainbowPlayer(int client)
{
	if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
	{
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		
	}
	
	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 1) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 3) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * 3.0) + client + 5) * 127.5 + 127.5);
	
	SetEntProp(client, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
	
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	
	SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
	
	SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
	
	return Plugin_Continue;
} 