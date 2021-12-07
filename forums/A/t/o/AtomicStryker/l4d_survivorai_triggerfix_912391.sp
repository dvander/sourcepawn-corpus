#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_NAME "L4D Survivor AI Trigger Fix"

new bool:MapTrigger;
new TriggeringBot;

new PlayerReachedSafeRoom[MAXPLAYERS+1];
new bool:ReachedSafeRoom;

new bool:FinaleHasStarted;
new bool:RoundHasEnded;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker",
	description = " Fixes Survivor Bots not advancing at Crescendos or closing Saferooms ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=912391"
};

/*

Big cheers to mi123645 for his assistance

Find the entity of an Crescendo that needs activating using sm_findentity and the class given.


How to trigger Crescendos:

Buttons: (class func_button, name NM4: elevator_button) - this applies for elevator buttons, the BH3 Train release, the DA3 Dumpster Lever...
AcceptEntityInput(func_button_entity, "Press");
Use MagTrigger bool to make sure you do this ONCE only. This ignores buttons being already pressed, so screws up majorly if done twice.

DA3 Gas Cans: (class prop_physics, name barricade_gas_can)
AcceptEntityInput(barricade_gas_can_entity, "Ignite");

Found many Doors and Finales workarounds, ent_fire commands, with mi123645s help

*/

public OnPluginStart()
{
	CreateConVar("l4d_survivoraitriggerfix_version", PLUGIN_VERSION, " Version of L4D Survivor AI Trigger Fix on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_findentitybyclass", Cmd_FindEntityByClass, ADMFLAG_BAN, "sm_findentitybyclass <classname> <entid> - find an entity by classname and starting index.");
	RegAdminCmd("sm_findentitybyname", Cmd_FindEntityByName, ADMFLAG_BAN, "sm_findentitybyname <name> <entid> - find an entity by name and starting index.");
	RegAdminCmd("sm_listentities", Cmd_ListEntities, ADMFLAG_BAN, "sm_listentities - server console dump of all valid entities");
	RegAdminCmd("sm_findnearentities", Cmd_FindNearEntities, ADMFLAG_BAN, "sm_findnearentities <radius> - find all Entities in a radius around you.");
	RegAdminCmd("sm_sendentityinput", Cmd_SendEntityInput, ADMFLAG_BAN, "sm_entityinput <entity id> <input string> - sends an Input to said Entity.");
	RegAdminCmd("sm_findentprop", Cmd_FindEntPropVal, ADMFLAG_BAN, "sm_findentprop <property string> - returns an entity property value in yourself");

	CreateTimer(3.0, CheckAroundTriggers, 0, TIMER_REPEAT);
	
	HookEvent("finale_start", FinaleBegins);
	HookEvent("round_end", GameEnds);
	HookEvent("map_transition", GameEnds);
	HookEvent("mission_lost", GameEnds);
	HookEvent("finale_win", GameEnds);
	
	HookEvent("player_entered_checkpoint", Event_PlayerEnterRescueZone);
	HookEvent("player_left_checkpoint", Event_PlayerLeavesRescueZone);
}

public OnMapStart()
{
	MapTrigger = false;
	ReachedSafeRoom = false;
	FinaleHasStarted = false;
	RoundHasEnded = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		PlayerReachedSafeRoom[i] = 0;
	}
}

public OnMapEnd()
{
	MapTrigger = false;
	ReachedSafeRoom = false;
	FinaleHasStarted = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		PlayerReachedSafeRoom[i] = 0;
	}
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client)) SetConVarInt(FindConVar("sb_all_bot_team"), 1);
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client)) return;
	
	for (new client2 = 1; client2 <= MaxClients; client2++)
	{
		if (IsClientInGame(client2))
			if (!IsFakeClient(client2)) return;
	}
	
	SetConVarInt(FindConVar("sb_all_bot_team"), 0);
}

public Action:GameEnds(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(7.0, DelayedBoolReset, 0);
	ReachedSafeRoom = false;
	FinaleHasStarted = false;
	RoundHasEnded = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		PlayerReachedSafeRoom[i] = 0;
	}
}

