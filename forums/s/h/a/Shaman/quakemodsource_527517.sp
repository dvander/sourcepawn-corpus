/*
quakemodsource.sp
Quake Mod: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log (N: New, C: Changed, S: Same, R: Removed, X: Not included in the package)

v0.0.2
Release Notes:
	None.
Changes:
	None.

v0.0.1
Release Notes:
	First release.
	SStocks is needed to compile this plugin.
Changes:
	First release.
*/
/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sstocks>

//||||||||||||||||||||Plugin Information

new const String:PLUGIN_NAME[]= "Quake Mod: Source";
new const String:PLUGIN_DESCRIPTION[]= "Adds Quake sounds to the game.";
#define PLUGIN_VERSION "0.0.2"

public Plugin:myinfo=
	{
	name= PLUGIN_NAME,
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= PLUGIN_DESCRIPTION,
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
	}

//||||||||||||||||||||Constants

new const String:Sound_Death1[]= "quakemodsource/death1.wav";
new const String:Sound_Death1_Long[]= "sound/quakemodsource/death1.wav";
new const String:Sound_Death2[]= "quakemodsource/death2.wav";
new const String:Sound_Death2_Long[]= "sound/quakemodsource/death2.wav";
new const String:Sound_Death3[]= "quakemodsource/death3.wav";
new const String:Sound_Death3_Long[]= "sound/quakemodsource/death3.wav";
new const String:Sound_FallDamage[]= "quakemodsource/fall1.wav";
new const String:Sound_FallDamage_Long[]= "sound/quakemodsource/fall1.wav";
new const String:Sound_Hit[]= "quakemodsource/hit.wav";
new const String:Sound_Hit_Long[]= "sound/quakemodsource/hit.wav";
new const String:Sound_Humiliation[]= "quakemodsource/humiliation.wav";
new const String:Sound_Humiliation_Long[]= "sound/quakemodsource/humiliation.wav";
new const String:Sound_Hurt25[]= "quakemodsource/pain25_1.wav";
new const String:Sound_Hurt25_Long[]= "sound/quakemodsource/pain25_1.wav";
new const String:Sound_Hurt50[]= "quakemodsource/pain50_1.wav";
new const String:Sound_Hurt50_Long[]= "sound/quakemodsource/pain50_1.wav";
new const String:Sound_Hurt75[]= "quakemodsource/pain75_1.wav";
new const String:Sound_Hurt75_Long[]= "sound/quakemodsource/pain75_1.wav";
new const String:Sound_Hurt100[]= "quakemodsource/pain100_1.wav";
new const String:Sound_Hurt100_Long[]= "sound/quakemodsource/pain100_1.wav";
new const String:Sound_Talk[]= "quakemodsource/talk.wav";
new const String:Sound_Talk_Long[]= "sound/quakemodsource/talk.wav";
new const String:Sound_Spawn[]= "quakemodsource/telein.wav";
new const String:Sound_Spawn_Long[]= "sound/quakemodsource/telein.wav";
new const String:Sound_WeaponEmpty[]= "quakemodsource/noammo.wav";
new const String:Sound_WeaponEmpty_Long[]= "sound/quakemodsource/noammo.wav";

//||||||||||||||||||||Initialization

