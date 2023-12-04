/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Nextmap Plugin
 * Adds sm_nextmap cvar for changing map and nextmap chat trigger.
 *
 * SourceMod (C)2004-2023 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#pragma semicolon 1

new g_Time = 22;

new bool:g_RoundEnd = false;
#define WEAPONS_MAX_LENGTH 33
new g_BlueGlowSprite;
new g_RedGlowSprite;
new g_GreenGlowSprite;
new g_YellowGlowSprite;
new g_PurpleGlowSprite;
new g_OrangeGlowSprite;
new g_WhiteGlowSprite;
new precache_fire_line;

new modelindex;
new haloindex;

new hasNinja[MAXPLAYERS+1];
new bool:onninja[MAXPLAYERS+1];
new bool:canuse[MAXPLAYERS+1];

new bool:bUserHasBoost[ 33 ];

new g_SmokeSprite;
new g_LightningSprite;

public Plugin:myinfo =
{
	name        = "BeaconLastThor",
	description = "Amauri Beacons last survivor for X seconds.",
	author      = "Amauri bueno dos Santos",
	version = SOURCEMOD_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2266832"
}

public OnPluginStart()
{
	
	RegAdminCmd("admin_thor", Command_Beacon, ADMFLAG_KICK, "Kicks a player by name");
	RegConsoleCmd("sm_thor", Command_Beacon,  "sm_thor <player> ");
	LoadTranslations("BeaconLastThor.phrases");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/sprites/blueglow2.vmt");
	AddFileToDownloadsTable("materials/sprites/redglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/greenglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/yellowflare.vmt");
	AddFileToDownloadsTable("materials/sprites/purpleglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/orangecore1.vmt");
	AddFileToDownloadsTable("materials/sprites/lgtning.vmt");
	AddFileToDownloadsTable("materials/sprites/steam2.vmt");
	AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");///
	AddFileToDownloadsTable("materials/sprites/fire.vmt");
	
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/glow_test02.vmt");

	g_BlueGlowSprite = PrecacheModel("sprites/blueglow2.vmt",true);
	g_RedGlowSprite = PrecacheModel("sprites/redglow1.vmt",true);
	g_GreenGlowSprite = PrecacheModel("sprites/greenglow1.vmt",true);
	g_YellowGlowSprite = PrecacheModel("sprites/yellowflare.vmt",true);
	g_PurpleGlowSprite = PrecacheModel("sprites/purpleglow1.vmt",true);
	g_OrangeGlowSprite = PrecacheModel("sprites/orangecore1.vmt",true);
	g_WhiteGlowSprite = PrecacheModel("sprites/lgtning.vmt",true);
	g_SmokeSprite = PrecacheModel("sprites/steam2.vmt",true);
	g_LightningSprite = PrecacheModel("sprites/tp_beam001.vmt",true);///
	precache_fire_line = PrecacheModel("sprites/fire.vmt",true);
	
	modelindex = PrecacheModel("sprites/laser.vmt",true);
	haloindex = PrecacheModel("sprites/glow_test02.vmt",true);
	
	AddFileToDownloadsTable("sound/zr_facosa/incesivel.mp3");
	PrecacheSound("zr_facosa/incesivel.mp3", true);
	
	AddFileToDownloadsTable("sound/zr_facosa/raio.mp3");
	PrecacheSound("zr_facosa/raio.mp3", true);
	
	AutoExecConfig();
	
}