public Action:FinaleBegins(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleHasStarted = true;
}

public Action:DelayedBoolReset(Handle:Timer)
{
	MapTrigger = false; // to circumvent bugs with slow-ass l4d engine.
	RoundHasEnded = false;
}


public Action:CheckAroundTriggers(Handle:timer)
{
	if (!AllBotTeam()) return Plugin_Continue;
	
	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (StrContains(mapname, "hospital03_sewers", false) != -1)
	{
		//NM3. requested gas station blowup, entities: prop_physics, names pump01_breakable and pump02_breakable
		
		new gaspump = FindEntityByName("pump01_breakable", -1);
		
		if (gaspump == -1) // has it been destroyed already? continue without doing anything.
		{
			MapTrigger = true;
			return Plugin_Continue;
		}
			
		// using coordinates for approach. Pumps can misfire because range is too high.
		// 11180.7 6559.1 78.0;
		decl Float:pos1[3];
		pos1[0] = 11180.7
		pos1[1] = 6559.1
		pos1[2] = 78.0
	
		if (CheckforBots(pos1, 300.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found approaching the gas station. 'Sploding Stuff Now.");
			AcceptEntityInput(gaspump, "Ignite");
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "hospital04_interior", false) != -1)
	{
		//NM4: func_button, VS entids 134 and 1616
		//NM4 second elevator button coordinates: 13501 15133 486
		//coordinates first button: setpos 13488.7 15093.5 479.8; setang 5.0 -86.0 0.0
		
		// map is No Mercy 4, using coordinates for elevator button
		decl Float:pos1[3];
		pos1[0] = 13488.7
		pos1[1] = 15093.5
		pos1[2] = 479.8
	
		if (CheckforBots(pos1, 200.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the first elevator button. Executing a fake call");
			AcceptEntityInput(134, "Press");
			MapTrigger = true;
			
			// elevator takes about 1 minute to descend, lets use 75 secs
			CreateTimer(75.0, NoMercy4ElevatorTeleport, 0);
		}
	}
	
	if (StrContains(mapname, "hospital05_rooftop", false) != -1)
	{
		if (MapTrigger) return Plugin_Continue;
		// map is No Mercy 5
		decl Float:pos1[3];
		new button = FindEntityByClassname(-1, "func_button");
	
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
			CreateTimer(20.0, FinaleStart, 0);
			return Plugin_Continue;
		}
		
		GetEntityAbsOrigin(button, pos1);
		if (CheckforBots(pos1, 200.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Radio. Executing a fake call");
			AcceptEntityInput(button, "Press");
			MapTrigger = true;
			
			CreateTimer(20.0, FinaleStart, 0);
		}
	}

	if (StrContains(mapname, "farm02_traintunnel", false) != -1)
	{
		// map is BH2
		decl Float:posdoor[3], Float:postriggerer[3], Float:anglestriggerer[3];
		
		posdoor[0] = -8605.0
		posdoor[1] = -7530.0
		posdoor[2] = -21.0
		
		postriggerer[0] = -8600.0
		postriggerer[1] = -7504.0
		postriggerer[2] = -60.0
		
		anglestriggerer[0] = 8.0
		anglestriggerer[1] = -90.0
		anglestriggerer[2] = 0.0
		
		if (CheckforBots(posdoor, 300.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Alarm Door. Trying to get him to open it");
			MapTrigger = true;
			
			TeleportEntity(TriggeringBot, postriggerer, anglestriggerer, NULL_VECTOR); // move bot infront of the door, facing it
			
			/*new buttons = GetEntProp(TriggeringBot, Prop_Data, "m_nButtons");
			buttons &= IN_USE;
			buttons &= IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			SetEntProp(TriggeringBot, Prop_Data, "m_nButtons", buttons);*/ // fake execute a Use ... doesnt work
			
			//FakeClientCommand(TriggeringBot, "+use"); // doesnt work
			
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "emergency_door", "open");
		}
	}
	
	if (StrContains(mapname, "farm03_bridge", false) != -1)
	{
		// map is Blood Harvest 3
		decl Float:pos1[3];
		new button = FindEntityByClassname(-1, "func_button");
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			MapTrigger = true;
			//CreateTimer(30.0, BloodHarvest3RampTeleport, 0);
			return Plugin_Continue;
		}
		
		if (!IsValidEntity(button)) return Plugin_Continue;
		
		GetEntityAbsOrigin(button, pos1);
	
		if (CheckforBots(pos1, 1500.0) && MapTrigger == false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found somewhat close to the Train Car button. Executing a fake call");
			AcceptEntityInput(button, "Press");
			MapTrigger = true;
			//CreateTimer(30.0, BloodHarvest3RampTeleport, 0);
		}
	}
	
	if (StrContains(mapname, "smalltown03_ranchhouse", false) != -1)
	{
		// map is Death Toll 3
		decl Float:pos1[3];
		new button = FindEntityByClassname(-1, "func_button");
		GetEntityAbsOrigin(button, pos1);
	
		if (CheckforBots(pos1, 400.0) && MapTrigger == false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Church Guy Door. Triggering...");
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "button_safedoor_panic", "");
			AcceptEntityInput(FindEntityByClassname(-1, "func_orator"), "Kill"); // shut up Church Guy, for he wont stop talking
			MapTrigger = true;
		}
	}
	
	if (StrContains(mapname, "smalltown05_houseboat", false) != -1)
	{
		if (MapTrigger) return Plugin_Continue;
		// map is Death Toll 5
		decl Float:pos1[3];
		new button = FindEntityByClassname(-1, "func_button");
	
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
			CreateTimer(20.0, FinaleStart, 0);
			return Plugin_Continue;
		}
		
		GetEntityAbsOrigin(button, pos1);
		if (CheckforBots(pos1, 500.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Radio. Executing a fake call");
			AcceptEntityInput(button, "Press");
			AcceptEntityInput(FindEntityByClassname(-1, "func_orator"), "Kill"); // shut up John Slater, for he wont stop talking
			MapTrigger = true;
			
			CreateTimer(20.0, FinaleStart, 0);
		}
	}
	
	if (StrContains(mapname, "airport03_garage", false) != -1)
	{
		// map is Dead Air 3. VS entity id of the gas cans is 963
		// name is "barricade_gas_can"

		new gascans = FindEntityByName("barricade_gas_can", -1);
		
		if (gascans == -1) // has it been destroyed already? continue without doing anything.
		{
			MapTrigger = true;
			return Plugin_Continue;
		}
			
		decl Float:pos1[3];
		GetEntityAbsOrigin(gascans, pos1);
	
		if (CheckforBots(pos1, 900.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the gas can barricade. Triggering Crescendo.");
			AcceptEntityInput(gascans, "Ignite");
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "airport05_runway", false) != -1)
	{
		// map is Dead Air 5
		if (MapTrigger) return Plugin_Continue;

		new button = FindEntityByClassname(-1, "func_button");

		if (!IsValidEntity(button) && MapTrigger==false)
		{
			MapTrigger = true;
			CreateTimer(10.0, FinaleStart, 0);
			return Plugin_Continue;
		}
		
		decl Float:pos1[3];		
		GetEntityAbsOrigin(button, pos1);
		if (CheckforBots(pos1, 400.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Radio. Executing a fake call");
			AcceptEntityInput(button, "Press");
			MapTrigger = true;
			
			CreateTimer(10.0, FinaleStart, 0);
		}
	}
	
	if (StrContains(mapname, "garage02_lots", false) != -1)
	{
		// map is CC2
		decl Float:stuckpos[3];
		
		stuckpos[0] = 3227.0;
		stuckpos[1] = -24.0;
		stuckpos[2] = -200.0;
	
		if (CheckforBots(stuckpos, 300.0) && MapTrigger==false)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the evil stuck spot. Warping them FAR ahead in 25 seconds.");
			MapTrigger = true;
			
			CreateTimer(25.0, CrashCourse2StuckFix, 0);
		}
	}
	return Plugin_Continue;
}

public Action:CrashCourse2StuckFix(Handle:Timer)
{
	PrintToChatAll("\x04[BOTFIX] \x01Warping Bots ahead, far away from their huddling spot.");
	PrintToChatAll("\x04[BOTFIX] \x01It has to be that far away, because they keep running back.");
	
	decl Float:warpto[3];
	
	warpto[0] = 5404.0
	warpto[1] = 68.0
	warpto[2] = -60.0
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				TeleportEntity(target, warpto, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

/*
public Action:BloodHarvest3RampTeleport(Handle:Timer)
{
	PrintToChatAll("\x04[BOTFIX] \x01Shoving Bots onto the Ramp.");
	
	decl Float:postriggerer[3];
	
	postriggerer[0] = 13500.0
	postriggerer[1] = 15163.0
	postriggerer[2] = 427.0
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				TeleportEntity(target, postriggerer, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
*/

public Action:NoMercy4ElevatorTeleport(Handle:Timer)
{
	PrintToChatAll("\x04[BOTFIX] \x01Shoving Bots into that Elevator.");
	
	decl Float:postriggerer[3], Float:anglestriggerer[3];
	
	postriggerer[0] = 13500.0
	postriggerer[1] = 15163.0
	postriggerer[2] = 427.0
	anglestriggerer[0] = 8.0
	anglestriggerer[1] = -89.0
	anglestriggerer[2] = 0.0
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
			TeleportEntity(target, postriggerer, anglestriggerer, NULL_VECTOR);
			TriggeringBot = target;
			}
		}
	}
	CreateTimer(1.0, ElevatorCall, 0);
}