public OnPluginStart()
	{
	//Version ConVar
	CreateConVar("quakemodsource_version", PLUGIN_VERSION, "Quake Mod: Source Version", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	//ConVars
	CreateConVar("quakemodsource_enable", "1", "Enable/disable Quake Mod: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CreateConVar("quakemodsource_talk_enable", "1", "Quake Mod: Source | Enable/disable talk sound.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("quakemodsource_talk_senderhears", "1", "Quake Mod: Source | If enabled sender hears talk sound sound too.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("quakemodsource_talk_playmode", "0", "Quake Mod: Source | Talk sound play mode. 0: Play always, 1: Play only for all chat, 2: Play only for team chat", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	
	//Command hooks
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	if(CheckMod("ins"))//'Insurgency: Modern Infantry Combat' support
		RegConsoleCmd("say2", Command_SayTeam);
	
	//Event hooks
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_falldamage", Event_PlayerFallDamage, EventHookMode_Post);
	HookEvent("weapon_fire_on_empty", Event_WeaponFireOnEmpty, EventHookMode_Post);
	}

public OnMapStart()
	{
	PrecacheSounds();
	}

//||||||||||||||||||||Command hooks

public Action:Command_Say(sender, args)
	{
	if(!TalkRunning() || TalkIConVar("playmode")==2){return Plugin_Continue;}
	//Start emiting sound to clients
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		if(IsClientInGame(client))
			{
			new bool:play= true;
			//Do not play the sound if client is the sender and we are going to exclude the sender
			if(client==sender && !TalkBConVar("senderhears"))
				play= false;
			//Do not play the sound if sender is dead, but client is alive
			if(!IsPlayerAlive(sender) && IsPlayerAlive(client))
				play= false;
			//Play the sound if we are going to
			if(play)	
				EmitSoundToClient(client, Sound_Talk);
			}
		}
	return Plugin_Continue;
	}

public Action:Command_SayTeam(sender, args)
	{
	if(!TalkRunning() || TalkIConVar("playmode")==1){return Plugin_Continue;}
	//Start emiting sound to clients
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		if(IsClientInGame(client))
			{
			new bool:play= true;
			//Do not play the sound if client is the sender and we are going to exclude the sender
			if(client==sender && !TalkBConVar("senderhears"))
				play= false;
			//Do not play the sound if sender is dead, but client is alive
			if(!IsPlayerAlive(sender) && IsPlayerAlive(client))
				play= false;
			//Do not play the sound if sender and client are not in the same team
			if(GetClientTeam(sender)!=GetClientTeam(client))
				play= false;
			//Play the sound if we are going to
			if(play)	
				EmitSoundToClient(client, Sound_Talk);
			}
		}
	return Plugin_Continue;
	}

//||||||||||||||||||||Event hooks

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who spawned?
	new client= GetClientOfUserId(GetEventInt(event, "userid"));
	//Where is the client?
	new Float:ClientLocation[3];
	GetClientAbsOrigin(client, ClientLocation);
	//Play Sound_Spawn
	EmitSoundToAll(Sound_Spawn, _, _, SNDLEVEL_SNOWMOBILE, _, _, _, _, ClientLocation);
	}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is the victim?
	new victim= GetClientOfUserId(GetEventInt(event, "userid"));
	//Who is the attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "attacker"));
	//Return if the damage is recieved from world
	if(attacker==0)
		return;
	//Play Sound_Hit to attacker
	EmitSoundToClient(attacker, Sound_Hit);
	//Play sound to victim
	new damage= GetEventInt(event, "dmg_health");
	if(damage>=100)
		EmitSoundToClient(victim, Sound_Hurt100, _, _, SNDLEVEL_SCREAMING);
	else if(damage>=75)
		EmitSoundToClient(victim, Sound_Hurt75, _, _, SNDLEVEL_SCREAMING);
	else if(damage>=50)
		EmitSoundToClient(victim, Sound_Hurt50, _, _, SNDLEVEL_SCREAMING);
	else
		EmitSoundToClient(victim, Sound_Hurt25, _, _, SNDLEVEL_SCREAMING);
	}

public Event_PlayerFallDamage(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is the client?
	new client= GetClientOfUserId(GetEventInt(event, "userid"));
	//Play sound to victim
	EmitSoundToClient(client, Sound_FallDamage, _, _, SNDLEVEL_SCREAMING);
	}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is the victim?
	new victim= GetClientOfUserId(GetEventInt(event, "userid"));
	//Who is the attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "attacker"));
	//Return if the attacker is world
	if(attacker==0)
		return;
	//Which weapon did our attacker use?
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//Play humiliation sound if our attacker killed with knife
	if(StrEqual(weapon, "knife"))
		EmitSoundToAll(Sound_Humiliation);
	//Where is the victim?
	new Float:VictimLocation[3];
	GetClientAbsOrigin(victim, VictimLocation);
	//Play the sound
	new random= GetRandomInt(1, 3);
	if(random==1)
		EmitSoundToAll(Sound_Death1, _, _, SNDLEVEL_SCREAMING, _, _, _, _, VictimLocation);
	else if(random==2)
		EmitSoundToAll(Sound_Death2, _, _, SNDLEVEL_SCREAMING, _, _, _, _, VictimLocation);
	else if(random==3)
		EmitSoundToAll(Sound_Death3, _, _, SNDLEVEL_SCREAMING, _, _, _, _, VictimLocation);
	}

