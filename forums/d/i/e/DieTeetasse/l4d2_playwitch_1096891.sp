#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_InfectedSpawnApi>

#define WITCH_MODEL "models/infected/witch.mdl"
#define WITCH_SOUNDS_PATH "npc/witch/voice/"
#define WITCH_SOUNDS_ATTACKING_PATH "attack/"
#define WITCH_SOUNDS_DYING_PATH "die/"
#define WITCH_SOUNDS_IDLE_PATH "idle/"
#define WITCH_SOUNDS_PAIN_PATH "pain/"
#define WITCH_SOUNDS_SUPRISED_PATH "mad/"

/*
	duration: 1-2 seconds
	0 & 1 => attacking
	2 & 3 => shredding
*/
new String:witch_sound_attacking[4][32] = {"female_distantscream1.wav", "female_distantscream2.wav", "female_shriek_1.wav", "female_shriek_2.wav"};

/*
	duration: 2 seconds
*/
new String:witch_sounds_dying[32] = {"female_death_1.wav"};

/*
	duration: 2-5 seconds
	0 => sitting
	1 => wandering
*/
new String:witch_sounds_idle[2][4][32] = {{"female_cry_1.wav", "female_cry_2.wav", "female_cry_3.wav", "female_cry_4.wav"}, {"walking_cry_07.wav", "walking_cry_10.wav", "walking_cry_11.wav", "walking_cry_12.wav"}}; 

/*
	duration: 1 second
*/
new String:witch_sound_pain[3][32] = {"witch_pain_1.wav", "witch_pain_2.wav", "witch_pain_3.wav"};

/*
	duration: 1-2 seconds
	0 & 1 => suprised
	2 - 4 => getting mad
	5 & 6 => calming down
*/
new String:witch_sound_suprised[7][32] = {"female_ls_b_attackgrunt16.wav", "female_ls_b_surprised01.wav", "female_ls_d_madscream01.wav", "female_ls_d_madscream02.wav", "female_ls_d_madscream03.wav", "zombiefemale_growl1.wav", "zombiefemale_growl6.wav"};

new bool:global_blockwitch = false;
new bool:global_event = false;
new bool:global_witchdeathscratch = false;
new global_spitterclawdmg = 4;
new global_witchent = -1;
new global_witchplayer = -1;

public OnPluginStart()
{
	RegConsoleCmd("sm_spawnwitch", Command_SpawnWitch);
	HookEvents();
	
	SetRandomSeed(GetTime());
}

public OnMapStart()
{
	PrecacheModel(WITCH_MODEL, true);
	PrecacheWitchSounds();
	
	//save for resett
	global_spitterclawdmg = GetConVarInt(FindConVar("spitter_pz_claw_dmg"));
}

PrecacheWitchSounds()
{
	new i;
	new String:path[256];
	
	for (i = 0; i < 4; i++)
	{
		Format(path, sizeof(path), "%s%s%s", WITCH_SOUNDS_PATH, WITCH_SOUNDS_ATTACKING_PATH, witch_sound_attacking[i]);
		PrefetchSound(path);
		PrecacheSound(path);		
	}
	
	Format(path, sizeof(path), "%s%s%s", WITCH_SOUNDS_PATH, WITCH_SOUNDS_DYING_PATH, witch_sounds_dying);
	PrefetchSound(path);
	PrecacheSound(path);
	
	for (i = 0; i < 2; i++)
	{
		for (new j = 0; j < 4; j++)
		{
			Format(path, sizeof(path), "%s%s%s", WITCH_SOUNDS_PATH, WITCH_SOUNDS_IDLE_PATH, witch_sounds_idle[i][j]);
			PrefetchSound(path);
			PrecacheSound(path);		
		}
	}	
	
	for (i = 0; i < 3; i++)
	{
		Format(path, sizeof(path), "%s%s%s", WITCH_SOUNDS_PATH, WITCH_SOUNDS_PAIN_PATH, witch_sound_pain[i]);
		PrefetchSound(path);
		PrecacheSound(path);		
	}
	
	for (i = 0; i < 7; i++)
	{
		Format(path, sizeof(path), "%s%s%s", WITCH_SOUNDS_PATH, WITCH_SOUNDS_SUPRISED_PATH, witch_sound_suprised[i]);
		PrefetchSound(path);
		PrecacheSound(path);		
	}
}