public Action:ElevatorCall(Handle:Timer)
{
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "elevator_button", "use");
}

public Action:FinaleStart(Handle:Timer)
{
	if (FinaleHasStarted) return Plugin_Continue;
	
	if (!TriggeringBot) TriggeringBot = GetAnyValidClient();
	else if (!IsClientInGame(TriggeringBot)) TriggeringBot = GetAnyValidClient();
	
	if (!TriggeringBot) return Plugin_Continue;
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "trigger_finale", "");
	PrintToChatAll("\x04[BOTFIX] \x01Executing fake Finale Call.");
	return Plugin_Continue;
}

GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))	return target;
	}
	return 1;
}


public Action:Event_PlayerEnterRescueZone(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundHasEnded) return Plugin_Continue;
	decl String:door[64];
	GetEventString(event, "doorname", door, sizeof(door));

	if (StrEqual(door, "checkpoint_entrance", false) || StrEqual(door, "door_checkpointentrance", false))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new door_id = GetEventInt(event, "door");

		if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			PlayerReachedSafeRoom[client] = 1;
			ReachedSafeRoom = true;
			
			if (!AllBotTeam()) return Plugin_Continue;
			
			if (SurvivorsSafe() >= SurvivorsAlive())
			{
			// all Survivors in Saferoom.
			PrintToChatAll("\x04[BOTFIX] \x01All Bot Survivors in Safe Room. Force Shutting Door.");
			AcceptEntityInput(door_id, "Close");
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerLeavesRescueZone(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundHasEnded) return Plugin_Continue;
	if (ReachedSafeRoom)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			PlayerReachedSafeRoom[client] = 0;
		}
	}
	return Plugin_Continue;
}

