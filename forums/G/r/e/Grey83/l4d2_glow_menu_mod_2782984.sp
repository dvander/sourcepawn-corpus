#pragma semicolon 1

#include <colors>

#pragma newdecls required

#include <sdkhooks>
#include <clientprefs>

static const char
	COLOR_NAME[][] =
{
	"Desactive\n ",
	"Green",
	"Blue",
	"Violet",
	"Cyan",
	"Orange",
	"Red",
	"Gray",
	"Yellow",
	"Lime",
	"Maroon",
	"Teal",
	"Pink",
	"Purple",
	"White",
	"Golden",
	"Rainbow"
};

static const int
	COLOR_VALUE[] = 
{
	0x000000,	//   0
	0x00FF00,	//   0 + (255 * 256) + (  0 * 65536));
	0xFA1307,	//   7 + ( 19 * 256) + (250 * 65536));
	0xFA13F9,	// 249 + ( 19 * 256) + (250 * 65536));
	0xFAFA42,	//  66 + (250 * 256) + (250 * 65536));
	0x549BF9,	// 249 + (155 * 256) + ( 84 * 65536));
	0x0000FF,	// 255 + (  0 * 256) + (  0 * 65536));
	0x323232,	//  50 + ( 50 * 256) + ( 50 * 65536));
	0x00FFFF,	// 255 + (255 * 256) + (  0 * 65536));
	0x00FF80,	// 128 + (255 * 256) + (  0 * 65536));
	0x000080,	// 128 + (  0 * 256) + (  0 * 65536));
	0x808000,	//   0 + (128 * 256) + (128 * 65536));
	0x9600FF,	// 255 + (  0 * 256) + (150 * 65536));
	0xFF009B,	// 155 + (  0 * 256) + (255 * 65536));
	0xFFFFFF,	//  -1 + ( -1 * 256) + ( -1 * 65536));
	0x009BFF,	// 255 + (155 * 256) + (  0 * 65536));
	0x000000
};

Handle
	cookie;
int
	GlowType[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "[L4D2] Glow Survivor",
	author		= "King_OXO(edited, now have cookie)",
	description	= "Aura or glow for the survivors",
	version		= "5.0.0 (rewritten by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?t=332956"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
		return APLRes_Success;

	strcopy(error, err_max, "This plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_team", Event_Player_Death, EventHookMode_Pre);

	RegConsoleCmd("sm_aura", SetAura, "Set your aura.");
	RegConsoleCmd("sm_glow", SetAura, "Set your aura.");

	cookie = RegClientCookie("l4d2_glow", "cookie for aura id", CookieAccess_Private);
}

public void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || IsFakeClient(client))
		return;

	int team = GetClientTeam(client);
	if(team == 3)
		DisableGlow(client);
	else if(team == 2)
		ReadCookies(client);
}

public void Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && !IsFakeClient(client)) DisableGlow(client);
}

stock void DisableGlow(int client)
{
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
}

public void ReadCookies(int client)
{
	if(client < 1 || MaxClients < client || !IsClientInGame(client) || IsFakeClient(client)
	|| !AreClientCookiesCached(client))
		return;

	char str[4];
	GetClientCookie(client, cookie, str, sizeof(str));
	if(str[0]) GetAura(client, StringToInt(str));
}

public Action SetAura(int client, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Handled;

	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{blue}[{orange}GLOW MENU{blue}] {olive}You must be {blue}alive {default}to use this {green}command {default}!");
		return Plugin_Handled;
	}

	Menu menu = new Menu(VIPAuraMenuHandler);
	menu.SetTitle("|★| GLOW MENU |★|\n▼▼▼▼▼▼▼▼▼▼\n ");
	for(int i; i < sizeof(COLOR_NAME); i++)
		menu.AddItem("", COLOR_NAME[i], GlowType[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int VIPAuraMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(client))
			{
				CPrintToChat(client, "[SM] You must be alive to set your aura.");
				return 0;
			}

			GetAura(client, param);
			SetCookie(client, cookie, param);
		}
	}

	return 0;
}


public void SetCookie(int client, Handle hCookie, int n)
{
	char strCookie[4];
	IntToString(n, strCookie, 4);
	SetClientCookie(client, hCookie, strCookie);
}

stock void GetAura(int client, int id)
{
	GlowType[client] = id;

	if(id == 16)
	{
		SDKHook(client, SDKHook_PreThink, RainbowPlayer);
		CPrintToChat(client, "\x05You \x01Changed \x03Color\x01: \x04%s \x01!", COLOR_NAME[id]);
	}
	else if(!id)
	{
		DisableGlow(client);
		CPrintToChat(client, "\x04Glow Disabled");
	}
	else
	{
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		EnableGlow(client, COLOR_VALUE[id]);
		CPrintToChat(client, "\x05You \x01Changed \x03Color\x01: \x04%s \x01!", COLOR_NAME[id]);
	}
}

public Action RainbowPlayer(int client)
{
	if(!IsPlayerAlive(client))
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	else
	{
		int color[3];
		float time = client + 3 * GetGameTime();
		color[0] = RoundToNearest(Cosine(time + 1) * 127.5 + 127.5);
		color[1] = RoundToNearest(Cosine(time + 3) * 127.5 + 127.5);
		color[2] = RoundToNearest(Cosine(time + 5) * 127.5 + 127.5);

		EnableGlow(client, color[0] + color[1] << 8 + color[2] << 16);
	}
}

stock void EnableGlow(int client, int color)
{
	SetEntProp(client, Prop_Send, "m_glowColorOverride", color);
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
	SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
}