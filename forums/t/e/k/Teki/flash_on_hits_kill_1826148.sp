#include <sourcemod>
#include <clientprefs>
#define PLUGIN_VERSION "0.4"
#define AUTHOR "Teki"
#define URL "https://forums.alliedmods.net/showpost.php?p=1826148&postcount=5"

const MAXCLIENTS = 20;

#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one

new Handle:pluginEnabled = INVALID_HANDLE;
new Handle:pluginAction = INVALID_HANDLE;
new Handle:hitLength = INVALID_HANDLE;
new Handle:killLength = INVALID_HANDLE;
new Handle:hitDensity = INVALID_HANDLE;
new Handle:killDensity = INVALID_HANDLE;
new Handle:hitTransparency = INVALID_HANDLE;
new Handle:killTransparency = INVALID_HANDLE;
new Handle:fohkCookie = INVALID_HANDLE;
new fohkDisabled[MAXCLIENTS];

public Plugin:myinfo = 
{
	name = "Flash On Hits/Kill",
	author = AUTHOR,
	description = "This plugin will flash a bit your screen when you hurt and/or kill an ennemy",
	version = PLUGIN_VERSION,
	url = URL
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	CreateConVar("sm_fohk_version", PLUGIN_VERSION, "Version of Flash On Hits/Kill.", FCVAR_NOTIFY);
	pluginEnabled = CreateConVar("sm_fohk_enable", "1", "(1)Enable or (0)Disable Flash On Hits/Kill. Default: 1", FCVAR_NOTIFY);
	pluginAction = CreateConVar("sm_fohk_action", "1", "Flash on: (O)Only Kills (1)Hits and Kills (2)Only Hits. Default: 1", FCVAR_NOTIFY);
	hitLength = CreateConVar("sm_fohk_hit_length", "100", "Flash Length on Hits in milliseconds. Default: 100", FCVAR_NOTIFY);
	killLength = CreateConVar("sm_fohk_kill_length", "500", "Flash Length on Kills in milliseconds. Default: 500", FCVAR_NOTIFY);
	hitDensity = CreateConVar("sm_fohk_hit_density", "50", "(0-255) Flash Density on Hits. Default: 50", FCVAR_NOTIFY);
	killDensity = CreateConVar("sm_fohk_kill_density", "100", "(0-255) Flash Density on Kills. Default: 100", FCVAR_NOTIFY);
	hitTransparency = CreateConVar("sm_fohk_hit_transparency", "150", "(0-255) Flash Transparency on Hits. Default: 150", FCVAR_NOTIFY);
	killTransparency = CreateConVar("sm_fohk_kill_transparency", "150", "(0-255) Flash Transparency on Kills. Default: 150", FCVAR_NOTIFY);
	RegConsoleCmd("fohk", FohkCommand);
	fohkCookie = RegClientCookie("fohk", "Flash On Hits/Kill (0)On/(1)Off", CookieAccess_Public);
}

public OnClientCookiesCached(client)
{
	new String:cookie[2];
	GetClientCookie(client, fohkCookie, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
	{
		fohkDisabled[client] = 1;
	}
	else
	{
		fohkDisabled[client] = 0;
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);
	
	fohkDisabled[client] = 0;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new victimId = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(attackerId);
	new victim = GetClientOfUserId(victimId);
	new victimTeam = GetClientTeam(victim);
	
	if (attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker) && GetConVarInt(pluginEnabled) == 1 && GetConVarInt(pluginAction) > 0 && fohkDisabled[attacker] == 0)
	{
		Fade(attacker, victimTeam, GetConVarInt(hitLength), GetConVarInt(hitDensity), GetConVarInt(hitTransparency));
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new victimId = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(attackerId);
	new victim = GetClientOfUserId(victimId);
	new victimTeam = GetClientTeam(victim);
	
	if (attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker) && GetConVarInt(pluginEnabled) == 1 && GetConVarInt(pluginAction) < 2 && fohkDisabled[attacker] == 0)
	{
		Fade(attacker, victimTeam, GetConVarInt(killLength), GetConVarInt(killDensity), GetConVarInt(killTransparency));
	}
}

stock Fade(client, victimTeam, length, density, transparency)
{
	new Handle:fadeClient = StartMessageOne("Fade", client);
	if (fadeClient !=INVALID_HANDLE)
	{
		BfWriteShort(fadeClient, length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
		BfWriteShort(fadeClient, 0);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
		BfWriteShort(fadeClient,FFADE_PURGE|FFADE_IN); // fade type (in / out)
		if (victimTeam == 2)
		{
			BfWriteByte(fadeClient, density);	// fade red
			BfWriteByte(fadeClient, 0);	// fade green
			BfWriteByte(fadeClient, 0);	// fade blue
		}
		else if (victimTeam == 3)
		{
			BfWriteByte(fadeClient, 0);	// fade red
			BfWriteByte(fadeClient, 0);	// fade green
			BfWriteByte(fadeClient, density);	// fade blue
		}
		BfWriteByte(fadeClient, transparency);// fade alpha
		EndMessage();
	}
}

public Action:FohkCommand(client, args)
{
	if (GetConVarInt(pluginEnabled) == 1)
	{
		new String:commandArg[32];
		GetCmdArgString(commandArg, sizeof(commandArg))
		
		if (StrEqual(commandArg, "help"))
		{
			PrintToChat(client, "\x01\x0B\x05[FOHK]\x01 Type \x05!fohk\x01 to Enable or Disable Flash On Hits/Kills");
		}
		else if (StrEqual(commandArg, ""))
		{
			if (fohkDisabled[client] == 0)
			{
				fohkDisabled[client] = 1;
				SetClientCookie(client, fohkCookie, "1");
				PrintToChat(client, "\x01\x0B\x05[FOHK]\x01 Flash On Hits/Kills Disabled !");
			}
			else
			{
				fohkDisabled[client] = 0;
				SetClientCookie(client, fohkCookie, "0");
				PrintToChat(client, "\x01\x0B\x05[FOHK]\x01 Flash On Hits/Kills Enabled !");
			}
		}
	}
}