SurvivorsAlive()
{
	new Survivors = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
			Survivors++;
	}

	return Survivors;
}

SurvivorsSafe()
{
	new Survivors;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (PlayerReachedSafeRoom[i] == 1)
			Survivors++;
	}

	return Survivors;
}

// this bool return true if a Bot was found in a radius around the given position, and sets TriggeringBot to it.
public bool:CheckforBots(Float:position[3], Float:distancesetting)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				decl Float:targetPos[3];
				GetClientAbsOrigin(target, targetPos);
				new Float:distance = GetVectorDistance(targetPos, position); // check Survivor Bot Distance from checking point
					
				if (distance < distancesetting)
				{
					TriggeringBot = target;
					return true;
				}
				else
				{
					continue;
				}
			}
		}
	}
	return false;
}

public bool:AllBotTeam()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			if (!IsFakeClient(client)) return false;
		}
	}
	return true;
}


// this console command is for finding entities and their id
public Action:Cmd_FindEntityByClass(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyclass <classname> <startindex> - find an entity class starting from index number");
		return Plugin_Handled;
	}

	decl String:name[64], String:startnum[12];
	GetCmdArg(1, name, 64);
	GetCmdArg(2, startnum, 12);
	new entid = FindEntityByClassname(StringToInt(startnum), name);
	if (entid == -1)
	{
		PrintToChat(client, "Found no Entity of that class.");
		return Plugin_Handled;
	}

	
	decl Float:clientpos[3], Float:entpos[3];
	GetClientAbsOrigin(client, clientpos);
	GetEntityAbsOrigin(entid, entpos);
	new Float:distance = GetVectorDistance(clientpos, entpos);
	
	GetEntPropString(entid, Prop_Data, "m_iName", name, sizeof(name));
	PrintToChat(client, "Found Entity Id %i, of name: %s; distance from you: %f", entid, name, distance);

	return Plugin_Handled;
}

