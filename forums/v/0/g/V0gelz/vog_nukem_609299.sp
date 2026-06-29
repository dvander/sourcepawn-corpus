/********************************************************************************
 *  vog_nukem.sma         version 1.2.7                Date: 13/12/2008
 *   Author: Frederik        frederik156@hotmail.com
 *   Alias: V0gelz           Upgrade: http://www.sourcemod.com
 *   Original Idea: Eric Lidman aka Ludgwig Van
 *
 *
 * COMMANDS:
 * 
 *    sm_nukem
 *    sm_nukem_jk
 *
 *  sm_nukem is a slayall command that calls on lots of special effects in
 *   in the process. sm_nukem_jk is the "just kidding" version of the nuke.
 *   Its non-lethal, and just does the explosions and FX which includes 2 
 *   screen shakes, howling people suffereing, and a whole lot of fire and
 *   explosions.
 *
 *   Thanks to Davethegreat and L. Duke for help with the shake effect.
 *
 **************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.7"

#define FADE_IN  0x0001
#define FADE_OUT 0x0002

// Global vars
new BOMB_FUSE = 16;        // fuse time - 10
new bool:bIsNuking = false;
new bool:lethal = true;
new nuke_tmr;

new Float:start_cor[3];

// Textures
new fire;
new white;
new g_HaloSprite;
new g_ExplosionSprite;

public Plugin:myinfo =
{
	name = "Nuke the world!",
	author = "V0gelz",
	description = "NUKEM!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("round_end",RoundEnd);
	CreateTimer(1.0, nuke_timer, _, TIMER_REPEAT);
	RegAdminCmd( "sm_nukem",	Command_Nukem,	ADMFLAG_SLAY, "blows everyone up except you in a firestorm of explosions." );
	RegAdminCmd( "sm_nukem_jk",	Command_Nukem_jk,	ADMFLAG_SLAY, "does the nukem count down and FX, but doesnt kill anyone." );
	CreateConVar("sm_nukem_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

public OnMapStart()
{
	// Sprites
	fire=PrecacheModel("materials/sprites/fire2.vmt");
	white=PrecacheModel("materials/sprites/white.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");

	// Sounds
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
	PrecacheSound( "ambient/machines/aircraft_distant_flyby3.wav", true);
	PrecacheSound( "misc/horror/the_horror1.wav",true);
	PrecacheSound( "misc/horror/the_horror2.wav",true);
	PrecacheSound( "misc/horror/the_horror3.wav",true);
	PrecacheSound( "misc/horror/the_horror4.wav",true);
	PrecacheSound( "vox/alert.wav", true);
	PrecacheSound( "vox/atomic.wav", true);
	PrecacheSound( "vox/weapon.wav", true);
	PrecacheSound( "vox/detected.wav", true);
	PrecacheSound( "fvox/range.wav", true);
	PrecacheSound( "hl1/fvox/five.wav", true);
	PrecacheSound( "fvox/four.wav", true);
	PrecacheSound( "fvox/three.wav", true);
	PrecacheSound( "fvox/two.wav", true);
	PrecacheSound( "fvox/one.wav", true);

	// Sound downloads
	AddFileToDownloadsTable("sound/vox/alert.wav");
	AddFileToDownloadsTable("sound/vox/atomic.wav");
	AddFileToDownloadsTable("sound/vox/weapon.wav");
	AddFileToDownloadsTable("sound/vox/detected.wav");
	AddFileToDownloadsTable("sound/fvox/range.wav");
	
	AddFileToDownloadsTable("sound/fvox/four.wav");
	AddFileToDownloadsTable("sound/fvox/three.wav");
	AddFileToDownloadsTable("sound/fvox/two.wav");
	AddFileToDownloadsTable("sound/fvox/one.wav");
	AddFileToDownloadsTable("sound/misc/horror/the_horror1.wav");
	AddFileToDownloadsTable("sound/misc/horror/the_horror2.wav");
	AddFileToDownloadsTable("sound/misc/horror/the_horror3.wav");
	AddFileToDownloadsTable("sound/misc/horror/the_horror4.wav");
}

public RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(bIsNuking == true)
	{
		blowem_up();
	}

//	return Plugin_Handled;
}

public Action:Command_Nukem( client, args )
{
	if(bIsNuking == true)
	{
		PrintToConsole(client,"[SM] The nuke is already in progress");
		return Plugin_Handled;
	}

	if(client==0) // Console Nuke
	{
		//PrintToConsole(client,"[SM] A nuke can not be started through console. Admin has to be ingame.");
		PrintToChatAll("[SM] :  Admin has launched the NUKE, were all gonna die!!!");
		PrintToServer("[Nukem] Admin: has launched a nuke on the server.");
		
		lethal = true;
		bIsNuking = true;
		nuke_tmr = BOMB_FUSE;
		
		return Plugin_Handled;
	}

	GetClientAbsOrigin(client, start_cor);

	new String:User[32];
	GetClientName(client,User,31);
	
	PrintToChatAll("[SM] :  %s has launched the NUKE, were all gonna die!!!", User);
	PrintToServer("[Nukem] Admin: %s has launched a nuke on the server.", User);

	lethal = true;
	bIsNuking = true;
	nuke_tmr = BOMB_FUSE;

	CreateTimer(11.5, shake_timer,client);

	return Plugin_Handled;
}

public Action:Command_Nukem_jk( client, args )
{
	if(bIsNuking == true)
	{
		PrintToConsole(client,"[SM] The nuke is already in progress");
		return Plugin_Handled;
	}

	if(client==0)// Console Nuke
	{
		//PrintToConsole(client,"[SM] A nuke can not be started through console. Admin has to be ingame.");
		PrintToChatAll("[SM] :  Admin has launched the NUKE, were all gonna die!!!");
		PrintToServer("[Nukem] Admin: has launched a nuke on the server.");
		
		lethal = false;
		bIsNuking = true;
		nuke_tmr = BOMB_FUSE;
		
		return Plugin_Handled;
	}

	GetClientAbsOrigin(client, start_cor);

	new String:User[32];
	GetClientName(client,User,31);

	PrintToChatAll("[SM] :  %s has launched the NUKE, were all gonna die!!!", User);
	PrintToServer("[Nukem] Admin: %s has launched a fake nuke on the server.", User);

	lethal = false;
	bIsNuking = true;
	nuke_tmr = BOMB_FUSE;

	CreateTimer(11.5, shake_timer,client);	

	return Plugin_Handled;
}

public Action:shake_timer(Handle:timer, any:client)
{
	// Shake
	env_shake(client, 10.0, 10000.0, 10.0, 150.0);
}

public Action:nuke_timer(Handle:timer)
{
	if(bIsNuking == false)
	{
		return Plugin_Handled;
	}
	new maxplayers=GetMaxClients();
	nuke_tmr -=1;

	if (nuke_tmr > 0)
	{
		if(nuke_tmr == 15)
		{
			EmitSoundToAll("vox/alert.wav");
		}
		if(nuke_tmr == 14)
		{
			EmitSoundToAll("vox/atomic.wav");
		}
		if(nuke_tmr == 13)
		{
			EmitSoundToAll("vox/weapon.wav");
		}	
		if(nuke_tmr == 12)
		{
			EmitSoundToAll("vox/detected.wav");
			EmitSoundToAll("ambient/machines/aircraft_distant_flyby3.wav");
			EmitSoundToAll("ambient/machines/aircraft_distant_flyby3.wav");
		}	
		if( (nuke_tmr > 5) && (nuke_tmr < 11) )
		{
			PrintToChatAll("The world will explode in %d seconds.",nuke_tmr - 5);
			PrintCenterTextAll("The world will explode in %d seconds.",nuke_tmr - 5);
		}
		if(nuke_tmr == 11)
		{
			EmitSoundToAll("fvox/range.wav");
		}
		if(nuke_tmr == 10)
		{
			EmitSoundToAll("hl1/fvox/five.wav");
		}
		if(nuke_tmr == 9)
		{
			EmitSoundToAll("fvox/four.wav");
		}
		if(nuke_tmr == 8)
		{
			EmitSoundToAll("fvox/three.wav");
		}
		if(nuke_tmr == 7)
		{
			EmitSoundToAll("fvox/two.wav");
		}
		if(nuke_tmr == 6)
		{
			EmitSoundToAll("fvox/one.wav");
		}
		if(nuke_tmr == 5)
		{
			EmitSoundToAll("misc/horror/the_horror1.wav");
 			new color[4]={250,250,250,255};
			Fade(600, 600 , color);
			new Float:origin[3];
			explodeall(origin);
		}

		if(nuke_tmr < 5)
		{
			new horror_num;
			horror_num = GetRandomInt(0,3);

			switch(horror_num)
			{
				case 0: EmitSoundToAll("misc/horror/the_horror1.wav");
				case 1: EmitSoundToAll("misc/horror/the_horror2.wav");
				case 2: EmitSoundToAll("misc/horror/the_horror3.wav");
				case 3: EmitSoundToAll("misc/horror/the_horror4.wav");
			}
			if(nuke_tmr == 4)
			{
				start_cor[2] = start_cor[2] + 1000.0;
				explodeall(start_cor);
			}
			else
			{
				new Float:rorigin[3],sb;
				for(new i = 1 ;i < 50; ++i)
				{
					rorigin = start_cor;
					rorigin[0] = GetRandomFloat(0.0,3000.0);
					rorigin[1] = GetRandomFloat(0.0,3000.0);
					rorigin[2] = GetRandomFloat(0.0,2000.0);
					sb = GetRandomInt(0,2);
					if(sb == 0)
						rorigin[0] = rorigin[0] * -1;
					sb = GetRandomInt(0,2);
					if(sb == 0)
						rorigin[1] = rorigin[1] * -1;
					sb = GetRandomInt(0,2);
					if(sb == 0)
						rorigin[2] = rorigin[2] * -1;
					explodeall(rorigin);
				}
			}
			
   			for(new x = 1; x <= maxplayers; x++)
    			{
				if(IsClientConnected(x) && IsClientInGame(x))
				{
					new rndkill = GetRandomInt(0,9);
					if(rndkill == 0)
					{
						if(lethal == true)
						{
							ForcePlayerSuicide(x);
							new Float:origin[3];
							GetClientAbsOrigin(x, origin);
							origin[2] = origin[2] - 26;
							explode(origin);
							IgniteEntity(x, 10.0);
						}

					}
				}
			}
		}
	}
	else
	{
		blowem_up();
	}
	return Plugin_Continue;
}

public Action:blowem_up()
{
	bIsNuking = false;
	nuke_tmr = 0;

	if(lethal == true)
	{
		PrintCenterTextAll("The world has exploded.");
		PrintToChatAll("The world has exploded.");
	}
	else
	{
		PrintToChatAll("HAHAHAHA -- Just kidding. That wasnt a real NUKE.");
		PrintCenterTextAll("HAHAHAHA -- Just kidding. That wasnt a real NUKE.");
	}

	new Float:origin[3];
	new maxpl = GetMaxClients();
	for(new a=1; a<=maxpl; a++)
	{
		if(IsClientConnected(a) && IsClientInGame(a))
		{
			GetClientAbsOrigin(a, origin);
			origin[2] = origin[2] - 26;

			explode(origin);

			if(lethal == true)
			{
				ForcePlayerSuicide(a);
			}
		}
	}
	return Plugin_Handled;
}

public Fade(duration,time,const color[4])
{
	new Handle:hBf=StartMessageAll("Fade");
	if(hBf!=INVALID_HANDLE)
	{
		BfWriteShort(hBf,duration);
		BfWriteShort(hBf,time);
		BfWriteShort(hBf,FADE_IN);
		BfWriteByte(hBf,color[0]);
		BfWriteByte(hBf,color[1]);
		BfWriteByte(hBf,color[2]);
 		BfWriteByte(hBf,color[3]);
		EndMessage();
	}
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

public Action:KillEnt(Handle:Timer, any:Ent)
{
	//Kill:
	if(IsValidEdict(Ent)) AcceptEntityInput(Ent, "Kill", 0);
}

stock explodeall(Float:vec1[3])
{
	vec1[2] += 10;

	new color[4]={188,220,255,255};

	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);
	EmitSoundFromOrigin("ambient/explosions/explode_8.wav", vec1);

	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 0, 5000); // 600
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 1500.0, fire, g_HaloSprite, 0, 66, 6.0, 128.0, 0.2, color, 25, 0);
  	TE_SendToAll();
}

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

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
