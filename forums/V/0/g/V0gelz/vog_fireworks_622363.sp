/*****************************************************************************************
 *  vog_fireworks.sma     version 1.4                 Date: 02/01/2010
 *   Author: V0gelz      frederik156@hotmail.com
 *   Original Idea: Eric Lidman aka Ludgwig Van
 *
 *   Shoots fireworks into the sky.
 *   The effects look best on bigger more open maps.
 *   Youtube movie: http://www.youtube.com/watch?v=gTBSEl6Frfw
 * 
 *   I'm adding effects but this is work in progress, if any of
 *   you have seen some cool effects that maybe could be used in
 *   this fireworks plugin let me know! PM me on sourcemod if you do.
 *   The effects look best on bigger more open maps.
 *
 *   Support For CS:S, TF2, DODS!
 *
 *  ADMIN COMMANDS:
 *
 *   sm_fireworks     		Sets fireworks off at random points on map.
 *   sm_fireworks_cancel    	Cancels the on going fireworks.
 *   sm_fireworks_sound		Toggles the sound of the explosions off and on.
 *
 *  CVARS (which can be set in the mod/cfg/sourcemod/sourcemod.cfg):
 *
 * 	sm_fireworks_noise 1		This sets whether your fireworks makes noise.
 *
 *	sm_fireworks_roundend 1  -- 0 = no fireworks display at round end in CS:S.
 *                               -- 1 = fireworks at round end.
 *
 *	sm_fireworks_field_size 1	How large the fireworks field size is,
 *					1 small/2 average/3 big
 *
 *	sm_fireworks_low_ceiling 1	Low ceiling map such as standard maps like de_dust, we put 1,
 *					big huge maps with a high ceiling, we put 0.
 *
 *  NOTE:
 *
 *   This plugin has room to grow. If you have ideas, let me know. Perhaps we
 *    can set off fireworks automatically on events like multikill
 *    or headshot. The possiblilities for attaching fireworks to game events
 *    are limitless. Check back often as new effects and options will be added.
 *
 *
 *  CREDITS:
 * 		Olly & Tsunami - for helping on the env_shooter problem.
 *		MatthiasVance - for info!
 * 		Silent_Water - Sphere code.
 *
 ****************************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

// Sprites
new g_ExplosionSprite;
new g_Smoke1;
new g_Smoke2;
new g_BlueGlowSprite;
new g_RedGlowSprite;
new g_GreenGlowSprite;
new g_YellowGlowSprite;
new g_PurpleGlowSprite;
new g_OrangeGlowSprite;
new g_WhiteGlowSprite;
new precache_fire_line;

// Handlers
new Handle:fireworks01;
new Handle:fireworks01_;
new SpawningFireworks;
new Handle:fireworks_roundend;
new Handle:fireworks_sound;
new Float:start_cor[3];
new Handle:Field_Size;
new Handle:low_ceiling;
new EndroundFireworks;
new round_start = 0;

// Game
new String:game_dir[30];

public Plugin:myinfo =
{
	name = "Fireworks",
	author = "V0gelz",
	description = "My firework plugin, thanks to Ludwigvan",
	version = PLUGIN_VERSION,
	url = "http://www.kittnz.be/css"
};

public OnPluginStart()
{
	GetGameFolderName(game_dir, 29);

	if( StrEqual(game_dir,"tf") )
	{
		// TF2
        	// Round Start Events
		HookEvent("teamplay_round_start", Event_teamplay_round_start);
		HookEvent("teamplay_round_win", Event_teamplay_round_win);
	}
	else if( StrEqual(game_dir,"dod") )
	{
		// DODS
		HookEvent("dod_round_win",DODS_RoundEnd);
		HookEvent("dod_round_start",RoundStart);
	}
	else
	{
		// CSS and L4D Round Events
		HookEvent("round_end",RoundEnd);
		HookEvent("round_start",RoundStart);
	}

	RegAdminCmd( "sm_fireworks",	fireworks,	ADMFLAG_CUSTOM2, "Fires fireworks in the sky till map ends." );
	RegAdminCmd( "sm_fireworks_cancel",	fireworks_cancel,	ADMFLAG_CUSTOM2, "Fires fireworks in the sky till map ends." );
	RegAdminCmd( "sm_fireworks_sound",	fireworks_sound_var,	ADMFLAG_CUSTOM2, "Toggles fireworks noise on and off." );

	fireworks_roundend = CreateConVar("sm_fireworks_roundend","1", "Fireworks at round end. 0/1", FCVAR_PLUGIN | FCVAR_NOTIFY);
	fireworks_sound = CreateConVar("sm_fireworks_noise","1", "Fireworks sounds. 0/1", FCVAR_PLUGIN | FCVAR_NOTIFY);
	Field_Size = CreateConVar("sm_fireworks_field_size","2", "How large the fireworks field size is, 1 small/2 average/3 big", FCVAR_PLUGIN | FCVAR_NOTIFY);
	low_ceiling = CreateConVar("sm_fireworks_low_ceiling","1", "Low ceiling maps is 1, big huge maps is 0", FCVAR_PLUGIN | FCVAR_NOTIFY);

	CreateConVar("sm_fireworks_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_pang01.mp3");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_shatter01.mp3");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark001.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark002.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark003.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark004.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark005.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark006.wav");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark007.mp3");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark008.mp3");
	AddFileToDownloadsTable("sound/ambient/fireworks/fireworks_spark009.mp3");

	// Sprites
	PrecacheModel("materials/sprites/blueflare1.vmt",true);	
	PrecacheModel("materials/effects/redflare.vmt",true);
	PrecacheModel("materials/sprites/yellowflare.vmt",true);
	PrecacheModel("materials/sprites/orangeflare1.vmt",true);
	PrecacheModel("materials/sprites/flare1.vmt",true);

	g_ExplosionSprite = PrecacheModel("materials/sprites/sprite_fire01.vmt",true);
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",true);
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",true);
	g_BlueGlowSprite = PrecacheModel("materials/sprites/blueglow1.vmt",true);
	g_RedGlowSprite = PrecacheModel("materials/sprites/redglow1.vmt",true);
	g_GreenGlowSprite = PrecacheModel("materials/sprites/greenglow1.vmt",true);
	g_YellowGlowSprite = PrecacheModel("materials/sprites/yellowglow1.vmt",true);
	g_PurpleGlowSprite = PrecacheModel("materials/sprites/purpleglow1.vmt",true);
	g_OrangeGlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt",true);
	g_WhiteGlowSprite = PrecacheModel("materials/sprites/glow1.vmt",true);
	precache_fire_line = PrecacheModel("materials/sprites/fire.vmt",true);

	// Sounds
	PrecacheSound( "ambient/fireworks/fireworks_pang01.mp3", true);
	PrecacheSound( "ambient/fireworks/fireworks_shatter01.mp3", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark001.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark002.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark003.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark004.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark005.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark006.wav", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark007.mp3", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark008.mp3", true);
	PrecacheSound( "ambient/fireworks/fireworks_spark009.mp3", true);

	CreateTimer(60.0, RealTimeUpdatePositions, _, TIMER_REPEAT);

	if (fireworks01_ != INVALID_HANDLE)
	{
		KillTimer(fireworks01_);
		fireworks01_ = INVALID_HANDLE;
	}
	if (fireworks01 != INVALID_HANDLE)
	{
		KillTimer(fireworks01);
		fireworks01 = INVALID_HANDLE;
	}
	SpawningFireworks = 0;
	EndroundFireworks = 0;
}

public OnMapEnd()
{
	if (fireworks01_ != INVALID_HANDLE)
	{
		KillTimer(fireworks01_);
		fireworks01_ = INVALID_HANDLE;
	}
	if (fireworks01 != INVALID_HANDLE)
	{
		KillTimer(fireworks01);
		fireworks01 = INVALID_HANDLE;
	}
	SpawningFireworks = 0;
	EndroundFireworks = 0;
}

//
//
// Game Events!
//
//

//
// Counter-Strike: Source Events & Left 4 Dead Events
// *l4d doesn't allow people to download from the server so no support for l4d yet.
// But if it comes it should be ready to use.
//
public Action:RoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new Float:fireworks_roundend_ = GetConVarFloat(fireworks_roundend);
	if(fireworks_roundend_ == 1.0)
	{
		//PrintToChatAll("CSS: Round Ended");
		fireworks01 = CreateTimer(0.1, fireworks_01, _, TIMER_REPEAT);
		SpawningFireworks = 1;
		EndroundFireworks = 1;
	}
        return Plugin_Continue;
}

public Action:RoundStart(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if(round_start == 0)
	{
		//PrintToChatAll("CSS: Round Started");
		round_start = 1;
		new Float:ROUND_START_TIME = 20.0;
		CreateTimer(ROUND_START_TIME, roundstartover);
	}
	CreateTimer(10.0, DelayonStart);
        return Plugin_Continue;
}

//
// Team Fortress 2 Events
//
public Action:Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
        new Float:fireworks_roundend_ = GetConVarFloat(fireworks_roundend);
	if(fireworks_roundend_ == 1.0)
	{
		//PrintToChatAll("TF2: Round Ended");
		fireworks01 = CreateTimer(0.1, fireworks_01, _, TIMER_REPEAT);
		SpawningFireworks = 1;
		EndroundFireworks = 1;
	}

        return Plugin_Continue;
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(round_start == 0)
	{
		//PrintToChatAll("TF2: Round started");
		round_start = 1;
		new Float:ROUND_START_TIME = 20.0;
		CreateTimer(ROUND_START_TIME, roundstartover);
	}
	CreateTimer(20.0, DelayonStart);

	return Plugin_Continue;
}

//
// Day of Defeat: Source Events
//
public Action:DODS_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
        new Float:fireworks_roundend_ = GetConVarFloat(fireworks_roundend);
	if(fireworks_roundend_ == 1.0)
	{
		//PrintToChatAll("DODS: Round ended");
		fireworks01 = CreateTimer(0.1, fireworks_01, _, TIMER_REPEAT);
		SpawningFireworks = 1;
		EndroundFireworks = 1;
	}

        return Plugin_Continue;
}

public Action:DODS_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(round_start == 0)
	{
		//PrintToChatAll("DODS: Round started");
		round_start = 1;
		new Float:ROUND_START_TIME = 20.0;
		CreateTimer(ROUND_START_TIME, roundstartover);
	}
	CreateTimer(20.0, DelayonStart);

	return Plugin_Continue;
}

public Action:roundstartover(Handle:timer)
{
	round_start = 0;
}

public Action:DelayonStart(Handle:timer)
{
	if (fireworks01_ != INVALID_HANDLE)
	{
		KillTimer(fireworks01_);
		fireworks01_ = INVALID_HANDLE;
	}
	if (fireworks01 != INVALID_HANDLE)
	{
		KillTimer(fireworks01);
		fireworks01 = INVALID_HANDLE;
	}
	SpawningFireworks = 0;
	EndroundFireworks = 0;
}

public Action:RealTimeUpdatePositions(Handle:timer)
{
	new iMaxClients = GetMaxClients();
	
	for (new i = 1; i <= iMaxClients; i++)
	{
		// Position Check
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, start_cor);
		}
	}
}

public Action:fireworks( client, args )
{
	if(round_start == 1)
	{
		PrintToConsole(client, "[SM] It will be a little longer captain, the fireworks machine is malfunctioning.");
		return Plugin_Handled;
	}
	if(SpawningFireworks)
	{
		PrintToConsole(client, "[SM] Fireworks allready in progress.");
		return Plugin_Handled;
	}
	if(EndroundFireworks)
	{
		PrintToConsole(client, "[SM] End round fireworks is still active, wait a few seconds.");
		return Plugin_Handled;
	}	

	new String:User[32];
	GetClientName(client,User,sizeof(User));

	PrintToServer("[Fireworks] Admin: %s has fired some fireworks in the server.", User);

	PrintToChatAll("[SM]  Oooooo! Ahhhhh!  Fireworks!");

	fireworks01_ = CreateTimer(0.1, fireworks_01, client, TIMER_REPEAT);

	SpawningFireworks = 1;

	return Plugin_Handled;
}

public Action:fireworks_cancel( client, args )
{
	if(!SpawningFireworks)
	{
		PrintToConsole(client,"[SM] Fireworks are not in progress");
		return Plugin_Handled;
	}
	if (fireworks01_ != INVALID_HANDLE)
	{
		KillTimer(fireworks01_);
		fireworks01_ = INVALID_HANDLE;
	}

	SpawningFireworks = 0;
	new String:User[32];
	GetClientName(client,User,sizeof(User));

	PrintToChatAll("[SM]  Awww, no more fireworks.");
	PrintToServer("[Fireworks] Admin: %s has canceled the fireworks in the server.", User);

	return Plugin_Handled;
}

public Action:fireworks_sound_var( client, args )
{
	new Float:fireworks_sound_ = GetConVarFloat(fireworks_sound);
	if(fireworks_sound_ == 1){
		SetConVarFloat(fireworks_sound, 0.0);
		PrintToChatAll("[SM] Fireworks sound is now OFF");
	}
	else{
		SetConVarFloat(fireworks_sound, 1.0);
		PrintToChatAll("[SM] Fireworks sound is now ON");
	}

	return Plugin_Handled;
}

public Action:fireworks_01(Handle:timer, any:client)
{
	new Float:rorigin[3];
	new rand = GetRandomInt(0,2);
	new Field_Size_ = GetConVarInt(Field_Size);
	new lowceiling = GetConVarInt(low_ceiling);

	rorigin = start_cor;
	
	if(Field_Size_ == 2) // avarage
	{
		rorigin[0] += GetRandomFloat(-3200.0,3000.0);
		rorigin[1] += GetRandomFloat(-3200.0,3000.0);
	}
	if(Field_Size_ == 3) // big
	{
		rorigin[0] += GetRandomFloat(-4200.0,4000.0);
		rorigin[1] += GetRandomFloat(-4200.0,4000.0);
	}
	else // small
	{
		rorigin[0] += GetRandomFloat(-2200.0,2200.0);
		rorigin[1] += GetRandomFloat(-2200.0,2200.0);
	}

	// Effects
	switch(rand)
	{
		// Normal sparks with some smoke and a sound
		case 0:
		{	
			if(lowceiling)
				rorigin[2] += GetRandomFloat(-100.0,200.0);
			else
				rorigin[2] += GetRandomFloat(-800.0,1000.0);

			sound(rorigin);
			//explode(rorigin);
			smoke(rorigin);
			spark(rorigin);
		}
		// The real lookalike fireworks explosions.
		// Sprites, sparks, smoke and a fire line.
		case 1:
		{
			if(lowceiling)
				rorigin[2] += GetRandomFloat(-50.0,200.0);
			else
				rorigin[2] += GetRandomFloat(-250.0,600.0);

			FireSprites(rorigin);

			//CreateTimer(0.1, Fire_Spriteworks01, rorigin);
			//CreateTimer(0.6, Fire_Spriteworks02, rorigin);
		}
		// The sprites that fly all over the map.
		// They are the balls you see flying around.
		case 2:
		{
			if(lowceiling)
			{
				rorigin[2] += GetRandomFloat(-10.0,10.0);
			}
			else
			{
				rorigin[2] += GetRandomFloat(-500.0,500.0);
			}
			
	
			//if(GetClientCount() > 0){
			
			// env_shooter seems to crash for ep2 games at the moment.
			// I hope i have this fixed soon. till then only css has env_shooter entity.
			if((GetClientCount() > 0) /*&& !StrEqual(game_dir,"tf") && !StrEqual(game_dir,"dod")*/ ){
				SpritesShooter(rorigin, client);
			}
			else{
				FireSprites(rorigin);
			}
		}
	}
}

