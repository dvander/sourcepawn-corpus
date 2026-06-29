#include <sourcemod>
#include <clientprefs>
#define PLUGIN_VERSION "0.1"
#define AUTHOR "Teki"
#define URL "https://forums.alliedmods.net/"

const MAXCLIENTS = 20;
new Handle:pluginEnabled = INVALID_HANDLE;
new Handle:showDamageCookie = INVALID_HANDLE;
new showDamageDisabled[MAXCLIENTS];

public Plugin:myinfo = 
{
	name = "Show Damage Hints",
	author = AUTHOR,
	description = "This plugin will show damages you deal and the health you left to your ennemies in a Hint",
	version = PLUGIN_VERSION,
	url = URL
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	CreateConVar("sm_sdh_version", PLUGIN_VERSION, "Version of Show Damage Hints.", FCVAR_NOTIFY);
	pluginEnabled = CreateConVar("sm_sdh_enable", "1", "(1)Enable or (0)Disable Show Damage Hints. Default: 1", FCVAR_NOTIFY);
	RegConsoleCmd("sdh", ShowDamageCommand);
	showDamageCookie = RegClientCookie("showDamage", "Show Damage Hints (0)On/(1)Off", CookieAccess_Public);
}

public OnClientCookiesCached(client)
{
	new String:cookie[2];
	GetClientCookie(client, showDamageCookie, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
	{
		showDamageDisabled[client] = 1;
	}
	else
	{
		showDamageDisabled[client] = 0;
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new victimId = GetEventInt(event, "userid");
	new dmgHealth = GetEventInt(event, "dmg_health");
	new attacker = GetClientOfUserId(attackerId);
	new victim = GetClientOfUserId(victimId);
	new victimHP = GetClientHealth(victim);
	decl String:victimName[32];
	GetClientName(victim, victimName, sizeof(victimName));
	new String:buffer[32];
	
	if (attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker) && GetConVarInt(pluginEnabled) == 1 && showDamageDisabled[attacker] == 0)
	{
		if (victimHP > 0)
		{
			Format(buffer, sizeof(buffer), "-%d HP\n%s (%d)", dmgHealth, victimName, victimHP);
		}
		else
		{
			Format(buffer, sizeof(buffer), "-%d HP\n%s (Dead)", dmgHealth, victimName);
		}
		PrintHintText(attacker, buffer)
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new user = GetClientOfUserId(userId);
	
	showDamageDisabled[user] = 0;
}

public Action:ShowDamageCommand(client, args)
{
	if (GetConVarInt(pluginEnabled) == 1)
	{
		new String:commandArg[32];
		GetCmdArgString(commandArg, sizeof(commandArg))
		
		if (StrEqual(commandArg, "help"))
		{
			PrintToChat(client, "\x01\x0B\x05[SD]\x01 Type \x05!sdh\x01 to Enable or Disable Show Damage Hints");
		}
		else if (StrEqual(commandArg, ""))
		{
			if (showDamageDisabled[client] == 1)
			{
				showDamageDisabled[client] = 0;
				SetClientCookie(client, showDamageCookie, "0");
				PrintToChat(client, "\x01\x0B\x05[SD]\x01 Show Damage Enabled !");
			}
			else
			{
			showDamageDisabled[client] = 1;
			SetClientCookie(client, showDamageCookie, "1");
			PrintToChat(client, "\x01\x0B\x05[SD]\x01 Show Damage Disabled !");
			}
		}
	}
}