#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <adminmenu>

#define PLUGIN_VERSION "1.4.4t2"

new Handle:sm_l8d_difficulty = INVALID_HANDLE;
new Handle:sm_l8d_doubleitems = INVALID_HANDLE;
new Handle:sm_l8d_nobots = INVALID_HANDLE;
new disallowBot=0;

new bool:bL8DEnabled;

// Finale asthetics
new bool:bIncappedOrDead[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Left8Dead",
	author = "Mad_Dugan",
	description = "Allows 8 players to play as survivor",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=89422"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if(!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	CreateConVar("sm_l8d_version", PLUGIN_VERSION, "Version of L8D plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_l8d_difficulty = CreateConVar("sm_l8d_difficulty", "Hard", "L8D Difficulty Level", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_l8d_doubleitems = CreateConVar("sm_l8d_doubleitems", "1", "L8D Double Item Count", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_l8d_nobots = CreateConVar("sm_l8d_nobots", "0", "L8D only spawns bots for human replacement", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_l8d_enable", L8DEnable, ADMFLAG_KICK, "Enable L8D");
	RegAdminCmd("sm_l8d_disable", L8DDisable, ADMFLAG_KICK, "Disable L8D");
	RegAdminCmd("sm_l8d_changemap", L8DMapMenu, ADMFLAG_KICK, "Select co-op map for L8D.");
	RegAdminCmd("sm_l8d_hardzombies", L8DHardZombies, ADMFLAG_KICK, "Increase Zombie amount (-1 off, 1 on)");
	RegConsoleCmd("sm_addbot", CreateOneBot, "Create one bot to take over");
	RegConsoleCmd("sm_joingame",AddPlayer, "Attempt to join Survivors");
	RegConsoleCmd("sm_away",GoAFK,"Let a player go AFK");
	
	HookEvent("player_afk",HandleAFK);
	HookEvent("player_bot_replace",HandleReplace);

	bL8DEnabled = false;

	AutoExecConfig(true, "l8d");
}

public HandleAFK(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bL8DEnabled) disallowBot=0;
}

public HandleReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bL8DEnabled&&disallowBot==1) {KickClient(GetClientOfUserId(GetEventInt(event,"bot")),"Fake Player"); disallowBot=0;}
}

Survivors()
{
	new survivors;
	for(new i=1; i <= MaxClients; i++) if(IsClientInGame(i)&&GetClientTeam(i) == 2) survivors++;
	return survivors;
}

AliveBots()
{
	new survivors;
	for(new i=1; i <= MaxClients; i++) if(IsClientInGame(i)&&GetClientTeam(i) == 2&&IsPlayerAlive(i)) survivors++;
	return survivors;
}

public Action:OnClientCommand(client, args)
{
    new String:cmd[16];
    GetCmdArg(0, cmd, sizeof(cmd));
    if (bL8DEnabled&&StrEqual(cmd, "spectate")){FakeClientCommand(client,"go_away_from_keyboard");return Plugin_Handled;}
    return Plugin_Continue;
}

public bool:OnClientConnect(client)
{
	if(!IsFakeClient(client)) //if it's a real player connecting.
	{
		SetConVarInt(FindConVar("director_no_human_zombies"), 0); // Make it a versus
		CreateTimer(0.1, ResetCoOp); // reset to co-op in 0.1 seconds!
	}
	return true; // permit the client to connect
} // Using this, it allows a player to connect the "co-op" server, because it is "versus" at time of connection.

public Action:ResetCoOp(Handle:timer) // this delay is necassary or it fails.
{
	SetConVarInt(FindConVar("director_no_human_zombies"), 1);
}

