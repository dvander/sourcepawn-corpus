/*//
THIS PLUGIN DROPS RANDOM OR EVERY "X" DEATHS A "PACKAGE OF SPEED" AFTER A PLAYER DIES.
RANDOM VALUE = 22 + PLAYERS ON SERVER! RANDOM = 9 A SPEEDPACK DROPS. RANDOM = 11 A HEALTPACK DROPS. RANDOM = 7 TWO GRENADES DROP!
MODELS LIST = 0=chianti bottle; 1=chicken; 2=Life Ring; 3=Mushroom_Small; 4=Mushroom_Large; 5=HEGrenade; 6=CardBoard; 7=Skull
VERSION 1.1
ADDED GRUNT MODEL
thanks to Morell for the good work: (http://mapeadores.com/topic/5002-servant-grunt/page__p__7089__hl__grunt__fromsearch__1#entry7089)
VERSION 1.2
ADDED DROP HEALTHPACK TOO .. :)
CHANGED NAME TO DROP RANDOM PACKAGE
VERSION 1.3
ADDED NEW CVARS
VERSION 1.4
CHANGED THE DROP CO-ORDINATES
deathorigin[2] += 15.0 + deathorigin[1] += 10.0
VERSION 1.5
ADDED HE Grenade
ADDED MAX HP CHECK
VERSION 1.6
now you can choose which Packagemodel is used for Health and Speed
added HEGrenade Model as own dropmodel
VERSION 1.7
changed how to play own pickup Sound
VERSION 1.8
code cleanup
added more Models
VERSION 1.9
fixed speed package when a players levels up in AR Mode! (speed goes back to normal before!)
VERSION 2.0
plugin now checks speed of player when pick up health (problem with my Knife&Speed plugin!)
some litte improvements!
VERSION 2.1
added max Entities Check to prevent crashes!
changed sdkhook from Touch -> StartTouch
added new Model cs_gift package
VERSION 2.2
ADDED FROM ROOT (thanks a lot)
	if (DispatchSpawn(healthkit))
		{
			SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
			SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
		}
reverted from V2.1 :sdkhook from StrtTouch -> Touchback	
VERSION 2.3
changed soundpath
		
*/

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>
#define MAXENTITIES 1024
#define MAX_FILE_LEN 128
#define PLUGIN_VERSION "2.3"
#define PLAYER_MDL "models/player/mapeadores/morell/amnesia/grunt/grunt.mdl"

public Plugin:myinfo =
{
	name = "CS:GO Drop Random Package Plugin",
	author = "Darkranger",
	description = "Random when a Player dies a Health-, Speed-, or HEGrenade Package will be dropped!",
	version = PLUGIN_VERSION,
	url = "http://dark.asmodis.at"
}

static const String:g_HealthKit_Model[9][] = { "models/props/cs_italy/chianti02.mdl" , "models/chicken/chicken.mdl" , "models/props_urban/life_ring001.mdl" , "models/items/medkit_small.mdl" , "models/items/medkit_large.mdl" , "models/weapons/w_eq_fraggrenade.mdl" , "models/props/cs_office/cardboard_box01.mdl" , "models/gibs/hgibs.mdl" , "models/items/cs_gift.mdl"}
new String:soundName[MAX_FILE_LEN]
new Handle:HealthKitDropTimer[MAXENTITIES+1] = INVALID_HANDLE
new String:g_HealthKit_Sound[] = { "ui/beep22.wav" }
new g_HealthKit_Skin[2] = { 0, 0 }
new Handle:kitspeed = INVALID_HANDLE
new Handle:kittime = INVALID_HANDLE
new Handle:kithealth = INVALID_HANDLE
new Handle:kitcount = INVALID_HANDLE
new Handle:kithealthmax = INVALID_HANDLE
new Handle:kitcounthealth = INVALID_HANDLE
new Handle:kitcountgrenade = INVALID_HANDLE
new Handle:dropmodelspeed = INVALID_HANDLE
new Handle:dropmodelhealth = INVALID_HANDLE
new Handle:dropmodelgrenade = INVALID_HANDLE
new Handle:messagedropenabled = INVALID_HANDLE
new Handle:messagepickupenabled = INVALID_HANDLE
new Handle:kithegrenade = INVALID_HANDLE
new Handle:PickUpSoundName = INVALID_HANDLE
new Handle:UseOwnPickUpSound = INVALID_HANDLE
new Handle:UseOwnModel = INVALID_HANDLE
new kitcountcounterspeed = 0
new kitcountcounterhealth = 0
new kitcountcountergrenade = 0
new g_LevelUp[MAXPLAYERS + 1]    = {1, ...}

