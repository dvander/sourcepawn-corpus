/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Map Management Plugin
 * Provides all map related functionality, including map changing, map voting,
 * and nextmap.
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
#include <zombiereloaded>


#define EFL_NO_PHYSCANNON_INTERACTION (1<<30)

#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "3.1"

new bool:g_ZombieExplode[MAXPLAYERS+1];
new Handle:tiempo;

#define EXPLODE_SOUND	"ambient/explosions/explode_7.mp3"
#define PLAYER_ONFIRE (1 << 24)

new g_ExplosionSprite;

#define SOUND_END  "zombie_plague/survivor1.mp3"

#define zr_facosa  "zr_facosa/normal4.mp3"
#define zr_facosa1 "zr_facosa/rambo1.mp3"
#define zr_facosa2 "zr_facosa/rambo2.mp3"
#define zr_facosa3 "zr_facosa/chuck_norris1.mp3"
#define zr_facosa4 "zr_facosa/chuck_norris2.mp3"

#define zr_punishment1 "zr_punishment/punishment1.mp3"
#define zr_punishment2 "zr_punishment/punishment2.mp3"
#define zr_punishment3 "zr_punishment/punishment3.mp3"
#define zr_punishment4 "zr_punishment/punishment4.mp3"

new orange;
new g_HaloSprite;
new contar = 0;
new g_LightningSprite;
new g_SmokeSprite;

new modelindex;
new haloindex;
new g_beamsprite;

new bool:g_RoundEnd = false;

#define MAX_FILE_LEN 80

new g_Time = 3;

#define DMG_GENERIC 0

public Plugin:myinfo =
{
	name = "KBOOOM",
	author = "Amauri Bueno dos Santos",
	description = "Kill zombies with knife",
	version = SOURCEMOD_VERSION,
	url = "www.sourcemod.com"
};

public OnPluginStart()
{
	CreateConVar("sm_zombiexplode3_version", SOURCEMOD_VERSION, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_hurt", EnDamage);
	HookEvent("player_death", PlayerDeathEvent, EventHookMode_Pre);
	HookEvent("round_start", eventRoundStart);
	HookEvent("round_end", EventRoundEnd);
	LoadTranslations("bZm_KBOOOM.phrases");
	tiempo = CreateConVar("sm_zombiexplode3_time", "3.0", "Seconds that zombie have for catch to humans");
	g_RoundEnd = false;

}

public OnMapStart()
{
	
	AddFileToDownloadsTable("sound/zombie_plague/nemesis_pain2.mp3");
	AddFileToDownloadsTable("sound/zombie_plague/survivor1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/normal4.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/chuck_norris1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/chuck_norris2.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/rambo1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/rambo2.mp3");

	AddFileToDownloadsTable("sound/zr_punishment/punishment1.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment2.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment3.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment4.mp3");
	
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/glow_test02.vmt");
	AddFileToDownloadsTable("materials/sprites/lgtning.vmt");
	AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");
	AddFileToDownloadsTable("materials/sprites/fire.vmt");
	
	//icons Zombies custom 

	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/fish.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/fuck.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/boobs.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/kick.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/skull2.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/zombie_walking_csgo.svg");
	
	PrecacheModel("sprites/laser.vmt");
	PrecacheModel("sprites/glow_test02.vmt");
	PrecacheModel("sprites/lgtning.vmt");
	PrecacheModel("sprites/tp_beam001.vmt");
	PrecacheModel("sprites/fire.vmt");
	PrecacheModel("sprites/blueglow2.vmt");
	

	PrecacheSound(SOUND_END, true);
	PrecacheSound(zr_facosa, true);
	PrecacheSound(zr_facosa1, true);
	PrecacheSound(zr_facosa2, true);
	PrecacheSound(zr_facosa3, true);
	PrecacheSound(zr_facosa4, true);

	PrecacheSound(zr_punishment1, true);
	PrecacheSound(zr_punishment2, true);
	PrecacheSound(zr_punishment3, true);
	PrecacheSound(zr_punishment4, true);
	PrecacheSound("zr/zombie_voice_idle1.mp3", true);
	PrecacheSound("zr/zombie_voice_idle2.mp3", true);
	PrecacheSound("zombie_plague/nemesis_pain2.mp3", true);
	orange=PrecacheModel("sprites/fire.vmt");
	g_HaloSprite = PrecacheModel("sprites/fire.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	
	modelindex = PrecacheModel("sprites/laser.vmt");
	haloindex = PrecacheModel("sprites/glow_test02.vmt");
	g_beamsprite = PrecacheModel("sprites/lgtning.vmt");
	
	AutoExecConfig();
}

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (!g_RoundEnd)//"Round time Extender Zombie Reload"
	{
		ServerCommand("mp_humanteam {CT}");
		ServerCommand("mp_warmup_end");
		ServerCommand("mp_warmupend 1");
		ServerCommand("mp_freezetime 3");
		ServerCommand("mp_restartgame 1");
		ServerCommand("mp_roundtime 60");
		g_RoundEnd = true;
		return Plugin_Stop;
	} else if (contar == 0){
		ServerCommand("mp_warmupend 1");
	}
	contar = 0;
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	contar = 0;
	new ev_winner = GetEventInt(event, "winner");
	if(ev_winner == 2) {
	EmitSoundToAll(SOUND_END);
	}
	
}

public IsValidClient( client )
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
		return false;
	
	return true;
}