public Action:Cmd_FindEntityByName(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyname <name> <startindex> - find an entity by name starting from index number");
		return Plugin_Handled;
	}

	decl String:entname[64], String:number[12];
	GetCmdArg(1, entname, 64);
	GetCmdArg(2, number, 64);

	new foundid = FindEntityByName(entname, StringToInt(number));
	if (foundid == -1) PrintToChatAll("Nothing by that name found.");
	else PrintToChatAll("Found Entity: %i by name %s", foundid, entname);
	
	return Plugin_Handled;
}

//this sends Entity Inputs like "Kill" or "Activate"
public Action:Cmd_SendEntityInput(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_entityinput <entity id> <input string> - sends an Input to said Entity");
		return Plugin_Handled;
	}

	decl String:entid[64], String:input[12];
	GetCmdArg(1, entid, 64);
	GetCmdArg(2, input, 64);
	
	AcceptEntityInput(StringToInt(entid), input);

	return Plugin_Handled;
}


//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
public Action:GetEntityAbsOrigin(entity,Float:origin[3])
{
    decl Float:mins[3], Float:maxs[3];

    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
    GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
    GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}

// this finds entites - who have a position - in a radius around you
public Action:Cmd_FindNearEntities(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findnearentities <radius> - find all Entities with a position close to you");
		return Plugin_Handled;
	}
	decl String:value[64];
	GetCmdArg(1, value, 64);
	new Float:radius = StringToFloat(value);
	
	decl Float:entpos[3], Float:clientpos[3], String:name[128], String:classname[128];
	GetClientAbsOrigin(client, clientpos);
	new maxentities = GetMaxEntities();
	
	for (new i = 1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		
		// you wouldn't believe how long this took me.
		if (strcmp(classname, "cs_team_manager") == 0) continue;
		if (strcmp(classname, "terror_player_manager") == 0) continue;
		if (strcmp(classname, "terror_gamerules") == 0) continue;
		if (strcmp(classname, "soundent") == 0) continue;
		if (strcmp(classname, "vote_controller") == 0) continue;	
		if (strcmp(classname, "move_rope") == 0) continue;
		if (strcmp(classname, "keyframe_rope") == 0) continue;
		if (strcmp(classname, "water_lod_control") == 0) continue;
		if (strcmp(classname, "predicted_viewmodel") == 0) continue;
		if (strcmp(classname, "beam") == 0) continue;
		if (strcmp(classname, "info_particle_system") == 0) continue;
		if (strcmp(classname, "color_correction") == 0) continue;
		if (strcmp(classname, "shadow_control") == 0) continue;
		if (strcmp(classname, "env_fog_controller") == 0) continue;
		if (strcmp(classname, "ability_lunge") == 0) continue;
		if (strcmp(classname, "cs_ragdoll") == 0) continue;
		if (strcmp(classname, "instanced_scripted_scene") == 0) continue;
		if (strcmp(classname, "ability_vomit") == 0) continue;
		if (strcmp(classname, "ability_tongue") == 0) continue;
		if (strcmp(classname, "env_wind") == 0) continue;
		if (strcmp(classname, "env_detail_controller") == 0) continue;		
		if (strcmp(classname, "func_occluder") == 0) continue;
		if (strcmp(classname, "logic_choreographed_scene") == 0) continue;		
		
		GetEntityAbsOrigin(i, entpos);
		if (GetVectorDistance(entpos, clientpos) < radius)
		{
			PrintToChat(client, "Found: Entid %i, name %s, class %s", i, name, classname);
		}
	}
	return Plugin_Handled;
}


