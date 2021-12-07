#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "Ravid"
#define PLUGIN_VERSION "1.0"
#define PREFIX " \x04[TeleportGun]\x01"

ConVar g_cvEnabled;
ConVar g_cvWeapon;

bool g_bTeleportGun[MAXPLAYERS + 1] =  { false, ... };
char g_szWeapon[128];

public Plugin myinfo = 
{
	name = "[CS:GO] Teleport Gun", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/Over_Wolf", 
}

public void OnPluginStart()
{
	EngineVersion iEngineVersion = GetEngineVersion();
	if (iEngineVersion != Engine_CSGO && iEngineVersion != Engine_CSS)
	{
		SetFailState("This plugin is designed only for CS:GO and CS:S.");
	}
	
	g_cvEnabled = CreateConVar("sm_teleportgun_enabled", "1", "Is plugin enabled to work", _, true, 0.0, true, 1.0);
	g_cvWeapon = CreateConVar("sm_teleportgun_weapon", "ak47", "The gun that telports (no need for weapon_)");
	HookConVarChange(g_cvWeapon, Hook_ChangeConVarValue);
	HookEvent("bullet_impact", Event_BulletImpact);
}

public void OnMapStart()
{
	g_cvWeapon.GetString(g_szWeapon, sizeof(g_szWeapon));
}

public void Hook_ChangeConVarValue(ConVar convar, char[] oldValue, char[] newValue)
{
	strcopy(g_szWeapon, sizeof(g_szWeapon), newValue);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (buttons != 0 && buttons != GetEntProp(client, Prop_Data, "m_nOldButtons"))
	{
		char szWeapon[64];
		GetClientWeapon(client, szWeapon, sizeof(szWeapon));
		if ((buttons & IN_ATTACK2) && StrContains(szWeapon, g_szWeapon) != -1 && g_cvEnabled.BoolValue)
		{
			g_bTeleportGun[client] = !g_bTeleportGun[client];
			PrintToChat(client, "%s Teleport gun is %s\x01.", PREFIX, g_bTeleportGun[client] ? "\x04Enabled":"\x02Disabled");
		}
	}
}

public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	float fVectors[3];
	fVectors[0] = event.GetFloat("x");
	fVectors[1] = event.GetFloat("y") - 50.0;
	fVectors[2] = event.GetFloat("z") - 50.0;
	
	char szWeapon[64];
	GetClientWeapon(client, szWeapon, sizeof(szWeapon));
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_bTeleportGun[client] && StrContains(szWeapon, g_szWeapon) != -1 && g_cvEnabled.BoolValue)
	{
		float fAngles[3], fVelocity[3];
		GetClientEyeAngles(client, fAngles)
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		TeleportEntity(client, fVectors, fAngles, fVelocity);
	}
} 