public OnClientDisconnect( id )

{
	new String:nome[MAX_NAME_LENGTH];
	char name[32], buffer[128];
	GetClientName(id, nome, sizeof(nome));
	
	PrintToChat(id, "%T", "zr_disconnect", id, name);
	Format(buffer, sizeof(buffer), "%T", "zr_disconnect", LANG_SERVER, name);
	if (contar<=1)
	{
		contar=contar-1;
		//PrintToChatAll("The player %s He left because he's an asshole!", nome);
		PrintToChat(id, "%t", "zr_disconnect", name);
		EmitSoundToAll(zr_punishment3);
	}
}

public Action: PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new	victim   = GetClientOfUserId(GetEventInt(event,"userid"));contar++;
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(victim, vecOrigin);
	if(IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		new rnd_sound = GetRandomInt(1, 5);
		
		if(rnd_sound == 1)
		{
			EmitAmbientSound("zombie_plague/nemesis_pain2.mp3", vecOrigin, victim, _, _, 1.0);
			SetEventString(event, "weapon", "skull2");
		}
		else if(rnd_sound == 2) {
			EmitAmbientSound("zr/zombie_voice_idle1.mp3", vecOrigin, victim, _, _, 1.0);
			SetEventString(event, "weapon", "fuck");
			}
			else if(rnd_sound == 3) {
				EmitAmbientSound("zr/zombie_voice_idle2.mp3", vecOrigin, victim, _, _, 1.0);
				SetEventString(event, "weapon", "prop_exploding_barrel");//icon zombie_claws_of_death.svg or prop_exploding_barrel
			}
			else if(rnd_sound == 4) {
				EmitAmbientSound("zr/zombie_voice_idle3.mp3", vecOrigin, victim, _, _, 1.0);
				SetEventString(event, "weapon", "fish");//icon zombie_claws_of_death.svg or prop_exploding_barrel
			}
			else if(rnd_sound == 5) {
				EmitAmbientSound("zr/zombie_voice_idle4.mp3", vecOrigin, victim, _, _, 1.0);
				SetEventString(event, "weapon", "boobs");//icon zombie_claws_of_death.svg or prop_exploding_barrel
			}
			else SetEventString(event, "weapon", "fuck");//zm infect 
			
		
	}
	else SetEventString(event, "weapon", "zombie_walking_csgo");//zm infect 
	//zombie_walking_csgo
	//fuck
	//skull2
	//fish
	//boobs
}

public EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:nome[MAX_NAME_LENGTH];
	char buffer[128];
	
	GetClientName(attacker, nome, sizeof(nome));
	
	
	
	if (!IsValidClient(attacker))
		return;
	
	if (IsPlayerAlive(attacker))
	{
		
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		decl String:weapon[WEAPONS_MAX_LENGTH];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && contar > 0)
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			if(StrEqual(weapon, "knife", false))
			{
				g_ZombieExplode[client] = true;
				//PrintToChat(client, "\x02[\x05B\x06z\x05M\x02_\x07K\x03BOOM TIMER\x02]\x03Was stabbed by \x06%s :) \x03you have 30 seconds to pick up any human being or you will die!",nome);
				PrintToChat(attacker, "\x02[\x05B\x06z\x05M\x02_\x07K\x03BOOM TIMER\x02]\x03%T", "BOOMTIMER", attacker, nome);
				Format(buffer, sizeof(buffer), "%T", "BOOMTIMER", LANG_SERVER, nome);
				
				new Handle:pack;
				new rnd_sound = GetRandomInt(1, 6);
				if(rnd_sound == 1) 
				{
					EmitAmbientSound(zr_facosa, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, "Congratulations %s :) Kill zombie!",nome);
					
					PrintToChat(attacker, "%T", "knife0", attacker, nome);
					Format(buffer, sizeof(buffer), "%T", "knife0", LANG_SERVER, nome);
				}
				else if(rnd_sound == 2) {
					EmitAmbientSound(zr_facosa, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, " %s you, and fuck even!",nome);
					
					PrintToChat(attacker, "%T", "knife1", attacker, nome);
					Format(buffer, sizeof(buffer), "%T", "knife1", LANG_SERVER, nome);
				}
				else if(rnd_sound == 3) {
					EmitAmbientSound(zr_facosa1, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, "YOU LIKE RAMBO stabbed ATTACK YOUR OPPONENT %s !",nome);
					
					PrintToChat(attacker, "%T", "knife2", attacker, nome);
					Format(buffer, sizeof(buffer), "%T", "knife2", LANG_SERVER, nome);
				}
				else if(rnd_sound == 4) {
					EmitAmbientSound(zr_facosa2, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, "crazy Rambo you very cool es %s !",nome);
					
					PrintToChat(attacker, "%T", "knife3", attacker, nome);
					Format(buffer, sizeof(buffer), "%T", "knife3", LANG_SERVER, nome);
				}
				else if(rnd_sound == 5) {
					EmitAmbientSound(zr_facosa3, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, "putz was that %s!",nome);
					
					PrintToChat(attacker, "%T", "knife4", attacker, nome);
					Format(buffer, sizeof(buffer), "%T", "knife4", LANG_SERVER, nome);
				}
				else if(rnd_sound == 6) {
					EmitAmbientSound(zr_facosa4, vec, client, SNDLEVEL_RAIDSIREN);
					//PrintToChat(attacker, "Congratulations you are Chuck Norris %s",nome);
					
					PrintToChat(attacker, "%T", "knife5", attacker,nome);
					Format(buffer, sizeof(buffer), "%T", "knife5", LANG_SERVER, nome);
				}
				CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
				CreateDataTimer(GetConVarFloat(tiempo), ByeZM, pack);
				WritePackCell(pack, client);
				WritePackCell(pack, attacker);
			}
			
		}
		else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && StrEqual(weapon, "knife", false))
		{
			EmitSoundToAll(zr_punishment1);
			contar++;
			//PrintToChatAll("\x02[\x06B\x07z\x08M\x09_\x05KBOOM TIMER\x02] \x03%s\x07 He was punished for knife the first zombie!",nome);
			
			PrintToChat(attacker, "\x02[\x06B\x07z\x08M\x09_\x05KBOOM TIMER\x02] \x03%T\x07", "zr_punishment1", attacker, nome);
			Format(buffer, sizeof(buffer), "%T", "zr_punishment1", LANG_SERVER, nome);
			
			IgniteEntity(attacker,12.0);
			ZR_InfectClient(attacker);
			new playerstate = GetEntProp ( attacker , Prop_Send , "m_nPlayerCond" );
			if (( playerstate & PLAYER_ONFIRE ) != 0 )
			{
				SetEntProp ( attacker , Prop_Send , "m_nPlayerCond" , ( playerstate & (~ PLAYER_ONFIRE )));
			}
			
		}
		else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && contar == 0)
		{
			EmitSoundToAll(zr_punishment4);
			ZR_InfectClient(attacker);
			//PrintToChatAll("\x03%s\x05 He suffered the virus HIV ZOMBIE!",nome);
			
			PrintToChat(attacker, "\x03%T\x05", "zr_punishment2", attacker, nome);
			Format(buffer, sizeof(buffer), "%T", "zr_punishment2", LANG_SERVER,nome);
			
			PrintHintTextToAll("%s He suffered the virus QUIMERA ZOMBIE!",nome);contar++;
		}
	}
	
}

