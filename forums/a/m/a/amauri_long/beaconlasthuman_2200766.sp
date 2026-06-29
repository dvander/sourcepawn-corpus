#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <zombiereloaded>

#define PL_VERSION "1.0.0-stable"

new Handle:g_hTime = INVALID_HANDLE;
new g_Time = 60;

new bool:g_RoundEnd = false;

new g_BlueGlowSprite;
new g_RedGlowSprite;
new g_GreenGlowSprite;
new g_YellowGlowSprite;
new g_PurpleGlowSprite;
new g_OrangeGlowSprite;
new g_WhiteGlowSprite;//21
new precache_fire_line;

new g_SmokeSprite;
new g_LightningSprite;

public Plugin:myinfo =
{
    name        = "Amauri Beacon Last Human",
    author      = "Amauri bueno dos Santos",
    description = "Amauri Beacons last survivor for X seconds.",
    version     = PL_VERSION,
    url         = "www.mapple.net.br"
}

public OnPluginStart()
{
	g_hTime = CreateConVar("blt_time", "15", "The amount of time in seconds to beacon last survivor.", FCVAR_PLUGIN);
	HookConVarChange(g_hTime, OnTimeCvarChange);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true);
}

public OnMapStart()
{
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");

	PrecacheModel("materials/sprites/blueflare1.vmt",true);	
	PrecacheModel("materials/effects/redflare.vmt",true);
	PrecacheModel("materials/sprites/yellowflare.vmt",true);
	PrecacheModel("materials/sprites/orangeflare1.vmt",true);
	PrecacheModel("materials/sprites/flare1.vmt",true);
	
	g_BlueGlowSprite = PrecacheModel("materials/sprites/blueglow1.vmt",true);
	g_RedGlowSprite = PrecacheModel("materials/sprites/redglow1.vmt",true);
	g_GreenGlowSprite = PrecacheModel("materials/sprites/greenglow1.vmt",true);
	g_YellowGlowSprite = PrecacheModel("materials/sprites/yellowglow1.vmt",true);
	g_PurpleGlowSprite = PrecacheModel("materials/sprites/purpleglow1.vmt",true);
	g_OrangeGlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt",true);
	g_WhiteGlowSprite = PrecacheModel("materials/sprites/glow1.vmt",true);
	precache_fire_line = PrecacheModel("materials/sprites/fire.vmt",true);
	
	AddFileToDownloadsTable("sound/ambient/zr/beacon_mixdown_.mp3");
	PrecacheSound("ambient/zr/beacon_mixdown_.mp3", true);
}

public OnTimeCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Time = GetConVarInt(cvar);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new humans = 0;
	new zombies = 0;

	new client = -1;

	for (new i = 1; i < GetMaxClients(); ++i)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		if (ZR_IsClientHuman(i))
		{
			humans++;
			client = i;
		}
		else if (ZR_IsClientZombie(i))
		{
			zombies++;
		}
	}

	if (zombies > 0 && humans == 1 && client != -1)
	{
		EmitSoundToAll("ambient/zr/beacon_mixdown_.mp3");
		CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = false;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = true;
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;
	if (g_RoundEnd)
	{
		times = 0;
		return Plugin_Stop;
	}
	if (times < g_Time)
	{
		if (IsClientInGame(client))
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			vec[2] += 10;
			new beaconColor[4];
			new modelindex = PrecacheModel("sprites/laser.vmt");
			new haloindex = PrecacheModel("sprites/glow02.vmt");
			//yellow
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 130.0, modelindex, haloindex, 0, 15, 1.1, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Orange
			beaconColor[0] = 250;
			beaconColor[1] = 130;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 120.0, modelindex, haloindex, 0, 10, 1.0, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Pink
			beaconColor[0] = 255;
			beaconColor[1] = 120;
			beaconColor[2] = 175;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 110.0, modelindex, haloindex, 0, 15, 0.9, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Cyan
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 100.0, modelindex, haloindex, 0, 10, 0.8, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Purple
			beaconColor[0] = 128;
			beaconColor[1] = 0;
			beaconColor[2] = 128;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 90.0, modelindex, haloindex, 0, 10, 0.7, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//White
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 80.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Red
			beaconColor[0] = 255;
			beaconColor[1] = 0;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 70.0, modelindex, haloindex, 0, 15, 0.5, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Green
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();//Blue
			beaconColor[0] = 0;
			beaconColor[1] = 0;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 50.0, modelindex, haloindex, 0, 10, 0.3, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();

	// define where the lightning strike ends
			new Float:clientpos[3];
			clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	// get random numbers for the x and y starting positions
			new randomx = GetRandomInt(-500, 500);
			new randomy = GetRandomInt(-500, 500);
	
	// define where the lightning strike starts
			new Float:startpos[3];
			startpos[0] = clientpos[0] + randomx;
			startpos[1] = clientpos[1] + randomy;
			startpos[2] = clientpos[2] + 800;
	
	// define the color of the strike
			new color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
			new Float:dir[3] = {0.0, 0.0, 0.0};
	
			TE_SetupBeamPoints(startpos, vec, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
			TE_SendToAll();
	
			TE_SetupSparks(vec, dir, 5000, 1000);
			TE_SendToAll();
	
			TE_SetupEnergySplash(vec, dir, false);
			TE_SendToAll();
	
			TE_SetupSmoke(vec, g_SmokeSprite, 5.0, 10);
			TE_SendToAll();
			

			
			new Float:vec2[3];
			vec2 = vec;
			vec2[2] = vec[2] + 300.0;
			fire_line(vec,vec2);
			sphere(vec2);
			spark(vec2);
			
			//EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
			times++;

			PrintCenterTextAll("Parabens voce esta vivo que zeus te ajude %d trovoes.", (g_Time - times));
		}
	}
	else
	{
		times = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
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

public spark(Float:vec[3])
{
	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}