public OnPluginStart()
{
	CreateConVar("csgo_drop_package_version", PLUGIN_VERSION, "CS:GO Drop Random Package Plugin Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	kitspeed = CreateConVar("csgo_drop_random_speed", "1.5", "Speed for the Player when picking up a Pack", FCVAR_PLUGIN, true, 1.0, true, 2.0)
	kittime = CreateConVar("csgo_drop_random_lifetime", "20", "<#> = number of seconds a dropped Package stays on the map", FCVAR_PLUGIN, true, 10.0, true, 60.0)
	kithegrenade = CreateConVar("csgo_drop_random_HEgrenade", "0", "Enable (1) or disable(0) Drop a HEgrenade with Health & Speed Pack", FCVAR_PLUGIN)
	kithealthmax = CreateConVar("csgo_drop_health_maximum", "200", "max. Amount of HP a Player can have to pickup a Healthpack", FCVAR_PLUGIN, true, 100.0, true, 600.0)
	kithealth = CreateConVar("csgo_drop_random_health_amount", "40", "<#> = Amount of HP to add to a player when pick up a Healthpack", FCVAR_PLUGIN, true, 5.0, true, 300.0)
	kitcount = CreateConVar("csgo_drop_random_xspeed_counter", "0", "drop a Speed Package every X deaths! 0=disable - if greater 0 random is disabled! use uneven numbers! and dont use same numbers!", FCVAR_PLUGIN, true, 0.0, true, 200.0)
	kitcounthealth = CreateConVar("csgo_drop_random_xhealth_counter", "0", "drop a Health Package every X deaths! 0=disable - if greater 0 random is disabled! use uneven numbers! and dont use same numbers!", FCVAR_PLUGIN, true, 0.0, true, 200.0)
	kitcountgrenade = CreateConVar("csgo_drop_random_xgrenade_counter", "0", "drop 2 HEgreandes every X deaths! 0=disable - if greater 0 random is disabled! use uneven numbers! and dont use same numbers!", FCVAR_PLUGIN, true, 0.0, true, 200.0)
	dropmodelspeed = CreateConVar("csgo_drop_random_model_speed", "0", "Model for Speed:0=ChiantiBottle;1=chicken;2=LifeRing;3=MushroomSmall;4=MushroomLarge;5=HEGrenade;6=CardBoard;7=Skull;8=CS_Gift", FCVAR_PLUGIN, true, 0.0, true, 8.0)
	dropmodelhealth = CreateConVar("csgo_drop_random_model_health", "4", "Model for Health:0=ChiantiBottle;1=chicken;2=LifeRing;3=MushroomSmall;4=MushroomLarge;5=HEGrenade;6=CardBoard;7=Skull;8=CS_Gift", FCVAR_PLUGIN, true, 0.0, true, 8.0)
	dropmodelgrenade = CreateConVar("csgo_drop_random_model_grenade", "6", "Model for Grenade:0=ChiantiBottle;1=chicken;2=LifeRing;3=MushroomSmall;4=MushroomLarge;5=HEGrenade;6=CardBoard;7=Skull;8=CS_Gift", FCVAR_PLUGIN, true, 0.0, true, 8.0)
	messagedropenabled    = CreateConVar("csgo_drop_random_message_dropped",    "0", "Enable(1) or disable(0) message when a Pack was dropped", FCVAR_PLUGIN)
	messagepickupenabled    = CreateConVar("csgo_drop_random_message_pickup",    "1", "Enable (1) or disable(0) message when Pickup a Pack", FCVAR_PLUGIN)
	PickUpSoundName = CreateConVar("csgo_drop_random_pickup_sound", "darky/mario_powerup.mp3", "Own Sound played when Pickup Health or Speed(must be MP3 and in sound folder)")
	UseOwnPickUpSound    = CreateConVar("csgo_drop_random_own_pickup_sound",    "0", "Enable (1) or disable(0) your own PickUp Soundfile", FCVAR_PLUGIN)
	UseOwnModel   = CreateConVar("csgo_drop_random_own_model",    "0", "Enable (1) or disable(0) Player Model change when pickup a Speedpack", FCVAR_PLUGIN)
	AutoExecConfig(true, "csgo_drop_random_package", "csgo_drop_random_package")
	LoadTranslations("csgo_drop_random_package.phrases")
	HookEvent("player_spawn", OnPlayerSpawn)
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre)
	HookEvent("gg_player_levelup",            Event_CSGOGGLevelUpSpeed)
	HookEvent("ggtr_player_levelup",          Event_CSGOGGLevelUpSpeed)
	HookEvent("ggprogressive_player_levelup", Event_CSGOGGLevelUpSpeed)
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
	AddFileToDownloadsTable("models/player/mapeadores/morell/amnesia/grunt/grunt.mdl")
	AddFileToDownloadsTable("models/player/mapeadores/morell/amnesia/grunt/grunt.dx90.vtx")
	AddFileToDownloadsTable("models/player/mapeadores/morell/amnesia/grunt/grunt.phy")
	AddFileToDownloadsTable("models/player/mapeadores/morell/amnesia/grunt/grunt.vvd")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/Servant_grunt.vmt")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt.vtf")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_hair.vmt")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_hair.vtf")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_hair_nrm.vtf")
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/amnesia/grunt/servant_grunt_nrm.vtf")
	AddFileToDownloadsTable("models/items/cs_gift.dx80.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.dx90.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.mdl")
	AddFileToDownloadsTable("models/items/cs_gift.phy")
	AddFileToDownloadsTable("models/items/cs_gift.sw.vtx")
	AddFileToDownloadsTable("models/items/cs_gift.vvd")
	AddFileToDownloadsTable("materials/models/items/cs_gift.vmt")
	AddFileToDownloadsTable("materials/models/items/cs_gift.vtf")
	PrecacheModel(PLAYER_MDL , true)
	PrecacheModel(g_HealthKit_Model[0],true)
	PrecacheModel(g_HealthKit_Model[1],true)
	PrecacheModel(g_HealthKit_Model[2],true)
	PrecacheModel(g_HealthKit_Model[3],true)
	PrecacheModel(g_HealthKit_Model[4],true)
	PrecacheModel(g_HealthKit_Model[5],true)
	PrecacheModel(g_HealthKit_Model[6],true)
	PrecacheModel(g_HealthKit_Model[7],true)
	PrecacheModel(g_HealthKit_Model[8],true)
	PrecacheSound(g_HealthKit_Sound, true)
	kitcountcounterspeed = 0
	kitcountcounterhealth = 0
	kitcountcountergrenade = 0
	ServerCommand("ammo_grenade_limit_default 4")
}

