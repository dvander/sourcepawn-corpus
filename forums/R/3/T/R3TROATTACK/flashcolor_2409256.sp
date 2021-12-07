
#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <clientprefs>

#define FFADE_IN            0x0001
#define FFADE_OUT           0x0002
#define FFADE_MODULATE      0x0004
#define FFADE_STAYOUT       0x0008
#define FFADE_PURGE         0x0010

public Plugin myinfo = 
{
	name = "Flashbang Colors",
	author = PLUGIN_AUTHOR,
	description = "Adds colors to your flashbangs",
	version = PLUGIN_VERSION,
	url = "www.steam-gamers.net/forum/forum.php"
};

int g_iFlashColor[MAXPLAYERS + 1][16];
Handle g_hFlashCookie = INVALID_HANDLE;

EngineVersion g_Game;

ConVar g_cColorsEnabled;

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");
	}
	
	g_cColorsEnabled = CreateConVar("flashcolors_enabled", "1", "Is this plugin enabled?", FCVAR_NONE, true, 0.0);
	
	HookEvent("player_blind", player_blind);
	HookEvent("flashbang_detonate", Event_FlashbangDetonated);
	RegAdminCmd("sm_flashcolors", Command_FlashColor, ADMFLAG_CUSTOM6);
	
	g_hFlashCookie = RegClientCookie("FlashColorCookie", "Temp Flash Color Cookie", CookieAccess_Public);
}

public Action Command_FlashColor(int client, int args)
{
	if(g_cColorsEnabled.IntValue == 0)
		return Plugin_Handled;
	
	if (client > MaxClients || client < 0)
		return Plugin_Handled;
	
	if (args < 3)
	{
		OpenFlashColorMenu(client);
		return Plugin_Handled;
	}
	
	if (args == 3)
	{
		char color[3][16];
		
		GetCmdArg(1, color[0], 16);
		GetCmdArg(2, color[1], 16);
		GetCmdArg(3, color[2], 16);
		
		g_iFlashColor[client][0] = StringToInt(color[0]);
		g_iFlashColor[client][1] = StringToInt(color[1]);
		g_iFlashColor[client][2] = StringToInt(color[2]);
		
		int color1[3];
		color1[0] = g_iFlashColor[client][0];
		color1[1] = g_iFlashColor[client][1];
		color1[2] = g_iFlashColor[client][2];
		
		UpdateCookies(client, color1);
	}
	
	return Plugin_Handled;
}

public void OpenFlashColorMenu(int client)
{
	Menu menu = new Menu(FlashColorMenuHandler);
	
	menu.SetTitle("Choose a flash color");
	
	menu.AddItem("red", "Red");
	menu.AddItem("green", "Green");
	menu.AddItem("blue", "Blue");
	menu.AddItem("pink", "Pink");
	menu.AddItem("orange", "Orange");
	menu.AddItem("teal", "Teal");
	menu.AddItem("purple", "Purple");
	
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int FlashColorMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(choice, info, sizeof(info));
		int color[3] =  { 0, 0, 0 };
		if (StrEqual(info, "red", false))
		{
			color[0] = 255;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "green", false))
		{
			color[1] = 255;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "blue", false))
		{
			color[2] = 255;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "pink", false))
		{
			color[0] = 255;
			color[1] = 100;
			color[2] = 255;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "orange", false))
		{
			color[0] = 255;
			color[1] = 165;
			color[2] = 0;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "teal", false))
		{
			color[0] = 0;
			color[1] = 153;
			color[2] = 255;
			g_iFlashColor[client] = color;
		}
		else if (StrEqual(info, "purple", false))
		{
			color[0] = 128;
			color[1] = 0;
			color[2] = 128;
			g_iFlashColor[client] = color;
		}
		UpdateCookies(client, color);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void UpdateCookies(int client, int color[3])
{
	char cookiecolor[512];
	Format(cookiecolor, sizeof(cookiecolor), "%i|%i|%i", color[0], color[1], color[2]);
	SetClientCookie(client, g_hFlashCookie, cookiecolor);
}

public void OnClientPostAdminCheck(int client)
{
	g_iFlashColor[client][0] = 255;
	g_iFlashColor[client][1] = 255;
	g_iFlashColor[client][2] = 255;
	
	if(g_cColorsEnabled.IntValue > 0)
		CreateTimer(1.0, Timer_CookieCheck, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CookieCheck(Handle Timer, int client)
{
	if (IsClientInGame(client))
	{
		if (AreClientCookiesCached(client))
		{
			char cookiebuffer[512];
			GetClientCookie(client, g_hFlashCookie, cookiebuffer, sizeof(cookiebuffer));
			
			char explode[3][16];
			ExplodeString(cookiebuffer, "|", explode, 3, 16);
			
			if (StrEqual(cookiebuffer, "", false))
			{
				g_iFlashColor[client][0] = 255;
				g_iFlashColor[client][1] = 255;
				g_iFlashColor[client][2] = 255;
			} else
			{
				g_iFlashColor[client][0] = StringToInt(explode[0]);
				g_iFlashColor[client][1] = StringToInt(explode[1]);
				g_iFlashColor[client][2] = StringToInt(explode[2]);
			}
		}
	}
}

int g_iLastBanger = -1;

public void Event_FlashbangDetonated(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cColorsEnabled.IntValue == 0)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iLastBanger = client;
}

public void player_blind(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_cColorsEnabled.IntValue == 0)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	float duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
	
	PerformFade(client, duration, g_iLastBanger);
}

public void PerformFade(int client, float &fduration, int banger)
{
	int color[4];
	
	color[0] = g_iFlashColor[banger][0];
	color[1] = g_iFlashColor[banger][1];
	color[2] = g_iFlashColor[banger][2];
	color[3] = 255;
	
	if (fduration <= 3.0)
	{
		color[3] = RoundToNearest((255.0 / 3.0) * fduration);
	}
	
	fduration -= 3.0;
	fduration *= 1000.0;
	fduration /= 2.0;
	fduration = fduration < 0.0 ? 0.0:fduration;
	
	int holdtime = RoundToNearest(fduration);
	int duration = 1500; // 3sec 
	
	
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
	
	Handle message = StartMessageOne("Fade", client);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(message, "duration", duration);
		PbSetInt(message, "hold_time", holdtime);
		PbSetInt(message, "flags", FFADE_IN | FFADE_PURGE);
		PbSetColor(message, "clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, FFADE_IN | FFADE_PURGE);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
} 