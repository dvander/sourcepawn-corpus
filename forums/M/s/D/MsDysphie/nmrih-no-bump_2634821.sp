#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#pragma semicolon 1
#pragma newdecls required

#define NOBUMP_VERSION "1.0.1"
#define SET_RADIUS_DECREASE 0
#define SET_RADIUS_INCREASE 1
#define SET_RADIUS_DISABLE  2
#define SET_RADIUS_INFINITE 3 
#define BUBBLE_MAX_RADIUS 184
#define BUBBLE_MIN_RADIUS 32

bool g_bLateLoaded;
bool g_bEnabled;

ConVar g_cvEnabled;
ConVar g_cvDefaultRadius;

Handle g_hRadiusCookie;

int g_iRadius[MAXPLAYERS+1];
int g_iDefaultRadius;

public Plugin myinfo =
{
	name = "[NMRiH] NoBump",
	author = "Dysphie",
	description = "Prevents players from bumping into each other",
    version = NOBUMP_VERSION,
    url = ""
};

public void OnPluginStart()
{

	bool g_bClPrefsLoaded = (GetExtensionFileStatus("clientprefs.ext") == 1 && SQL_CheckConfig("clientprefs")); 
	if(g_bClPrefsLoaded) 
	{ 
		SetCookieMenuItem(CookieMenuHandler, 0, "NoBump Preferences"); 
		g_hRadiusCookie = RegClientCookie("comfort_radius",
									      "Size of your safe radius. Players within this radius won't collide with you",
									      CookieAccess_Public);
	} 

	g_cvEnabled = CreateConVar("sm_nobump_enable", "1","Sets whether NoBlock is enabled");
	g_cvDefaultRadius = CreateConVar("sm_nobump_default_comfort_radius", "64",
									 "Comfort radius to use by default. Players within this radius won't be rendered by the client and thus, not collide");
	g_bEnabled = GetConVarBool(g_cvEnabled); 

	HookConVarChange(g_cvEnabled, Action_OnSettingsChange);
	HookConVarChange(g_cvDefaultRadius, Action_OnSettingsChange);	

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);

	RegConsoleCmd("sm_nobump", PreferencesPanel);

	/* Late load handling */ 
	if(g_bLateLoaded)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPostAdminCheck(i);				
} 

public void CookieMenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
        PreferencesPanel(client, 0);
    }
}

public void Action_OnSettingsChange(Handle cvar, const char[] oldvalue, const char[] newvalue)
{
	if(cvar == g_cvEnabled)
		g_bEnabled = view_as<bool>(StringToInt(newvalue));

	if(cvar == g_cvDefaultRadius)
		g_iDefaultRadius = StringToInt(newvalue);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   g_bLateLoaded = late; 
   return APLRes_Success;
}

public void OnClientPostAdminCheck(int client)
{
	g_iRadius[client] = GetClientSafeRadius(client);

	// Players can obstruct movement before clicking "Join Game"
	SDKHook(client, SDKHook_SetTransmit, OnSetTransmit);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Unhook in case we come from OnClientPostAdminCheck
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit);
	SDKHook(client, SDKHook_SetTransmit, OnSetTransmit);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit);
}

public Action OnSetTransmit(int self, int other)
{
	if(g_bEnabled)
	{
		// Don't transmit ourselves to alive players whose safe radius we are invading
		if(other > 0 && other <= MaxClients && other != self)
		{	
			if(IsPlayerAlive(other) && (g_iRadius[other] == -1 || (GetDistanceBetweenPlayers(self, other) <= g_iRadius[other])))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock float GetDistanceBetweenPlayers(int a, int b)
{
	float aPos[3]; float bPos[3];
	GetClientAbsOrigin(a, aPos);
	GetClientAbsOrigin(b, bPos);
	return GetVectorDistance(aPos, bPos);
}

int GetClientSafeRadius(int client)
{
	if (AreClientCookiesCached(client))
	{
		char sClientRadius[12];
		GetClientCookie(client, g_hRadiusCookie, sClientRadius, sizeof(sClientRadius));

		if(!StrEqual(sClientRadius, ""))
		{
			int iClientRadius = StringToInt(sClientRadius);
			return iClientRadius;			
		}
	}

	// If we found no preferences, return default value
	return g_iDefaultRadius;
}

public Action PreferencesPanel(int client, int args)
{
	Menu menu = new Menu(PreferencesPanelHandler);

	char sRadiusPreview[32] = "Comfort radius: ";
	switch(g_iRadius[client])
	{
		case 0:
		{
			StrCat(sRadiusPreview, sizeof(sRadiusPreview), "Disabled");
		}
		case -1:
		{
			StrCat(sRadiusPreview, sizeof(sRadiusPreview), "Infinite");
		}
		default:
		{
			char buffer[12];
			IntToString(g_iRadius[client], buffer, sizeof(buffer));
			Format(sRadiusPreview, sizeof(sRadiusPreview), "%s%s units", sRadiusPreview, buffer);
		}
	}

	menu.SetTitle(sRadiusPreview);
	menu.AddItem(NULL_STRING, "[-] Decrease", (g_iRadius[client] == 0 || g_iRadius[client] == BUBBLE_MIN_RADIUS)
											   ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT); 

	menu.AddItem(NULL_STRING, "[+] Increase", (g_iRadius[client] == -1 || g_iRadius[client] == BUBBLE_MAX_RADIUS)
											   ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT); 

	menu.AddItem(NULL_STRING, "Always draw teammates", (g_iRadius[client] == 0)
											   ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	menu.AddItem(NULL_STRING, "Never draw teammates", (g_iRadius[client] == -1)
											   ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	// TODO: Show preview beacon

	return Plugin_Handled;
}

public int PreferencesPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	// param1 - client, param2 - menu item index

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case SET_RADIUS_DECREASE:
			{
				if(g_iRadius[param1] == -1)
				{
					g_iRadius[param1] = BUBBLE_MAX_RADIUS;
				}
				else
				{
					g_iRadius[param1] -= 8;
				}
			}
			case SET_RADIUS_INCREASE:
			{
				if(g_iRadius[param1] == 0)
				{
					g_iRadius[param1] = BUBBLE_MIN_RADIUS;
				}
				else
				{
					g_iRadius[param1] += 8;
				}
			}
			case SET_RADIUS_DISABLE:
			{
				g_iRadius[param1] = 0;
			}
			case SET_RADIUS_INFINITE:
			{
				g_iRadius[param1] = -1;
			}
		}

		// Refresh panel
		PreferencesPanel(param1, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		// Update client's cookie on exit
		char sNewValue[12];
		IntToString(g_iRadius[param1], sNewValue, sizeof(sNewValue));
		SetClientCookie(param1, g_hRadiusCookie, sNewValue);

		// TODO: Stop preview beacon
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}