public OnConfigsExecuted()
{
	GetConVarString(PickUpSoundName, soundName, MAX_FILE_LEN)
	decl String:buffer[MAX_FILE_LEN]
	PrecacheSound(soundName, true)
	Format(buffer, sizeof(buffer), "sound/%s", soundName)
	AddFileToDownloadsTable(buffer)
	ServerCommand("ammo_grenade_limit_default 4")
}

public OnClientPutInServer(client)
{
	g_LevelUp[client] = 0	
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		g_LevelUp[client] = 0
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// LOG MESSAGE IF MAX. ENTITIES REACHED
	if (GetEntityCount() >= GetMaxEntities() - 64)
	{
		LogMessage("too much Entity spawned %i : max. is %i ( -64 )", GetEntityCount(), GetMaxEntities())
		SetFailState("Plugin unloaded because of too much entities!")
	}
	
	// NEW: CHECK IF MAXENTITES REACHED - WHEN YES: DO NOTHING!!
	if (((GetConVarInt(kitcount) == 0) && (GetConVarInt(kitcounthealth) == 0) && (GetConVarInt(kitcountgrenade) == 0)) && (GetEntityCount() < GetMaxEntities() - 64))
	{
		new randomplayercount = 22+GetClientCount()
		new randomdeath = GetURandomInt() % randomplayercount

		// DROP RANDOM SPEED PACK
		if (randomdeath == 9 || randomdeath == 11)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"))
			g_LevelUp[client] = 0
			new Float:deathorigin[3]
			GetClientAbsOrigin(client,deathorigin)
			deathorigin[2] += 40.0 // above
			deathorigin[1] += 20.0 // + = left from front
			deathorigin[0] -= 200.0 // + = front
			new healthkit = CreateEntityByName("prop_physics_override")
			SetEntityModel(healthkit,g_HealthKit_Model[GetConVarInt(dropmodelspeed)])
			SetEntProp(healthkit, Prop_Send, "m_nSkin", g_HealthKit_Skin[0])
			if (DispatchSpawn(healthkit))
			{
				SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
				SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
			}
			TeleportEntity(healthkit, deathorigin, NULL_VECTOR, NULL_VECTOR)
			SDKHook(healthkit, SDKHook_Touch, OnHealthKitTouchedSpeed)
			HealthKitDropTimer[healthkit] = CreateTimer(GetConVarFloat(kittime), RemoveDroppedHealthKit, healthkit, TIMER_FLAG_NO_MAPCHANGE)
			if (GetConVarInt(messagedropenabled) == 1)
			{
				PrintToChatAll("\x01\x0B\x02 %t", "player_drop_speed", client)
				PrintCenterTextAll("%t", "player_drop_speed", client)
			}
			return Plugin_Continue
		}
	}

	kitcountcounterspeed++
	kitcountcounterhealth++
	kitcountcountergrenade++
	
	// DROP SPEED PACK
	if ((GetConVarInt(kitcount) == kitcountcounterspeed) && (GetEntityCount() < GetMaxEntities() - 64))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		new Float:deathorigin[3]
		GetClientAbsOrigin(client,deathorigin)
		deathorigin[2] += 40.0 // above
		deathorigin[1] += 20.0 // + = left from front
		deathorigin[0] -= 200.0 // + = front
		new healthkit = CreateEntityByName("prop_physics_override")
		SetEntityModel(healthkit,g_HealthKit_Model[GetConVarInt(dropmodelspeed)])
		SetEntProp(healthkit, Prop_Send, "m_nSkin", g_HealthKit_Skin[0])
		if (DispatchSpawn(healthkit))
		{
			SetEntProp(healthkit, Prop_Send, "m_usSolidFlags",  152)
			SetEntProp(healthkit, Prop_Send, "m_CollisionGroup", 11)
		}
		TeleportEntity(healthkit, deathorigin, NULL_VECTOR, NULL_VECTOR)
		SDKHook(healthkit, SDKHook_Touch, OnHealthKitTouchedSpeed)
		HealthKitDropTimer[healthkit] = CreateTimer(GetConVarFloat(kittime), RemoveDroppedHealthKit, healthkit, TIMER_FLAG_NO_MAPCHANGE)
		if (GetConVarInt(messagedropenabled) == 1)
		{
			PrintToChatAll("\x01\x0B\x02 %t", "player_drop_speed", client)
			PrintCenterTextAll("%t", "player_drop_speed", client)
		}
		kitcountcounterspeed = 0
	}
	if (GetConVarInt(kitcount) == kitcountcounterspeed)
	{
		LogMessage("Speedcounter was %d ! Error - reset to 0", kitcountcounterspeed)
		kitcountcounterspeed = 0
	}

		
	return Plugin_Continue
}