public Action:L8DHardZombies(client, args) 
{
	if(!bL8DEnabled) return Plugin_Handled;
	new String:arg[8];
	GetCmdArg(1,arg,8);
	new Input=StringToInt(arg[0]);
	if(Input==1)
	{
		SetConVarInt(FindConVar("z_common_limit"), 30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10); // Default
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20); // Default
		SetConVarInt(FindConVar("z_mega_mob_size"), 45); // Default
	}		
	else if(Input>1&&Input<7)
	{
		SetConVarInt(FindConVar("z_common_limit"), 30*Input); // Default 30
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 30*Input); // Default 10
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30*Input); // Default 30
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 30*Input); // Default 20
		SetConVarInt(FindConVar("z_mega_mob_size"), 30*Input); // Default 45
	}
	else {ReplyToCommand(client, "\x01[SM] Usage: How many zombies you want. (In multiples of 30. Recommended: 3 Max: 6)");ReplyToCommand(client, "\x01          : Anything above 3 may cause moments of lag 1 resets the defaults");}
	return Plugin_Handled;
}

public Action:AddPlayer(client, args)
{ // If the player is still connected and in-game, put the client into the bot!
	if(bL8DEnabled&&IsClientInGame(client)&&AliveBots()>0) FakeClientCommand(client, "jointeam 2");
	if(bL8DEnabled&&AliveBots()<1) ReplyToCommand(client, "\x01[SM] A bot must be rescued before you can spawn!");
	return Plugin_Handled;
}

public Action:GoAFK(client, args)
{ // If the player is still connected and in-game, put the client into the bot!
	if(bL8DEnabled&&IsClientInGame(client)) FakeClientCommand(client, "go_away_from_keyboard");
}

public OnEventShutdown()
{
	UnhookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	UnhookEvent("revive_success", Event_ReviveSuccess);
	UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);
	UnhookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	if(bL8DEnabled)
	{
		PrintToChatAll("\x01[SM] Left8Dead %s loaded\x03", PLUGIN_VERSION);
		
		new String:MapName[80];
		GetCurrentMap(MapName, sizeof(MapName));

		new String:szDifficulty[64];	
		GetConVarString(sm_l8d_difficulty, szDifficulty, 64);
		
		if (StrContains(MapName, "_vs_", false) != -1)
		{
			SetConVarInt(FindConVar("z_difficulty_locked"), 0, true);
			SetConVarString(FindConVar("z_difficulty"), szDifficulty, true);
		}
		else
		{
			// only do this for first map
			if (StrContains(MapName, "01_", false) != -1)
			{
				CreateTimer(20.0, CreateBotsTimer);
			}
			
			// Manually change difficulty mode since locked by versus lobby
			SetConVarInt(FindConVar("z_difficulty_locked"), 0, true);
			SetConVarString(FindConVar("z_difficulty"), szDifficulty, true);
			
			UpdateCounts();
			
			for(new i=1; i <= MaxClients; i++)
			{
				bIncappedOrDead[i] = false;
			}			
		}
	}
}

UpdateCounts()
{
	new bool:bDoubleItemCounts = (GetConVarInt(sm_l8d_doubleitems) == 1);

	if(bDoubleItemCounts)
	{
		PrintToChatAll("\x01[SM] Left8Dead doubling start items\x03");
		
		// update fixed item spawn counts to handle 8 players
		// These only update item spawns found in starting area/saferooms
		UpdateEntCount("weapon_pumpshotgun_spawn", "9"); // defaults 4/5
		UpdateEntCount("weapon_smg_spawn", "9"); // defaults 4/5
		UpdateEntCount("weapon_rifle_spawn", "9"); // defaults 4/5
		UpdateEntCount("weapon_hunting_rifle_spawn", "9"); // default 4/5
		UpdateEntCount("weapon_autoshotgun_spawn", "9"); // default 4/5
		UpdateEntCount("weapon_first_aid_kit_spawn", "2"); // default 1
		
		// pistol spawns come in two flavors stacks of 5, or multiple singles props
		UpdateEntCount("weapon_pistol_spawn", "8"); // defaults 1/4/5
		
		SetConVarInt(FindConVar("director_pain_pill_density"), 12);  // default 6
	}
	else
	{
		ResetConVar(FindConVar("director_pain_pill_density"));
	}
}

