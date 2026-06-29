#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Kill Message Overlays",
	author = "Black Haze",
	description = "Kill message overlays for CSS",
	version = "Beta",
	url = "www.beernweed.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	UnlockConsoleCommandAndConvar("r_screenoverlay");
	PrepareOverlays();
}

//UnlockConsoleCommandAndConvar by AtomicStryker, http://forums.alliedmods.net/showpost.php?p=1318884&postcount=7
UnlockConsoleCommandAndConvar(const String:command[])
{
    new flags = GetCommandFlags(command);
    if (flags != INVALID_FCVAR_FLAGS)
    {
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    }
    
    new Handle:cvar = FindConVar(command);
    if (cvar != INVALID_HANDLE)
    {
        flags = GetConVarFlags(cvar);
        SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
    }
}  

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	new String:weapon[32];
	GetEventString(event, "weapon",weapon, sizeof(weapon));
	
	ClearScreen(attacker);
	ShowKillMessage(attacker);	
}

public ShowKillMessage(client)
{
	//debug code////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	decl String: client_name[192];
	GetClientName(client, client_name, sizeof(client_name));
	PrintToChatAll("ShowKillMessage: %s", client_name);
	//end debug code
	ClientCommand(client, "r_screenoverlay \"overlays/kill/kill_1.vtf\"");
}

public ClearScreen(client)
{
	ClientCommand(client, "r_screenoverlay \"\"");
}

public PrepareOverlays()
{
	new String:overlays_file[64];
	Format(overlays_file,sizeof(overlays_file),"overlays/kill/kill_1.vtf");
	PrecacheDecal(overlays_file,true);
	AddFileToDownloadsTable("materials/overlays/kill/kill_1.vtf");
	Format(overlays_file,sizeof(overlays_file),"overlays/kill/kill_1.vmt");
	PrecacheDecal(overlays_file,true);
	AddFileToDownloadsTable("materials/overlays/kill/kill_1.vmt");
}
