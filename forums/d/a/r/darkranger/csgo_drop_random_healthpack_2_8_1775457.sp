/*//
THIS PLUGIN DROPS RANDOM OR EVERY "X" DEATHS A HEALTH PACKAGE AFTER A PLAYER DIES.
RANDOM VALUE = 10 + PLAYERS ON SERVER! IF RANDOM = 9 A HEALTHPACK WILL BE DROPED.
THE PLUGIN CONTAINS PARTS OF FEUERSTURMs DOD DROPHEALTHKIT SOURCE. (THANKS)
 
VERSION 1.4
Converted from DOD:S to CS:GO
VERSION 1.5
added other Health Models, changed text
VERSION 1.6
added sound when pickup a HealthPack
VERSION 1.7
added max. Health where a player can pickup a healthpack
VERSION 1.8
added Cvar to control what happens when max HP is reached!
VERSION 1.9
added Sound when max HP reached
VERSION 2.0
added "do nothing" to what happens when max HP reached!
tranlation file!
VERSION 2.1
added CVARs to disable messages!
VERSION 2.2
added new Models!
VERSION 2.3
soundfile mario powerup!
PLEASE ADD ALL MODELS & MATERIALS & SOUNDS TO THE SERVER & FASTDL
VERSION 2.4
added MAX HP check (thanks to Tpunkt)
VERSION 2.5
added new Model HL2-healthkit
code cleanup
VERSION 2.6
added max Entities Check to prevent crashes!
changed sdkhook from Touch -> StartTouch
added new Model cs_gift pacakge
VERSION 2.7
ADDED FROM ROOT (thanks a lot)
	if (DispatchSpawn(healthkit))
		{
			SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
			SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
		}
reverted from V2.6 :sdkhook from StrtTouch -> Touchback	
VERSION 2.8
changed soundpath
*/

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>
#define MAXENTITIES 2048
#define MAX_FILE_LEN 80
#define PLUGIN_VERSION "2.8"

public Plugin:myinfo = 
{
	name = "CS:GO Drop Random Healthpack Plugin",
	author = "Darkranger",
	description = "a dead player drops random a Healthpack!",
	version = PLUGIN_VERSION,
	url = "http://dark.asmodis.at"
}

static const String:g_HealthKit_Model[7][] = { "models/props/cs_italy/chianti02.mdl" , "models/chicken/chicken.mdl" , "models/props_urban/life_ring001.mdl" , "models/items/medkit_small.mdl" , "models/items/medkit_large.mdl" , "models/items/HealthKit.mdl" , "models/items/cs_gift.mdl" }
new String:soundName[MAX_FILE_LEN]
new Handle:HealthKitDropTimer[MAXENTITIES+1] = INVALID_HANDLE
new String:g_HealthKit_Sound[] = { "ui/beep22.wav" }  
new String:g_HealthKitdenied_Sound[] = { "player/suit_denydevice.wav" }
new g_HealthKit_Skin[2] = { 0, 0 }
new Handle:kithealth = INVALID_HANDLE
new Handle:kithealthmax = INVALID_HANDLE
new Handle:kithealthmaxvar = INVALID_HANDLE
new Handle:kittime = INVALID_HANDLE
new Handle:kitcount = INVALID_HANDLE
new Handle:dropmodel = INVALID_HANDLE
new Handle:messagedropenabled = INVALID_HANDLE
new Handle:messagepickupenabled = INVALID_HANDLE
new Handle:PickUpSoundName = INVALID_HANDLE
new Handle:UseOwnPickUpSound = INVALID_HANDLE
new kitcountcounter = 0
new deadkitammount = 0