public Action:Fire_Spriteworks01(Handle:timer, Float:vec[3])
{
	new Float:vec2[3];
	vec2 = vec;
	vec2[2] = vec[2] + 300.0;
	fire_line(vec,vec2);
}

public Action:Fire_Spriteworks02(Handle:timer, Float:vec[3])
{
	new Float:vec2[3];
	vec2 = vec;
	vec2[2] = vec[2] + 300.0;
	sound(vec2);
	sphere(vec2);
}

public FireSprites(Float:vec[3])
{
	new Float:vec2[3];
	vec2 = vec;
	vec2[2] = vec[2] + 300.0;
	fire_line(vec,vec2);
	sound(vec2);
	//explode(vec2);
	sphere(vec2);
	spark(vec2);
}

public fire_line(Float:startvec[3],Float:endvec[3])
{
	new color[4]={255,255,255,200};
	TE_SetupBeamPoints( startvec,endvec, precache_fire_line, 0, 0, 0, 0.8, 2.0, 1.0, 1, 0.0, color, 10);
	TE_SendToAll();
}

public sphere(Float:vec[3])
{
	new Float:rpos[3], Float:radius, Float:phi, Float:theta, Float:live, Float: size, Float:delay;
	new Float:direction[3];
	new Float:spos[3];
	new bright = 255;
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	radius = GetRandomFloat(75.0,150.0);
	new rand = GetRandomInt(0,6);
	for (new i=0;i<50;i++)
	{
		delay = GetRandomFloat(0.0,0.5);
		bright = GetRandomInt(128,255);
		live = 2.0 + delay;
		size = GetRandomFloat(0.5,0.7);
		phi = GetRandomFloat(0.0,6.283185);
		theta = GetRandomFloat(0.0,6.283185);
		spos[0] = radius*Sine(phi)*Cosine(theta);
		spos[1] = radius*Sine(phi)*Sine(theta);
		spos[2] = radius*Cosine(phi);
		rpos[0] = vec[0] + spos[0];
		rpos[1] = vec[1] + spos[1];
		rpos[2] = vec[2] + spos[2];

		switch(rand)
		{
			case 0:	TE_SetupGlowSprite(rpos, g_BlueGlowSprite,live, size, bright);
			case 1:	TE_SetupGlowSprite(rpos, g_RedGlowSprite,live, size, bright);
			case 2: TE_SetupGlowSprite(rpos, g_GreenGlowSprite,live, size, bright);
			case 3: TE_SetupGlowSprite(rpos, g_YellowGlowSprite,live, size, bright);
			case 4: TE_SetupGlowSprite(rpos, g_PurpleGlowSprite,live, size, bright);
			case 5: TE_SetupGlowSprite(rpos, g_OrangeGlowSprite,live, size, bright);
			case 6: TE_SetupGlowSprite(rpos, g_WhiteGlowSprite,live, size, bright);
		}
		TE_SendToAll(delay);
	}
}

