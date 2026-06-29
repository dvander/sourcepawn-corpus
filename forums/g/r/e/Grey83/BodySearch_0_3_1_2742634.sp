#pragma semicolon 1

#include <sdktools_engine>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_sound>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

int
	redColor[4]		= {255, 75, 75, 255},
	greenColor[4]	= {75, 255, 75, 255},
	blueColor[4]	= {75, 75, 255, 255},
	whiteColor[4]	= {255, ...},
	greyColor[4]	= {128, 128, 128, 255};

TopMenu
	hTopMenu;
UserMsg
	g_FadeUserMsgId;
EngineVersion
	g_GameEngine = Engine_Unknown;
int
	g_Serial_Gen,
	g_BeamSprite		= -1,
	g_BeamSprite2		= -1,
	g_HaloSprite		= -1,
	g_GlowSprite		= -1,
	g_ExplosionSprite	= -1,
	g_ExternalBeaconColor[4]	= {255, ...},
	g_Team1BeaconColor[4]		= {255, ...},
	g_Team2BeaconColor[4]		= {255, ...},
	g_Team3BeaconColor[4]		= {255, ...},
	g_Team4BeaconColor[4]		= {255, ...},
	g_TeamUnknownBeaconColor[4]	= {255, ...};
char
	g_BlipSound[PLATFORM_MAX_PATH],
	g_BeepSound[PLATFORM_MAX_PATH],
	g_FinalSound[PLATFORM_MAX_PATH],
	g_BoomSound[PLATFORM_MAX_PATH],
	g_FreezeSound[PLATFORM_MAX_PATH];
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE
#include "funcommands/beacon.sp"
#include "funcommands/drug.sp"
#include "funcommands/ice.sp"

#define WHITE		0x01
#define LIGHTGREEN	0x05
#define GREEN		0x06

bool
	g_bAlreadySearch[MAXPLAYERS+1],
	blockSpawn;
char
	g_cLastSearchModel[MAXPLAYERS+1][PLATFORM_MAX_PATH+1];
Handle
	g_hTimeSearch[MAXPLAYERS+1],
	g_hGiveLoot[MAXPLAYERS+1];

int
	iFlags,
	iTeam,
	g_iCollisionGroup = -1;
ArrayList
	g_aRagdollArray,
	g_aWeapon;

public Plugin myinfo = 
{
	name		= "Dead Body Search",
	author		= "Vexyos",
	description	= "Make interactions with dead bodys",
	version		= "0.3.1 (rewritten by Grey83)",
	url			= "http://www.oftenplay.fr"
}

enum struct Ragdoll
{
	int ent;
	int victim;
	int attacker;
	char victimName[MAX_NAME_LENGTH];
	char attackerName[MAX_NAME_LENGTH];
	bool scanned;
	float gameTime;
	char weaponused[32];
	bool found;
}