public UpdateEntCount(const String:entname[], const String:count[])
{
	new edict_index = FindEntityByClassname(-1, entname);
	
	while(edict_index != -1)
	{
		DispatchKeyValue(edict_index, "count", count);
		edict_index = FindEntityByClassname(edict_index, entname);
	}
}

public Action:L8DEnable(client, args) 
{
	new String:MapName[80];
	GetCurrentMap(MapName, sizeof(MapName));
	
	if(client == 0)
	{
		ReplyToCommand(client, "\x01[SM] Usage: type '!l8d_enable' in chat\x03");
		return;
	}
	
	bL8DEnabled = true;
	
	UnsetCheatVar(FindConVar("director_no_human_zombies"));
	UnsetCheatVar(FindConVar("sb_all_bot_team"));
	
	SetConVarInt(FindConVar("sv_alltalk"), 1); // so you can tell the infected what is happening
	SetConVarInt(FindConVar("vs_max_team_switches"), 9999);
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
	SetConVarInt(FindConVar("director_no_human_zombies"), 1); // switches to co-op mode
	SetConVarInt(FindConVar("sb_stop"), 1);
	
	SetConVarInt(FindConVar("z_exploding_limit"), 2);
	SetConVarInt(FindConVar("z_gas_limit"), 2);
	
	// Finale asthetics handling
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);

	PrintToChatAll("\x01[SM] Left8Dead %s is now enabled.\x03", PLUGIN_VERSION);
	
	L8DMapMenu(client, args);
	return;
}

public Action:L8DDisable(client, args) 
{
	if(bL8DEnabled)
	{
		bL8DEnabled = false;
	
		UnhookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
		UnhookEvent("revive_success", Event_ReviveSuccess);
		UnhookEvent("survivor_rescued", Event_SurvivorRescued);
		UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);
		UnhookEvent("player_death", Event_PlayerDeath);
		
		ResetConVar(FindConVar("sv_alltalk"));
		ResetConVar(FindConVar("vs_max_team_switches"));
		ResetConVar(FindConVar("director_pain_pill_density"));
		
		ResetConVar(FindConVar("director_no_human_zombies"));
		ResetConVar(FindConVar("sb_all_bot_team"));
		
		SetCheatVar(FindConVar("director_no_human_zombies"));
		SetCheatVar(FindConVar("sb_all_bot_team"));
	}
	return Plugin_Handled;
}

public Action:L8DMapMenu(client, args) 
{
	if(bL8DEnabled)
	{
		new Handle:menu = CreateMenu(L8DMapMenuHandler);
	
		SetMenuTitle(menu, "L8D co-op map choice");
		AddMenuItem(menu, "option1", "No Mercy");
		AddMenuItem(menu, "option2", "Dead Air");
		AddMenuItem(menu, "option3", "Death Toll");
		AddMenuItem(menu, "option4", "Blood Harvest");
		AddMenuItem(menu, "option5", "Random");
		AddMenuItem(menu, "option6", "Allow Vote");
		SetMenuExitButton(menu, true);
	
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
	
	return Plugin_Handled;
}

public Action:L8DMapMenuVote(client, args)
{
	new Handle:menu = CreateMenu(L8DMapMenuVoteHandler);
	
	SetMenuTitle(menu, "L8D co-op map choice");
	AddMenuItem(menu, "option1", "No Mercy");
	AddMenuItem(menu, "option2", "Dead Air");
	AddMenuItem(menu, "option3", "Death Toll");
	AddMenuItem(menu, "option4", "Blood Harvest");
	AddMenuItem(menu, "option5", "Random");
	SetMenuExitButton(menu, false);
	
	VoteMenuToAll(menu, 20);
	
	return Plugin_Handled;
}

public L8DMapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        switch (itemNum)
        {
            case 0: //No Mercy
            {
				ServerCommand("changelevel l4d_hospital01_apartment");
            }
            case 1: //Dead Air
            {
				ServerCommand("changelevel l4d_airport01_greenhouse");
            }
            case 2: //Death Toll
            {
				ServerCommand("changelevel l4d_smalltown01_caves");
            }
			case 3: //Blood Harvest
            {
				ServerCommand("changelevel l4d_farm01_hilltop");
            }
			case 4: // Random
			{
				// pick random and call this function again
				new rnditemNum = GetRandomInt(0, 3);
				L8DMapMenuHandler(menu, MenuAction_Select, client, rnditemNum);
			}			
			case 5: // Vote
			{
				L8DMapMenuVote(client, 0);
			}
        }
    }
}

