#pragma semicolon 1

#include <sourcemod>
#include <console>
#include <events>
#include <entity>
#include <string>
#include <float>
#include <clients>
#include <core>
#include <timers>
#include <tempents>

// Colors
#define GREEN 0x04
#define DEFAULTCOLOR 0x01

public Plugin:myinfo = 
{
	name = "SpawnProtect",
	author = "FlyingMongoose",
	description = "Spawn Protection",
	version = "1.0.2",
	url = "http://www.gameconnect.info/"
};

// Define global variables
new Handle:cvarProtectionTimer;

new g_endFreezeTime;
new g_HealthOffset;
new g_LifeStateOffset;

// Effect globals
new g_Lightning;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

new bool:g_isHooked;

/* "SayText2" message
 * color define
 * \x01 = client console color
 * \x03 = team color T=red; CT=blue; Server=light green; Spec=gray
 * \x04 = green color
 * \n   = new line
 *
 * Thanks jopmako for this text thingy
 */
stock SendMsg_SayText2(target, color, const String:szMsg[], any:...)
{
   if (strlen(szMsg) > 191){
      LogError("Disallow string len(%d) > 191", strlen(szMsg));
      return;
   }

   decl String:buffer[192];
   VFormat(buffer, sizeof(buffer), szMsg, 4);

   new Handle:hBf;
   if (!target)
      hBf = StartMessageAll("SayText2");
   else hBf = StartMessageOne("SayText2", target);

   if (hBf != INVALID_HANDLE)
   {
      BfWriteByte(hBf, color); // Players index, to send a global message from the server make it 0
      BfWriteByte(hBf, 0); // 0 to phrase for colour 1 to ignore it
      BfWriteString(hBf, buffer); // the message itself
      EndMessage();
   }
}

// nifty pretties
stock SlayEffects(entity)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(entity,playerpos);
	
	// set lightning settings
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;	
	new Float:lightningdelay = 0.0;
	new Float:lightninglife = 2.0;
	new Float:lightningwidth = 5.0;
	new Float:lightningendwidth = 5.0;
	new lightningstartframe = 0;
	new lightningframerate = 1;
	new lightningfadelength = 1;
	new Float:lightningamplitude = 1.0;
	new lightningspeed = 250;
	
	// set smoke settings
	new Float:smokedelay = 0.0;
	new Float:smokedelay2 = 0.5;
	new Float:smokescale = 10.0;
	new smokeframerate = 1;
	
	new Float:SmokePos[3];
	SmokePos[0] = playerpos[0];
	SmokePos[1] = playerpos[1];
	SmokePos[2] = playerpos[2] + 10;
	
	new Float:PlayerHeadPos[3];
	PlayerHeadPos[0] = playerpos[0];
	PlayerHeadPos[1] = playerpos[1];
	PlayerHeadPos[2] = playerpos[2] + 100;
	
	new Float:direction[3];
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	
	new attackerTeam = GetClientTeam(entity);
	for(new index=1; index <= GetMaxClients(); ++index){
		if(IsClientConnected(index)){
			if(!IsFakeClient(index)){
				if(attackerTeam == GetClientTeam(index)){
					TEBeamPoints(g_Lightning,index,lightningdelay,toppos,playerpos,lightninglife,lightningwidth,lightningendwidth,lightningcolor,lightningstartframe,lightningframerate,lightningfadelength,lightningamplitude,lightningspeed);
					TESmoke(g_Smoke1, index, smokedelay, playerpos, smokescale, smokeframerate);
					TESmoke(g_Smoke2, index, smokedelay, playerpos, smokescale, smokeframerate);
					TESmoke(g_FireBurst, index, smokedelay, playerpos, smokescale, smokeframerate);
					TESmoke(g_Smoke1, index, smokedelay2, SmokePos, smokescale, smokeframerate);
					TESmoke(g_Smoke2, index, smokedelay2, SmokePos, smokescale, smokeframerate);
					TESmoke(g_FireBurst, index, smokedelay, SmokePos, smokescale, smokeframerate);
					ClientCommand(index, "play ambient/explosions/explode_8.wav");
				}
			}
		}
	}
}


// Force the client to commit suicide (a.k.a. slay)
// before you other coders go "omgwtfhax" honestly
// this was the only way that any of this would actually
// work...don't ask me how/why, but it's the truth.
stock CommitSuicide(entity)
{
	FakeClientCommand(entity,"kill");
	/*// Set player's life state to LIFE_DISCARDBODY (4)
	SetEntData(entity,g_LifeStateOffset,4,true);
	FakeClientCommand(entity,"kill");
	// Set player's health to 0
	SetEntData(entity,g_HealthOffset,0,true);
	FakeClientCommand(entity,"kill");
	// Set player's life state to LIFE_DYING (1)
	SetEntData(entity,g_LifeStateOffset,1,true);
	// Send FakeClientCommand kill
	FakeClientCommand(entity,"kill");
	// Set player's life state to LIFE_DEAD (2)
	SetEntData(entity,g_LifeStateOffset,2,true);
	FakeClientCommand(entity,"kill");*/
}

// sets the victim's health after attack
public SetPlayerHealth(entity, amount)
{
	SetEntData(entity,g_HealthOffset,amount,true);
}