public Event_WeaponFireOnEmpty(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is the client?
	new client= GetClientOfUserId(GetEventInt(event, "userid"));
	//Play the sound
	EmitSoundToClient(client, Sound_WeaponEmpty);
	}

//||||||||||||||||||||Functions

public bool:Running()
	{
	return BConVar("enable");
	}

public bool:TalkRunning()
	{
	return (BConVar("enable") && TalkBConVar("enable"));
	}

public bool:BConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "quakemodsource_%s", subcv);
	return GetConVarBool(FindConVar(ConVarName));
	}

public IConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "quakemodsource_%s", subcv);
	return GetConVarInt(FindConVar(ConVarName));
	}

public bool:TalkBConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "quakemodsource_talk_%s", subcv);
	return GetConVarBool(FindConVar(ConVarName));
	}

public TalkIConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "quakemodsource_talk_%s", subcv);
	return GetConVarInt(FindConVar(ConVarName));
	}

public PrecacheSounds()
	{
	//Precache Sound_Death1
	if(!PrecacheSound(Sound_Death1, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Death1_Long);
	AddFileToDownloadsTable(Sound_Death1_Long);
	//Precache Sound_Death2
	if(!PrecacheSound(Sound_Death2, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Death2_Long);
	AddFileToDownloadsTable(Sound_Death2_Long);
	//Precache Sound_Death3
	if(!PrecacheSound(Sound_Death3, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Death3_Long);
	AddFileToDownloadsTable(Sound_Death3_Long);
	//Precache Sound_FallDamage
	if(!PrecacheSound(Sound_FallDamage, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_FallDamage_Long);
	AddFileToDownloadsTable(Sound_FallDamage_Long);
	//Precache Sound_Hit
	if(!PrecacheSound(Sound_Hit, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Hit_Long);
	AddFileToDownloadsTable(Sound_Hit_Long);
	//Precache Sound_Hit
	if(!PrecacheSound(Sound_Humiliation, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Humiliation_Long);
	AddFileToDownloadsTable(Sound_Humiliation_Long);
	//Precache Sound_Hurt25
	if(!PrecacheSound(Sound_Hurt25, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Hurt25_Long);
	AddFileToDownloadsTable(Sound_Hurt25_Long);
	//Precache Sound_Hurt50
	if(!PrecacheSound(Sound_Hurt50, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Hurt50_Long);
	AddFileToDownloadsTable(Sound_Hurt50_Long);
	//Precache Sound_Hurt75
	if(!PrecacheSound(Sound_Hurt75, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Hurt75_Long);
	AddFileToDownloadsTable(Sound_Hurt75_Long);
	//Precache Sound_Hurt100
	if(!PrecacheSound(Sound_Hurt100, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Hurt100_Long);
	AddFileToDownloadsTable(Sound_Hurt100_Long);
	//Precache Sound_Talk
	if(!PrecacheSound(Sound_Talk, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Talk_Long);
	AddFileToDownloadsTable(Sound_Talk_Long);
	//Precache Sound_Spawn
	if(!PrecacheSound(Sound_Spawn, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_Spawn_Long);
	AddFileToDownloadsTable(Sound_Spawn_Long);
	//Precache Sound_WeaponEmpty
	if(!PrecacheSound(Sound_WeaponEmpty, true))
		Fail(PLUGIN_NAME, "Can't precache sound: %s", Sound_WeaponEmpty_Long);
	AddFileToDownloadsTable(Sound_WeaponEmpty_Long);
	}