#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.1.3"

new bool:CurrentlySpawning = false;
new currenttank = 0; // this is how I keep track of who the tank is.  Obviously can't handle multiple tanks at once.
new bool:fire = false;
new Handle:tankspeed = INVALID_HANDLE;
new Handle:spawndelay = INVALID_HANDLE;
new Handle:imonfire = INVALID_HANDLE;
new Handle:imfrozen = INVALID_HANDLE;
new Handle:Max_Tank_Speed = INVALID_HANDLE;
new bool:finaleyet = false;
new Max_Tank_Speed_Manip = 0;
new Tank_Spawner = 0;
new offsetIsGhost;
new offsetIsAlive;
new bool:frozen = false;

public Plugin:myinfo = 
{
	name = "Chase 4 Dead",
	author = "kaffaljidhma",  //credit to James Richardson and Voiderest for code stolen from their plugins
	description = "Invincitank",
	version = PLUGIN_VERSION,  //thanks to pretty much everyone on #sourcemod for pretty much writing the thing for me
	url = "http://www.sourcemod.net/" //don't get on my back I'm making a list of all of you
}

public OnPluginStart()
{
	//RegAdminCmd("randclient", Command_randclient, ADMFLAG_CHEATS);
	CreateConVar("Chase4Dead", PLUGIN_VERSION, "Chase 4 Dead Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	spawndelay = CreateConVar("Chase4Dead_spawn_delay", "10.0", "How long the tank is frozen after it spawns");
	tankspeed = FindConVar("z_tank_speed_vs");
	Max_Tank_Speed = CreateConVar("Chase4Dead_max_speed", "210", "Initial speed of tank"); //used as pretty much a const to prevent runaway tank speeds
	Max_Tank_Speed_Manip = GetConVarInt(Max_Tank_Speed);
	StripAndChangeServerConVarFloat("versus_tank_chance", 0.0); //all to prevent multiple tanks.  Might make an error message if the tank tracker fails
	StripAndChangeServerConVarFloat("versus_tank_chance_finale", 0.0);
	StripAndChangeServerConVarFloat("versus_tank_chance_intro", 0.0);
	finaleyet = false;
	// We find some offsets
	offsetIsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	//offsetIsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	offsetIsAlive = 2236;	

	HookEvent("player_left_start_area", Event_player_left_start_area);
	//HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("finale_radio_start", Event_finale_radio_start, EventHookMode_PostNoCopy); //might change to the press of the finale radio button
	HookEvent("tank_frustrated", Event_tank_frustrated);
	HookEvent("waiting_checkpoint_button_used", Event_elevator_wait, EventHookMode_PostNoCopy);
	HookEvent("success_checkpoint_button_used", Event_elevator_success, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true);
}

/*
public Action:Command_randclient(client, args) {
	new randclient = GetRandomClient(2);
	PrintToChatAll("Random Client: %N", randclient);
}
	

Command_SpawnInfected(client) {
	new String:command[] = "z_spawn"; //didn't have the heart to change it from its all4dead version
	CurrentlySpawning = true;
	StripAndExecuteClientCommand(client, command, "tank", "auto", "");
	//PrintToChatAll("A tank has been spawned"); // NOTE; I use these a lot for debugging
}
*/

public SpawnTank(client)
{
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetDead[MAXPLAYERS+1];
	new bool:resetTeam[MAXPLAYERS+1];
	new bool:resetTank = false;
	new bool:InfectedPlayers[MAXPLAYERS+1];
	new n_infected = CountRealInfected(InfectedPlayers);
	//PrintToChatAll("Number of Infected: %d", n_infected);
	PrintToServer("Number of Infected: %d", n_infected);
	if (n_infected == 0)
	{
		// Spawn AI tank
		PrintToServer("Campaign Spawn");
		//PrintToChatAll("Campaign Spawn");
		StripAndExecuteClientCommand(client, "z_spawn", "tank", "auto", "");
		//ServerCommand("z_spawn tank auto");
		CurrentlySpawning = true;
		return;
	}
	else
	{
		// Find a random infected player
		// I know changing the argument variable mid-function is confusing.  OH WELL.
		new infected_client = GetRandomInfectedPlayer(n_infected, InfectedPlayers);
		PrintToServer("RandClient is %N", infected_client);
		//PrintToChatAll("RandClient is %N", infected_client);
		resetGhost[infected_client] = false;
		resetDead[infected_client] = false;
		resetTeam[infected_client] = false;
		// Exclude the other infected players/bots
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 3 && infected_client != i)
			{
				PrintToChat(i, "Tank should not see this");
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					/*
					if(IsPlayerAlive(i)) {
						PrintToServer("Ghost Player is alive! ERROR")
						PrintToChat(i, "Ghost Player is alive! ERROR")
					}
					*/
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					//might have to change this, ghosts are alive
					resetDead[i] = true;
					SetAliveStatus(i, true);
				}
				else if (!IsPlayerAlive(i)) // if player is just dead ...
				{
					resetTeam[i] = true;
					ChangeClientTeam(i, 1);
				}
			}
		}

		// Spawn player as tank
		//Note: Ghosts are alive.
		if (IsPlayerAlive(infected_client) && !IsPlayerGhost(infected_client))
		{
			//PrintToServer("Player killed for tank");
			//PrintToChat(infected_client, "Player killed for tank");
			// Commented this out for now. If the above code doesn't work, we will need to kill the player instead
			new String:command[] = "kill" // I put it back in because I don't want bots if I can help it
			StripAndExecuteClientCommand(infected_client, command, "", "", "");
			//might have to change this, ghosts are alive
			resetTank = true;
			SetGhostStatus(infected_client, true);
			/*
			if(IsPlayerAlive(infected_client)) {
				PrintToServer("Ghost Player is alive! ERROR");
				PrintToChat(infected_client, "Ghost Player is alive! ERROR");
			}
			*/
			SetAliveStatus(infected_client, false);
		}
		CurrentlySpawning = true;
		//PreviousTank = client;
		//hold out on that judgement till I can get a guarantee
		Tank_Spawner = infected_client; //for error checking
		new String:command[] = "z_spawn"; //didn't have the heart to change it from its all4dead version
		StripAndExecuteClientCommand(client, command, "tank", "auto", "");
		// Restore the other players status
		for (new i = 1; i <= MaxClients; i++)
		{
			if (resetGhost[i]) {
				//PrintToChat(client, "You're a ghost");
				SetGhostStatus(i, true);
			}
			if (resetDead[i]) {
				SetAliveStatus(i, false);
			}
			if (resetTeam[i]) {
				ChangeClientTeam(i, 3);
			}
		}
		
		// Restore Tank status if we killed him
		if(resetTank) {
			SetGhostStatus(infected_client, false);
			SetAliveStatus(infected_client, true);
		}
		return;
	}
}