public L8DMapMenuVoteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd) 
	{
		L8DMapMenuHandler(menu, MenuAction_Select, 0, param1);
	}
}

public Action:CreateBotsTimer(Handle:timer)
{
	disallowBot=-1;
	new nSpecs = 0;
	
	new bool:bnoBots = (GetConVarInt(sm_l8d_nobots) == 1);
	
	if(bnoBots)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientInGame(i))
			{
				if(GetClientTeam(i) == 1)
				{
					nSpecs++;
				}
			}		
		}	
	}
	else
	{
		// Some people want to play with 7 bots.
		nSpecs = 4;
	}
	
	for(new i=0;i<nSpecs;i++)
	{
		l8dbot();
	}
	
	CreateTimer(20.0, SwitchSpectators);
	
	PrintToChatAll("\x01[SM] Spectators will automatically be moved to the survivor team\x03");
}

public Action:CreateOneBot(client, args)
{
	if(Survivors()<8&&bL8DEnabled) l8dbot();
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if(bL8DEnabled&&!IsFakeClient(client)&&Survivors()>4) disallowBot=1;
}

public Action:SwitchSpectators(Handle:timer)
{
	// switch the spectators
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == 1)
			{
				FakeClientCommand(i, "jointeam 2");
			}
		}		
	}
	disallowBot=1;
	SetConVarInt(FindConVar("sb_stop"), 0);
}

UnsetCheatVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_CHEAT;
	SetConVarFlags(hndl, flags);
}

SetCheatVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags |= FCVAR_CHEAT;
	SetConVarFlags(hndl, flags);
}

// lifted from l4dhax and modified
public Action:l8dbot()
{
	if(bL8DEnabled)
	{
		disallowBot=0;
		new bot = CreateFakeClient("I am not real.");
		
		if(bot != 0)
		{
			ChangeClientTeam(bot, 2);
			if(DispatchKeyValue(bot, "classname", "SurvivorBot") == false)
			{
				PrintToChatAll("\x01[SM] Failed to set bot's classname\x03");
			}
			
			if(DispatchSpawn(bot) == false)
			{
				PrintToChatAll("\x01[SM] Failed to spawn bot\x03");
			}
			
			SetEntityRenderColor(bot, 128, 0, 0, 255);
			
			CreateTimer(0.1, kickbot, bot); // reduced timer
		}
		else
		{
			PrintToChatAll("\x01[SM] Fake client failed to be created\x03");
		}
	}
}

public Action:kickbot(Handle:timer, any:value)
{
	KickClient(value,"fake player");
	disallowBot=0;
	return Plugin_Stop;
}

/* Finale asthetics handling */
public Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	// if not incapped, teleport to 'pos'
	// It should be fine to teleport the primaries again
	
	// TODO: use class data to determine if player has survived.
	//bool CTerrorPlayer::IsImmobilized()
	//bool CTerrorPlayer::IsIncapacitated()
	
	new edict_index = FindEntityByClassname(-1, "info_survivor_position");
	
	if (edict_index != -1&&bL8DEnabled)
	{
		new Float:pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientInGame(i))
			{
				if((GetClientTeam(i) == 2) && (bIncappedOrDead[i] == false))
				{
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
				}
			}				
		}	
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	
	bIncappedOrDead[client] = false;
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	bIncappedOrDead[client] = false;
}

public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	bIncappedOrDead[client] = true;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	bIncappedOrDead[client] = true;
}