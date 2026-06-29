/********************************
	INCLUDES AND DEFINITIONS
********************************/
#include <sourcemod>
#include <tf2_stocks>

new Handle:g_cvarPluginEnable = INVALID_HANDLE;
new Handle:g_cvarAdminOnly = INVALID_HANDLE;

new bool:IsClientAdmin[MAXPLAYERS +1] = false;
new bool:AdminOnly = false;

new ammoOffset;

/********************************
	PLUGIN INFO
********************************/
public Plugin:myinfo=
{
	name = "[TF2] Unlimited Ammo",
	author = "John B.",
	description = "Plugin regenerates ammo for everyone",
	version = "2.0.0.",
	url = "http://www.the-gcp.com",
}

/********************************
	PLUGIN START
********************************/
public OnPluginStart()
{
	g_cvarPluginEnable = CreateConVar("sm_unlimitedammo_enable", "1", "0 Disabled || 1 Enabled");
	g_cvarAdminOnly = CreateConVar("sm_unlimitedammo_adminonly", "0", "0 All players || 1 Admin Only");

	StartPlugin();
	CheckAdminOnly();
	
	AutoExecConfig(true, "unlimited_ammo");
}

/********************************
	CLIENT CONNECT
********************************/
public OnClientPostAdminCheck(client)
{
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		IsClientAdmin[client] = true;
	}
}

/********************************
	CLIENT DISCONNECT
********************************/
public OnClientDisconnect(client)
{
	if(IsClientAdmin[client])
	{
		IsClientAdmin[client] = false;
	}
}

/********************************
	TIMED ACTION
********************************/
public Action:Timer_RefillAmmo(Handle:timer)
{
	if(!AdminOnly)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{	
				RefillAmmo(i);
			}
		}
	}
	else if(AdminOnly)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientAdmin[i] && IsPlayerAlive(i))
			{	
				RefillAmmo(i);
			}
		}
	}
	
	return Plugin_Continue;
}

/********************************
	STOCKS
********************************/
stock StartPlugin()
{
	if(GetConVarInt(g_cvarPluginEnable) == 1)
	{
		CheckGameType();
		ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		CreateTimer(1.0, Timer_RefillAmmo, _, TIMER_REPEAT);
	}
}

stock CheckGameType()
{
	new String:sGameType[16];
	GetGameFolderName(sGameType, sizeof(sGameType));
	new bool:IsTeamFortress = StrEqual(sGameType, "tf", true);
	
	if(!IsTeamFortress)
	{
		SetFailState("This plugin is Team Fortress 2 only.");
	}
}

stock CheckAdminOnly()
{
	if(GetConVarInt(g_cvarAdminOnly) == 1)
	{
		AdminOnly = true;
	}
}

stock RefillAmmo(i)
{
	if(ammoOffset != -1)
	{
		SetEntData(i, ammoOffset +4, 50);
		SetEntData(i, ammoOffset +8, 50);
	}
}