public Action:OnHealthKitTouchedSpeed(healthkit, client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(kitspeed))
		g_LevelUp[client] = 1
				
		// GIVE PLAYER HEGRENADE
		if (GetConVarInt(kithegrenade) == 1)
		{
			GivePlayerItem(client, "weapon_hegrenade")
		}
		
		if (GetConVarInt(UseOwnModel) == 1)
		{
			SetEntityModel(client, PLAYER_MDL)
		}
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
			PrintToChat(client, " \x04 %t", "player_pickup_speed")
			PrintCenterText(client, "%t", "player_pickup_speed")
		}
		return Plugin_Handled
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
	ClientCommand(client, "playgamesound \"%s\"", g_HealthKit_Sound)
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

public bool:IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
	{
		return false
	}
	return true
}

public Event_CSGOGGLevelUpSpeed(Handle: event, const String: name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if((IsValidClient(client) && !IsFakeClient(client)) && (g_LevelUp[client] == 1))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(kitspeed))
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_death", OnPlayerDeath)
	UnhookEvent("player_spawn", OnPlayerSpawn)
	UnhookEvent("gg_player_levelup",            Event_CSGOGGLevelUpSpeed)
	UnhookEvent("ggtr_player_levelup",          Event_CSGOGGLevelUpSpeed)
	UnhookEvent("ggprogressive_player_levelup", Event_CSGOGGLevelUpSpeed)
}