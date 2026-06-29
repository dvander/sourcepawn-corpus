#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

public Plugin:myinfo =
{
    name = "hesmokerds",
    description = "Provides every player on spawn with a Grenade",
    author = "AMAURI BUENO DOS SANTOS",
    version = "2.2",
    url = "https://forums.alliedmods.net/showthread.php?p=2266832"
};

new hasNinja[MAXPLAYERS+1];
new bool:onninja[MAXPLAYERS+1];
new bool:canuse[MAXPLAYERS+1];


public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	RegAdminCmd("admin_he", Command_he, ADMFLAG_KICK, "Kicks a player by name");
	RegConsoleCmd("sm_he", Command_he,  "sm_he <player> ");
	RegConsoleCmd("sm_smoke", Command_smoke,  "sm_smoke <player> ");
	RegConsoleCmd("sm_molotov", Command_molotov,  "sm_molotov <player> ");
	RegConsoleCmd("sm_decoy", Command_decoy,  "sm_decoy <player> ");
	RegConsoleCmd("sm_bang", Command_bang,  "sm_bang <player> ");
}

public OnMapStart()
{
    AddFileToDownloadsTable("sound/admin_plugin/holyshit.wav");
    PrecacheSound("admin_plugin/holyshit.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/groovey.wav");
    PrecacheSound("admin_plugin/groovey.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/yeah.wav");
    PrecacheSound("admin_plugin/yeah.wav", true);
    AddFileToDownloadsTable("sound/admin_plugin/scream.wav");
    PrecacheSound("admin_plugin/scream.wav", true);
    
    for(new i = 1; i <= MaxClients; i++)
    {
    	onninja[i] = false;
    	canuse[i] = true;
    	hasNinja[i] = 3;
    }
    
    AutoExecConfig();
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
        
        if (Client && IsClientInGame(Client))
        {
            CreateTimer(0.5, Timer_GiveWeapons, Client, 0);
        }
}

public Action:Timer_GiveWeapons(Handle:Timer, any:client)
{
    GivePlayerItem(client, "item_assaultsuit", 0);
    for(new i = 1; i <= MaxClients; i++)
    {
            onninja[i] = false;
            canuse[i] = true;
            hasNinja[i] = 3;
    }
}

public Action:Command_he(client, args)
{

	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		PrintToChat(client, "[HERMOSKERDS] %s", "Player Buy !he"); 
		new Float:vec[3];
		hasNinja[client] = hasNinja[client] -1;
		EmitAmbientSound("admin_plugin/yeah.wav", vec, client, SNDLEVEL_RAIDSIREN);
		GivePlayerItem(client, "weapon_hegrenade", 0);
		GetClientAbsOrigin(client, vec);
	}
	else
	{
		PrintHintTextToAll("I HAVE JUST A HE!", client);
	}
	
	return Plugin_Handled;
}

public Action:Command_smoke(client, args)
{

	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		PrintToChat(client, "[HERMOSKERDS] %s", "Player Buy !smoke"); 
		new Float:vec[3];
		hasNinja[client] = hasNinja[client] -1;
		EmitAmbientSound("admin_plugin/groovey.wav", vec, client, SNDLEVEL_RAIDSIREN);
		GivePlayerItem(client, "weapon_smokegrenade", 0);
		GetClientAbsOrigin(client, vec);
	}
	else
	{
		PrintHintTextToAll("I HAVE JUST A SMOKE!", client);
	}
	
	return Plugin_Handled;
}

public Action:Command_molotov(client, args)
{

	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		PrintToChat(client, "[HERMOSKERDS] %s", "Player Buy !molotov");
		new Float:vec[3];
		hasNinja[client] = hasNinja[client] -1;
		EmitAmbientSound("admin_plugin/holyshit.wav", vec, client, SNDLEVEL_RAIDSIREN);
		GivePlayerItem(client, "weapon_molotov", 0);
		GetClientAbsOrigin(client, vec);
	}
	else
	{
		PrintHintTextToAll("I HAVE JUST A MOLOTOV!", client);
	}
	
	return Plugin_Handled;
}

public Action:Command_decoy(client, args)
{

	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		PrintToChat(client, "[HERMOSKERDS] %s", "Player Buy !decoy"); 
		new Float:vec[3];
		hasNinja[client] = hasNinja[client] -1;
		EmitAmbientSound("admin_plugin/scream.wav", vec, client, SNDLEVEL_RAIDSIREN);
		GivePlayerItem(client, "weapon_decoy", 0);
		GetClientAbsOrigin(client, vec);
	}
	else
	{
		PrintHintTextToAll("I HAVE JUST A DECOY!", client);
	}
	
	return Plugin_Handled;
}

public Action:Command_bang(client, args)
{

	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		PrintToChat(client, "[HERMOSKERDS] %s", "Player Buy !bang"); 
		new Float:vec[3];
		hasNinja[client] = hasNinja[client] -1;
		EmitAmbientSound("admin_plugin/scream.wav", vec, client, SNDLEVEL_RAIDSIREN);
		GivePlayerItem(client, "weapon_flashbang", 0);
		GetClientAbsOrigin(client, vec);
	}
	else
	{
		PrintHintTextToAll("I HAVE JUST A FlashBang!", client);
	}
	
	return Plugin_Handled;
}