CountRealInfected(InfectedPlayers[])
{
	new Infected;
	for (new i = 1;i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)) && GetClientTeam(i) == 3)
		{
			InfectedPlayers[i] = true;
			Infected++;
		}
		else
			InfectedPlayers[i] = false;
	}
	return Infected;
}

GetRandomInfectedPlayer(NumberofInfected, InfectedPlayers[])
{
	if (NumberofInfected <= 1)
	{
		// If there is only one infected player.
		for (new i = 1;i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)) && GetClientTeam(i) == 3)
				return i;
		}
	}
	else
	{
		//Someday, I'll store currenttank as a userid instead of a client.  Someday.
		new tank_client;
		if(currenttank != 0) {
			tank_client = GetClientOfUserId(currenttank);
		} else {
			tank_client = 0;
		}
		// Remove the previous tank from the selection if there are atleast 2 infected players.
		if (tank_client != 0 && IsClientConnected(tank_client) && IsClientInGame(tank_client) && (!IsFakeClient(tank_client)) && GetClientTeam(tank_client) == 3)
		{
			InfectedPlayers[tank_client] = false;
			NumberofInfected--;
		}

		new randclient = GetRandomInt(1, NumberofInfected);
		new count;
		for (new i = 1;i <= MaxClients; i++)
		{
			if (InfectedPlayers[i])
			{
				count++;
				if (count == randclient)
					return i;
			}
		}
	}
	return 0;
}

