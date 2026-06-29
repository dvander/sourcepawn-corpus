/***************************************************************************
 *  vog_wildride.sp         version 0.9.4                Date: 12/12/2008
 *   Author: Frederik        frederik156@hotmail.com
 *   Alias: V0gelz           Upgrade: http://www.sourcemod.com
 *   Original Idea: Eric Lidman aka Ludgwig Van
 *
 *   Support for all mods.
 *
 * COMMANDS:
 * 
 *    sm_wildride <name or all/t/ct/red/blue>
 *
 *   sm_wildride is a fun slay command that shuffs someone in the air
 *   and drops them to the ground. There are a few effects in it as gibs
 *   some sounds very funny if you see one flying around.
 *   If you have any more ideas post it in the thread at sourcemod forums.
 *
 *   Thanks to Pinkfairie, SAMURAI16 and raydan for help and gib code.
 *
 **************************************************************************/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION "0.9.4"

// Global vars
new gravity[65];
new isUp[65];

// Sprites
new white;
new g_HaloSprite;
new g_ExplosionSprite;

public Plugin:myinfo = 
{
	name = "The Wild Ride",
	author = "V0gelz",
	description = "The Wild Ride - Idea by Ludwig van",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	HookEvent("player_death", EventDeath);
	HookEvent("player_hurt", EventDamage);

	CreateConVar("sm_wildride_version", PLUGIN_VERSION, "Wild Ride Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_wildride", Command_Wild_Ride, ADMFLAG_SLAY, "sm_wildride <name or all/t/ct> - The Wild Ride (Very funny!)");
}