public explode(Float:vec[3])
{
	TE_SetupExplosion(vec, g_ExplosionSprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
}

public spark(Float:vec[3])
{
	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}

public smoke(Float:vec[3])
{
	new Float:smokescale = 100.0;
	new smokeframerate = 2;
	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSmoke(vec, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(vec, g_Smoke2, smokescale, smokeframerate);
	TE_SetupDust(vec, dir, 100.0, 10.0);
	TE_SendToAll();
}

public sound(Float:vec[3])
{
	new Float:fireworks_sound_ = GetConVarFloat(fireworks_sound);
	if(fireworks_sound_ == 1)
	{
		new rand = GetRandomInt(0,9);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("ambient/fireworks/fireworks_pang01.mp3", vec);
			case 1: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark001.wav", vec);
			case 2: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark002.wav", vec);
			case 3: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark003.wav", vec);
			case 4: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark004.wav", vec);
			case 5: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark005.wav", vec);
			case 6: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark006.wav", vec);
			case 7: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark007.mp3", vec);
			case 8: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark008.mp3", vec);
			case 9: EmitSoundFromOrigin("ambient/fireworks/fireworks_spark009.mp3", vec);
		}
	}
}

public	SpritesShooter(Float:vec[3], client)
{
	new Float:dir[3]={-90.0,0.0,0.0};
	new Float:fireworks_sound_ = GetConVarFloat(fireworks_sound);
	if(fireworks_sound_ == 1)
	{
		EmitSoundFromOrigin("ambient/fireworks/fireworks_shatter01.mp3", vec);
	}

	// The random with the switch seems to crash the client.
	// If the material stays the same it doesn't crash the client.
	// 
	// This worked in ep1 and now everything is ep2 and doesn't seem to work anymore.
	// Using flare1 for the moment.

	/*new rand = GetRandomInt(0,4);
	switch(rand)
	{
		case 0:	env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/sprites/blueflare1.vmt");
		case 1:	env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/effects/redflare.vmt");
		case 2: env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/sprites/yellowflare.vmt");
		case 3: env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/sprites/orangeflare1.vmt");
		case 4: env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/sprites/flare1.vmt");
	}*/

	env_shooter(client, dir, 2.0, 0.1, dir, 1200.0, 1.0, 2.5, vec, "materials/sprites/flare1.vmt");
}

stock env_shooter(client ,Float:Angles[3], Float:iGibs, Float:Delay, Float:GibAngles[3], Float:Velocity, Float:Variance, Float:Giblife, Float:Location[3], String:ModelType[] )
{
	//decl Ent;

	//Initialize:
	new Ent = CreateEntityByName("env_shooter");
		
	//Spawn:

	if (Ent == -1)
	return;

  	//if (Ent>0 && IsValidEdict(Ent))

	if(Ent>0 && IsValidEntity(Ent) && IsValidEdict(Ent))
  	{

		//Properties:
		//DispatchKeyValue(Ent, "targetname", "flare");

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Ent, "angles", Angles);
	
		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Ent, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Ent, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Ent, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Ent, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Ent, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Ent, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Ent, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Ent, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Ent, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Ent, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Ent,"AddOutput");

		ActivateEntity(Ent);

		//Input:
		// Shoot!
		AcceptEntityInput(Ent, "Shoot", client);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		CreateTimer(3.0, KillEnt, Ent);
	}
}

public Action:KillEnt(Handle:Timer, any:Ent)
{
        if(IsValidEntity(Ent))
        {
                decl String:classname[64];
                GetEdictClassname(Ent, classname, sizeof(classname));
                if (StrEqual(classname, "env_shooter", false) || StrEqual(classname, "gib", false) || StrEqual(classname, "env_sprite", false))
                {
                        RemoveEdict(Ent);
                }
        }
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