public GetPlayerHealth(entity)
{
	return GetEntData(entity, g_HealthOffset);
}

public OnPluginStart()
{
	// Look for the offset pertaining to the player's health
	g_HealthOffset = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	// If cannnot find offsets fail
	if (g_HealthOffset == -1)
	{
		g_isHooked = false;
		PrintToServer("* FATAL ERROR: Failed to get offset for CCSPlayer::m_iHealth");
	}else{
		g_LifeStateOffset = FindSendPropOffs("CCSPlayer", "m_lifeState");
		if(g_LifeStateOffset == -1)
		{
			g_isHooked = false;
			PrintToServer("* FATAL ERROR: Failed to get offset for CCSPlayer::m_lifeState");
		}else{
			cvarProtectionTimer = CreateConVar("sm_protecttime","10","Sets in seconds the spawn protection timer",FCVAR_PLUGIN,true,0.0,true,30.0);
			if(GetConVarInt(cvarProtectionTimer) <= 0 || GetConVarInt(cvarProtectionTimer) > 30){
				g_isHooked = false;
			}else{
				// If offsets are all found, start a timer to hook events
				CreateTimer(3.0, OnPluginStart_Delayed);
			}
		}
	}
}

// When timer is up this is called and hooks all necessary events
public Action:OnPluginStart_Delayed(Handle:timer)
{
	// Hook things
	g_isHooked = true;
	
	HookEvent("round_freeze_end",ev_RoundStart);
	HookEvent("player_hurt",ev_PlayerHurt);
	
	HookConVarChange(cvarProtectionTimer,ProtectTimerChange);
	
	// Output to confirm load
	PrintToServer("[SpawnProtect] - Loaded");
	g_Lightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",false);
	g_FireBurst = PrecacheModel("materials/sprites/fireburst.vmt",false);
	if(g_Lightning == 0){
		PrintToServer("Precache Failed");
	}
}

// When the cvar for the plugin is changed this checks it's value
public ProtectTimerChange(Handle:convar, const String:oldValue[], const String:newValue[]){
// if the cvar is outside it's boundaries it will unhook
	if(GetConVarInt(cvarProtectionTimer) <= 0 || GetConVarInt(cvarProtectionTimer) > 30){
		if(g_isHooked == true){
			UnhookEvent("round_freeze_end",ev_RoundStart);
			UnhookEvent("player_hurt",ev_PlayerHurt);
			g_isHooked = false;
		}
// if the plugin is not already hooked this will hook the events
	}else if(g_isHooked == false){
		HookEvent("round_freeze_end",ev_RoundStart);
		HookEvent("player_hurt",ev_PlayerHurt);
		
		SetConVarInt(cvarProtectionTimer,StringToInt(newValue));
		
		g_isHooked = true;
	}
}

public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	// gets the time from the unix epoch in seconds if the cvar is set
	new ProtectTime = GetConVarInt(cvarProtectionTimer);
	if(ProtectTime>0){
		g_endFreezeTime = GetTime();
	}
}

public ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){
	decl String:victimName[100];
	decl String:attackerName[100];
	// gets the time when the player is hurt and checks if it's under or equal to the cvar time
	new ProtectTime = GetConVarInt(cvarProtectionTimer);
	if(ProtectTime>0){
		new queryTime = GetTime();
		if((queryTime-g_endFreezeTime)<=ProtectTime){
			new userid = GetEventInt(event,"userid");		
			new userid2 = GetEventInt(event,"attacker");
			
			new victim = GetClientOfUserId(userid);
			new attacker = GetClientOfUserId(userid2);
			
			if(attacker != 0){	
				if(IsClientConnected(attacker) || IsClientConnected(victim)){
					if(!IsFakeClient(attacker) || !IsClientConnected(victim)){
						new victimTeam = GetClientTeam(victim);
						new attackerTeam = GetClientTeam(attacker);
						//checks if the victim and attackers teams are the same
						if(victimTeam==attackerTeam){
							GetClientName(victim,victimName,100);
							GetClientName(attacker,attackerName,100);
							
							// makes slay pretties
							SlayEffects(attacker);
							// forces attacker to commit suicide
							CommitSuicide(attacker);
							
							new dmgDone = GetEventInt(event,"dmg_health");
							
							new currentHealth = GetPlayerHealth(victim);
							
							new fixedHealth = currentHealth + dmgDone;
							
							if(fixedHealth > 100){
								SetPlayerHealth(victim,100);
							}else{
								SetPlayerHealth(victim,fixedHealth);
							}
							PrintToConsole(attacker,"You have been slain for team attacking %s at the beginning of the round",victimName);
							SendMsg_SayText2(attacker,0,"%cYou have been slain for team attacking %s at the beginning of the round%c",GREEN,victimName,DEFAULTCOLOR);
							PrintToConsole(victim,"%s has been slain for team attacking you at the beginning of the round",attackerName,victimName);
							SendMsg_SayText2(victim,0,"%c%s has been slain for team attacking you at the beginning of the round%c",GREEN,attackerName,DEFAULTCOLOR);
						}
					}
				}
			}
		}
	}
}