public OnMapStart()
{
	// Sounds
	PrecacheSound( "ambient/voices/f_scream1.wav", true);
	PrecacheSound( "vo/k_lab/kl_ahhhh.wav", true);
	PrecacheSound( "ambient/fallscream.wav", true);
	PrecacheSound( "weapons/explode3.wav", true);
	PrecacheSound( "weapons/explode4.wav", true);
	PrecacheSound( "weapons/explode5.wav", true);

	// Sound Downloads
	AddFileToDownloadsTable("sound/ambient/fallscream.wav");

	// Models
	PrecacheModel("models/Gibs/HGIBS.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_rib.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_spine.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_scapula.mdl", true);

	// Sprites
	white=PrecacheModel("materials/sprites/white.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
}

public Action:Command_Wild_Ride(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM]  sm_wildride <name or all/t/ct>");
		return Plugin_Handled;
	}

	new String:szArg[65];
	GetCmdArg(1, szArg, sizeof(szArg));

	if(strcmp(szArg, "all", false) == 0)
	{
		PrintCenterTextAll("Everyone is going for a wild ride!");
		PrintHintTextToAll("Everyone is going for a wild ride!");
		PrintToChatAll("[SM] Everyone is going for a wild ride!");

		new iMaxClients = GetMaxClients();
		
		for (new i = 1; i <= iMaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				CreateTimer(1.0, wildride_step01, i);
				CreateTimer(2.0, wildride_step1, i);
				CreateTimer(4.0, wildride_step3, i);
				CreateTimer(5.5, check_water, i);
				CreateTimer(6.0, wildride_step4, i);
				isUp[i] = 1;
			}
		}
	}
	else if(strcmp(szArg, "t", false) == 0 || strcmp(szArg, "ct", false) == 0 || strcmp(szArg, "red", false) == 0|| strcmp(szArg, "blue", false) == 0)
	{
		PrintCenterTextAll("A team is going for a wild ride!");
		PrintHintTextToAll("A team is going for a wild ride!");
		PrintToChatAll("[SM] A team is going for a wild ride!");

		new iMaxClients = GetMaxClients();
		
		for (new i = 1; i <= iMaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if(GetClientTeam(i) == (strcmp(szArg, "t", false) == 0 || strcmp(szArg, "red", false) == 0 ? 2 : 3))
				{
					CreateTimer(1.0, wildride_step01, i);
					CreateTimer(2.0, wildride_step1, i);
					CreateTimer(4.0, wildride_step3, i);
					CreateTimer(5.5, check_water, i);
					CreateTimer(6.0, wildride_step4, i);
					isUp[i] = 1;
				}
			}
		}
		
	}
	else
	{
		new iClients[2];
		new iNumClients = SearchForClients(szArg, iClients, 2);

		if (iNumClients == 0)
		{
			ReplyToCommand(client, "[SM]  The wild rider can't find that guy.");
			return Plugin_Handled;
		}
		else if (iNumClients > 1)
		{
			ReplyToCommand(client, "[SM]  More than one person matches the description you gave the wild rider.", szArg);
			return Plugin_Handled;
		}
		else if (!CanUserTarget(client, iClients[0]))
		{
			ReplyToCommand(client, "[SM]  I can't find the guy man!");
			return Plugin_Handled;
		}
		else if (isUp[iClients[0]] == 1)
		{
			ReplyToCommand(client, "[SM]  That guy is allready having fun!!!");
			return Plugin_Handled;
		}
		else if (!IsPlayerAlive(iClients[0]))
		{
			ReplyToCommand(client, "[SM]  That guy isn't alive for a ride.");
			return Plugin_Handled;
		}

		new String:User[32];
		GetClientName(iClients[0],User,64);
		
		// Text
		PrintCenterTextAll("%s is going for a wild ride!",User);
		PrintHintTextToAll("%s is going for a wild ride!",User);
		PrintToChatAll("[SM] %s is going for a wild ride!",User);

		// Timers
		CreateTimer(1.0, wildride_step01, iClients[0]);
		CreateTimer(2.0, wildride_step1, iClients[0]);
		CreateTimer(4.0, wildride_step3, iClients[0]);
		CreateTimer(5.5, check_water, iClients[0]);
		CreateTimer(6.0, wildride_step4, iClients[0]);

		isUp[iClients[0]] = 1;
	}

	return Plugin_Handled;
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl client;
	new Float:wxyz[3];
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	GetClientAbsOrigin(client, wxyz);

	new String:User[32];
	GetClientName(client,User,64);

	if(isUp[client] == 1)
	{
		// Sparks
		new Float:test[3];
		TE_SetupSparks(wxyz,test,255,2);
		TE_SendToAll();

		// Explode
		explode(wxyz);
		
		// Gibs
		Gib(client, "models/Gibs/HGIBS.mdl",2);
		Gib(client, "models/Gibs/HGIBS_spine.mdl",2);
		Gib(client, "models/Gibs/HGIBS_rib.mdl",2);
		Gib(client, "models/Gibs/HGIBS_scapula.mdl",2);
		
		// Shake
		env_shake(client, 8.0, 2000.0, 10.0, 150.0);
	
		// Text
		PrintCenterTextAll("%s died of a terrible fall.",User);
		PrintHintTextToAll("%s died of a terrible fall.",User);
		PrintToChatAll("[SM] %s died of a terrible fall.",User);
	}

	CloseHandle(Event);
}	

public EventDamage(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(isUp[client] == 1)
	{
		SetEntityHealth(client, 0);
	}
	CloseHandle(Event);
}
	
public Action:wildride_step01(Handle:timer, any:client)
{
	new Red = GetRandomInt(1,255);
	new Green = GetRandomInt(1,255);
	new Blue = GetRandomInt(1,255);

	// Set renderstate
	// For effects
	SetEntityRenderColor(client, Red, Green, Blue, 255);
	SetEntityRenderFx(client, RENDERFX_GLOWSHELL); // RENDERFX_GLOWSHELL, RENDERFX_HOLOGRAM
}

public Action:wildride_step1(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin( client, wxyz );
	wxyz[2] += 30.0;
	TeleportEntity( client, wxyz, NULL_VECTOR, NULL_VECTOR );

	// Save his gravity parameters
	gravity[client] = GetEntityGravity( client );

	// Set gravity
	SetEntityGravity( client, -50.0 );
}


