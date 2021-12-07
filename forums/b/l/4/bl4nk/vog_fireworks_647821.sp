/*****************************************************************************
 * vog_fireworks.sma     version 0.6                  Date: 6/5/2008
 *  Author: V0gelz and Eric Lidman      frederik156@hotmail.com
 *  Upgrade: http://dekaftgent.be/css/plugins.html
 *
 *  Shoots fireworks into the sky.
 *   I'm adding effects but this is work in progress, if any of
 *   you have seen some cool effects that maybe could be used in
 *   this fireworks plugin let me know! PM me on sourcemod if you do.
 *   The effects look best on bigger more open maps.
 *   This plugin is mainly designed for css. I will prob add more support for
 *   it later on if it is requested.
 *
 *  ADMIN COMMANDS:
 *
 *   sm_fireworks     		<time in seconds or 0 to stop>
 *                     		Sets fireworks off at random points on map.
 *   sm_fireworks_cancel    	<time in seconds or 0 to stop>
 *                     		Cancels the on going fireworks.
 *
 *  CVARS (which can be set in the mod/cfg/sourcemod/sourcemod.cfg):
 *
 * 	sm_fireworks_noise 1     -- 0 or 1, this sets whether your fireworks
 *                             		make noise by default.
 *	sm_fireworks_roundend 1  -- 0 = no fireworks display at round end in CS:S.
 *                               -- 1 = fireworks at round end.
 *
 *  NOTE:
 *
 *   This plugin has room to grow. If you have ideas, let me know. Perhaps we
 *    can set off fireworks automatically on events like multikill
 *    or headshot. The possiblilities for attaching fireworks to game events
 *    are limitless. Check back often as new effects and options will be added.
 *
 *****************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.6a"

new g_ExplosionSprite;

new Handle:fireworks01;
new Handle:fireworks01_;
new SpawningFireworks;
new Float:mapadjust;
new Handle:fireworks_roundend;
new Handle:fireworks_sound;

public Plugin:myinfo =
{
	name = "Fireworks",
	author = "V0gelz",
	description = "My firework plugin, thanks to Ludwigvan",
	version = PLUGIN_VERSION,
	url = "http://www.dekaftgent.be/css"
};

public OnPluginStart()
{
	HookEvent("round_end",RoundEnd);
	HookEvent("round_start",RoundStart);
	RegAdminCmd( "sm_fireworks",	fireworks,	ADMFLAG_CUSTOM2, "Fires fireworks in the sky till map ends." );
	RegAdminCmd( "sm_fireworks_cancel",	fireworks_cancel,	ADMFLAG_CUSTOM2, "Fires fireworks in the sky till map ends." );

	fireworks_roundend = CreateConVar("sm_fireworks_roundend","1", "Fireworks at round end. 0/1", FCVAR_PLUGIN);
	fireworks_sound = CreateConVar("sm_fireworks_noise","1", "Fireworks sounds at round end. 0/1", FCVAR_PLUGIN);

	CreateConVar("sm_fireworks_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

	CreateTimer(0.1, adjust_range, _, TIMER_REPEAT);
}

public Action:adjust_range(Handle:timer)
{
	new Float:lowest;
	new maxplayers=GetMaxClients();
	for(new x=1;x<=maxplayers;x++)
	{
		if(IsClientConnected(x) && IsClientInGame(x))
		{
			new Float:origin[3];
			GetClientAbsOrigin(x, origin);
			if(lowest > origin[2])
			{
				lowest = origin[2];
			}
		}
	}
	if(mapadjust > lowest)
	{
		mapadjust = lowest;
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
	PrecacheSound( "weapons/mortar/mortar_explode1.wav", true);
	PrecacheSound( "weapons/mortar/mortar_explode2.wav", true);
	PrecacheSound( "weapons/mortar/mortar_explode3.wav", true);
}

public RoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new Float:fireworks_roundend_ = GetConVarFloat(fireworks_roundend);
	if(fireworks_roundend_ == 1)
	{
		fireworks01 = CreateTimer(0.1, fireworks_01, _, TIMER_REPEAT);
		SpawningFireworks = 1;
	}
}

public RoundStart(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if(SpawningFireworks==1)
	{
		if (fireworks01_ != INVALID_HANDLE)
		{
			KillTimer(fireworks01_);
			fireworks01_ = INVALID_HANDLE;
		}
	}

	if (fireworks01 != INVALID_HANDLE)
	{
		KillTimer(fireworks01);
		fireworks01 = INVALID_HANDLE;
	}

	SpawningFireworks = 0;
}

public Action:fireworks( client, args )
{
	if(SpawningFireworks)
	{
		PrintToConsole(client, "[SM] Fireworks are allready in progress");
		return Plugin_Handled;
	}

	new String:User[32];
	GetClientName(client,User,sizeof(User));

	PrintToServer("[Fireworks] Admin: %s has fired some fireworks in the server.", User);

	PrintToChatAll("[SM]  Oooooo! Ahhhhh!  Fireworks!");

	fireworks01_ = CreateTimer(0.1, fireworks_01, _, TIMER_REPEAT);

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

public Action:fireworks_01(Handle:timer)
{
	new Float:rorigin[3];

	rorigin[0] = GetRandomFloat(-2200.0,2200.0);
	rorigin[1] = GetRandomFloat(-2200.0,2200.0);
	rorigin[2] = GetRandomFloat(100.0,1400.0) + mapadjust;

	rorigin[0] = rorigin[0] * -1;

	// Switching effects
	// To do:
	// Add more effects...
	// only has 2 effects atm.
	new rand = GetRandomInt(0,1);
	switch(rand)
	{
		case 0: explode(rorigin);
		case 1: spark(rorigin);
	}

	//PrintToChatAll("Firework spawned at: %d  %d  %d",rorigin[0], rorigin[1], rorigin[2]);
}

public explode(Float:vec[3])
{
	new Float:fireworks_sound_ = GetConVarFloat(fireworks_sound);
	if(fireworks_sound_ == 1)
	{
		new rand = GetRandomInt(0,3);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec);
			case 1: EmitSoundFromOrigin("weapons/mortar/mortar_explode1.wav", vec);
			case 2: EmitSoundFromOrigin("weapons/mortar/mortar_explode2.wav", vec);
			case 3: EmitSoundFromOrigin("weapons/mortar/mortar_explode3.wav", vec);
		}
	}

	TE_SetupExplosion(vec, g_ExplosionSprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
}

public spark(Float:vec[3])
{
	new Float:fireworks_sound_ = GetConVarFloat(fireworks_sound);
	if(fireworks_sound_ == 1)
	{
		new rand = GetRandomInt(0,3);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec);
			case 1: EmitSoundFromOrigin("weapons/mortar/mortar_explode1.wav", vec);
			case 2: EmitSoundFromOrigin("weapons/mortar/mortar_explode2.wav", vec);
			case 3: EmitSoundFromOrigin("weapons/mortar/mortar_explode3.wav", vec);
		}
	}

	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSparks(vec, dir, 500, 2);
	TE_SendToAll();
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