public OnPluginStart()
{	
	CreateConVar("csgo_drop_random_health_version", PLUGIN_VERSION, "CS:GO Healthpack drop Plugin Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("csgo_drop_random_health_version"), PLUGIN_VERSION)
	kithealth = CreateConVar("csgo_drop_health_amount", "40", "<#> = Amount of HP to add to a player when pick up a Healthpack", FCVAR_PLUGIN, true, 5.0, true, 300.0)
	kithealthmax = CreateConVar("csgo_drop_health_maximum", "150", "max. Amount of Health a Player can have to pickup a Healthpack", FCVAR_PLUGIN, true, 100.0, true, 600.0)
	kithealthmaxvar = CreateConVar("csgo_drop_health_maximum_var", "1", "what happens when max. Health is reached: 0 = delete Healthpack , 1 = Healthpack will dropped from next dead player , 2 = do nothing with Healthpack", FCVAR_PLUGIN, true, 0.0, true, 2.0)
	kittime = CreateConVar("csgo_drop_health_lifetime", "30", "<#> = number of seconds a dropped Healthpackage stays on the map", FCVAR_PLUGIN, true, 10.0, true, 180.0)
	kitcount = CreateConVar("csgo_drop_health_counter", "0", "drop a Package every X deaths! 0 = disable - when enabled random drop is disabled", FCVAR_PLUGIN, true, 0.0, true, 60.0)
	dropmodel = CreateConVar("csgo_drop_model", "2", "Model to use: 0=chianti bottle; 1=chicken; 2=Life Ring; 3=Mushroom_Small; 4=Mushroom_Large; 5=HL2-Healthkit; 6=CS_GIFT", FCVAR_PLUGIN, true, 0.0, true, 6.0)
	messagedropenabled    = CreateConVar("csgo_drop_message_dropped",    "0", "Enable(1) or disable(0) message when a Pack was dropped", FCVAR_PLUGIN)
	messagepickupenabled    = CreateConVar("csgo_drop_message_pickup",    "1", "Enable (1) or disable(0) message when Pickup a Pack", FCVAR_PLUGIN)
	PickUpSoundName = CreateConVar("csgo_drop_pickup_sound", "darky/mario_powerup.mp3", "Own Sound played when Pickup the Pack(must be MP3 and in sound folder!)")
	UseOwnPickUpSound    = CreateConVar("csgo_drop_own_pickup_sound",    "0", "Enable (1) or disable(0) your own PickUp Soundfile", FCVAR_PLUGIN)
	AutoExecConfig(true, "csgo_drop_random_health", "csgo_drop_random_health")
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre)
	LoadTranslations("csgo_drop_random_health.phrases")
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/items/medkit_large.dx80.vtx")
	AddFileToDownloadsTable("models/items/medkit_large.dx90.vtx")
	AddFileToDownloadsTable("models/items/medkit_large.mdl")
	AddFileToDownloadsTable("models/items/medkit_large.phy")
	AddFileToDownloadsTable("models/items/medkit_large.sw.vtx")
	AddFileToDownloadsTable("models/items/medkit_large.vvd")
	AddFileToDownloadsTable("models/items/medkit_small.dx80.vtx")
	AddFileToDownloadsTable("models/items/medkit_small.dx90.vtx")
	AddFileToDownloadsTable("models/items/medkit_small.mdl")
	AddFileToDownloadsTable("models/items/medkit_small.phy")
	AddFileToDownloadsTable("models/items/medkit_small.sw.vtx")
	AddFileToDownloadsTable("models/items/medkit_small.vvd")
	AddFileToDownloadsTable("materials/models/items/mushroom/eye.vmt")
	AddFileToDownloadsTable("materials/models/items/mushroom/eye.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/eye_normal.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/lightwrap.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/mush_large.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/mush_large.vmt")
	AddFileToDownloadsTable("materials/models/items/mushroom/mush_small.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/mush_small.vmt")
	AddFileToDownloadsTable("materials/models/items/mushroom/normal.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/stem.vmt")
	AddFileToDownloadsTable("materials/models/items/mushroom/stem.vtf")
	AddFileToDownloadsTable("materials/models/items/mushroom/stem_normal.vtf")
	
	AddFileToDownloadsTable("models/items/healthkit.dx80.vtx")
	AddFileToDownloadsTable("models/items/healthkit.dx90.vtx")
	AddFileToDownloadsTable("models/items/healthkit.mdl")
	AddFileToDownloadsTable("models/items/healthkit.phy")
	AddFileToDownloadsTable("models/items/healthkit.sw.vtx")
	AddFileToDownloadsTable("models/items/healthkit.vvd")
	AddFileToDownloadsTable("materials/models/items/healthkit01.vmt")
	AddFileToDownloadsTable("materials/models/items/healthkit01.vtf")
	AddFileToDownloadsTable("materials/models/items/healthkit01_mask.vtf")
	
	AddFileToDownloadsTable("models/items/cs_gift.dx80.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.dx90.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.mdl")
	AddFileToDownloadsTable("models/items/cs_gift.phy")
	AddFileToDownloadsTable("models/items/cs_gift.sw.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.vvd")
	AddFileToDownloadsTable("materials/models/items/cs_gift.vmt")
	AddFileToDownloadsTable("materials/models/items/cs_gift.vtf")
		
	PrecacheModel(g_HealthKit_Model[0],true)
	PrecacheModel(g_HealthKit_Model[1],true)
	PrecacheModel(g_HealthKit_Model[2],true)
	PrecacheModel(g_HealthKit_Model[3],true)
	PrecacheModel(g_HealthKit_Model[4],true)
	PrecacheModel(g_HealthKit_Model[5],true)
	PrecacheModel(g_HealthKit_Model[6],true)
	PrecacheSound(g_HealthKit_Sound, true)
	PrecacheSound(g_HealthKitdenied_Sound, true)
	kitcountcounter = 0
	deadkitammount = 0
	GetConVarString(PickUpSoundName, soundName, MAX_FILE_LEN)
	decl String:buffer[MAX_FILE_LEN]
	PrecacheSound(soundName, true)
	Format(buffer, sizeof(buffer), "sound/%s", soundName)
	AddFileToDownloadsTable(buffer)
}