public Action:wildride_step3(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin( client, wxyz );
	new rand = GetRandomInt(0,2);
	switch(rand)
	{
		case 0: EmitSoundFromOrigin("ambient/voices/f_scream1.wav", wxyz);
		case 1: EmitSoundFromOrigin("vo/k_lab/kl_ahhhh.wav", wxyz);
		case 2: EmitSoundFromOrigin("ambient/fallscream.wav", wxyz);
	}
	SetEntityGravity( client, 30.0 );
}

public Action:wildride_step4(Handle:timer, any:client)
{
	// Reset Gravity
	SetEntityGravity( client, gravity[client] );

	// Reset color and fx
	SetEntityRenderFx(client, RENDERFX_NONE);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	// Client isn't riding anymore.
	isUp[client] = 0;
}

public Action:check_water(Handle:timer, any:client)
{
	if(isUp[client] == 1 && GetEntityFlags(client) & FL_INWATER)
	{
		ForcePlayerSuicide(client);
	}
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

// Effects!
//
// Gib Effects
// Taken from Gore Mod plugin.
// Credits to Pinkfairie. with a little tweak by myself ofc :p
//
stock Gib(Client, String:Model[], Amount = 1)
{
	//Loop:
	for(new X = 0; X < Amount; X++)
	{
		//Declare:
		decl Ent, Float:MaxEnts;

		//Initialize:
		Ent = CreateEntityByName("prop_physics");
		MaxEnts = 0.9 * GetMaxEntities();
		
		//Anti-Crash:
		if(Ent < MaxEnts)
		{
			//Declare:
			decl CollisionOffset;
			decl Float:ClientOrigin[3];

			//Properties:
			DispatchKeyValue(Ent, "model", Model);

			//Spawn:
			DispatchSpawn(Ent);

			//Collision:
			CollisionOffset = GetEntSendPropOffs(Ent, "m_CollisionGroup");
			if(IsValidEntity(Ent)) SetEntData(Ent, CollisionOffset, 1, 1, true);

			//Origin:
			GetClientAbsOrigin(Client, ClientOrigin);
		
			//Send:
			TeleportEntity(Ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR);

			//Delete:
			CreateTimer(30.0, KillEnt, Ent);
		}
	}
}

public Action:KillEnt(Handle:Timer, any:Ent)
{
	//Kill:
	if(IsValidEdict(Ent)) AcceptEntityInput(Ent, "Kill", 0);
}

stock env_shake(client, Float:Amplitude, Float:Radius, Float:Duration, Float:Frequency)
{
	decl Ent;
	decl Float:ClientOrigin[3];

	//Initialize:
	Ent = CreateEntityByName("env_shake");
		
	//Spawn:
	if(DispatchSpawn(Ent))
	{
		//Properties:
		DispatchKeyValueFloat(Ent, "amplitude", Amplitude);
		DispatchKeyValueFloat(Ent, "radius", Radius);
		DispatchKeyValueFloat(Ent, "duration", Duration);
		DispatchKeyValueFloat(Ent, "frequency", Frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(Ent,"AddOutput");

		//Input:
		AcceptEntityInput(Ent, "StartShake", client);
	
		//Origin:
		GetClientAbsOrigin(client, ClientOrigin);
		
		//Send:
		TeleportEntity(Ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		CreateTimer(30.0, KillEnt, Ent);
	}
}
// My explode!
stock explode(Float:vec1[3])
{
	new color[4]={188,220,255,200};

	new rand = GetRandomInt(0,2);
	switch(rand)
	{
		case 0: EmitSoundFromOrigin("weapons/explode3.wav", vec1);
		case 1: EmitSoundFromOrigin("weapons/explode4.wav", vec1);
		case 2: EmitSoundFromOrigin("weapons/explode5.wav", vec1);
	}
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, white, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}