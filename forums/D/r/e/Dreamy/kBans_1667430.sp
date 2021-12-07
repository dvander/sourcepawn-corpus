#pragma semicolon 1
#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <sourcebans>

#define PLUGIN_VERSION			"1.4"
#define PLUGIN_DESCRIPTION		"Bans a player if he does [n] amount of kills in [n] seconds"

new bool:k_SBans;
new kCount[MAXPLAYERS+1];
new kFirstKill[MAXPLAYERS+1];

new	Handle:kvar_Kills = INVALID_HANDLE,
	Handle:kvar_Time = INVALID_HANDLE,
	Handle:kvar_Ban = INVALID_HANDLE,
	Handle:kvar_Text = INVALID_HANDLE,
	Handle:kvar_Bots = INVALID_HANDLE;

public Plugin:myinfo =
{
    name 		=	"kBans",
    author		=	"Dreamy",
    description	=	PLUGIN_DESCRIPTION,
    version		=	PLUGIN_VERSION,
    url			=	"http://SourceMod.net"
};

public OnPluginStart()
{
	CreateConVar("kBans_version", PLUGIN_VERSION, "kBans Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	kvar_Kills = CreateConVar("kBans_kills", "12", "Amount of kills players are not allowed to do in [n] seconds", FCVAR_PLUGIN, true, 1.0);
	kvar_Time = CreateConVar("kBans_interval", "40", "In which interval players are not allowed to do [n] kills", FCVAR_PLUGIN, true, 0.0);
	kvar_Ban = CreateConVar("kBans_bantime", "0", "0 = Permban, >0 = Time in minutes", FCVAR_PLUGIN, true, 0.0);
	kvar_Text = CreateConVar("kBans_reason", "[kBans]: Suspicion of Cheating", "If you are/are not using sourcebans = Log Reason in your database/ Kick Message showed to player", FCVAR_PLUGIN);
	kvar_Bots = CreateConVar("kBans_bots", "0", "1/0 = Bots are treated/not treated as human players", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AutoExecConfig();
	
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!client || (client == victim) || StrEqual(weapon, "hegrenade") || IsFakeClient(client))
		return;
	
	if (!GetConVarBool(kvar_Bots) && IsFakeClient(victim))
		return;
	
	new time = GetTime();
	
	if ((kFirstKill[client]+GetConVarInt(kvar_Time)) >= time)
	{
		if (++kCount[client] == GetConVarInt(kvar_Kills))
		{		
			decl String:auth[32];
			GetClientAuthString(client, auth, sizeof(auth));

			decl String:reason[128];
			GetConVarString(kvar_Text, reason, sizeof(reason));
			
			if (k_SBans)
				SBBanPlayer(0, client, GetConVarInt(kvar_Ban), reason);
			else
			{
				LogMessage("The player %N (%s) was banned for suspicion of cheating.", client, auth);
				BanClient(client, GetConVarInt(kvar_Ban), BANFLAG_AUTHID, "kBans", reason, "kBan", client);
			}
		}
	}
	else
	{
		kCount[client] = 1;
		kFirstKill[client] = time;
	}
}

public OnLibraryAdded(const String:name[])
	if (StrEqual(name, "sourcebans"))
		k_SBans = true;

public OnAllPluginsLoaded()
	if (LibraryExists("sourcebans"))
		k_SBans = true;
	
public OnLibraryRemoved(const String:name[])
	if (StrEqual(name, "sourcebans"))
		k_SBans = false;
	
public OnClientDisconnect(client)
{
	kCount[client] = 0;
	kFirstKill[client] = 0;
}