// dumps a list of all map entities into your servers console. if you localhost that is YOUR console ^^
public Action:Cmd_ListEntities(client, args)
{
	new maxentities = GetMaxEntities();
	decl String:name[128], String:classname[128];

	for (new i = 0; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		PrintToServer("%i: name %s, classname %s", i, name, classname);

	}
	return Plugin_Handled;
}

public FindEntityByName(String:name[], any:startcount)
{
	decl String:classname[128];
	new maxentities = GetMaxEntities();
	
	for (new i = startcount; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEdictClassname(i, classname, 128)
		
		// you wouldn't believe how long this took me.
		if (strcmp(classname, "cs_team_manager") == 0) continue;
		if (strcmp(classname, "terror_player_manager") == 0) continue;
		if (strcmp(classname, "terror_gamerules") == 0) continue;
		if (strcmp(classname, "soundent") == 0) continue;
		if (strcmp(classname, "vote_controller") == 0) continue;	
		if (strcmp(classname, "move_rope") == 0) continue;
		if (strcmp(classname, "keyframe_rope") == 0) continue;
		if (strcmp(classname, "water_lod_control") == 0) continue;
		if (strcmp(classname, "predicted_viewmodel") == 0) continue;
		if (strcmp(classname, "beam") == 0) continue;
		if (strcmp(classname, "info_particle_system") == 0) continue;
		if (strcmp(classname, "color_correction") == 0) continue;
		if (strcmp(classname, "shadow_control") == 0) continue;
		if (strcmp(classname, "env_fog_controller") == 0) continue;
		if (strcmp(classname, "ability_lunge") == 0) continue;
		if (strcmp(classname, "cs_ragdoll") == 0) continue;
		if (strcmp(classname, "instanced_scripted_scene") == 0) continue;
		if (strcmp(classname, "ability_vomit") == 0) continue;
		if (strcmp(classname, "ability_tongue") == 0) continue;
		if (strcmp(classname, "env_wind") == 0) continue;
		if (strcmp(classname, "env_detail_controller") == 0) continue;		
		if (strcmp(classname, "func_occluder") == 0) continue;
		if (strcmp(classname, "logic_choreographed_scene") == 0) continue;
		
		decl String:iname[128];
		GetEntPropString(i, Prop_Data, "m_iName", iname, sizeof(iname));
		if (strcmp(name,iname,false) == 0) return i;
	}
	return -1;
}

public Action:Cmd_FindEntPropVal(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentprop <property string> - returns an entity property value in yourself");
		return Plugin_Handled;
	}

	decl String:prop[64];
	GetCmdArg(1, prop, sizeof(prop));
	
	new offset = FindSendPropInfo("CTerrorPlayer", prop);
	
	if (offset == -1)
	{
		PrintToChat(client, "No such property: %s", prop)
		return Plugin_Handled;
	}
	
	else if (offset == 0)
	{
		PrintToChat(client, "No offset found for: %s", prop)
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Value of %s: %i", prop, GetEntData(client, offset));
	return Plugin_Handled;
}

public Action:UnflagAndExecuteCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	if (client == 0 || !IsClientConnected(client))
	{		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				client = i
				break;
			}
		}
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2)
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}