bool:IsPlayerGhost (client)
{
	new isghost;
	isghost = GetEntData(client, offsetIsGhost, 1);
	
	if (isghost == 1)
		return true;
	else
	return false;
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
		SetEntData(client, offsetIsGhost, 1, 1, true);
	else
	SetEntData(client, offsetIsGhost, 0, 1, false);
}

SetAliveStatus (client, bool:alive)
{
	if (alive)
		SetEntData(client, offsetIsAlive, 1, 1, true);
	else
	SetEntData(client, offsetIsAlive, 0, 1, false);
}

//Tank slowdown and invincibility code

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {	
	new userid = GetEventInt(event, "userid");
	if(currenttank == userid && !finaleyet) {
		new type = GetEventInt(event, "type");  //need this to prevent clients from surviving fatal punches
		//PrintToChatAll("Damage Type is %d", type);
		new client = GetClientOfUserId(currenttank);
		new dmg_health = GetEventInt(event, "dmg_health");
		new health = GetEventInt(event, "health"); //stolen directly from l4d_damage_0_9
		//PrintToChatAll("Damage is %d to %d total", dmg_health, health);
		SetEntityHealth(client, (health + dmg_health));  //give health back
		//type 8 is touching fire, type 268435464 is the damage from being on fire
		if(type == 8) {
			if(fire) {
				if(imonfire != INVALID_HANDLE) {
					KillTimer(imonfire); //condition is for safety reasons, killtimer does first half of extinguish reset
				}
			} else {
				fire = true;
				Max_Tank_Speed_Manip = RoundFloat(GetConVarFloat(Max_Tank_Speed) * (3.0/4.0)); //might make fraction a convar
				//whenever you see tankspeed != 1, that means I'm protecting against tank unfreezing before elevator close
				if(GetConVarInt(tankspeed) != 1) {
					StripAndChangeServerConVarInt("z_tank_speed_vs", Max_Tank_Speed_Manip);
					StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
				}
			}
			if(IsFakeClient(client)) {
				imonfire = CreateTimer(25.0, Extinguish);
			} else {
				imonfire = CreateTimer(30.0, Extinguish); //second half of extinguish reset if already on fire
			}
		}
		if(type != 268435464 && GetConVarInt(tankspeed) != 1) {
			StripAndChangeServerConVarInt("z_tank_speed_vs", (Max_Tank_Speed_Manip) / 2);
			StripAndChangeServerConVarInt("z_tank_speed", (Max_Tank_Speed_Manip) / 2);
			if(GetConVarInt(tankspeed) < Max_Tank_Speed_Manip) {
				CreateTimer(1.0, Restore_Speed);
				//I don't use killtimer because I'm thinking of compounding tank slowdown events based on weapon damage
			}
		}
		//PrintToChatAll("Health is %d", health);
	} 
	return Plugin_Continue;
}

public Action:Extinguish(Handle:timer)
{
	new client = GetClientOfUserId(currenttank);
	ExtinguishEntity(client);
	fire = false;
	Max_Tank_Speed_Manip = GetConVarInt(Max_Tank_Speed);
	if(GetConVarInt(tankspeed) != 1) {
		StripAndChangeServerConVarInt("z_tank_speed_vs", Max_Tank_Speed_Manip);
		StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
	}
	return Plugin_Continue;
}

public Action:Restore_Speed(Handle:timer)
{
	if(GetConVarInt(tankspeed) != 1) {
		StripAndChangeServerConVarInt("z_tank_speed_vs", Max_Tank_Speed_Manip);
		StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
	}
	return Plugin_Continue;
}

public Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast) {
	//Reset convars in case my code fails, also in case server continues after finale
	finaleyet = false;
	if(fire) {
		TriggerTimer(imonfire, false); //don't want a 10 second molotov
	}
	if(frozen) {
		TriggerTimer(imfrozen, false);
	}
	currenttank = 0;
	Max_Tank_Speed_Manip = GetConVarInt(Max_Tank_Speed);
	StripAndChangeServerConVarInt("z_tank_speed_vs", Max_Tank_Speed_Manip);
	StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
	new client_userid = GetEventInt(event, "userid");
	new client =  GetClientOfUserId(client_userid);
	//PrintToChatAll("%N set off the tank!", client);
	//Command_SpawnInfected(client); //since a survivor spawns the tank, it spawns nearby
	SpawnTank(client);
}

//duhhhhh I thought this was for debugging purpose but it has an all important function

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	if(!finaleyet && IsFakeClient(client)) {
		PrintToServer("Campaign Tank");
		//PrintToChatAll("Campaign Tank");
		if(currenttank != 0) {
			if(fire) {
				TriggerTimer(imonfire, false); //I don't want any timers on during finale, for safety.
			}
			if(frozen) {
				TriggerTimer(imfrozen,false);
			}
			StripAndExecuteClientCommand(client, "kill", "", "", "");
			PrintToServer("Previous AI Tank killed");
			//PrintToChatAll("Previous AI Tank killed");
		}
	}
	currenttank = client_userid;  //THIS is how I select who is the tank
	client = GetClientOfUserId(currenttank); // why am I doing thissss
	//PrintToChatAll("Tank is %N.", client)
	//PrintToConsole(client, "Tank is %N.", client)
	PrintToServer("Tank is %N.", client)
	if (GetClientTeam(client) == 3 && CurrentlySpawning  && !finaleyet) {
		//PrintToChatAll("Health for %N.", client)
		//PrintToConsole(client, "Health for %N.", client)
		PrintToServer("Health for %N.", client)
		StripAndExecuteClientCommand(client, "give", "health", "", "");
		//Sometimes "give health" will only give the amount of the previous class.  This is a temp fix.
		SetEntityHealth(client, 6000);
		//We have added health to the thing we have spawned so turn ourselves off
		CurrentlySpawning = false;
		if(!finaleyet && client != Tank_Spawner && !IsFakeClient(client)) {
			PrintToChatAll("Error: Tank does not match random spawner.  Contact plugin creator.")
			PrintToConsole(client, "Error: Tank does not match random spawner.  Contact plugin creator.")
			PrintToServer("Error: Tank does not match random spawner.  Contact plugin creator.")
		}
	}
	if(!finaleyet) {
		FreezeTank(client, GetConVarFloat(spawndelay));
	}
}

FreezeTank(client, Float:time) {
	SetEntityMoveType(client, MOVETYPE_NONE);
	frozen = true;
	imfrozen = CreateTimer(time, Timer_Unfreeze);
}

public Action:Timer_Unfreeze(Handle:timer) {
	new client = GetClientOfUserId(currenttank);
	SetEntityMoveType(client, MOVETYPE_WALK);
	frozen = false;
	return Plugin_Continue;
}

//I don't really need this, and it's been giving me a lot of problems
/*
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//Direct rip from all4dead
	//If something spawns and we have just requested something to spawn - assume it is the same thing and make sure it has max health
	if (GetClientTeam(client) == 3 && CurrentlySpawning  && !finaleyet) {
		PrintToChatAll("Health for %N.", client)
		PrintToConsole(client, "Health for %N.", client)
		PrintToServer("Health for %N.", client)
		StripAndExecuteClientCommand(client, "give", "health", "", "");
		//We have added health to the thing we have spawned so turn ourselves off
		CurrentlySpawning = false;
		if(!finaleyet && client != Tank_Spawner && !IsFakeClient(client)) {
			PrintToChatAll("Error: Tank does not match random spawner.  Contact plugin creator.")
			PrintToConsole(client, "Error: Tank does not match random spawner.  Contact plugin creator.")
			PrintToServer("Error: Tank does not match random spawner.  Contact plugin creator.")
		}
	}
}
*/