public void OnPluginStart()
{
	ConVar cvar = CreateConVar("sm_dbs_weapon", "p90,bizon", "List of random weapons (without 'weapon_', comma to separate)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Weapon);
	CVarChanged_Weapon(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_dbs_flag", "", "The flag is necessary so that the corpses can be searched.", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Flag);
	CVarChanged_Flag(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_dbs_team", "1", "A team whose corpses can be searched: 0 - none, 1 - both, 2 - T, 3 - CT", _, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChanged_Team);
	iTeam = cvar.IntValue;

	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("round_prestart", Event_RoundStartPre, EventHookMode_Pre);

	HookEvent("player_changename", Event_ChangeName);

	g_iCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	g_aRagdollArray = new ArrayList(sizeof(Ragdoll));

	g_GameEngine = GetEngineVersion();

	AutoExecConfig(true, "dead_body_search");
}

public void CVarChanged_Weapon(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(g_aWeapon) g_aWeapon.Clear();
	int num;
	char buffer[512], wpn[34][16];
	cvar.GetString(buffer, sizeof(buffer));
	if(strlen(buffer) < 3 || !(num = ExplodeString(buffer, ",", wpn, sizeof(wpn), sizeof(wpn[]))))
		return;

	g_aWeapon = new ArrayList(ByteCountToCells(16));
	for(int i; i < num; i++) if(strlen(wpn[i]) > 2) g_aWeapon.PushString(wpn[i]);
}

public void CVarChanged_Flag(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char flags[24];
	cvar.GetString(flags, sizeof(flags));
	iFlags = flags[0] ? ReadFlagString(flags) : 0;
}

public void CVarChanged_Team(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iTeam = cvar.IntValue;
}

public void OnMapStart()
{
	GameData gameConfig = new GameData("funcommands.games");
	if(!gameConfig)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	char buffer[PLATFORM_MAX_PATH];
	if(gameConfig.GetKeyValue("SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
		PrecacheSound(g_BlipSound, true);
	if(gameConfig.GetKeyValue("SoundBeep", g_BeepSound, sizeof(g_BeepSound)) && g_BeepSound[0])
		PrecacheSound(g_BeepSound, true);
	if(gameConfig.GetKeyValue("SoundFinal", g_FinalSound, sizeof(g_FinalSound)) && g_FinalSound[0])
		PrecacheSound(g_FinalSound, true);
	if(gameConfig.GetKeyValue("SoundBoom", g_BoomSound, sizeof(g_BoomSound)) && g_BoomSound[0])
		PrecacheSound(g_BoomSound, true);
	if(gameConfig.GetKeyValue("SoundFreeze", g_FreezeSound, sizeof(g_FreezeSound)) && g_FreezeSound[0])
		PrecacheSound(g_FreezeSound, true);
	if(gameConfig.GetKeyValue("SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
		g_BeamSprite = PrecacheModel(buffer);
	if(gameConfig.GetKeyValue("SpriteBeam2", buffer, sizeof(buffer)) && buffer[0])
		g_BeamSprite2 = PrecacheModel(buffer);
	if(gameConfig.GetKeyValue("SpriteExplosion", buffer, sizeof(buffer)) && buffer[0])
		g_ExplosionSprite = PrecacheModel(buffer);
	if(gameConfig.GetKeyValue("SpriteGlow", buffer, sizeof(buffer)) && buffer[0])
		g_GlowSprite = PrecacheModel(buffer);
	if(gameConfig.GetKeyValue("SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
		g_HaloSprite = PrecacheModel(buffer);
	if(gameConfig.GetKeyValue("ExternalBeaconColor", buffer, sizeof(buffer)) && buffer[0])
		g_ExternalBeaconColor = ParseColor(buffer);
	if(gameConfig.GetKeyValue("Team1BeaconColor", buffer, sizeof(buffer)) && buffer[0])
		g_Team1BeaconColor = ParseColor(buffer);
	if(gameConfig.GetKeyValue("Team2BeaconColor", buffer, sizeof(buffer)) && buffer[0])
		g_Team2BeaconColor = ParseColor(buffer);
	if(gameConfig.GetKeyValue("Team3BeaconColor", buffer, sizeof(buffer)) && buffer[0])
		g_Team3BeaconColor = ParseColor(buffer);
	if(gameConfig.GetKeyValue("Team4BeaconColor", buffer, sizeof(buffer)) && buffer[0])
		g_Team4BeaconColor = ParseColor(buffer);
}

public void OnMapEnd()
{
	KillAllBeacons();
	KillAllFreezes();
	KillAllDrugs();
}

stock int[] ParseColor(const char[] buffer)
{
	char sColor[16][4];
	ExplodeString(buffer, ",", sColor, sizeof(sColor), sizeof(sColor[]));

	int iColor[4];
	iColor[0] = StringToInt(sColor[0]);
	iColor[1] = StringToInt(sColor[1]);
	iColor[2] = StringToInt(sColor[2]);
	iColor[3] = StringToInt(sColor[3]);

	return iColor;
}

public Action Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	g_aRagdollArray.Clear();

	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i))
	{
		g_bAlreadySearch[i] = false;
		g_hTimeSearch[i] = null;
		g_hGiveLoot[i] = null;
	}
}

stock bool IsClientValid(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public void Event_PlayerDeathPre(Event event, const char[] menu, bool dontBroadcast)
{
	if(!iTeam) return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	g_hTimeSearch[client] = null;
	g_hGiveLoot[client] = null;

	if(iTeam == 1 || GetClientTeam(client) == iTeam)
	{
		int iRagdoll;
		if((iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll")) > 0)
			AcceptEntityInput(iRagdoll, "Kill");

		char playermodel[128];
		GetClientModel(client, playermodel, 128);

		int iEntity = CreateEntityByName("prop_ragdoll");
		DispatchKeyValue(iEntity, "model", playermodel);

		// Prevent crash. If spawn isn't dispatched successfully,
		// TeleportEntity() crashes the server. This left some very
		// odd crash dumps, and usually only happened when 2 players
		// died inside each other in the same tick.
		// Thanks to -
		//		Phoenix Gaming Network(pgn.site)
		//		Prestige Gaming Organization
		if(!blockSpawn)
		{
			float origin[3], angles[3], velocity[3];
			GetClientAbsOrigin(client, origin);
			GetClientAbsAngles(client, angles);
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);

			blockSpawn = true;

			ActivateEntity(iEntity);
			if(DispatchSpawn(iEntity))
				TeleportEntity(iEntity, origin, angles, GetVectorLength(velocity) >= 500 ? NULL_VECTOR : velocity);

			blockSpawn = false;
		}

		SetEntData(iEntity, g_iCollisionGroup, 2, 4, true);

		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		Ragdoll body;
		body.ent = EntIndexToEntRef(iEntity);
		body.victim = client;
		Format(body.victimName, sizeof(Ragdoll::victimName), name);
		body.scanned = false;
		GetClientName(iAttacker, name, sizeof(name));
		body.attacker = iAttacker;
		Format(body.attackerName, sizeof(Ragdoll::attackerName), name);
		body.gameTime = GetGameTime();
		event.GetString("weapon", body.weaponused, sizeof(body.weaponused));

		g_aRagdollArray.PushArray(body);

		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", iEntity);
	}
}

public Action Event_ChangeName(Event event, const char[] name, bool dontBroadcast)
{
	int iSize = GetArraySize(g_aRagdollArray);
	if(!iSize)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || IsClientInGame(client))
		return;

	char userName[MAX_NAME_LENGTH];
	event.GetString("newname", userName, sizeof(userName));

	Ragdoll body;

	for(int i, size = GetArraySize(g_aRagdollArray); i < size; i++)
	{
		g_aRagdollArray.GetArray(i, body);

		if(client == body.attacker)
		{
			Format(body.attackerName, sizeof(Ragdoll::attackerName), userName);
			g_aRagdollArray.SetArray(i, body);
		}
		else if(client == body.victim)
		{
			Format(body.victimName, sizeof(Ragdoll::victimName), userName);
			g_aRagdollArray.SetArray(i, body);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!iTeam || !IsClientInGame(client) || iFlags && !(iFlags & GetUserFlagBits(client)))
		return Plugin_Continue;

	if(buttons & IN_ATTACK && g_bAlreadySearch[client])
		buttons &= ~IN_ATTACK; 

	if(!(buttons & IN_USE))
		return Plugin_Continue;

	int iSize = GetArraySize(g_aRagdollArray);
	if(!iSize)
		return Plugin_Continue;

	int entidad = GetClientAimTarget(client, false);
	if(entidad < 1)
		return Plugin_Continue;

	float OriginG[3], TargetOriginG[3];
	GetClientEyePosition(client, TargetOriginG);
	GetEntPropVector(entidad, Prop_Data, "m_vecOrigin", OriginG);
	if(GetVectorDistance(TargetOriginG,OriginG, false) > 90.0)
		return Plugin_Continue;

	Ragdoll body;

	for(int i, uid = GetClientUserId(client); i < iSize; i++)
	{
		g_aRagdollArray.GetArray(i, body);

		if(EntRefToEntIndex(body.ent) == entidad && GetClientTeam(client) == 2)
		{
			if(!g_bAlreadySearch[client])
			{
				g_hTimeSearch[client] = CreateTimer(3.0, Timer_SearchBlock, uid);
				SetEntityRenderColor(client, 255, 0, 0, 255);
				SetEntityMoveType(client, MOVETYPE_NONE);
				g_bAlreadySearch[client] = true;

				if(!body.found && IsPlayerAlive(client))
				{
					body.found = true;

					PrintToChat(client, "[%cSearch%c] Ragdoll searching ...", LIGHTGREEN, WHITE);

					GetClientModel(body.victim, g_cLastSearchModel[client], sizeof(g_cLastSearchModel[]));

					g_hGiveLoot[client] = CreateTimer(3.0, Timer_GiveLoot, uid);
				}
				else PrintToChat(client, "[%cSearch%c] This body was already stripped and clothes are full of blood .", LIGHTGREEN, WHITE);
			}

			g_aRagdollArray.SetArray(i, body);

			break;
		}
	}

	return Plugin_Continue;
}

public Action Timer_SearchBlock(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)))
	{
		g_bAlreadySearch[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_hTimeSearch[client] = null;
	}
}

public Action Timer_GiveLoot(Handle timer, any client)
{
	if(!(client = GetClientOfUserId(client)))
	{
		g_hGiveLoot[client] = null;
		return Plugin_Stop;
	}

	static int reward;
	if(!(reward = GetRandomInt(0, 99)%20))			// 5%
	{
		SetEntityModel(client, g_cLastSearchModel[client]);
		PrintToChat(client, "[%cSearch%c] You stole the clothes of the dead body, you look like him now!", LIGHTGREEN, WHITE);
	}
	else if(reward < 3)	// 10%
	{
		GivePlayerItem(client, "weapon_healthshot");
		GivePlayerItem(client, "weapon_tagrenade");
		GivePlayerItem(client, "weapon_axe");
		PrintToChat(client, "[%cSearch%c] You found a healthshot, TA grenade and axe in the pockets and on the belt of the dead body", LIGHTGREEN, WHITE);
	}
	else if(reward < 6)	// 15%
	{
		char wpn[24];
		int iSize = GetArraySize(g_aWeapon);
		if(!iSize) wpn ="weapon_taser";
		else
		{
			g_aWeapon.GetString(GetRandomInt(0, iSize-1), wpn, sizeof(wpn));
			Format(wpn, sizeof(wpn), "weapon_%s", wpn);
		}
		GivePlayerItem(client, wpn);
		PrintToChat(client, "[%cSearch%c] You found a gun in the cases on the belt of the dead body.", LIGHTGREEN, WHITE);
	}
	else if(reward < 12)// 30%
	{
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_smokegrenade");
		PrintToChat(client, "[%cSearch%c] You found few grenades in the pocket  of the dead body.", LIGHTGREEN, WHITE);
	}
	else				// 40%
	{
		switch(GetRandomInt(0, 3))
		{
			case 0:
			{
				CreateDrug(client);
				CreateTimer(5.0, Timer_KillDrug, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			case 1:	SlapPlayer(client, 5);
			case 2:	IgniteEntity(client, 5.0);
			case 3:	FreezeClient(client, 5);
			case 4:
			{
				CreateBeacon(client);
				CreateTimer(5.0, Timer_KillBeacon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		PrintToChat(client, "[%cSearch%c] Nothing is usable on this body, try an another one.", LIGHTGREEN, WHITE);
	}

	g_hGiveLoot[client] = null;
	return Plugin_Stop;
}

public Action Timer_KillDrug(Handle timer, any client)
{
	if((client = GetClientOfUserId(client))) KillDrug(client);
}

public Action Timer_KillBeacon(Handle timer, any client)
{
	if((client = GetClientOfUserId(client))) KillBeacon(client);
}