public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// LOG MESSAGE IF MAX. ENTITIES REACHED
	if (GetEntityCount() >= GetMaxEntities() - 64)
	{
		LogMessage("too much Entity spawned %i : max. is %i ( -64 )", GetEntityCount(), GetMaxEntities())
		SetFailState("Plugin unloaded because of too much entities!")
	}
	
	if ((GetConVarInt(kitcount) == 0) && (GetEntityCount() < GetMaxEntities() - 64))
	{
		if (deadkitammount == 1)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"))
			new Float:deathorigin[3]
			GetClientAbsOrigin(client,deathorigin)
			deathorigin[2] += 80.0 // above
			deathorigin[1] -= 20.0 // + = left from front
			deathorigin[0] -= 150.0 // + = front
			new healthkit = CreateEntityByName("prop_physics_override")
			SetEntityModel(healthkit,g_HealthKit_Model[GetConVarInt(dropmodel)])
			SetEntProp(healthkit, Prop_Send, "m_nSkin", g_HealthKit_Skin[0])
			if (DispatchSpawn(healthkit))
			{
				SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
				SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
			}
			TeleportEntity(healthkit, deathorigin, NULL_VECTOR, NULL_VECTOR)
			SDKHook(healthkit, SDKHook_Touch, OnHealthKitTouched)
			HealthKitDropTimer[healthkit] = CreateTimer(GetConVarFloat(kittime), RemoveDroppedHealthKit, healthkit, TIMER_FLAG_NO_MAPCHANGE)
			if (GetConVarInt(messagedropenabled) == 1)
			{
				PrintToChatAll("\x01\x0B\x02 %t", "player_drop", client, GetConVarInt(kithealth))
				PrintCenterTextAll("%t", "player_drop", client, GetConVarInt(kithealth))
			}
			deadkitammount = 0
			return Plugin_Continue		
		}
			
		new randomplayercount = 12+GetClientCount()
		new randomdeath = GetURandomInt() % randomplayercount
		if (randomdeath == 9)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"))
			new Float:deathorigin[3]
			GetClientAbsOrigin(client,deathorigin)
			deathorigin[2] += 80.0 // above
			deathorigin[1] -= 20.0 // + = left from front
			deathorigin[0] -= 150.0 // + = front
			new healthkit = CreateEntityByName("prop_physics_override")
			SetEntityModel(healthkit,g_HealthKit_Model[GetConVarInt(dropmodel)])
			SetEntProp(healthkit, Prop_Send, "m_nSkin", g_HealthKit_Skin[0])
			if (DispatchSpawn(healthkit))
			{
				SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
				SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
			}
			TeleportEntity(healthkit, deathorigin, NULL_VECTOR, NULL_VECTOR)
			SDKHook(healthkit, SDKHook_Touch, OnHealthKitTouched)
			HealthKitDropTimer[healthkit] = CreateTimer(GetConVarFloat(kittime), RemoveDroppedHealthKit, healthkit, TIMER_FLAG_NO_MAPCHANGE)
			if (GetConVarInt(messagedropenabled) == 1)
			{
				PrintToChatAll("\x01\x0B\x02 %t", "player_drop", client, GetConVarInt(kithealth))
				PrintCenterTextAll("%t", "player_drop", client, GetConVarInt(kithealth))
			}	
			return Plugin_Continue
		}
	}
	kitcountcounter++
	if ((GetConVarInt(kitcount) == kitcountcounter) && (GetEntityCount() < GetMaxEntities() - 64))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		new Float:deathorigin[3]
		GetClientAbsOrigin(client,deathorigin)
		deathorigin[2] += 80.0 // above
		deathorigin[1] -= 20.0 // + = left from front
		deathorigin[0] -= 150.0 // + = front
		new healthkit = CreateEntityByName("prop_physics_override")
		SetEntityModel(healthkit,g_HealthKit_Model[GetConVarInt(dropmodel)])
		SetEntProp(healthkit, Prop_Send, "m_nSkin", g_HealthKit_Skin[0])
		if (DispatchSpawn(healthkit))
		{
			SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
			SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
		}
		TeleportEntity(healthkit, deathorigin, NULL_VECTOR, NULL_VECTOR)
		SDKHook(healthkit, SDKHook_Touch, OnHealthKitTouched)
		HealthKitDropTimer[healthkit] = CreateTimer(GetConVarFloat(kittime), RemoveDroppedHealthKit, healthkit, TIMER_FLAG_NO_MAPCHANGE)
		if (GetConVarInt(messagedropenabled) == 1)
		{
			PrintToChatAll("\x01\x0B\x02 %t", "player_drop", client, GetConVarInt(kithealth))
			PrintCenterTextAll("%t", "player_drop", client, GetConVarInt(kithealth))
		}	
		kitcountcounter = 0
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:OnHealthKitTouched(healthkit, client)
{
	if(client > 0 && client <= GetMaxClients() && healthkit > 0 && !IsFakeClient(client) && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEdict(healthkit))
	{
		new health = GetClientHealth(client)
		new healthkitadd = GetConVarInt(kithealth)
		new healthkitmax = GetConVarInt(kithealthmax)
		if (health < healthkitmax)
		{
			new healthtemp = 0
			if((health + healthkitadd) > healthkitmax)
			{
				healthtemp = healthkitmax
			}
			else
			{
				healthtemp = health + healthkitadd
			}
			SetEntityHealth(client,healthtemp)			
			KillHealthKitTimer(healthkit)
			if (GetConVarInt(UseOwnPickUpSound) == 0)
			{
				PlayPickUpSound(client)
			}
			else
			{
				//EmitSoundToClient(client,soundName)
				ClientCommand(client, "play *%s" , soundName)
			}
			RemoveEdict(healthkit)
			if (GetConVarInt(messagepickupenabled) == 1)
			{
				PrintToChat(client, " \x04 %t", "player_pickup", GetConVarInt(kithealth))
				PrintCenterText(client, "%t", "player_pickup", GetConVarInt(kithealth))
			}	
		}
		else
		{
			if (GetConVarInt(kithealthmaxvar) == 0)
			{
				KillHealthKitTimer(healthkit)
				RemoveEdict(healthkit)
				PlayDeniedSound(client)
				if (GetConVarInt(messagepickupenabled) == 1)
				{
					PrintToChat(client, " \x04 %t", "player_health_destroyed")
					PrintCenterText(client, "%t", "player_health_destroyed")
				}	
			}
			if (GetConVarInt(kithealthmaxvar) == 1)
			{
				KillHealthKitTimer(healthkit)
				RemoveEdict(healthkit)
				PlayDeniedSound(client)
				if (GetConVarInt(messagepickupenabled) == 1)
				{
					PrintToChat(client, " \x04 %t", "player_health_next_dead")
					PrintCenterText(client, "%t", "player_health_next_dead")
				}	
				deadkitammount = 1
			}
			if (GetConVarInt(kithealthmaxvar) == 2)
			{
				// SHIT WHAT DO DO THAT PLAYER CAN NOT PICK IT UP !!!!
				if (GetConVarInt(messagepickupenabled) == 1)
				{
					PrintCenterText(client, "%t", "player_health_do_nothing")
				}	
			}	
		}	
	}
	return Plugin_Handled
}

stock KillHealthKitTimer(healthkit)
{
	if(HealthKitDropTimer[healthkit] != INVALID_HANDLE)
	{
		CloseHandle(HealthKitDropTimer[healthkit])
	}
	HealthKitDropTimer[healthkit] = INVALID_HANDLE
}

stock PlayPickUpSound(client)
{
	EmitSoundToClient(client, g_HealthKit_Sound, SOUND_FROM_PLAYER,SNDCHAN_WEAPON,SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
}

stock PlayDeniedSound(client)
{
	EmitSoundToClient(client, g_HealthKitdenied_Sound, SOUND_FROM_PLAYER,SNDCHAN_WEAPON,SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
}

public Action:RemoveDroppedHealthKit(Handle:timer, any:healthkit)
{
	HealthKitDropTimer[healthkit] = INVALID_HANDLE
	if(IsValidEdict(healthkit))
	{
		RemoveEdict(healthkit)
	}
	return Plugin_Handled
}