public Action:Command_Beacon(client, args)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	char name[32], buffer[128];
	GetClientName(client, name, sizeof(name));
	
	
	
	if( bUserHasBoost[client] )
		{
			//PrintToChat( client, "\x01[BeaconThor] \x03You already have BeaconThor effects on you." );
			PrintToChat(client, "%T", "inform1", client, name);
			Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "inform1", LANG_SERVER, name);
			
			return Plugin_Stop;
		}
		
	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{
		EmitAmbientSound("zr_facosa/incesivel.mp3", vec, client, SNDLEVEL_RAIDSIREN);
		EmitSoundToAll("zr_facosa/raio.mp3", client, SNDLEVEL_RAIDSIREN);
		CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
		hasNinja[client] = hasNinja[client] -1;
	}
	else
	{
		//PrintToChat( client, "\x01[BOOST] \x03You don't have BOOST! You need %d$!", hasNinja[client] );
		PrintToChat(client, "%T", "inform2",  hasNinja[client], name);
		Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "inform2", LANG_SERVER, name);
	}
	
	return Plugin_Continue;

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

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[WEAPONS_MAX_LENGTH];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	bUserHasBoost[ victim ] = false;
	
	new team = GetClientTeam(victim);
	new humans = 0;
	new zombies = 0;
	
	char attackername[32], buffer[128];
	GetClientName(attacker, attackername, sizeof(attackername));
	
	
	if( bUserHasBoost[attacker] )
		{
			//PrintToChat( attacker, "\x01[BeaconThor] \x03You already have BeaconThor effects on you." );
			
			PrintToChat(attacker, "%T", "inform3",  attacker, attackername);
			Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "inform3", LANG_SERVER, attackername);
			
			return Plugin_Stop;
		}

	for (new i = 1; i < MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;
		if (team==3)
			

		if (ZR_IsClientHuman(i))
		{
			humans++;
			//client = i;
		}
		else if (ZR_IsClientZombie(i))
		{
			zombies++;
		}
		
		if (team==3) //(team==2)t or (team==3)ct
		{
			humans= humans + 1;
			//PrintCenterTextAll("Congratulations, CT %d contagem.", humans);
			continue;
		}
		
		if (team==2)
		{
			zombies = zombies + 1;
			//PrintCenterTextAll("Congratulations, TR %d contagem.", zombies);
			continue;
		}
	}
	
	//open fution
	new Float:vec[3];
	GetClientAbsOrigin(victim, vec);

	if (zombies > 0 && humans == 1 && IsPlayerAlive(attacker))
	{
		EmitAmbientSound("zr_facosa/incesivel.mp3", vec, attacker, SNDLEVEL_RAIDSIREN);
		CreateTimer(0.5, Timer_Beacon, attacker, TIMER_REPEAT);
		
		Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "messagem", LANG_SERVER, attackername);
		PrintCenterTextAll("%t", "messagem", humans);
	}
	
	if(StrEqual(weapon, "ssg08", false) || StrEqual(weapon, "awp", false) && humans == 1)
	{
		EmitAmbientSound("zr_facosa/incesivel.mp3", vec, attacker, SNDLEVEL_RAIDSIREN);
		CreateTimer(0.5, Timer_Beacon, attacker, TIMER_REPEAT);
	}
}

public OnClientDisconnect( id )
{
	bUserHasBoost[ id ] = false;
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	new iHumans = 0;
	
	char attackername[32], buffer[128];
	GetClientName(attacker, attackername, sizeof(attackername));
	
	if( bUserHasBoost[client] )
		{
			//PrintToChat( client, "\x01[BeaconThor] \x03You already have BeaconThor effects on you." );
			
			PrintToChat(attacker, "%T", "ClientInfect",  attacker, attackername);
			Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "ClientInfect", LANG_SERVER, attackername);
			
			return Plugin_Stop;
		}
		
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
		{
			iHumans++;
		}
	}
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	if (iHumans <= 1)
	{   
        
		//PrintCenterTextAll("Congratulations");
	
		Format(buffer, sizeof(buffer), "\x01[BeaconThor]%T \x03", "ClientInfect2", LANG_SERVER, attackername);
		PrintCenterTextAll("%t", "ClientInfect2", attackername);
		
		EmitAmbientSound("zr_facosa/incesivel.mp3", vec, client, SNDLEVEL_RAIDSIREN);
		CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
		return Plugin_Handled;
 	}
	
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	bUserHasBoost[ client ] = false;
	g_RoundEnd = false;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	bUserHasBoost[ client ] = false;
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
			
			
			//yellow
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 130.0, haloindex, modelindex, 0, 15, 1.1, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Orange
			beaconColor[0] = 250;
			beaconColor[1] = 130;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 120.0, haloindex, modelindex, 0, 10, 1.0, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Pink
			beaconColor[0] = 255;
			beaconColor[1] = 120;
			beaconColor[2] = 175;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 110.0, haloindex, modelindex, 0, 15, 0.9, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Cyan
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 100.0, haloindex, modelindex, 0, 10, 0.8, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Purple
			beaconColor[0] = 128;
			beaconColor[1] = 0;
			beaconColor[2] = 128;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 90.0, modelindex, haloindex, 0, 10, 0.7, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			
			//White
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 80.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			
			//Red
			beaconColor[0] = 255;
			beaconColor[1] = 0;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 70.0, haloindex, modelindex, 0, 15, 0.5, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Green
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 60.0, haloindex, modelindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Blue
			beaconColor[0] = 0;
			beaconColor[1] = 0;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 50.0, haloindex, modelindex, 0, 10, 0.3, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			
			
			EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);

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
			
			//EmitAmbientSound("zr_facosa/raio.mp3", vec, client, SNDLEVEL_RAIDSIREN);
			times++;

			PrintCenterTextAll("Congratulations, you're alive, may Thor help you %d thunder.", (g_Time - times));
			bUserHasBoost[ client ] = true;
			
		}
	}
	else
	{
		times = 0;
		bUserHasBoost[ client ] = false;
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