//I haven't thought of how to integrate with finale yet, so I'm going to turn everything back to normal
public Event_finale_radio_start(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(currenttank);
	new String:command[] = "kill" //Maybe in case we want to make it more showy... I dunno
	//PrintToChatAll("Finale has started, %N will now die", client);
	finaleyet = true;
	if(fire) {
		TriggerTimer(imonfire, false); //I don't want any timers on during finale, for safety.
	}
	if(frozen) {
		TriggerTimer(imfrozen,false);
	}
	StripAndExecuteClientCommand(client, command, "", "", "");
	Max_Tank_Speed_Manip = GetConVarInt(Max_Tank_Speed); //Redundant with the trigger, but I'm not taking my chances
	StripAndChangeServerConVarInt("z_tank_speed_vs", 210); //I don't have the courage to enforce a custom Max speed across the board
}

//The survivors really need a break at the elevator, since it can't be closed if people outside are incapped
public Event_elevator_wait(Handle:event, const String:name[], bool:dontBroadcast) {
	StripAndChangeServerConVarInt("z_tank_speed_vs", 1); //0 will make the game really fun ... for the tank
	StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
}

public Event_elevator_success(Handle:event, const String:name[], bool:dontBroadcast) {
	StripAndChangeServerConVarInt("z_tank_speed_vs", Max_Tank_Speed_Manip); //If he's still on fire, I don't want to give him a free ride
	StripAndChangeServerConVarInt("z_tank_speed", Max_Tank_Speed_Manip);
}

public Action:Event_tank_frustrated(Handle:event, const String:name[], bool:dontBroadcast) {
	new client_userid = GetEventInt(event, "userid");
	if (!finaleyet) {
		if(fire) {
			TriggerTimer(imonfire, false); //don't want a 10 second molotov
		}
		if(frozen) {
			TriggerTimer(imfrozen, false);
		}
		new client = GetClientOfUserId(client_userid);
		new String:command[] = "kill"; //I forgot why I made this string
		//PrintToChat(client, "Time's up, %N! Next tank's turn", client);
		StripAndExecuteClientCommand(client, command, "", "", "");
		CreateTimer(3.0, Frustration_Respawn); //If I do the function immediately, it will be overtaken by regular frustation
		//don't tell me to do EventHookMode_Pre and Plugin_Handled, cause it doesn't work.
	}
	return Plugin_Continue;
}

//Killing the tank when frustrated gives the survivors a chance if the tank tries to camp a chokepoint ahead of them
public Action:Frustration_Respawn(Handle:timer)
{
	new randclient = GetRandomClient(2); //I might switch it to survivor team so tank doesn't spawn out of map sometimes
	/*
	PrintToChatAll("The new tank is %N" in 3 seconds", newtank);
	if(IsPlayerAlive(newtank)) {
		StripAndExecuteClientCommand(newtank, "kill", "", "", ""); //z_spawn tank creates AI tank if you're alive, no matter the team
	}
	Command_SpawnInfected(newtank);
	*/
	SpawnTank(randclient);
	return Plugin_Continue;
}

GetRandomClient(team) {
	new bool:valid = false;
	new client = 0;
	while(!valid) {
		client = GetRandomInt(1, MaxClients);
		//Have to put isclientconnected first or function may fail
		if(IsClientConnected(client) && GetClientTeam(client) == team) {
			valid = true; //I don't care if bots spawn the tank, cause they're usually not alive on infected
			//I might change that if I make a campaign-compatible version
		}
	}
	//PrintToServer("RandClient is %N", client);
	return client;
}

//stolen directly from all4dead, and for some reason won't work if sv_cheats are on, or I'm mistaken
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
}

StripAndChangeServerConVarInt(String:command[], value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
}

//Needed for changing tank spawn chance
StripAndChangeServerConVarFloat(String:command[], Float:value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarFloat(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