HookEvents()
{
	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_Pre);
	HookEvent("witch_harasser_set", Event_WitchAttack, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Command_SpawnWitch(client, args)
{
	SpawnWitch(client);
}

SpawnWitch(client, bool:wandering = false)
{
	//TODO: wandering
	SpawnInfectedBoss(client, ZC_WITCH);
}

public Action:Event_WitchSpawn(Handle:event, String:name[], bool:nobroadcast)
{
	new infected[MAXPLAYERS];
	new infectedcounter = 0;
	
	global_witchent = GetEventInt(event, "witchid");
	global_witchplayer = -1;
	
	//select player
	for (new i = 1; i < MaxClients+1; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != 3) continue;
		if (IsFakeClient(i)) continue;

		if (!IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isGhost") == 0)
		{
			global_witchplayer = i;
			break;
		}
		else 
		{
			infected[infectedcounter] = i;
			infectedcounter++;
		}
	}
	
	//infected player?
	if (global_witchplayer == -1 && infectedcounter == 0) return;
	
	//found sb?
	if (global_witchplayer == -1) 
	{
		//choose 
		new choice = GetRandomInt(0, infectedcounter-1);
		global_witchplayer = infected[choice];
		
		//move to spec and back
		ChangeClientTeam(global_witchplayer, 1);
		ChangeClientTeam(global_witchplayer, 3);	
	}
	
	//hook sound and block all sound from player
	AddNormalSoundHook(BlockTankSounds);
	
	//spawn witch player
	SpawnInfectedBoss(global_witchplayer, ZC_TANK, true);
	SetEntityModel(global_witchplayer, WITCH_MODEL);
	
	//change claws
	RemovePlayerItem(global_witchplayer, GetPlayerWeaponSlot(global_witchplayer, 0));
		
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(global_witchplayer, "give spitter_claw");
	SetCommandFlags("give", flags);	
	
	//get witch pos
	new Float:witchangles[3], Float:witchpos[3];
	GetEntPropVector(global_witchent, Prop_Send, "m_angRotation", witchangles);
	GetEntPropVector(global_witchent, Prop_Send, "m_vecOrigin", witchpos);
	
	//move to witch
	TeleportEntity(global_witchplayer, witchpos, witchangles, {0.0, 0.0, 0.0});
	
	//freeze
	SetEntityMoveType(global_witchplayer, MOVETYPE_NONE);
	
	//start blocking attack (for spawning)
	SDKHook(global_witchplayer, SDKHook_PreThink, BlockSpawn);
	
	PrintToChat(global_witchplayer, "You will become the witch!!!");
	
	global_blockwitch = true;
	CreateTimer(1.0, BlockWitch);
}

public Action:BlockTankSounds(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	PrintToChatAll("%s", sample);

	if (entity == global_witchplayer) return Plugin_Stop;
	
	return Plugin_Continue;
}

public BlockSpawn(client)
{
	//PrintToChatAll("thinka");

	if (global_witchplayer != client) return;
	if (!IsClientInGame(client)) return;

	//PrintToChatAll("thinkb");
	
	new buttons = GetClientButtons(client);
	if(buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK;
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
	//PrintToChatAll("thinkc");
}

public Action:Event_WitchAttack(Handle:event, String:name[], bool:nobroadcast)
{
	if (!global_blockwitch) ReplaceWitch();
	else global_event = true;
}

public Action:BlockWitch(Handle:timer)
{
	global_blockwitch = false;
	
	if (global_event) ReplaceWitch();
	global_event = false;
}

ReplaceWitch()
{
	if (global_witchplayer == -1 || global_witchent == -1) return;
	
	//PrintToChatAll("a");
	
	//TODO: calculate witch damage/health
	//get witch health
	new health = GetConVarInt(FindConVar("z_witch_health"));

	//PrintToChatAll("b");
	
	//set players health
	SetEntProp(global_witchplayer, Prop_Send, "m_iHealth", health);

	//PrintToChatAll("c");
	
	//kill witch
	//RemoveEdict(global_witchent);
	AcceptEntityInput(global_witchent, "kill");

	//PrintToChatAll("d");
	
	//spawn player
	SetPlayerGhostStatus(global_witchplayer, false);

	//PrintToChatAll("e");
	
	//reset movement
	SetEntityMoveType(global_witchplayer, MOVETYPE_WALK);

	//PrintToChatAll("f");
	
	//set witch speed
	new spitterspeed = GetConVarInt(FindConVar("z_tank_speed_vs"));
	new witchspeed = GetConVarInt(FindConVar("z_witch_speed"));
	new Float:speed = FloatDiv(float(witchspeed), float(spitterspeed));
	SetEntPropFloat(global_witchplayer, Prop_Send, "m_flLaggedMovementValue", speed);
	
	//disable attackblock hook
	SDKUnhook(global_witchplayer, SDKHook_PreThink, BlockSpawn);

	//PrintToChatAll("g");
	
	//enable attack hook
	SDKHook(global_witchplayer, SDKHook_PreThink, WitchLogicPre);
	SDKHook(global_witchplayer, SDKHook_PostThink, WitchLogicPost);
	
	//enable death scratch
	global_witchdeathscratch = true;
}

public WitchLogicPre(client)
{
	if (global_witchplayer != client) return;
	if (!IsClientInGame(client)) return;
	
	new buttons = GetClientButtons(client);
	if(buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK;
		
	}
	
	if(buttons & IN_ATTACK2)
	{
		//buttons &= ~IN_ATTACK2;
		if (global_witchdeathscratch)
		{
			new flags = GetCommandFlags("spitter_pz_claw_dmg");
			SetCommandFlags("spitter_pz_claw_dmg", flags & ~FCVAR_CHEAT);
			ServerCommand("spitter_pz_claw_dmg 100");
			SetCommandFlags("spitter_pz_claw_dmg", flags);					
		}
	}
	
	SetEntProp(client, Prop_Data, "m_nButtons", buttons);
}

public WitchLogicPost(client)
{
	if (global_witchplayer != client) return;
	if (!IsClientInGame(client)) return;
	if (global_witchdeathscratch) return;
	if (GetConVarInt(FindConVar("spitter_pz_claw_dmg")) < 100) return;
	
	//PrintToChatAll("reset (%d)", global_spitterclawdmg);
	
	new flags = GetCommandFlags("spitter_pz_claw_dmg");
	SetCommandFlags("spitter_pz_claw_dmg", flags & ~FCVAR_CHEAT);
	ServerCommand("spitter_pz_claw_dmg %d", global_spitterclawdmg);
	SetCommandFlags("spitter_pz_claw_dmg", flags);	
}
	
public Action:Event_WitchKilled(Handle:event, String:name[], bool:nobroadcast)
{
}

public Action:Event_PlayerIncap(Handle:event, String:name[], bool:nobroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker != global_witchplayer) return Plugin_Continue;
	
	//freeze player (NEED more testing)
	SetEntityMoveType(global_witchplayer, MOVETYPE_NONE);
	
	//disable death scratch
	global_witchdeathscratch = false;
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:nobroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (global_witchplayer != client) return Plugin_Continue;
	
	SDKUnhook(global_witchplayer, SDKHook_PreThink, WitchLogicPre);
	SDKUnhook(global_witchplayer, SDKHook_PostThink, WitchLogicPost);
	
	global_witchplayer = -1;
	global_witchent = -1;
	
	return Plugin_Continue;
}