public Action:ByeZM(Handle:timer, Handle:pack)
{
	
	new client;
	new attacker;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	attacker = ReadPackCell(pack);

	if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
	{
		g_ZombieExplode[client] = false;
		decl Float:location[3];
		GetClientAbsOrigin(client, location);
		new ent = CreateEntityByName("env_explosion");
		SetEntProp(ent, Prop_Data, "m_iMagnitude", 300);
		SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 350);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		DispatchSpawn(ent);
		TeleportEntity(ent, location, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode");
		new Float:vec2[3];
		vec2 = location;
		vec2[2] = location[2] + 300.0;
		Lightning(location);
		spark(location);
		Explode1(location);
		Explode2(location);
		EmitAmbientSound( EXPLODE_SOUND, vec2, client, SNDLEVEL_NORMAL );
		spark(vec2);

		if (IsValidClient(attacker)){
			DealDamage(client,9999,attacker,DMG_GENERIC," "); // enemy down ;)
		}
		else ForcePlayerSuicide(client);
	}
}

public Lightning(Float:vec1[3])
{
	new g_lightning	 = PrecacheModel("materials/sprites/tp_beam001.vmt");
	new Float:toppos[3];toppos[0] = vec1[0];toppos[1] = vec1[1];toppos[2] = vec1[2]+1000;new lightningcolor[4];
	lightningcolor[0]			   = 255;
	lightningcolor[1]			   = 255;
	lightningcolor[2]			   = 255;
	lightningcolor[3]			   = 255;
	new Float:lightninglife		 = 0.1;
	new Float:lightningwidth		= 40.0;
	new Float:lightningendwidth	 = 10.0;
	new lightningstartframe		 = 0;
	new lightningframerate		  = 20;
	new lightningfadelength		 = 1;
	new Float:lightningamplitude	= 20.0;
	new lightningspeed			  = 250;
	
	
	
	//raios
	
	new color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
	new Float:dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(toppos, vec1, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(vec1, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(vec1, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(vec1, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	TE_SetupBeamPoints(toppos, vec1, g_lightning, g_lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	
	TE_SendToAll(0.0);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_ZombieExplode[client] = false;
	if (ZR_IsClientZombie(client))
	{
		contar++;
	}
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;
	if (times < g_Time)
	{
		if (IsClientInGame(client))
		if (IsClientInGame(client))
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			new beaconColor[4];
			//Blue
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
			TE_SetupBeamRingPoint(vec, 210.0, 70.0, g_beamsprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.5, beaconColor, 100, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			//Green
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
			times++;
		}
	}
	else
	{
		times = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
public Explode1(Float:vec1[3])
{
	new color[4]={0,255,0,500};
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, orange, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
}

public Explode2(Float:vec1[3])
{
	vec1[2] += 10;
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}

public spark(Float:vec[3])
{
	new Float:dir[3]={10.0,1.0,600.5000};//0.0,0.0,0.0
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}

stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
{
	if(	nClientVictim > 0 &&
	   IsValidEdict(nClientVictim) &&
	   IsClientInGame(nClientVictim) &&
	   IsPlayerAlive(nClientVictim) &&
	   nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));
			
			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));
			
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
			DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");
			
			RemoveEdict(EntityPointHurt);
		}
	}
}



