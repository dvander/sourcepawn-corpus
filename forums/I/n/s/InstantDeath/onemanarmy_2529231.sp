/* Plugin by InstantDeath

Features:
Team setup system
randomize system for one man army
cloaking system
plugin weapon settings (restrictions & such)
Weapon ladder for the One Man Army.


Credits:
Pred - for speed code.
Greyscale - for grenade code
Sourcemod.


*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1

#define TEAM_T	2
#define TEAM_CT 3

#define Damage_Slot 0 //also used as defense slot
#define MoneySteal_Slot 1
#define MoneyFind_Slot 2
#define ItemFind_Slot 3
#define Skill_Slot 4
#define Skilltype_Slot 5
#define HEALTHKIT_SOUND	"items/medshot4.wav"
#define ITEMPICKUP_SOUND "item/ammopickup.wav"
#define GOODIEBOX_MODEL "models/items/boxmrounds.mdl"
#define EXPLODE_SPR "sprites/zerogxplode.spr"

#define ckevlar "650"
#define ckevlar_ct "100"
#define chelmet "350"
#define chegrenade "400"
#define csmokegrenade "300"
#define cnvgoggles "1250"
#define cOMA_ReqXP "1000"
#define cOMA_MaxLvl "18"


#define Slot_HEgrenade 11
#define Slot_Smokegrenade 13

#define PLUGIN_VERSION "1.71"

public Plugin:myinfo = 
{
	name = "One Man Army",
	author = "InstantDeath",
	description = "1 man with guns vs others with knife and nades",
	version = PLUGIN_VERSION,
	url = "http://www.xpgaming.net"
};

new Handle: cvarpluginstatus = INVALID_HANDLE;
new Handle: cvarallowbots = INVALID_HANDLE;
new Handle: cvarplugindebug = INVALID_HANDLE;
new Handle: cvardmgdetermines = INVALID_HANDLE;
new Handle: cvarkevlar = INVALID_HANDLE;
new Handle: cvarkevlar_ct = INVALID_HANDLE;
new Handle: cvarhelmet = INVALID_HANDLE;
new Handle: cvarhegrenade = INVALID_HANDLE;
new Handle: cvarsmokegrenade = INVALID_HANDLE;
new Handle: cvarnvgoggles = INVALID_HANDLE;
new Handle: cvarteamplay = INVALID_HANDLE;
new Handle: cvaromareqxp = INVALID_HANDLE;
new Handle: cvaromamaxlvl = INVALID_HANDLE;

new Float:PlayerRespawnTime[MAXPLAYERS+1];
new Float:PlayerSpeed[MAXPLAYERS+1];
new Float:PlayerRespawnCount[MAXPLAYERS+1];
//new PlayerSpeedlvl[MAXPLAYERS+1];
new Weaponlvl[MAXPLAYERS+1];
new HeadShotCount[MAXPLAYERS+1];
new PlayerXP[MAXPLAYERS+1];
new XPlvl[12];
new PlayerSkills[MAXPLAYERS+1][11];
new Playerlvl[MAXPLAYERS+1];
new PlayerPoints[MAXPLAYERS+1];
new OMAPoints[MAXPLAYERS+1];
new OMA_XP[MAXPLAYERS+1];
new OMA_lvl[MAXPLAYERS+1];
new OMA_Goodie[MAXPLAYERS+1];
new OMA_ReqXP;
new OMA_MaxLvl;
new OMACurrWeapon[MAXPLAYERS+1];
new OMAdmgTotal[MAXPLAYERS+1];
new OMAdmgTimer[MAXPLAYERS+1];
new KnifeStats[MAXPLAYERS+1][7];
new KnifeStats2[MAXPLAYERS+1][7];
new ArmorStats[MAXPLAYERS+1][6];
new ArmorStats2[MAXPLAYERS+1][6];
new XPlost[MAXPLAYERS+1];
new OMA_Team[MAXPLAYERS+1][4];
new OMA_Teamcount;
new EntityList[60];
new CheckedEntity[MAXPLAYERS+1];

//new bool:CloakGrenade[MAXPLAYERS+1];
new bool:OMAdmgTimerActive[MAXPLAYERS+1];
new bool:LongJump[MAXPLAYERS+1];
new bool:PlayerHealthChecked[MAXPLAYERS+1];
new bool:PlayerArmorChecked[MAXPLAYERS+1];
new bool:PlayerCanCloak[MAXPLAYERS+1];
new bool:OMAlvl2[MAXPLAYERS+1];
new bool:NadeRegenActive[MAXPLAYERS+1];
new bool:SNadeRegenActive[MAXPLAYERS+1];
new bool:OMAmenuActive[MAXPLAYERS+1];
new bool:MapHasEnded;
new bool:FreezeTime;
//new Float: PlayerGravity[MAXPLAYERS+1];
new playercount;
new OMA_StartHealth;
new scoutClient;
new chosenClient;
new g_Account = -1;
new PlayerHealth[MAXPLAYERS+1];
new PlayerArmor[MAXPLAYERS+1];
new bool:LoadedLate;
new VelocityOffset_x;
new VelocityOffset_y;
new BaseVelocityOffset;

new kevlar;
new kevlar_ct;
new helmet;
new hegrenade;
new smokegrenade;
new nvgoggles;


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	LoadedLate = late;
	playercount = GetClientCount(true);
	if(LoadedLate && playercount > 0)
	{
		ServerCommand("mp_restartgame 3");
		CreateTimer(4.7,TimedOMAchooser, TIMER_FLAG_NO_MAPCHANGE);
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("onemanarmy.phrases");
	CreateConVar("sm_onemanarmy_version", PLUGIN_VERSION, "One Man Army Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarallowbots = CreateConVar("sm_oma_allowbots", "1", "Defines whether bots can become the one man army", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarpluginstatus = CreateConVar("sm_onemanarmy_enable", "1", "Enable or disable this plugin", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarplugindebug = CreateConVar("sm_oma_debug", "0", "Prints Debug messages if this is set to 1", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvardmgdetermines = CreateConVar("sm_oma_dmg", "0", "When enabled, the person who did the most dmg to the oma becomes the oma when the oma dies.", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarkevlar = CreateConVar("sm_oma_kevlar", ckevlar, "the cost of regular kevlar", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarkevlar_ct = CreateConVar("sm_oma_kevlar_ct", ckevlar_ct, "the cost of kevlar for Counter-Terrorists", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarhelmet = CreateConVar("sm_oma_helmet", chelmet, "the cost of a helmet", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarhegrenade = CreateConVar("sm_oma_hegrenade", chegrenade, "the cost of an HE grenade", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarsmokegrenade = CreateConVar("sm_oma_smokegrenade", csmokegrenade, "the cost of a smoke grenade", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarnvgoggles = CreateConVar("sm_oma_nvgoggles", cnvgoggles, "the cost of night vision goggles", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvaromareqxp = CreateConVar("sm_oma_xpreq", cOMA_ReqXP, "how much experience is required for the OMA to level up", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvaromamaxlvl = CreateConVar("sm_oma_maxlvl", cOMA_MaxLvl, "The level at which to give the OMA the final weapon to end the game", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarteamplay = CreateConVar("sm_oma_teamplay", "1", "When enabled, the OMA can choose up to 4 teammates at level 2.", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_oma_who", Command_WhoIsOMA, ADMFLAG_GENERIC, "Displays current one man army and level");
	RegAdminCmd("sm_cloakstatus", Command_CloakStatus, ADMFLAG_GENERIC, "Displays current cloak status");
	//	RegAdminCmd("sm_hidehud", Command_HideHud, ADMFLAG_GENERIC, "hide hud");
	RegAdminCmd("sm_skillreset", Command_SkillReset, ADMFLAG_BAN, "Resets players skill set, so they can reassign their skills.");
	RegConsoleCmd("say", Command_Say);
	//RegConsoleCmd("spawngoodie", Command_SpawnGoodie);
	RegAdminCmd("sm_xp", Command_XP, ADMFLAG_GENERIC, "Displays current skill levels for 1 player or all players");
	//RegAdminCmd("sm_rechecklvl", Command_RecheckLevel, ADMFLAG_BAN, "Forces the plugin to recheck levels and sets everyone's level to the appropiate value.");
	RegAdminCmd("sm_oma_status", Command_OMAStatus, ADMFLAG_GENERIC, "Displays current skill tree status for one man army");
	// Find offsets
	g_Account = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	if (g_Account == -1)
	{
		SetFailState("[SM] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}
	
	VelocityOffset_x = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");
	if(VelocityOffset_x == -1)
		SetFailState("[SM] Error: Failed to find Velocity[0] offset, aborting");
	
	VelocityOffset_y = FindSendPropInfo("CBasePlayer","m_vecVelocity[1]");
	if(VelocityOffset_y == -1)
		SetFailState("[SM] Error: Failed to find Velocity[1] offset, aborting");
	
	BaseVelocityOffset = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");
	if(BaseVelocityOffset == -1)
		SetFailState("[SM] Error: Failed to find the BaseVelocity offset, aborting");
	
	//HookEvent("player_death", BeforePlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_freeze_end",RoundFreezeEndEvent);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_team", OnPlayerChangeTeam);
	HookEvent("player_team", OnPlayerChangeTeam2, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("item_pickup", OnItemPickup);
	HookEvent("bullet_impact", OnBulletImpact);
	//HookEvent("player_footstep", OnPlayerFootStep);
	//HookEvent("weapon_fire", OnWeaponFire);
	HookConVarChange(cvarkevlar, OnConVarChanged);
	HookConVarChange(cvarkevlar_ct, OnConVarChanged);
	HookConVarChange(cvarhelmet, OnConVarChanged);
	HookConVarChange(cvarhegrenade, OnConVarChanged);
	HookConVarChange(cvarsmokegrenade, OnConVarChanged);
	HookConVarChange(cvarnvgoggles, OnConVarChanged);
	HookConVarChange(cvaromareqxp, OnConVarChanged);
	
	
	kevlar = GetConVarInt(cvarkevlar);
	kevlar_ct = GetConVarInt(cvarkevlar_ct);
	helmet = GetConVarInt(cvarhelmet);
	hegrenade = GetConVarInt(cvarhegrenade);
	smokegrenade = GetConVarInt(cvarsmokegrenade);
	nvgoggles = GetConVarInt(cvarnvgoggles);
	OMA_ReqXP = GetConVarInt(cvaromareqxp);
	OMA_MaxLvl = GetConVarInt(cvaromamaxlvl);
	OMA_StartHealth = 100;
	scoutClient = -1;
	chosenClient = -1;
	for(new i = 1; i < MaxClients; i++)
	{
		PlayerRespawnTime[i] = 0.5;
		//PlayerGravity[i] = 1.0;
		//PlayerSpeed[i] = 1.0;
		//PlayerSpeedlvl[i] = 1;
		Weaponlvl[i] = 0;
	}
	XPlvl[1] = 100;
	XPlvl[2] = 200;
	XPlvl[3] = 400;
	XPlvl[4] = 800;
	XPlvl[5] = 1600;
	XPlvl[6] = 3200;
	XPlvl[7] = 6400;
	XPlvl[8] = 12800;
	XPlvl[9] = 25600;
	XPlvl[10] = 51200;
	XPlvl[11] = 9999999;
	if(LoadedLate)
	{
		FreezeTime = false;
		for(new a = 1; a <= MaxClients; a++)
		{	
			if(IsClientInGame(a))
			{
				SDKHook(a, SDKHook_Touch, Entity_Touch);
				SDKHook(a, SDKHook_WeaponCanUse, WeaponCanUse);
			}
			OMA_StartHealth = 100;
			scoutClient = -1;
			chosenClient = -1;
			Playerlvl[a] = 1;
			PlayerXP[a] = 0;
			PlayerCanCloak[a] = true;
			LongJump[a] = true;
			PlayerHealth[a] = 100;
			PlayerArmor[a] = 0;
			PlayerRespawnTime[a] = 1.0;
			PlayerSpeed[a] = 1.0;
			PlayerRespawnCount[a] = 1.0;
			Weaponlvl[a] = 0;
			HeadShotCount[a] = 0;
			PlayerSkills[a][0] = 0;
			PlayerSkills[a][1] = 0;
			PlayerSkills[a][2] = 0;
			PlayerSkills[a][3] = 0;
			PlayerSkills[a][4] = 0;
			PlayerSkills[a][5] = 0;
			PlayerSkills[a][6] = 0;
			PlayerSkills[a][7] = 0;
			PlayerSkills[a][8] = 0;
			PlayerPoints[a] = 0;
			OMAPoints[a] = 0;
			OMACurrWeapon[a] = -1;
			OMAlvl2[a] = false;
			NadeRegenActive[a] = false;
			SNadeRegenActive[a] = false;
			OMAmenuActive[a] = false;
			OMAdmgTotal[a] = 0;
			OMA_Team[a][0] = -1;
			OMA_Team[a][1] = -1;
			OMA_Team[a][2] = -1;
			OMA_Team[a][3] = 0;
			OMA_Goodie[a] = -1;
			OMA_lvl[a] = 1;
			Weaponlvl[a] = 0;
		}
	}
}

/*
public OnPluginEnd()
{
	for(new a = 1; a <= MaxClients; a++)
	{
		if(IsClientInGame(a))
		{
			SDKUnhook(a, SDKHook_EndTouch, Entity_Touch);
			SDKHook(a, SDKHook_WeaponCanUse, WeaponCanUse);
		}
	}
}*/

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarkevlar)
		kevlar == StringToInt(newValue);
	else if(convar == cvarkevlar_ct)
		kevlar_ct = StringToInt(newValue);
	else if(convar == cvarhelmet)
		helmet = StringToInt(newValue);
	else if(convar == cvarhegrenade)
		hegrenade = StringToInt(newValue);
	else if(convar == cvarsmokegrenade)
		smokegrenade = StringToInt(newValue);
	else if(convar == cvarnvgoggles)
		nvgoggles = StringToInt(newValue);
	else if(convar == cvaromareqxp)
		OMA_ReqXP = StringToInt(newValue);
	else if(convar == cvaromamaxlvl)
		OMA_MaxLvl = StringToInt(newValue);
	
}

public OnMapStart()
{
	PrecacheSound(HEALTHKIT_SOUND, true);
	PrecacheSound(ITEMPICKUP_SOUND, true);
	PrecacheModel(GOODIEBOX_MODEL, true);
	PrecacheModel(EXPLODE_SPR, true);
	FreezeTime = false;
	MapHasEnded = false;
	OMA_StartHealth = 100;
	scoutClient = -1;
	chosenClient = -1;
	//cloaktimer = false;
	ServerCommand("mp_autoteambalance 0");
	
}
public OnMapEnd()
{
	MapHasEnded = true;
	OMA_StartHealth = 100;
	scoutClient = -1;
	chosenClient = -1;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, Entity_Touch);
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	OMA_Goodie[client] = -1;
	OMA_lvl[client] = 1;
	Weaponlvl[client] = 0;
	Playerlvl[client] = 1;
	PlayerXP[client] = 0;
	PlayerCanCloak[client] = true;
	PlayerHealth[client] = 100;
	LongJump[client] = true;
	PlayerArmor[client] = 0;
	PlayerRespawnTime[client] = 1.0;
	PlayerHealthChecked[client] = false;
	//PlayerGravity[client] = 1.0;
	PlayerSpeed[client] = 1.0;
	PlayerRespawnCount[client] = 1.0;
	//PlayerSpeedlvl[client] = 1;
	Weaponlvl[client] = 0;
	HeadShotCount[client] = 0;
	PlayerSkills[client][0] = 0;
	PlayerSkills[client][1] = 0;
	PlayerSkills[client][2] = 0;
	PlayerSkills[client][3] = 0;
	PlayerSkills[client][4] = 0;
	PlayerSkills[client][5] = 0;
	PlayerSkills[client][6] = 0;
	PlayerSkills[client][7] = 0;
	PlayerSkills[client][8] = 0;
	PlayerPoints[client] = 0;
	OMAPoints[client] = 0;
	OMACurrWeapon[client] = -1;
	OMAlvl2[client] = false;
	NadeRegenActive[client] = false;
	SNadeRegenActive[client] = false;
	OMAmenuActive[client] = false;
	OMAdmgTotal[client] = 0;
	OMA_Team[client][0] = -1;
	OMA_Team[client][1] = -1;
	OMA_Team[client][2] = -1;
	OMA_Team[client][3] = 0;
	playercount++;
	for(new i = 1; i < 9; i++)
	{
		PlayerSkills[client][i] = 0;
	}
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_EndTouch, Entity_Touch);
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	playercount--;
	if(!MapHasEnded)
	{
		if(GetNumClientsOnTeam(TEAM_T) < 1 && playercount > 1)
		{
			scoutClient = -1;
			CreateTimer(5.5,TimedOMAchooser, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(playercount == 0)
			scoutClient = -1;
	}
}

public GetNumClientsOnTeam(teamid)
{
	new maxclients = GetMaxClients();
	new count = 0;
	
	for(new i = 1; i <= maxclients; i++)
	{
		if(IsClientInGame(i))
		{
			if(teamid == GetClientTeam(i))
				count++;
		}
	}
	return count;
}
/*
OnPlayerRunCmd will hook and detect player's +commands.
I have it set up so that this function will cloak the player
when they are pressing the crouch or walk key.
The weapon detection is for cloaking nades.
*/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(!omaenable)
		return Plugin_Continue;
	if(!IsClientInGame(client))
		return Plugin_Continue;
	if(FreezeTime)
		return Plugin_Continue;
	
	if(IsPlayerAlive(client) && GetClientTeam(client) == TEAM_CT)
	{
		new weaponid = GetPlayerWeaponSlot(client, 2);
		new henade, sgnade;
		
		if(PlayerSkills[client][2] >= 1) 
			henade = GetGrenadeID(client, "weapon_hegrenade");
		else
			henade = -1;
		
		if(PlayerSkills[client][3] >= 1)
			sgnade = GetGrenadeID(client, "weapon_smokegrenade");
		else
		sgnade = -1;
		
		
		//PrintToChat(client, "[SM] CheckCloak is called.");
		if(buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			if(PlayerCanCloak[client])
			{
				SetEntityRenderFx(client, RENDERFX_NONE);
				PlayerSpeed[client] = 1.0;
				SetSpeed(client, PlayerSpeed[client]);
				if(weaponid != -1)
					SetEntityRenderFx(weaponid, RENDERFX_NONE);
				if(henade != -1)
				{
					SetEntityRenderFx(henade, RENDERFX_NONE);
					SetAlpha(henade, 255);
				}
				if(sgnade != -1)
				{
					SetAlpha(sgnade, 255);
					SetEntityRenderFx(sgnade, RENDERFX_NONE);
				}
				
				PlayerCanCloak[client] = false;
				CreateTimer(1.0,CloakCharge, client,TIMER_FLAG_NO_MAPCHANGE);
				//PrintToChat(client, "[SM] Player Attacked. Rendering reset");
			}
			
			if(PlayerSkills[client][2] >= 1)
			{
				new count = GetClientGrenades(client, Slot_HEgrenade);
				if(!NadeRegenActive[client] && count < PlayerSkills[client][2])
					CreateTimer(FloatDiv(15.0, float(PlayerSkills[client][2])),HEnadeRegen, client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			
			else if(PlayerSkills[client][3] >= 1)
			{
				new count = GetClientGrenades(client, Slot_Smokegrenade);
				if(!SNadeRegenActive[client] && count < PlayerSkills[client][3])
					CreateTimer(FloatDiv(15.0, float(PlayerSkills[client][3])),SmokenadeRegen, client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if(buttons & IN_DUCK && !(GetEntityRenderFx(client) & RENDERFX_FADE_SLOW))
		{
			if(PlayerCanCloak[client])
			{
				if(buttons & IN_JUMP && LongJump[client])
				{
					new Float:vec[3];
					if(PlayerSkills[client][8] > 0 && PlayerCanCloak[client])
					{	
						PlayerSpeed[client] = 1.0;
						SetSpeed(client, PlayerSpeed[client]);
						vec[0]= GetEntDataFloat(client, VelocityOffset_x) * ((PlayerSkills[client][8] * 0.5) + 1.0) / 2.0;
						vec[1]= GetEntDataFloat(client, VelocityOffset_y) * ((PlayerSkills[client][8] * 0.5) + 1.0) / 2.0;
						vec[2]= 1.0 * 50.0;
						SetEntDataVector(client, BaseVelocityOffset, vec, true);
						
						PlayerCanCloak[client] = false;
						LongJump[client] = false;
						SetEntityRenderFx(client, RENDERFX_NONE);
						SetSpeed(client, PlayerSpeed[client]);
						if(weaponid != -1)
							SetEntityRenderFx(weaponid, RENDERFX_NONE);
						if(henade != -1)
						{
							SetAlpha(henade, 255);
							SetEntityRenderFx(henade, RENDERFX_NONE);
						}
						if(sgnade != -1)
						{
							SetAlpha(sgnade, 255);
							SetEntityRenderFx(sgnade, RENDERFX_NONE);
						}
						
						//PrintToChat(client, "[SM] Player Has used long jump.");
						CreateTimer(1.5,JumpCharge, client,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(1.0,CloakCharge, client,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if(buttons & IN_ATTACK || buttons & IN_ATTACK2 || buttons & IN_JUMP)
				{
					SetEntityRenderFx(client, RENDERFX_NONE);
					PlayerSpeed[client] = 1.0;
					SetSpeed(client, PlayerSpeed[client]);
					if(weaponid != -1)
						SetEntityRenderFx(weaponid, RENDERFX_NONE);
					if(henade != -1)
					{
						SetAlpha(henade, 255);
						SetEntityRenderFx(henade, RENDERFX_NONE);
					}
					if(sgnade != -1)
					{
						SetAlpha(sgnade, 255);
						SetEntityRenderFx(sgnade, RENDERFX_NONE);
					}
					
					PlayerCanCloak[client] = false;
					CreateTimer(1.0,CloakCharge, client,TIMER_FLAG_NO_MAPCHANGE);
					
					//PrintToChat(client, "[SM] Player Attacked or Jumped. Rendering reset");
				}
				else
				{
					SetEntityRenderFx(client, RENDERFX_FADE_FAST);
					if(weaponid != -1)
						SetEntityRenderFx(weaponid, RENDERFX_FADE_FAST);
					if(henade != -1)
					{
						SetEntityRenderFx(henade, RENDERFX_FADE_FAST);
						SetAlpha(henade, 0);
					}
					if(sgnade != -1)
					{
						SetEntityRenderFx(sgnade, RENDERFX_FADE_FAST);
						SetAlpha(sgnade, 0);
					}
					
					//PrintToChat(client, "[SM] Rendering fade fast");
					if(PlayerSkills[client][6] > 0)
					{
						PlayerSpeed[client] = 1.0 + (0.4 * PlayerSkills[client][6]);
						SetSpeed(client, PlayerSpeed[client]);
					}
				}
			}
		}	
		
		else if(buttons & IN_SPEED && !(GetEntityRenderFx(client) & RENDERFX_FADE_FAST))
		{
			if(PlayerCanCloak[client])
			{
				if(buttons & IN_ATTACK || buttons & IN_ATTACK2 || buttons & IN_JUMP)
				{
					SetEntityRenderFx(client, RENDERFX_NONE);
					PlayerSpeed[client] = 1.0;
					SetSpeed(client, PlayerSpeed[client]);
					if(weaponid != -1)
						SetEntityRenderFx(weaponid, RENDERFX_NONE);
					if(henade != -1)
					{
						SetAlpha(henade, 255);
						SetEntityRenderFx(henade, RENDERFX_NONE);
					}
					if(sgnade != -1)
					{
						SetAlpha(sgnade, 255);
						SetEntityRenderFx(sgnade, RENDERFX_NONE);
					}
					
					PlayerCanCloak[client] = false;
					CreateTimer(1.0,CloakCharge, client,TIMER_FLAG_NO_MAPCHANGE);
					
					//PrintToChat(client, "[SM] Player Attacked or Jumped. Rendering reset");
				}
				else
				{
					SetEntityRenderFx(client, RENDERFX_FADE_SLOW);
					if(weaponid != -1)
						SetEntityRenderFx(weaponid, RENDERFX_FADE_SLOW);
					if(henade != -1)
					{
						SetAlpha(henade, 0);
						SetEntityRenderFx(henade, RENDERFX_FADE_SLOW);
					}
					if(sgnade != -1)
					{
						SetAlpha(sgnade, 0);
						SetEntityRenderFx(sgnade, RENDERFX_FADE_SLOW);
					}
					
					//PrintToChat(client, "[SM] Rendering fade slow");
					if(PlayerSkills[client][6] > 0)
					{
						PlayerSpeed[client] = 1.0 + (0.6 * PlayerSkills[client][6]);
						SetSpeed(client, PlayerSpeed[client]);
					}
				}
			}
		}
		else if(!(buttons & IN_DUCK || buttons & IN_SPEED) && (buttons & IN_FORWARD 
		|| buttons & IN_BACK || buttons & IN_LEFT || buttons & IN_RIGHT || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_JUMP) && PlayerCanCloak[client])
		{
			SetEntityRenderFx(client, RENDERFX_NONE);
			if(PlayerSkills[client][7] > 0)
				PlayerSpeed[client] = 1.0 + (0.2 * PlayerSkills[client][7]);
			else
			PlayerSpeed[client] = 1.0;
			SetSpeed(client, PlayerSpeed[client]);
			if(weaponid != -1)
				SetEntityRenderFx(weaponid, RENDERFX_NONE);
			if(henade != -1)
			{
				SetEntityRenderFx(henade, RENDERFX_NONE);
				SetAlpha(henade, 255);
			}
			if(sgnade != -1)
			{
				SetAlpha(sgnade, 255);
				SetEntityRenderFx(sgnade, RENDERFX_NONE);
			}
			
			PlayerCanCloak[client] = false;
			CreateTimer(1.0,CloakCharge, client,TIMER_FLAG_NO_MAPCHANGE);
			
			//PrintToChat(client, "[SM] Rendering reset");
		}					
	}
	return Plugin_Continue;
}

public Action:CloakCharge(Handle:timer, any:index)
{
	PlayerCanCloak[index] = true;
	return Plugin_Stop;
}

public Action:DmgReset(Handle:timer, any:client)
{
	OMAdmgTimerActive[client] = true;
	OMAdmgTimer[client]--;
	if(OMAdmgTimer[client] <= 0)
	{
		OMAdmgTotal[client] = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:HEnadeRegen(Handle:timer, any:index)
{
	if(IsClientInGame(index))
	{
		if(IsPlayerAlive(index))
		{
			new count = GetClientGrenades(index, Slot_HEgrenade);
			if(count < PlayerSkills[index][2])
			{
				GiveClientGrenade(index, Slot_HEgrenade);
				NadeRegenActive[index] = true;
			}
			else
			{
				NadeRegenActive[index] = false;
				return Plugin_Stop;
			}
		}
		else
		return Plugin_Stop;
	}
	else
	return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action:SmokenadeRegen(Handle:timer, any:index)
{
	if(IsClientInGame(index))
	{
		if(IsPlayerAlive(index))
		{
			new count = GetClientGrenades(index, Slot_Smokegrenade);
			if(count < PlayerSkills[index][3])
			{
				GiveClientGrenade(index, Slot_Smokegrenade);
				SNadeRegenActive[index] = true;
			}
			else
			{	
				SNadeRegenActive[index] = false;
				return Plugin_Stop;
			}
		}
		else
		return Plugin_Stop;
	}
	else
	return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action:JumpCharge(Handle:timer, any:index)
{
	LongJump[index] = true;
	//PrintToChat(index, "[SM] Player Can use long jump again");
	return Plugin_Stop;
}
public Action:FixNames(Handle:timer, any:index)
{
	if(IsClientInGame(index))
	{
		if(!OMAmenuActive[index])
			SetEntProp(index, Prop_Send, "m_iHideHUD", 64);
	}
	return Plugin_Stop;
}

public Action:TimedCheckWeapon(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{	
		if(OMAlvl2[client])
			CheckLevel2(client);
		else
		CheckLevel(client);
		
		if(!IsFakeClient(client) && !OMAmenuActive[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
		
		CheckPistolLevel(client);
		EntityCleanup("weapon_", true);
	}
	return Plugin_Stop;
}

public Action:TimedDeleteWeapon(Handle:timer, any:weaponid)
{
	if(IsValidEdict(weaponid))
		RemoveEdict(weaponid);
	return Plugin_Stop;
}

public Action:TimedDeleteEntity(Handle:timer, any:ent)
{
	if(IsValidEdict(ent))
	{
		RemoveEdict(ent);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(OMA_Goodie[i] == ent)
				OMA_Goodie[i] = -1;
		}
	}
	return Plugin_Stop;
}

public Action:SwitchToKnife(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	else if(!IsPlayerAlive(client))
		return Plugin_Stop;
	
	new weaponid = GetPlayerWeaponSlot(client, 2);
	if(weaponid != -1)
	{
		EquipPlayerWeapon(client, weaponid);
	}
	return Plugin_Stop;
}

public Action:OnBulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(!omaenable)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	new Float:loc[3];
	loc[0] = GetEventFloat(event, "x");
	loc[1] = GetEventFloat(event, "y");
	loc[2] = GetEventFloat(event, "z");
	if(GetClientTeam(client) == TEAM_T && scoutClient != -1)
	{
		new Float: distance, Float: distance2;
		new Float:vec[3], Float:vec2[3];
		
		for(new a = 1; a <= MaxClients; a++)
		{
			if(IsClientInGame(a))
			{
				if(a != scoutClient && OMA_Team[scoutClient][0] != a && OMA_Team[scoutClient][1] != a && OMA_Team[scoutClient][2] != a && IsPlayerAlive(a))
				{
					GetClientAbsOrigin(client, vec);
					GetClientAbsOrigin(a, vec2);
					distance = GetVectorDistance(vec, vec2, false);
					distance2 = GetVectorDistance(loc, vec2, false);
					
					if(RoundFloat(distance) < 625)
					{
						if(Playerlvl[a] < 11)
							PlayerXP[a] += (-1*RoundFloat(SquareRoot(distance))+25);
						if(!IsFakeClient(a))
							PrintHintText(a, "%t", "currxp", PlayerXP[a], XPlvl[Playerlvl[a]]);
						ManageExperience(a);
					}	
					else if(RoundFloat(distance2) < 625)
					{
						if(Playerlvl[a] < 11)
							PlayerXP[a] += (-1*RoundFloat(SquareRoot(distance2))+25);
						if(!IsFakeClient(a))
							PrintHintText(a, "%t", "currxp", PlayerXP[a], XPlvl[Playerlvl[a]]);
						ManageExperience(a);
					}
				}
			}
		}	
	}
	return Plugin_Continue;
}

public ManageExperience(client)
{
	new team = GetClientTeam(client);
	new req, weaponid;
	new String: classname[32];
	if(OMA_Team[scoutClient][3] > 0)
		req = OMA_ReqXP * (OMA_Team[scoutClient][3]+1);
	else
	req = OMA_ReqXP;
	
	if(IsClientInGame(client))
	{
		if(team == TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				if(PlayerXP[client] >= XPlvl[Playerlvl[client]])
				{
					PlayerXP[client] = PlayerXP[client] - XPlvl[Playerlvl[client]];
					if(Playerlvl[client] + 1 <= 11)
					{
						Playerlvl[client] += 1;
						PlayerPoints[client] += 2;
						if(!IsFakeClient(client))
						{
							PrintToChat(client, "[SM] %t", "currlevel", Playerlvl[client]);
							PrintHintText(client, "%t", "currxp", PlayerXP[client], XPlvl[Playerlvl[client]]);
							Skills_Control(client, 0);
						}
						else
						{
							new rand, check = 0;
							do
							{
								if(PlayerSkills[client][4] == 0 && Playerlvl[client] >= 3)
									FakeSkillMenu(client, 5);
								else
								{
									rand = GetRandomInt(0, 11);
									FakeSkillMenu(client, rand);
								}
								check++;
								if(check > 1000)
								{
									LogError("[SM] Infinite Loop at line 900");
									break;
								}
							}while(PlayerPoints[client] > 0 && IsPlayerAlive(client));
						}
					}
				}
			}
			else if(Playerlvl[client] >= 5)
			{
				new lostxp = RoundFloat(FloatMul(float(PlayerXP[client]), 0.05));
				XPlost[client] += lostxp;
				PrintToChat(client, "[SM] %t", "lost xp", lostxp);
				PlayerXP[client] = PlayerXP[client] - lostxp;	
			}
		}
		else if(team == TEAM_T)
		{
			if(OMA_XP[client] >= OMA_ReqXP && !OMAlvl2[client])
			{
				OMA_XP[client] = OMA_XP[client] - OMA_ReqXP;
				
				if(OMA_lvl[client] + 1 < OMA_MaxLvl)
				{
					OMA_lvl[client] += 1;
					if(!IsFakeClient(client))
					{
						PrintToChat(client, "[SM] %t", "currlevel", OMA_lvl[client]);
						PrintHintText(client, "%t", "currxp", OMA_XP[client], OMA_ReqXP);
						
						if(Weaponlvl[client] + 1 < 17)
						{
							Weaponlvl[client]++;
							if(Weaponlvl[client] + 1 == 17)
								Weaponlvl[client] = 0;						
						}
					}
				}
				else if(OMA_lvl[client] + 1 == OMA_MaxLvl)
				{
					OMA_lvl[client] += 1;
					Weaponlvl[client] = 17;
					PrintToChatAll("[SM] %t", "last_level");
				}
			}
			else if(OMAlvl2[scoutClient] && OMA_XP[scoutClient] >= req)
			{
				if(OMA_lvl[client] + 1 < OMA_MaxLvl)
				{
					if(!FreezeTime)
					{
						OMAPoints[scoutClient] = 1;
						Weapons_Control(scoutClient, 0);
					}
					
					OMA_XP[client] = OMA_XP[client] - req;
					
					OMA_lvl[scoutClient] += 1;
					if(!IsFakeClient(scoutClient))
					{
						PrintToChat(scoutClient, "[SM] %t", "currlevel", OMA_lvl[scoutClient]);
						PrintHintText(scoutClient, "%t", "currxp", OMA_XP[scoutClient], OMA_ReqXP);
					}
					else
					WeaponsTimeOut(client);
					
					if(OMA_Team[scoutClient][3] > 0)
					{
						for(new i = 0; i < OMA_Team[scoutClient][3]; i++)
						{
							if(OMA_Team[scoutClient][i] != -1)
							{	
								OMAPoints[OMA_Team[scoutClient][i]] += 1;
								Weapons_Control(OMA_Team[scoutClient][i], 0);
								if(!IsFakeClient(OMA_Team[scoutClient][i]))
								{
									PrintToChat(OMA_Team[scoutClient][i], "[SM] %t", "currlevel", OMA_lvl[scoutClient]);
									PrintHintText(OMA_Team[scoutClient][i], "%t", "currxp", OMA_XP[scoutClient], OMA_ReqXP);
								}
								else
								WeaponsTimeOut(OMA_Team[scoutClient][i]);
							}
						}
					}
				}
				if(OMA_lvl[scoutClient] + 1 == OMA_MaxLvl)
				{
					OMAPoints[scoutClient] = 0;
					OMA_lvl[scoutClient] += 1;
					PrintToChat(scoutClient, "[SM] %t", "currlevel", OMA_lvl[client]);
					weaponid = GetPlayerWeaponSlot(scoutClient, 0);
					if(weaponid != -1)
					{
						GetEdictClassname(weaponid, classname, sizeof(classname));
						if(!StrEqual(classname, "weapon_m249", false))
						{
							OMACurrWeapon[scoutClient] = 13;
							RemovePlayerItem(scoutClient, weaponid);
							if(IsValidEdict(weaponid))
								RemoveEdict(weaponid);
							GivePlayerItem(scoutClient, "weapon_m249");
							PrintToChatAll("[SM] %t", "last_level");
						}
					}
					if(OMA_Team[scoutClient][3] > 0)
					{
						for(new i = 0; i < OMA_Team[scoutClient][3]; i++)
						{
							if(OMA_Team[scoutClient][i] != -1)
							{
								OMAPoints[OMA_Team[scoutClient][i]] += 1;
								PrintToChat(OMA_Team[scoutClient][i], "[SM] %t", "currlevel", OMA_lvl[scoutClient]);
								weaponid = GetPlayerWeaponSlot(OMA_Team[scoutClient][i], 0);
								if(weaponid != -1)
								{
									GetEdictClassname(weaponid, classname, sizeof(classname));
									if(!StrEqual(classname, "weapon_m249", false))
									{
										OMACurrWeapon[OMA_Team[scoutClient][i]] = 13;
										RemovePlayerItem(OMA_Team[scoutClient][i], weaponid);
										if(IsValidEdict(weaponid))
											RemoveEdict(weaponid);
										GivePlayerItem(OMA_Team[scoutClient][i], "weapon_m249");
									}
								}
								else
								GivePlayerItem(OMA_Team[scoutClient][i], "weapon_m249");
							}
						}
					}
				}
			}
		}
	}
}

public Action:Command_WhoIsOMA(client, args)
{
	new String: ClientName[64];
	
	if(scoutClient != -1)
	{
		GetClientName(scoutClient, ClientName, sizeof(ClientName));
		PrintToConsole(client, "[SM] Current One Man Army is: %s, id: %d", ClientName, scoutClient);
		PrintToConsole(client, "[SM] Current kill count: %d", Weaponlvl[scoutClient]);
		PrintToConsole(client, "[SM] Current headshot count: %d", HeadShotCount[scoutClient]);
	}
	else
	PrintToConsole(client, "[SM] Current One Man Army is: none, id: -1");
	
	return Plugin_Handled;
}
/*
public Action:Command_HideHud(client, args)
{
new String:tmp[64];
new value;
if(args < 1)
{
ReplyToCommand(client, "[SM] Usage: sm_hidehud <value>");
return Plugin_Handled;
}
GetCmdArg(1, tmp, sizeof(tmp));
value = StringToInt(tmp);

SetEntProp(client, Prop_Send, "m_iHideHUD", value);

return Plugin_Handled;
}*/

public Action:Command_SkillReset(client, args)
{
	new String:tmp[64];
	new target;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_skillreset <#userid/name>");
		return Plugin_Handled;
	}
	GetCmdArg(1, tmp, sizeof(tmp));
	target = FindTarget(client,tmp, false, false);
	if(target == -1)
		return Plugin_Handled;
	
	for(new i = 0; i < 9; i++)
	{
		PlayerSkills[target][i] = 0;
	}
	Playerlvl[target] = 1;
	PlayerXP[target] = 0;
	PlayerPoints[target] = Playerlvl[target] * 4;
	PlayerPoints[target] = PlayerPoints[target] - 4;
	PrintToConsole(client, "The target's skills have been reset.");
	return Plugin_Handled;
}

public Action:Command_XP(client, args)
{
	new String:tmp[64];
	new target;
	
	if(args < 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new String:Name[64];
				GetClientName(i, Name, sizeof(Name));
				PrintToConsole(client, "%s is level %d with %d/%d", Name, Playerlvl[i], PlayerXP[i], XPlvl[Playerlvl[i]]); 
			}
		}
	}
	else
	{
		GetCmdArg(1, tmp, sizeof(tmp));
		target = FindTarget(client,tmp, false, false);
		if(target == -1)
			return Plugin_Handled;
		
		new String: Name[64];
		GetClientName(target, Name, sizeof(Name));
		PrintToConsole(client, "%s is level %d with %d/%d", Name, Playerlvl[target], PlayerXP[target], XPlvl[Playerlvl[target]]); 
	}
	return Plugin_Handled;
}

public Action:Command_CloakStatus(client, args)
{
	if(PlayerCanCloak[client])
		PrintToConsole(client, "[SM] Cloak Status: Active");
	else
	PrintToConsole(client, "[SM] Cloak Status: Charging");
	
	//PrintToChat(client, "[SM] JumpTimer is: %d", JumpTimer[client]);
	
	if((GetEntityRenderFx(client) & RENDERFX_NONE))
		PrintToConsole(client, "[SM] Rendering reset");
	if((GetEntityRenderFx(client) & RENDERFX_FADE_FAST))
		PrintToConsole(client, "[SM] Rendering fade fast");
	if((GetEntityRenderFx(client) & RENDERFX_FADE_SLOW))
		PrintToConsole(client, "[SM] Rendering fade slow");
	
	return Plugin_Handled;
}

/*
public Action:Command_SpawnGoodie(client, args)
{
SpawnGoodieBox(client);

return Plugin_Handled;
}*/

public Action:Command_OMAStatus(client, args)
{
	new String: ClientName[32];
	PrintToConsole(client, "[SM] Team Count: %d", OMA_Teamcount);
	if(OMA_Team[client][0] != -1)
	{
		GetClientName(OMA_Team[client][0], ClientName, sizeof(ClientName));
		PrintToConsole(client, "[SM] Teammate 1: %s", ClientName);
	}
	
	if(OMA_Team[client][1] != -1)
	{
		GetClientName(OMA_Team[client][1], ClientName, sizeof(ClientName));
		PrintToConsole(client, "[SM] Teammate 2: %s", ClientName);
	}
	
	if(OMA_Team[client][2] != -1)
	{
		GetClientName(OMA_Team[client][2], ClientName, sizeof(ClientName));
		PrintToConsole(client, "[SM] Teammate 3: %s", ClientName);
	}
	return Plugin_Handled;
}

public Action:PlayerRespawn(Handle:timer, any:index)
{
	if(IsClientInGame(index))
	{
		PrintHintText(index, "%t", "respawn_time", PlayerRespawnCount[index]);
		PlayerRespawnCount[index] = FloatSub(PlayerRespawnCount[index], 0.1);
		if(!IsPlayerAlive(index) && GetClientTeam(index) > 1 && FloatCompare(PlayerRespawnCount[index], 0.0) <= 0)
		{
			CS_RespawnPlayer(index);
			//SetClientMoney(index, 0);
			PlayerRespawnCount[index] = PlayerRespawnTime[index];
			return Plugin_Stop;
		}
		else if(IsPlayerAlive(index))
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:TimedSwitchTeam(Handle:timer, any:victim)
{
	if(IsClientInGame(victim))
	{
		PrintDebugMsg("switching OMA to team CT");
		CS_SwitchTeam(victim, TEAM_CT);
		CS_RespawnPlayer(victim);		
	}
	if(chosenClient != -1)
	{
		if(IsClientInGame(chosenClient) && GetNumClientsOnTeam(TEAM_CT) > 1)
		{
			PrintDebugMsg("the chosen client is now invincible");
			SetEntProp(chosenClient, Prop_Data, "m_takedamage", 2, 1);
			CS_SwitchTeam(chosenClient, TEAM_CT);
			chosenClient = -1;
		}
	}
	
	return Plugin_Stop;
}

public Action:TimedSwitchTeam2(Handle:timer, any:victim)
{
	if(scoutClient == -1)
		return Plugin_Stop;
	if(!IsClientInGame(scoutClient))
		return Plugin_Stop;
	PrintDebugMsg("Client Has become OMA");
	CS_SwitchTeam(scoutClient, TEAM_T);
	//PlayerSpeed[scoutClient] = 1.0;
	CS_RespawnPlayer(scoutClient);
	CreateTimer(0.2, TimedCheckWeapon, scoutClient,TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:Command_Say(client,args)
{
	if(client == 0)
		return Plugin_Handled;
	
	decl String:speech[128];
	new team = GetClientTeam(client);
	GetCmdArgString(speech,sizeof(speech));
	if(client != 0 && GetConVarBool(cvarpluginstatus))
	{
		new startidx = 0;
		if (speech[0] == '"')
		{
			startidx = 1;
			// Strip the ending quote, if there is one
			new len = strlen(speech);
			if (speech[len-1] == '"')
			{
				speech[len-1] = '\0';
			}
		}
		if(strcmp(speech[startidx],"/skillmenu", false) == 0 && team == TEAM_CT)
		{
			Skills_Control(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx], "/buymenu", false) == 0 || strcmp(speech[startidx], "buy", false) == 0)
		{
			Buy_Equipment_Control(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx], "/knifestats", false) == 0 && team == TEAM_CT)
		{
			KnifeStatsControl(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx], "/armorstats", false) == 0 && team == TEAM_CT)
		{
			ArmorStatsControl(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx], "/gunsmenu", false) == 0 && team == TEAM_T)
		{
			Weapons_Control(client, 0);
			return Plugin_Handled;
		}
		else if(strcmp(speech[startidx], "/gamble", false) == 0 && team == TEAM_CT)
		{
			Gamble_Control(client, 0);
			return Plugin_Handled;
		}
		
	}
	
	
	return Plugin_Continue;
	
}

public Action:TimedRespawnProtect(Handle:timer, any:victim)
{
	new Float: distance;
	new Float:vec[3], Float:vec2[3];
	new maxclients = GetMaxClients();
	new weaponid;
	
	if(scoutClient == -1)
		return Plugin_Stop;
	
	for(new i = 1; i <= maxclients; i++)
	{
		if(i != scoutClient && OMA_Team[scoutClient][0] != i && OMA_Team[scoutClient][1] != i && OMA_Team[scoutClient][2] != i && IsClientInGame(i) && IsClientInGame(scoutClient))
		{
			GetClientAbsOrigin(scoutClient, vec);
			GetClientAbsOrigin(i, vec2);
			distance = GetVectorDistance(vec, vec2, false);
			
			if(distance <= 600 && GetClientTeam(i) == TEAM_CT)
			{
				CS_RespawnPlayer(i);
			}
			
			weaponid = GetPlayerWeaponSlot(i, 0);
			if(weaponid != -1)
			{
				RemovePlayerItem(i, weaponid);
				CreateTimer(0.3,TimedDeleteWeapon, weaponid,TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(i, "slot3");
			}
			weaponid = GetPlayerWeaponSlot(i, 1);
			if(weaponid != -1)
			{
				RemovePlayerItem(i, weaponid);
				CreateTimer(0.3,TimedDeleteWeapon, weaponid,TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(i, "slot3");
			}
			if(IsFakeClient(i))
			{
				weaponid = GetPlayerWeaponSlot(i, 2);
				if(weaponid != -1)
				{
					EquipPlayerWeapon(i, weaponid);
				}
			}
			PrintDebugMsg("Timed Respawn Protect Triggered");
			
		}			
	}
	
	return Plugin_Stop;
}

public Action:TimedTeamCheck(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(scoutClient == -1)
	{
		PrintDebugMsg("Scoutclient is -1");
		if(GetClientTeam(client) == TEAM_T)
		{
			CS_SwitchTeam(client, TEAM_CT);
			CS_RespawnPlayer(client);
		}
	}
	else if(scoutClient == client)
	{
		if(GetClientTeam(client) == TEAM_CT)
		{
			CS_SwitchTeam(client, TEAM_T);
			CS_RespawnPlayer(client);
		}
	}
	
	if(GetNumClientsOnTeam(TEAM_CT) != 0 && scoutClient != -1)
	{
		if(GetNumClientsOnTeam(TEAM_T) > 1)
		{			
			if(GetClientTeam(client) == TEAM_T)
			{
				if(scoutClient != client && chosenClient != client)
				{
					if(OMAlvl2[scoutClient])
					{
						if(OMA_Team[scoutClient][0] != client && OMA_Team[scoutClient][1] != client && OMA_Team[scoutClient][2] != client)
						{
							CS_SwitchTeam(client, TEAM_CT);
							CS_RespawnPlayer(client);
						}
					}
					else
					{
						CS_SwitchTeam(client, TEAM_CT);
						CS_RespawnPlayer(client);
					}
				}
			}
		}		
	}
	else if(GetNumClientsOnTeam(TEAM_T) > 1)
	{
		new maxclients = GetMaxClients();
		
		for(new i = 1; i <= maxclients; i++)
		{
			if(IsClientInGame(i))
			{
				if(i != scoutClient && GetClientTeam(client) == TEAM_T)
				{
					CS_SwitchTeam(i, TEAM_CT);
					CS_RespawnPlayer(i);
				}
			}
		}
	}
	
	if (GetNumClientsOnTeam(TEAM_CT) < 5)
	{
		OMA_StartHealth = 150;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 5 && GetNumClientsOnTeam(TEAM_CT) < 10)
	{
		OMA_StartHealth = 175;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 10 && GetNumClientsOnTeam(TEAM_CT) < 15)
	{
		OMA_StartHealth = 200;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 15 && GetNumClientsOnTeam(TEAM_CT) < 20)
	{
		OMA_StartHealth = 225;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 20 && GetNumClientsOnTeam(TEAM_CT) < 25)
	{
		OMA_StartHealth = 250;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 25 && GetNumClientsOnTeam(TEAM_CT) < 30)
	{
		OMA_StartHealth = 275;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 30 && GetNumClientsOnTeam(TEAM_CT) < 35)
	{
		OMA_StartHealth = 300;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 35 && GetNumClientsOnTeam(TEAM_CT) < 40)
	{
		OMA_StartHealth = 325;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 40 && GetNumClientsOnTeam(TEAM_CT) < 45)
	{
		OMA_StartHealth = 350;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 45 && GetNumClientsOnTeam(TEAM_CT) < 50)
	{
		OMA_StartHealth = 375;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 50 && GetNumClientsOnTeam(TEAM_CT) < 55)
	{
		OMA_StartHealth = 400;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 55 && GetNumClientsOnTeam(TEAM_CT) < 60)
	{
		OMA_StartHealth = 425;
	}
	else if(GetNumClientsOnTeam(TEAM_CT) >= 60 && GetNumClientsOnTeam(TEAM_CT) < 65)
	{
		OMA_StartHealth = 450;
	}
	PrintDebugMsg("OMA starting health has been chosen");
	
	return Plugin_Stop;
}

public FreezePlayer(client)
{
	SetSpeed(client, 0);
}

public UnFreezeAllPlayers()
{
	for(new c = 1; c <= MAXPLAYERS; c++)
	{
		if(IsClientInGame(c))
		{
			SetSpeed(c, 1);
		}
	}
}

public GetWeaponByID(weaponid, String:WeaponName[], maxlen)
{
	if(weaponid == 0)
	{
		strcopy(WeaponName, maxlen, "weapon_ak47");
	}
	else if(weaponid == 1)
	{
		strcopy(WeaponName, maxlen, "weapon_aug");
	}
	else if(weaponid == 2)
	{
		strcopy(WeaponName, maxlen, "weapon_awp");
	}
	else if(weaponid == 3)
	{
		strcopy(WeaponName, maxlen, "weapon_deagle");
	}
	else if(weaponid == 4)
	{
		strcopy(WeaponName, maxlen, "weapon_elite");
	}
	else if(weaponid == 5)
	{
		strcopy(WeaponName, maxlen, "weapon_famas");
	}
	else if(weaponid == 6)
	{
		strcopy(WeaponName, maxlen, "weapon_fiveseven");
	}
	else if(weaponid == 7)
	{
		strcopy(WeaponName, maxlen, "weapon_flashbang");
	}
	else if(weaponid == 8)
	{
		strcopy(WeaponName, maxlen, "weapon_g3sg1");
	}
	else if(weaponid == 9)
	{
		strcopy(WeaponName, maxlen, "weapon_galil");
	}
	else if(weaponid == 10)
	{
		strcopy(WeaponName, maxlen, "weapon_glock");
	}
	else if(weaponid == 11)
	{
		strcopy(WeaponName, maxlen, "weapon_hegrenade");
	}
	else if(weaponid == 12)
	{
		strcopy(WeaponName, maxlen, "weapon_knife");
	}
	else if(weaponid == 13)
	{
		strcopy(WeaponName, maxlen, "weapon_m249");
	}
	else if(weaponid == 14)
	{
		strcopy(WeaponName, maxlen, "weapon_m3");
	}
	else if(weaponid == 15)
	{
		strcopy(WeaponName, maxlen, "weapon_m4a1");
	}
	else if(weaponid == 16)
	{
		strcopy(WeaponName, maxlen, "weapon_mac10");
	}
	else if(weaponid == 17)
	{
		strcopy(WeaponName, maxlen, "weapon_mp5navy");
	}
	else if(weaponid == 18)
	{
		strcopy(WeaponName, maxlen, "weapon_p228");
	}
	else if(weaponid == 19)
	{
		strcopy(WeaponName, maxlen, "weapon_p90");
	}
	else if(weaponid == 20)
	{
		strcopy(WeaponName, maxlen, "weapon_scout");
	}
	else if(weaponid == 21)
	{
		strcopy(WeaponName, maxlen, "weapon_sg550");
	}
	else if(weaponid == 22)
	{
		strcopy(WeaponName, maxlen, "weapon_sg552");
	}
	else if(weaponid == 23)
	{
		strcopy(WeaponName, maxlen, "weapon_smokegrenade");
	}
	else if(weaponid == 24)
	{
		strcopy(WeaponName, maxlen, "weapon_tmp");
	}
	else if(weaponid == 25)
	{
		strcopy(WeaponName, maxlen, "weapon_ump45");
	}
	else if(weaponid == 26)
	{
		strcopy(WeaponName, maxlen, "weapon_usp");
	}
	else if(weaponid == 27)
	{
		strcopy(WeaponName, maxlen, "weapon_xm1014");
	}
	else if(weaponid == 28)
	{
		strcopy(WeaponName, maxlen, "weapon_c4");
	}
}

public GetWeaponidByName(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_ak47", false))
	{
		return 0;
	}
	else if(StrEqual(Weapon, "weapon_aug", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_deagle", false))
	{	
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_elite", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_famas", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_g3sg1", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_galil", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_glock", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_knife", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 13;
	}
	else if(StrEqual(Weapon, "weapon_m3", false))
	{
		return 14;
	}
	else if(StrEqual(Weapon, "weapon_m4a1", false))
	{
		return 15;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false))
	{
		return 16;
	}
	else if(StrEqual(Weapon, "weapon_mp5navy", false))
	{
		return 17;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 18;
	}
	else if(StrEqual(Weapon, "weapon_p90", false))
	{
		return 19;
	}
	else if(StrEqual(Weapon, "weapon_scout", false))
	{
		return 20;
	}
	else if(StrEqual(Weapon, "weapon_sg550", false))
	{
		return 21;
	}
	else if(StrEqual(Weapon, "weapon_sg552", false))
	{
		return 22;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade", false))
	{
		return 23;
	}
	else if(StrEqual(Weapon, "weapon_tmp", false))
	{
		return 24;
	}
	else if(StrEqual(Weapon, "weapon_ump45", false))
	{
		return 25;
	}
	else if(StrEqual(Weapon, "weapon_usp", false))
	{
		return 26;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false))
	{
		return 27;
	}
	else if(StrEqual(Weapon, "weapon_c4", false))
	{
		return 28;
	}
	else
	return -1;
}

public CheckLevel(client)
{
	new weaponid;
	new String:classname[32];
	
	PrintDebugMsg("Checklevel called.");
	switch(Weaponlvl[client])
	{
		case 0:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_ump45", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_ump45");
				}
			}
			else
			GivePlayerItem(client, "weapon_ump45");
			
		}
		case 1:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_tmp", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					
					GivePlayerItem(client, "weapon_tmp");
				}
			}
			else
			GivePlayerItem(client, "weapon_tmp");
		}
		case 2:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_mac10", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					
					GivePlayerItem(client, "weapon_mac10");
				}
			}
			else
			GivePlayerItem(client, "weapon_mac10");
		}
		case 3:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_mp5navy", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_mp5navy");
				}
			}
			else
			GivePlayerItem(client, "weapon_mp5navy");
		}
		case 4:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_p90", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_p90");
				}
			}
			else
			GivePlayerItem(client, "weapon_p90");
		}
		case 5:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_m3", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_m3");
				}
			}
			else
			GivePlayerItem(client, "weapon_m3");
		}
		case 6:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_xm1014", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_xm1014");
				}
			}
			else
			GivePlayerItem(client, "weapon_xm1014");
		}
		case 7:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_ak47", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_ak47");
				}
			}
			else
			GivePlayerItem(client, "weapon_ak47");
		}
		case 8:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_m4a1", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_m4a1");
				}
			}
			else
			GivePlayerItem(client, "weapon_m4a1");
		}
		case 9:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_galil", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_galil");
				}
			}
			else
			GivePlayerItem(client, "weapon_galil");
		}
		case 10:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_famas", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_famas");
				}
			}
			else
			GivePlayerItem(client, "weapon_famas");
		}
		case 11:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_sg552", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_sg552");
				}
			}
			else
			GivePlayerItem(client, "weapon_sg552");
		}
		case 12:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_aug", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_aug");
				}
			}
			else
			GivePlayerItem(client, "weapon_aug");
		}
		case 13:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_g3sg1", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_g3sg1");
				}			
			}
			else
			GivePlayerItem(client, "weapon_g3sg1");
		}
		case 14:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_sg550", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_sg550");
				}
				
			}
			else
			GivePlayerItem(client, "weapon_sg550");
		}
		case 15:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_scout", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_scout");
				}
			}
			else
			GivePlayerItem(client, "weapon_scout");
		}
		case 16:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_awp", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_awp");
				}
			}
			else
			GivePlayerItem(client, "weapon_awp");
		}
		case 17:
		{
			weaponid = GetPlayerWeaponSlot(client, 0);
			if(weaponid != -1)
			{
				GetEdictClassname(weaponid, classname, sizeof(classname));
				if(!StrEqual(classname, "weapon_m249", false))
				{
					RemovePlayerItem(client, weaponid);
					if(IsValidEdict(weaponid))
						RemoveEdict(weaponid);
					GivePlayerItem(client, "weapon_m249");	
				}
			}
			else
			GivePlayerItem(client, "weapon_m249");
		}
	}
}

public CheckLevel2(client)
{
	new weaponid;
	new String:classname[32], String:weapon[32], String:buffer[64];
	
	PrintDebugMsg("Check level 2 called");
	GetWeaponByID(OMACurrWeapon[client], weapon, sizeof(weapon));
	Format(buffer, sizeof(buffer), "Player's current weapon is: %s", weapon);
	PrintDebugMsg(buffer);
	
	// check to see if new oma has para set as current weapon
	if(OMA_lvl[scoutClient] != OMA_MaxLvl && OMACurrWeapon[scoutClient] == 13)
	{
		OMACurrWeapon[scoutClient] = -1;
		if(OMAPoints[scoutClient] < 1)
			OMAPoints[scoutClient] = 1;
		
		if(!IsFakeClient(scoutClient))
			Weapons_Control(scoutClient, 0);
		else
		WeaponsTimeOut(scoutClient);
	}
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(weaponid != -1)
	{
		GetEdictClassname(weaponid, classname, sizeof(classname));
		if(!StrEqual(classname, weapon, false))
		{
			RemovePlayerItem(client, weaponid);
			if(IsValidEdict(weaponid))
				RemoveEdict(weaponid);
			GivePlayerItem(client, weapon);
		}
	}
	else
	GivePlayerItem(client, weapon);
}

public CheckPistolLevel(client)
{
	new weaponid;
	new String:classname[32];
	
	PrintDebugMsg("CheckPistolLevel called");
	
	if(HeadShotCount[client] < 10)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			RemovePlayerItem(client, weaponid);
			if(IsValidEdict(weaponid))
				RemoveEdict(weaponid);
		}
	}
	else if(HeadShotCount[client] >= 10 && HeadShotCount[client] < 20)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_glock", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_glock");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_glock");
		}
	}
	else if(HeadShotCount[client] >= 20 && HeadShotCount[client] < 30)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_usp", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_usp");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_usp");
		}
	}
	else if(HeadShotCount[client] >= 30 && HeadShotCount[client] < 45)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_p228", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_p228");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_p228");
		}
	}
	else if(HeadShotCount[client] >= 45 && HeadShotCount[client] < 60)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_fiveseven", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_fiveseven");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_fiveseven");
		}
	}
	else if(HeadShotCount[client] >= 60 && HeadShotCount[client] < 70)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_deagle", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_deagle");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_deagle");
		}
	}
	else if(HeadShotCount[client] >= 70)
	{
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			GetEdictClassname(weaponid, classname, sizeof(classname));
			if(!StrEqual(classname, "weapon_elite", false))
			{
				RemovePlayerItem(client, weaponid);
				if(IsValidEdict(weaponid))
					RemoveEdict(weaponid);
				GivePlayerItem(client, "weapon_elite");
			}
		}
		else
		{
			GivePlayerItem(client, "weapon_elite");
		}
	}
}

public Action:RoundFreezeEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	PrintDebugMsg("RoundFreezeEnd event called");
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(omaenable)
	{
		EntityCleanup("func_bomb_target", false);
		EntityCleanup("hostage_entity", false);
		EntityCleanup("func_buyzone", false);
		EntityCleanup("func_hostage_rescue", false);
		PrintToChatAll("[SM] %t", "onemanarmy");
	}
}

public Action:OnPlayerChangeTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	new team = GetEventInt(event, "team");
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(omaenable)
	{
		if(team == TEAM_T)
		{
			CreateTimer(0.5,TimedTeamCheck, client,TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(team == TEAM_CT)
		{	
			if(scoutClient != -1)
			{
				CreateTimer(0.1,PlayerRespawn, client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if(GetNumClientsOnTeam(TEAM_CT) > 1)
					CreateTimer(5.5,TimedOMAchooser, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerChangeTeam2(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	
	if(scoutClient != -1)
	{
		if(scoutClient == client || chosenClient == client || OMA_Team[scoutClient][0] == client || OMA_Team[scoutClient][1] == client || OMA_Team[scoutClient][2] == client)
		{
			CreateTimer(1.0,TimedTeamCheck, client,TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Handled;
		}
	}	
	return Plugin_Continue;
}


public SetSpeed(target, any:speed)
{
	if (speed == 0)
	{
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed);
	}
	else if (speed == 1.0)
	{
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed);
	}
	else
	{
		PrintDebugMsg("Set Player's new speed");
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed);
	}
}

public Action:Remove_Corpse(Handle:timer, any:client)
{
	new Body_Offset, Body_Ragdoll;
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(!omaenable)
		return Plugin_Stop;
	if(IsClientInGame(client))
	{
		Body_Offset = FindSendPropInfo("CCSPlayer", "m_hRagdoll");
		Body_Ragdoll = GetEntDataEnt2(client, Body_Offset);
		if(Body_Ragdoll != -1)
		{
			RemoveEdict(Body_Ragdoll);
		}
		else
		LogError("[SM] Cannot Find Ragdoll.");
	}
	
	return Plugin_Stop;
}

/*
This is called when a player spawns.
It is divided by teams and will execute 
certain commands on the player as needed.
*/
public Action:OnPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
	new weaponid;
	
	SetEntityRenderFx(client, RENDERFX_NONE);
	
	if(client != 0 && GetConVarBool(cvarpluginstatus))
	{
		new team = GetClientTeam(client);
		PlayerHealthChecked[client] = false;
		//new weaponid = GetPlayerWeaponSlot(client, 1);
		
		if(client != 0 && GetConVarBool(cvarpluginstatus))
		{
			if(scoutClient == -1 && GetNumClientsOnTeam(TEAM_CT) > 1)
				CreateTimer(5.5,TimedOMAchooser, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(FreezeTime)
		{
			FreezePlayer(client);
			PrintToChat(client, "[SM] %t", "wait for OMA");
		}
		
		if(team == TEAM_CT)
		{
			PrintDebugMsg("Player Has Spawned as CT");
			LongJump[client] = true;
			PlayerCanCloak[client] = true;
			
			SetClientHealth(client, PlayerHealth[client]);
			SetClientArmor(client, ArmorStats[client][0]);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1);
			if(!IsFakeClient(client))
				PrintToChat(client, "[SM] %t", "currlevel", Playerlvl[client]);
			
			weaponid = GetPlayerWeaponSlot(client, 3);
			if(weaponid == -1)
			{
				new henade = GetGrenadeID(client, "weapon_hegrenade");
				new sgnade = GetGrenadeID(client, "weapon_smokegrenade");
				
				if(PlayerSkills[client][2] >= 1 && henade == -1)
				{
					GivePlayerItem(client, "weapon_hegrenade", 0);
					for(new c = 1; c < PlayerSkills[client][2]; c++)
					{
						GiveClientGrenade(client, Slot_HEgrenade);
					}
				}
				if(PlayerSkills[client][3] >= 1 && sgnade == -1)
				{
					GivePlayerItem(client, "weapon_smokegrenade", 0);
					for(new d = 1; d < PlayerSkills[client][3]; d++)
					{
						GiveClientGrenade(client, Slot_Smokegrenade);
					}
				}
			}
		}
		else if(team == TEAM_T && scoutClient == client)
		{
			SetClientHealth(client, OMA_StartHealth);
			PrintDebugMsg("Player Has Spawned as T");
			
			if(OMAlvl2[client])
			{
				if(OMACurrWeapon[client] == -1 && OMAPoints[client] == 0 && OMA_Teamcount > 0)
					TeamChoose_Control(client, 0);
				else
				OMAPoints[client] = 1;
				
				if(OMAPoints[client] > 0)
				{
					if(!IsFakeClient(client))
						Weapons_Control(client, 0);
					else
					WeaponsTimeOut(client);
				}
				else if(OMACurrWeapon[client] != -1)
					CreateTimer(0.2, TimedCheckWeapon, client,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			CreateTimer(0.2, TimedCheckWeapon, client,TIMER_FLAG_NO_MAPCHANGE);
			
			SetClientArmor(client, 100);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1);
			
		}
	}
	return Plugin_Continue;
}

/*
Timer function for health regeneration.
Timer is set to repeat and will heal
the player until they are fully healed
or die before they are fully healed.
*/
public Action:TimedHealthRegen(Handle:timer, any:victim)
{
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(!omaenable)
		return Plugin_Stop;
	if(!IsClientInGame(victim))
		return Plugin_Stop;
	
	new VictimHealth = GetClientHealth(victim);
	new VictimTeam = GetClientTeam(victim);
	
	if(VictimTeam == TEAM_CT)
	{
		if(IsPlayerAlive(victim) && VictimHealth < PlayerHealth[victim])
		{
			SetClientHealth(victim, VictimHealth+(2 * PlayerSkills[victim][4]));
		}
		else
		{
			PlayerHealthChecked[victim] = false;
			return Plugin_Stop;
		}
	}
	else if(VictimTeam == TEAM_T)
	{
		if(IsPlayerAlive(victim) && VictimHealth < OMA_StartHealth)
		{
			SetClientHealth(victim, VictimHealth+1);
		}
		else
		{
			PlayerHealthChecked[victim] = false;
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

/*
Timer function for Armor regeneration
has the same function as health regen.
*/
public Action:TimedArmorRegen(Handle:timer, any:victim)
{
	if(!IsClientInGame(victim))
		return Plugin_Stop;
	
	new VictimTeam = GetClientTeam(victim);
	new VictimArmor = GetClientArmor(victim);
	if(VictimTeam == TEAM_CT)
	{
		if(IsPlayerAlive(victim) && VictimArmor+(2 * PlayerSkills[victim][5]) < ArmorStats[victim][0])
		{
			SetClientArmor(victim, VictimArmor+(2 * PlayerSkills[victim][5]));
		}
		else
		{
			SetClientArmor(victim, PlayerArmor[victim]);
			PlayerArmorChecked[victim] = false;
			return Plugin_Stop;
		}
	}
	
	
	return Plugin_Continue;
}

/*
Called when a player is hurt.
Uses a global bool variable PlayerHealthChecked
to intermediate between this function and the
timer function to prevent the timer function from
being called more than once.
Also used to give a CT a new grenade when
they damage the OMA and to decloak a CT when
they are hit.
*/
public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool: omaenable = GetConVarBool(cvarpluginstatus);
	if(!omaenable)
		return Plugin_Continue;
	if(IsClientInGame(victim))
	{
		new VictimHealth = GetClientHealth(victim);
		new VictimArmor = GetClientArmor(victim);
		new VictimTeam = GetClientTeam(victim);
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new dmgdone = GetEventInt(event, "dmg_health");
		//new hitbox = GetEventInt(event, "hitgroup");
		
		if(victim == scoutClient && attacker != 0)
		{
			new String:AttackerWeapon[32];
			GetEventString(event, "weapon", AttackerWeapon, sizeof(AttackerWeapon));
			
			if(StrEqual(AttackerWeapon, "knife"))
			{
				dmgdone += KnifeStats[attacker][0];
				if(VictimHealth - dmgdone != 0)
					SetClientHealth(victim, (VictimHealth-dmgdone));
			}
			if(GetConVarBool(cvardmgdetermines))
			{
				OMAdmgTimer[attacker] = 3;
				OMAdmgTotal[attacker]+= dmgdone;
				if(!OMAdmgTimerActive[attacker])
					CreateTimer(1.0, DmgReset, attacker,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		if(IsPlayerAlive(victim) && PlayerHealthChecked[victim] == false)
		{
			
			PlayerHealthChecked[victim] = true;
			if(VictimTeam == TEAM_T && VictimHealth < OMA_StartHealth)
			{
				PrintDebugMsg("Terrorist Has begun regeneration");
				if(GetNumClientsOnTeam(TEAM_CT) < 10)
				{
					CreateTimer(1.1,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(GetNumClientsOnTeam(TEAM_CT) >= 10 && GetNumClientsOnTeam(TEAM_CT) < 20)
				{
					CreateTimer(1.0,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(GetNumClientsOnTeam(TEAM_CT) >= 20 && GetNumClientsOnTeam(TEAM_CT) < 30)
				{
					CreateTimer(0.9,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				} 
				else if(GetNumClientsOnTeam(TEAM_CT) >= 30 && GetNumClientsOnTeam(TEAM_CT) < 40)
				{
					CreateTimer(0.8,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(GetNumClientsOnTeam(TEAM_CT) >= 40 && GetNumClientsOnTeam(TEAM_CT) < 50)
				{
					CreateTimer(0.7,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(GetNumClientsOnTeam(TEAM_CT) >= 50 && GetNumClientsOnTeam(TEAM_CT) < 60)
				{
					CreateTimer(0.6,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				else if(GetNumClientsOnTeam(TEAM_CT) >= 60 && GetNumClientsOnTeam(TEAM_CT) < 65)
				{
					CreateTimer(0.5,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				} 
			}
			else if(VictimTeam == TEAM_CT && VictimHealth < PlayerHealth[victim])
			{
				PrintDebugMsg("CT Has begun regeneration");
				if(PlayerSkills[victim][4] > 0)
				{
					CreateTimer(1.0,TimedHealthRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				if(PlayerXP[victim] > 0)
					PlayerXP[victim]--;
				
				if(PlayerArmorChecked[victim] == false)
				{
					PlayerArmorChecked[victim] = true;
					if(VictimArmor < PlayerArmor[victim])
					{
						if(PlayerSkills[victim][5] > 0)
						{
							CreateTimer(1.0,TimedArmorRegen, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
				new weaponid = GetPlayerWeaponSlot(victim, 2);
				new weaponid2 = GetPlayerWeaponSlot(victim, 3);
				
				if(PlayerCanCloak[victim])
				{
					SetEntityRenderFx(victim, RENDERFX_NONE);
					PlayerSpeed[victim] = 1.0;
					SetSpeed(victim, PlayerSpeed[victim]);
					if(weaponid != -1)
						SetEntityRenderFx(weaponid, RENDERFX_NONE);
					if(weaponid2 != -1)
						SetEntityRenderFx(weaponid2, RENDERFX_NONE);
					
					PlayerCanCloak[victim] = false;
					CreateTimer(1.5,CloakCharge, victim,TIMER_FLAG_NO_MAPCHANGE);
					
					//PrintToChat(victim, "[SM] Player Hurt. Rendering reset");
				}
			}
		}
		
		if(attacker != 0)
		{ 	
			new AttackerHealth = GetClientHealth(attacker);
			new String:AttackerWeapon[32];
			GetEventString(event, "weapon", AttackerWeapon, sizeof(AttackerWeapon));
			
			if(IsPlayerAlive(attacker))
			{
				if(GetClientTeam(attacker) == TEAM_CT)
				{
					if(!StrEqual(AttackerWeapon, "knife"))
					{
						if(Playerlvl[attacker] < 11)
							PlayerXP[attacker] += 15;
						GivePlayerItem(attacker, "weapon_hegrenade");
						PrintDebugMsg("Player's nade regenerated");
					}
					else
					{
						new bool: moneyroll = ChanceRoll(5 + (Playerlvl[attacker]*2) + KnifeStats[attacker][MoneySteal_Slot] + ArmorStats[attacker][MoneySteal_Slot]);
						new cashstolen;
						if(Playerlvl[attacker] < 11)
							PlayerXP[attacker] += 30;
						
						if(moneyroll)
						{
							new VictimCash = GetClientMoney(victim);
							new AttackerCash = GetClientMoney(attacker);
							cashstolen = GetRandomInt(1, 100);
							if(cashstolen < VictimCash)
							{
								SetClientMoney(victim, VictimCash-cashstolen);
								SetClientMoney(attacker, AttackerCash+cashstolen);
								PrintToConsole(attacker, "[SM] %t", "stole cash", cashstolen);
							}
							else
							{
								SetClientMoney(attacker, AttackerCash+VictimCash);
								SetClientMoney(victim, 0);
								PrintToConsole(attacker, "[SM] %t", "stole cash", cashstolen);
							}
							
						}
						
					}
					if(!IsFakeClient(attacker))
						PrintHintText(attacker, "%t", "currxp", PlayerXP[attacker], XPlvl[Playerlvl[attacker]]);
					ManageExperience(attacker);
				}
				else if(GetClientTeam(attacker) == TEAM_T)
				{
					if(StrEqual(AttackerWeapon, "scout"))
					{
						if(AttackerHealth+50 <= OMA_StartHealth)
							SetClientHealth(attacker, AttackerHealth+50);
					}
					else if(StrEqual(AttackerWeapon, "awp"))
					{
						if(AttackerHealth+25 <= OMA_StartHealth)
							SetClientHealth(attacker, AttackerHealth+25);
					}
					else if(StrEqual(AttackerWeapon, "g3sg1"))
					{
						if(AttackerHealth+15 <= OMA_StartHealth)
							SetClientHealth(attacker, AttackerHealth+15);
					}
					else if(StrEqual(AttackerWeapon, "sg550"))
					{
						if(AttackerHealth+15 <= OMA_StartHealth)
							SetClientHealth(attacker, AttackerHealth+15);
					}
					
				}
			}
			
			if(PlayerSkills[attacker][9] > 0)
			{
				if(IsPlayerAlive(attacker) && GetClientTeam(attacker) == TEAM_CT)
				{
					if(AttackerHealth+(PlayerSkills[attacker][9]*10) < PlayerHealth[attacker])
						SetClientHealth(attacker, AttackerHealth+(PlayerSkills[attacker][9]*10));
					else
					SetClientHealth(attacker, PlayerHealth[attacker]);
				}
			}
		}
	}
	return Plugin_Continue;
}

/*
Called when a player dies. one of the main gears of the plugin.
This function will, based on the attacker and victim, give ammo, health
set the new OMA, give the oma his new pistol and announce that the OMA
is about to win.
*/
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	// get player userid
	new userid = GetEventInt(event, "userid");
	new userid2 = GetEventInt(event, "attacker");
	new bool: headshot = GetEventBool(event, "headshot");
	// get players entity ids
	new victim = GetClientOfUserId(userid);
	new victimTeam = GetClientTeam(victim);
	new attacker = GetClientOfUserId(userid2);
	new weaponid;
	//new bool: scoutdefeated = false;
	new timeleft;
	GetMapTimeLeft(timeleft);
	
	new String:AttackerName[64];
	new bool: teamdead = false;
	
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	
	if(!GetConVarBool(cvarpluginstatus))
	{
		return Plugin_Continue;
	}
	
	if(victimTeam == TEAM_T && scoutClient == victim)
	{
		new bool: allowbots = GetConVarBool(cvarallowbots);
		
		if(attacker == victim || attacker == 0)
		{
			CS_SwitchTeam(scoutClient, TEAM_CT);
			if(OMAlvl2[scoutClient] && OMA_Team[scoutClient][3] > 0)
			{
				for(new c = 0; c < OMA_Team[scoutClient][3]; c++)
				{
					if(IsClientInGame(OMA_Team[scoutClient][c]))
						CS_SwitchTeam(OMA_Team[scoutClient][c], TEAM_CT);
				}
			}
			
			if(!allowbots)
			{
				if(IsFakeClient(attacker))
				{
					new bool:fake, bool: notconnected, check = 0;
					do{
						scoutClient = GetRandomInt(1, MaxClients);
						if(IsClientInGame(scoutClient))
							notconnected = true;
						else
							notconnected = false;
						if(IsFakeClient(scoutClient))
							fake = true;
						else
						fake = false;
						
						check++;
						if(check > 1000)
						{
							LogError("[SM] Infinite Loop at line 2753");
							break;
						}
					}while(notconnected && fake);
				}
			}
			else
			{
				new check = 0;
				do{
					scoutClient = GetRandomInt(1, MaxClients);
					check++;
					if(check > 1000)
					{
						LogError("[SM] Infinite Loop at line 2776");
						break;
					}
				}while(!IsClientInGame(scoutClient));
			}
			
			if(timeleft > 0)
			{
				if(GetNumClientsOnTeam(TEAM_CT) >= 2 && timeleft > 0)
				{
					new bool: chosen = false;
					for(new c = 1; c <= GetMaxClients(); c++)
					{
						if(IsClientInGame(c))
						{
							if(GetClientTeam(c) == TEAM_CT)
							{
								if(!chosen)
								{
									if(IsPlayerAlive(c) && c != scoutClient)
									{
										chosenClient = c;
										CS_SwitchTeam(chosenClient, TEAM_T);
										SetEntProp(chosenClient, Prop_Data, "m_takedamage", 0, 1);
										chosen = true;
									}
								}	
							}
						}
						OMAdmgTotal[c] = 0;
					}
				}
				
				CreateTimer(1.5,TimedSwitchTeam, victim,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0,TimedSwitchTeam2, victim,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.9,TimedRespawnProtect, victim,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	if(attacker != 0 && victim != 0 && IsClientInGame(attacker) && IsClientInGame(victim) && scoutClient != -1)
	{	
		new AttackerHealth = GetClientHealth(attacker);
		new attackerTeam = GetClientTeam(attacker);
		
		new String: AttackerWeapon[64];
		new String:classname[32];
		
		GetEventString(event, "weapon", AttackerWeapon, sizeof(AttackerWeapon));
		CreateTimer(0.5, Remove_Corpse, victim, TIMER_FLAG_NO_MAPCHANGE);
		
		
		
		if(attackerTeam == TEAM_T)
		{			
			if(headshot)
				HeadShotCount[attacker] += 1;
			
			SetEntProp(attacker, Prop_Send, "m_iHideHUD", 0);
			
			switch(Playerlvl[victim])
			{
				case 1:
				{
					OMA_XP[scoutClient] += 50;
				}
				
				case 2:
				{
					OMA_XP[scoutClient] += 100;
				}
				
				case 3:
				{
					OMA_XP[scoutClient] += 150;
				}
				
				case 4:
				{
					OMA_XP[scoutClient] += 200;
				}
				
				case 5:
				{
					OMA_XP[scoutClient] += 250;
				}
				
				case 6:
				{
					OMA_XP[scoutClient] += 300;
				}
				
				case 7:
				{
					OMA_XP[scoutClient] += 350;
				}
				
				case 8:
				{
					OMA_XP[scoutClient] += 400;
				}
				
				case 9:
				{
					OMA_XP[scoutClient] += 450;
				}
				
				case 10:
				{
					OMA_XP[scoutClient] += 500;
				}
			}
			
			if(OMAlvl2[scoutClient])
			{				
				new req;
				if(OMA_Team[scoutClient][3] > 0)
					req = OMA_ReqXP * (OMA_Team[scoutClient][3]+1);
				else
				req = OMA_ReqXP;
				
				PrintDebugMsg("OMA killed CT as LVL2");
				PrintHintText(attacker, "%t", "currxp", OMA_XP[attacker], req);
				ManageExperience(attacker);
				CreateTimer(1.0,FixNames, attacker,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				PrintDebugMsg("OMA Killed CT as lvl1");
				CreateTimer(1.0,FixNames, attacker,TIMER_FLAG_NO_MAPCHANGE);
				ManageExperience(attacker);
				CheckLevel(attacker);
				PrintHintText(attacker, "%t", "currxp", OMA_XP[attacker], OMA_ReqXP);
			}
			
			
			
			if(HeadShotCount[attacker] == 10)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_glock", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_glock");
					}
				}
				else
				{
					if(!IsFakeClient(attacker))
						PrintToChat(attacker, "[SM] %t", "won_glock");
					GivePlayerItem(attacker, "weapon_glock");
				}
			}
			else if(HeadShotCount[attacker] == 20)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_usp", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_usp");
					}
				}
			}
			else if(HeadShotCount[attacker] == 30)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_p228", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_p228");
					}
				}
			}
			else if(HeadShotCount[attacker] == 45)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_fiveseven", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_fiveseven");
					}
				}
			}
			else if(HeadShotCount[attacker] == 60)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_deagle", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_deagle");
					}
				}
			}
			else if(HeadShotCount[attacker] == 80)
			{
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, "weapon_elite", false))
					{
						RemovePlayerItem(attacker, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(attacker, "weapon_elite");
					}
				}
			}
			
			PlayerHealthChecked[victim] = false;
			PlayerArmorChecked[victim] = false;
		}
		
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientInGame(i))
			{
				if(victimTeam == GetClientTeam(i))
				{
					if(IsPlayerAlive(i))
					{
						//PrintToConsole(attacker, "[SM] Found a live player.");
						teamdead = false;
						break;
					}							
					else
					teamdead = true;
				}
			}
		}
		
		if(scoutClient != -1)
		{
			new bool: omadmg = GetConVarBool(cvardmgdetermines);
			new bool: allowbots = GetConVarBool(cvarallowbots);
			new newoma = 1, oldoma = scoutClient;
			decl String: ClientName[64];
			if(attackerTeam == TEAM_CT && !IsPlayerAlive(scoutClient))
			{
				if(!allowbots)
				{
					if(omadmg)
					{
						for(new p = 1; p <= MaxClients; p++)
						{
							if(IsClientInGame(p))
							{
								if(!IsFakeClient(p))
								{
									if(OMAdmgTotal[newoma] < OMAdmgTotal[p])
									{
										newoma = p;
									}
								}
							}
						}	
						scoutClient = newoma;
						GetClientName(scoutClient, ClientName, sizeof(ClientName));
						PrintToChatAll("[SM] %t", "oma_dmg", ClientName, OMAdmgTotal[scoutClient]);
					}
					
					else if(IsFakeClient(attacker))
					{
						new bool:fake, bool: notconnected, check = 0;
						do{
							scoutClient = GetRandomInt(1, MaxClients);
							if(IsClientInGame(scoutClient))
								notconnected = true;
							else
								notconnected = false;
							if(IsFakeClient(scoutClient))
								fake = true;
							else
							fake = false;
							
							check++;
							if(check > 1000)
							{
								LogError("[SM] Infinite Loop at line 3073");
								break;
							}
						}while(notconnected && fake);
					}
					else
					scoutClient = attacker;
				}
				else if(omadmg)
				{
					for(new p = 1; p <= MaxClients; p++)
					{
						if(IsClientInGame(p))
						{
							if(OMAdmgTotal[newoma] < OMAdmgTotal[p])
							{
								newoma = p;
							}
						}
					}
					scoutClient = newoma;
					GetClientName(scoutClient, ClientName, sizeof(ClientName));
					PrintToChatAll("[SM] %t", "oma_dmg", ClientName, OMAdmgTotal[scoutClient]);
				}
				else
				scoutClient = attacker;
				
				PrintDebugMsg("CT killed OMA and is now the OMA");
				EntityCleanup("weapon_", true);
				
				
				PlayerHealthChecked[victim] = false;
				
				if(timeleft > 0)
				{
					if(GetNumClientsOnTeam(TEAM_CT) >= 2 && timeleft > 0)
					{
						new bool: ischosen = false;
						for(new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i))
							{
								if(GetClientTeam(i) == TEAM_CT)
								{
									if(!ischosen)
									{
										if(IsPlayerAlive(i) && i != scoutClient)
										{
											chosenClient = i;
											CS_SwitchTeam(chosenClient, TEAM_T);
											SetEntProp(chosenClient, Prop_Data, "m_takedamage", 0, 1);
											ischosen = true;
										}
									}
									
									if(!IsPlayerAlive(i) && i != oldoma)
									{
										CS_RespawnPlayer(i);
									}
								}
							}
							OMAdmgTotal[i] = 0;
						}
					}				
					
					CreateTimer(1.5,TimedSwitchTeam, victim,TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(1.0,TimedSwitchTeam2, victim,TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(1.9,TimedRespawnProtect, victim,TIMER_FLAG_NO_MAPCHANGE);
				}
			}	
			else
			{
				new String: weaponname[32];
				weaponid = GetPlayerWeaponSlot(attacker, 0);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
					SetWeaponAmmo(attacker, GetWeaponAmmoOffset(weaponname), GetWeaponAmmo(attacker, GetWeaponAmmoOffset(weaponname)) + 30);
				}
				weaponid = GetPlayerWeaponSlot(attacker, 1);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
					SetWeaponAmmo(attacker, GetWeaponAmmoOffset(weaponname), GetWeaponAmmo(attacker, GetWeaponAmmoOffset(weaponname)) + 30);
				}
				//SetClientMoney(attacker, 1);
				if(AttackerHealth+25 <= OMA_StartHealth)
					SetClientHealth(attacker, AttackerHealth+25);
				else
				SetClientHealth(attacker, OMA_StartHealth);
				//PrintToConsole(attacker, "[SM] Set Weapon Ammo");
			}
		}
	}
	if(scoutClient != -1)
	{
		new String: AttackerWeapon[64];
		
		GetEventString(event, "weapon", AttackerWeapon, sizeof(AttackerWeapon));
		//PrintToChatAll("[SM] victimTeam is: %d", victimTeam);
		if(IsClientInGame(victim) && victimTeam == TEAM_CT && !teamdead)
		{
			if(!StrEqual("m249", AttackerWeapon, false))
			{
				//PrintToConsole(attacker, "[SM] Respawning victim");
				if(ChanceRoll(35))
					SpawnGoodieBox(victim);
				
				ManageExperience(victim);
				PrintDebugMsg("Respawning CT");
				//EntityCleanup("weapon_knife", true);
				PlayerRespawnTime[victim] = FloatAdd(PlayerRespawnTime[victim], 0.5);
				CreateTimer(0.1, PlayerRespawn, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
				for(new m = 0; m < 59; m++)
				{	
					EntityList[m] = EntityList[m+1];
				}
				EntityList[59] = 0;
			}
			else
			{
				if(!IsFakeClient(victim))
					PrintToChat(victim, "[SM] %t", "defeated");
			}
		}
		else if(IsClientInGame(victim) && victimTeam == TEAM_T && IsPlayerAlive(scoutClient))
			CreateTimer(0.1, PlayerRespawn, victim,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(cvarpluginstatus))
	{
		return Plugin_Continue;
	}
	
	if(scoutClient != -1)
	{
		if(IsClientInGame(scoutClient))
		{
			if(IsPlayerAlive(scoutClient))
			{
				new String:Name[64];
				GetClientName(scoutClient, Name, sizeof(Name));
				PrintDebugMsg("Round has ended, checking OMA Status");
				if(OMA_lvl[scoutClient] == OMA_MaxLvl)
				{
					PrintToChatAll("[SM] %t", "won_round", Name);
					Weaponlvl[scoutClient] = 0;
					HeadShotCount[scoutClient] = 0;
					OMACurrWeapon[scoutClient] = -1;
					new weaponid = GetPlayerWeaponSlot(scoutClient, 0);
					if(weaponid != -1)
					{
						RemovePlayerItem(scoutClient, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
					}
					Weaponlvl[scoutClient] = 0;
					
					EndGame();
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnItemPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new String: PickedWeapon[64], String: buffer[64];
	new team = GetClientTeam(client);
	new weaponid;
	
	GetEventString(event, "item", PickedWeapon, sizeof(PickedWeapon));
	
	if(team == TEAM_CT)
	{
		Format(buffer, sizeof(buffer), "CT has picked up a %s.", PickedWeapon);
		PrintDebugMsg(buffer);
		
		
		weaponid = GetPlayerWeaponSlot(client, 0);
		if(weaponid != -1)
		{
			RemovePlayerItem(client, weaponid);
			CreateTimer(0.2,TimedDeleteWeapon, weaponid,TIMER_FLAG_NO_MAPCHANGE);
		}
		weaponid = GetPlayerWeaponSlot(client, 1);
		if(weaponid != -1)
		{
			RemovePlayerItem(client, weaponid);
			CreateTimer(0.2,TimedDeleteWeapon, weaponid,TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CreateTimer(0.2, SwitchToKnife, client,TIMER_FLAG_NO_MAPCHANGE);
		/*
		weaponid = GetPlayerWeaponSlot(client, 3);
		if(weaponid != -1)
		{
			if(StrEqual("hegrenade", PickedWeapon, true))
			{
				new gren = GetGrenadeID(client, "weapon_hegrenade");
				if(PlayerSkills[client][2] < 1)
				{
					if(gren != -1)
					{
						RemovePlayerItem(client, gren);
						CreateTimer(0.2,TimedDeleteWeapon, gren,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2, SwitchToKnife, client,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			
			if(StrEqual("smokegrenade", PickedWeapon, true))
			{
				new gren = GetGrenadeID(client, "weapon_smokegrenade");
				if(PlayerSkills[client][3] < 1)
				{
					if(gren != -1)
					{
						RemovePlayerItem(client, gren);
						CreateTimer(0.2,TimedDeleteWeapon, gren,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2, SwitchToKnife, client,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}*/
	}
	else if(team == TEAM_T)
	{
		Format(buffer, sizeof(buffer), "T has picked up a %s.", PickedWeapon);
		PrintDebugMsg(buffer);
		if(!StrEqual("hegrenade", PickedWeapon, true) && !StrEqual("smokegrenade", PickedWeapon, true))
		{
			CreateTimer(0.2, TimedCheckWeapon, client,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public EnableLevel2(client)
{
	OMAlvl2[scoutClient] = true;
	OMAPoints[scoutClient] = 0;
	if(GetConVarBool(cvarteamplay) && !IsFakeClient(scoutClient))
	{
		if(HeadShotCount[scoutClient] < 10)
		{
			FreezeTime = false;
			OMA_Teamcount = 0;
			OMAPoints[scoutClient] = 1;
		}
		else if(HeadShotCount[scoutClient] < 20 || playercount < 5)
		{
			FreezeTime = true;
			OMA_Teamcount = 1;
			TeamChoose_Control(scoutClient, 0);
		}
		else if(HeadShotCount[scoutClient] < 30 && playercount > 5)
		{
			FreezeTime = true;
			OMA_Teamcount = 2;
			TeamChoose_Control(scoutClient, 0);
		}
		else if(HeadShotCount[scoutClient] > 40 && playercount > 7)
		{
			FreezeTime = true;
			OMA_Teamcount = 3;
			TeamChoose_Control(scoutClient, 0);
		}	
	}
	else
	{
		FreezeTime = false;
		OMA_Teamcount = 0;
		OMAPoints[scoutClient] = 1;
	}
	
	OMA_Team[scoutClient][3] = OMA_Teamcount;
	
	OMAPoints[scoutClient] += 1;
	Weapons_Control(scoutClient, 0);
	if(!IsFakeClient(scoutClient))
	{
		PrintToChat(scoutClient, "[SM] %t", "currlevel", OMA_lvl[scoutClient]);
		PrintHintText(scoutClient, "%t", "currxp", OMA_XP[scoutClient], OMA_ReqXP);
	}
	else
	WeaponsTimeOut(client);
	for(new i = 0; i < OMA_Team[scoutClient][3]; i++)
	{
		if(OMA_Team[scoutClient][i] != -1)
		{
			OMAPoints[OMA_Team[scoutClient][i]] += 1;
			Weapons_Control(OMA_Team[scoutClient][i], 0);
			if(!IsFakeClient(OMA_Team[scoutClient][i]))
			{
				PrintToChat(OMA_Team[scoutClient][i], "[SM] %t", "currlevel", OMA_lvl[scoutClient]);
				PrintHintText(OMA_Team[scoutClient][i], "%t", "currxp", OMA_XP[scoutClient], OMA_ReqXP);
			}
			else
			WeaponsTimeOut(OMA_Team[scoutClient][i]);
		}
	}
}

/*
Timed function will randomly choose a OMA if scoutClient is -1

*/
public Action:TimedOMAchooser(Handle:timer)
{
	new String:ClientName[64];
	new bool: allowbots = GetConVarBool(cvarallowbots);
	
	if((scoutClient == -1 && GetClientCount(true) != 0))
	{
		PrintDebugMsg("Random OMA chooser called.");
		if(allowbots)
		{
			new check = 0;
			do{
				scoutClient = GetRandomInt(1, MaxClients);
				check++;
				if(check > 1000)
				{
					LogError("[SM] Infinite Loop at line 3413");
					break;
				}
			}while(!IsClientInGame(scoutClient));
		}
		else
		{
			new bool:fake, bool: notconnected, check = 0;
			do{
				scoutClient = GetRandomInt(1, MaxClients);
				if(IsClientInGame(scoutClient))
					notconnected = true;
				else
					notconnected = false;
				if(IsFakeClient(scoutClient))
					fake = true;
				else
				fake = false;
				check++;
				if(check > 1000)
				{
					LogError("[SM] Infinite Loop at line 3426");
					break;
				}
			}while(notconnected && fake);
		}
		if(GetNumClientsOnTeam(TEAM_T) > 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == TEAM_T)
					{
						CS_SwitchTeam(i, TEAM_CT);
						CS_RespawnPlayer(i);
					}
				}
			}
			CS_SwitchTeam(scoutClient, TEAM_T);
			CS_RespawnPlayer(scoutClient);
		}
		else
		{
			CS_SwitchTeam(scoutClient, TEAM_T);
			CS_RespawnPlayer(scoutClient);
		}
		GetClientName(scoutClient, ClientName, sizeof(ClientName));
		PrintToChatAll("[SM] %t", "chosen_oma", ClientName);
		/*if(!cloaktimer)
		{
		CreateTimer(1.0, CheckCloak, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		cloaktimer = true;
		}*/
	}
	return Plugin_Stop;
}

public FakeSkillMenu(param1, param2)
{
	//LogMessage("Bot client %d has chosen skill %d", param1, param2);
	if(IsPlayerAlive(param1))
	{
		if(param2 == 0)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][0] < 16)
			{
				if(Playerlvl[param1] <= 5 && PlayerSkills[param1][0] == 6)
					PrintToChat(param1, "%t", "low_level");
				else
				{
					PlayerSkills[param1][0]++;
					PlayerPoints[param1]--;
					PlayerHealth[param1] = 100 + (25 * PlayerSkills[param1][0]);
					//PrintToChat(param1, "Set ClientHealth to: %d", PlayerHealth[param1]);
					SetClientHealth(param1, PlayerHealth[param1]);
					PrintDebugMsg("Bot client has chosen skill 0");
				}
			}
		}
		else if(param2 == 1)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][1] < 5)
			{
				PlayerSkills[param1][1]++;
				PlayerPoints[param1]--;
				PrintDebugMsg("Bot client has chosen skill 1");
			}
		}
		else if(param2 == 2)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][10] < 5)
			{
				PlayerSkills[param1][10]++;
				PlayerPoints[param1]--;
				PrintDebugMsg("Bot client has chosen skill 10");
			}
		}
		else if(param2 == 3)
		{	
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][2] < 5)
			{
				PlayerSkills[param1][2]++;
				PlayerPoints[param1]--;
				GivePlayerItem(param1, "weapon_hegrenade");
				PrintDebugMsg("Bot client has chosen skill 2");
			}	
		}	
		else if(param2 == 4)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][3] < 3)
			{
				PlayerSkills[param1][3]++;
				PlayerPoints[param1]--;
				GivePlayerItem(param1, "weapon_smokegrenade");
				PrintDebugMsg("Bot client has chosen skill 3");
			}
		}
		else if(param2 == 5)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][4] < 10)
			{
				PlayerSkills[param1][4]++;
				PlayerPoints[param1]--;
				if(GetClientHealth(param1) < PlayerHealth[param1])
				{
					PlayerHealthChecked[param1] = false;
					CreateTimer(1.0,TimedHealthRegen, param1,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintDebugMsg("Bot client has chosen skill 4");
				}
			}
		}
		else if(param2 == 6)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][5] < 10)
			{
				PlayerSkills[param1][5]++;
				PlayerPoints[param1]--;
				PrintDebugMsg("Bot client has chosen skill 5");				
			}
		}
		else if(param2 == 7)
		{
			if(PlayerPoints[param1] > 0 && PlayerSkills[param1][6] < 3)
			{
				if(Playerlvl[param1] - 3 > PlayerSkills[param1][6])
				{
					PlayerSkills[param1][6]++;
					PlayerPoints[param1]--;
					PrintDebugMsg("Bot client has chosen skill 6");
				}
				else
				PrintToChat(param1, "%t", "low_level");
			}
		}
		
		if(PlayerSkills[param1][8] < 1 && PlayerSkills[param1][7] < 1 && PlayerSkills[param1][9] < 1)
		{
			if(param2 == 9)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][7] < 2)
				{
					PlayerSkills[param1][7]++;
					PlayerPoints[param1]--;
					PrintDebugMsg("Bot client has chosen skill 7");
				}
			}
			else if(param2 == 10)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][8] < 3)
				{
					PlayerSkills[param1][8]++;
					PlayerPoints[param1]--;
					PrintDebugMsg("Bot client has chosen skill 8");
				}
			}
			else if(param2 == 11)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][9] < 3)
				{
					PlayerSkills[param1][9]++;
					PlayerPoints[param1]--;
					PrintDebugMsg("Bot client has chosen skill 9");
				}
			}
		}
		else
		{
			if(PlayerSkills[param1][8] < 1 && PlayerSkills[param1][9] < 1)
			{
				if(param2 == 8 || param2 == 9 || param2 == 10 || param2 == 11)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][7] < 2)
					{	
						if(Playerlvl[param1] - 6 > PlayerSkills[param1][7])
						{
							PlayerSkills[param1][7]++;
							PlayerPoints[param1]--;
							PrintDebugMsg("Bot client has chosen skill 7");
						}
						else
						PrintToChat(param1, "%t", "low_level");
					}
				}
			}
			else if(PlayerSkills[param1][7] < 1 && PlayerSkills[param1][9] < 1)
			{
				if(param2 == 8 || param2 == 9 || param2 == 10 || param2 == 11)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][8] < 3)
					{
						if(Playerlvl[param1] - 6 > PlayerSkills[param1][8])
						{
							PlayerSkills[param1][8]++;
							PlayerPoints[param1]--;
							PrintDebugMsg("Bot client has chosen skill 8");
						}
						else
						PrintToChat(param1, "%t", "low_level");
					}	
				}
			}
			else if(PlayerSkills[param1][7] < 1 && PlayerSkills[param1][8] < 1)
			{
				if(param2 == 8 || param2 == 9 || param2 == 10 || param2 == 11)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][9] < 3)
					{
						if(Playerlvl[param1] - 6 > PlayerSkills[param1][9])
						{
							PlayerSkills[param1][9]++;
							PlayerPoints[param1]--;
							PrintDebugMsg("Bot client has chosen skill 9");
						}
						else
						PrintToChat(param1, "%t", "low_level");
					}	
				}
			}
		}
	}
}

public SkillMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if(GetClientTeam(param1) == TEAM_CT && IsPlayerAlive(param1))
		{
			if(param2 == 0)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][0] < 16)
				{
					if(Playerlvl[param1] <= 5 && PlayerSkills[param1][0] == 6)
						PrintToChat(param1, "%t", "low_level");
					else
					{
						PlayerSkills[param1][0]++;
						PlayerPoints[param1]--;
						PlayerHealth[param1] = 100 + (25 * PlayerSkills[param1][0]);
						//PrintToChat(param1, "Set ClientHealth to: %d", PlayerHealth[param1]);
						SetClientHealth(param1, PlayerHealth[param1]);
					}
				}
			}
			else if(param2 == 1)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][1] < 5)
				{
					PlayerSkills[param1][1]++;
					PlayerPoints[param1]--;
				}
			}
			else if(param2 == 2)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][10] < 5)
				{
					PlayerSkills[param1][10]++;
					PlayerPoints[param1]--;
				}
			}
			else if(param2 == 3)
			{	
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][2] < 5)
				{
					PlayerSkills[param1][2]++;
					PlayerPoints[param1]--;
					GivePlayerItem(param1, "weapon_hegrenade");
				}	
			}	
			else if(param2 == 4)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][3] < 3)
				{
					PlayerSkills[param1][3]++;
					PlayerPoints[param1]--;
					GivePlayerItem(param1, "weapon_smokegrenade");
				}
			}
			else if(param2 == 5)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][4] < 10)
				{
					PlayerSkills[param1][4]++;
					PlayerPoints[param1]--;
					if(GetClientHealth(param1) < PlayerHealth[param1])
					{
						PlayerHealthChecked[param1] = false;
						CreateTimer(1.0,TimedHealthRegen, param1,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			else if(param2 == 6)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][5] < 10)
				{
					PlayerSkills[param1][5]++;
					PlayerPoints[param1]--;
					
				}
			}
			else if(param2 == 7)
			{
				if(PlayerPoints[param1] > 0 && PlayerSkills[param1][6] < 3)
				{
					if(Playerlvl[param1] - 3 > PlayerSkills[param1][6])
					{
						PlayerSkills[param1][6]++;
						PlayerPoints[param1]--;
					}
					else
					PrintToChat(param1, "%t", "low_level");
				}
			}
			
			if(PlayerSkills[param1][8] < 1 && PlayerSkills[param1][7] < 1 && PlayerSkills[param1][9] < 1)
			{
				if(param2 == 9)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][7] < 2)
					{
						PlayerSkills[param1][7]++;
						PlayerPoints[param1]--;
					}
				}
				else if(param2 == 10)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][8] < 3)
					{
						PlayerSkills[param1][8]++;
						PlayerPoints[param1]--;
					}
				}
				else if(param2 == 11)
				{
					if(PlayerPoints[param1] > 0 && PlayerSkills[param1][9] < 3)
					{
						PlayerSkills[param1][9]++;
						PlayerPoints[param1]--;
					}
				}
			}
			else
			{
				if(PlayerSkills[param1][8] < 1 && PlayerSkills[param1][9] < 1)
				{
					if(param2 == 8)
					{
						if(PlayerPoints[param1] > 0 && PlayerSkills[param1][7] < 2)
						{	
							if(Playerlvl[param1] - 6 > PlayerSkills[param1][7])
							{
								PlayerSkills[param1][7]++;
								PlayerPoints[param1]--;
							}
							else
							PrintToChat(param1, "%t", "low_level");
						}
					}
				}
				else if(PlayerSkills[param1][7] < 1 && PlayerSkills[param1][9] < 1)
				{
					if(param2 == 8)
					{
						if(PlayerPoints[param1] > 0 && PlayerSkills[param1][8] < 3)
						{
							if(Playerlvl[param1] - 6 > PlayerSkills[param1][8])
							{
								PlayerSkills[param1][8]++;
								PlayerPoints[param1]--;
							}
							else
							PrintToChat(param1, "%t", "low_level");
						}	
					}
				}
				else if(PlayerSkills[param1][7] < 1 && PlayerSkills[param1][8] < 1)
				{
					if(param2 == 8)
					{
						if(PlayerPoints[param1] > 0 && PlayerSkills[param1][9] < 3)
						{
							if(Playerlvl[param1] - 6 > PlayerSkills[param1][9])
							{
								PlayerSkills[param1][9]++;
								PlayerPoints[param1]--;
							}
							else
							PrintToChat(param1, "%t", "low_level");
						}	
					}
				}
			}
			if(PlayerPoints[param1] > 0)
				Skills_Control(param1, 0);
		}
		else
		PrintToChat(param1, "[SM] %t", "skillmenu_1");
	}	
	
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t", "skillmenu_2");
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


/*
* Skills menu: Skill points can be used to improve a players abilities.
* lvl 2: Health Points
* lvl 2: HE nades
* lvl 2: Smoke Grenades
* lvl 2: Regen Health lvl 1
* lvl 3: Regen Armor 
* lvl 4: Super Stealth(faster speed when cloaked)

*/
public Action:Skills_Control(client, args)
{
	new String: buffer[64], String: buffer2[64], String: buffer3[64], String: buffer4[64], String: buffer5[64];
	new String: buffer6[64], String: buffer7[64], String: buffer8[64], String: buffer9[64], String: buffer10[64];
	new String: buffer11[64], String: buffer12[64];
	Format(buffer, sizeof(buffer), "%T %d/16", "hplvl", LANG_SERVER, PlayerSkills[client][0]);
	Format(buffer2, sizeof(buffer2), "%T %d/5", "mflvl", LANG_SERVER, PlayerSkills[client][1]);
	Format(buffer3, sizeof(buffer3), "%T %d/5", "helvl", LANG_SERVER, PlayerSkills[client][2]);
	Format(buffer4, sizeof(buffer4), "%T %d/3", "sglvl", LANG_SERVER, PlayerSkills[client][3]);
	Format(buffer5, sizeof(buffer5), "%T %d/10", "rhplvl", LANG_SERVER, PlayerSkills[client][4]);
	Format(buffer6, sizeof(buffer6), "%T %d/3", "sslvl", LANG_SERVER, PlayerSkills[client][6]);
	Format(buffer7, sizeof(buffer7), "%T %d/10", "raplvl", LANG_SERVER, PlayerSkills[client][5]);
	Format(buffer8, sizeof(buffer8), "%T %d/2", "slvl", LANG_SERVER, PlayerSkills[client][7]);
	Format(buffer9, sizeof(buffer9), "%T %d/3", "ljlvl", LANG_SERVER, PlayerSkills[client][8]);
	Format(buffer10, sizeof(buffer10), "%T %d/3", "lslvl", LANG_SERVER, PlayerSkills[client][9]);
	Format(buffer11, sizeof(buffer11), "%T", "choose_advanced", LANG_SERVER);
	Format(buffer12, sizeof(buffer12), "%T %d/5", "mslvl", LANG_SERVER, PlayerSkills[client][10]);
	new Handle:menu = CreateMenu(SkillMenu);
	SetMenuTitle(menu, "%t", "skill_point", PlayerPoints[client]);
	
	AddMenuItem(menu, buffer, buffer);
	AddMenuItem(menu, buffer2, buffer2);
	AddMenuItem(menu, buffer12, buffer12);
	AddMenuItem(menu, buffer3, buffer3);
	AddMenuItem(menu, buffer4, buffer4);
	AddMenuItem(menu, buffer5, buffer5);
	if(Playerlvl[client] >= 3)
		AddMenuItem(menu, buffer7, buffer7);
	if(Playerlvl[client] >= 4)
		AddMenuItem(menu, buffer6, buffer6);
	if(Playerlvl[client] >= 7 && PlayerSkills[client][8] < 1 && PlayerSkills[client][7] < 1 && PlayerSkills[client][9] < 1)
		AddMenuItem(menu, buffer11, buffer11);
	if(Playerlvl[client] >= 7 && PlayerSkills[client][8] < 1 && PlayerSkills[client][9] < 1)
		AddMenuItem(menu, buffer8, buffer8);
	if(Playerlvl[client] >= 7 && PlayerSkills[client][7] < 1 && PlayerSkills[client][9] < 1)
		AddMenuItem(menu, buffer9, buffer9);
	if(Playerlvl[client] >= 7 && PlayerSkills[client][7] < 1 && PlayerSkills[client][8] < 1)
		AddMenuItem(menu, buffer10, buffer10);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public GambleMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new ClientCash = GetClientMoney(param1);
		if(param2 == 0 && ClientCash >= 100)
		{
			SetClientMoney(param1, ClientCash - 100);
			new bool: fail = false;
			new r = GetRandomInt(0, 5);
			switch(r)
			{
				case 0:
				{
					KnifeStats2[param1][0] = GetRandomInt(0, 5);
				}
				case 1:
				{
					KnifeStats2[param1][1] = GetRandomInt(0, 7);
				}
				case 2:
				{
					KnifeStats2[param1][2] = GetRandomInt(0, 5);
				}
				case 3:
				{
					KnifeStats2[param1][3] = GetRandomInt(0, 3);
				}
				case 4:
				{
					KnifeStats2[param1][4] = GetRandomInt(0, 1);
					KnifeStats2[param1][5] = GetRandomInt(0, 10);
				}
				case 5:
				{
					PrintToChat(param2, "[SM] %t", "fail");
					fail = true;
				}
			}
			if(!fail)
				NewKnifeStatsControl(param1, 0);
		}
		else if(param2 > 0 && param2 <= 4)
		{
			new bool: canpay = false;
			switch(param2)
			{
				case 1:
				{
					if(ClientCash >= 500)
						canpay = true;
					SetClientMoney(param1, ClientCash - 500);
				}
				case 2:
				{
					if(ClientCash >= 1000)
						canpay = true;
					SetClientMoney(param1, ClientCash - 1000);
				}
				case 3:
				{
					if(ClientCash >= 5000)
						canpay = true;
					SetClientMoney(param1, ClientCash - 5000);
				}
				case 4:
				{
					if(ClientCash >= 10000)
						canpay = true;
					SetClientMoney(param1, ClientCash - 10000);
				}
			}
			new bool: win = ChanceRoll(19*param2);
			if(canpay)
			{
				if(win)
				{
					new rand;
					new lvl = param2+1;
					for(new i = 1; i <= lvl; i++)
					{
						rand = GetRandomInt(0, 4);
						switch(rand)
						{
							case 0:
							{
								KnifeStats2[param1][0] = GetRandomInt(0, (6*lvl));
							}
							case 1:
							{
								KnifeStats2[param1][1] = GetRandomInt(0, (8*lvl));
							}
							case 2:
							{
								KnifeStats2[param1][2] = GetRandomInt(0, (6*lvl));
							}
							case 3:
							{
								KnifeStats2[param1][3] = GetRandomInt(0, (4*lvl));
							}
							case 4:
							{
								KnifeStats2[param1][4] = GetRandomInt(0, (1*lvl));
								KnifeStats2[param1][5] = GetRandomInt(0, 10);
							}
						}
					}
					NewKnifeStatsControl(param1, 0);
				}
				else
				PrintToChat(param1, "[SM] %t", "fail");
			}
			else
			PrintCenterText(param1, "%t", "money");
		}
		else if(param2 == 5 && ClientCash >= 100)
		{
			SetClientMoney(param1, ClientCash - 100);
			new r = GetRandomInt(0, 4);
			new Float:max = FloatMul(25.0,(FloatDiv(float(Playerlvl[param1]),2.0)));
			ArmorStats2[param1][0] = GetRandomInt(10, RoundFloat(max));
			switch(r)
			{
				case 0:
				{
					ArmorStats2[param1][1] = GetRandomInt(0, 7);
				}
				case 1:
				{
					ArmorStats2[param1][2] = GetRandomInt(0, 5);
				}
				case 2:
				{
					ArmorStats2[param1][3] = GetRandomInt(0, 3);
				}
				case 3:
				{
					ArmorStats2[param1][4] = GetRandomInt(0, 1);
				}
				case 4:
				{
					ArmorStats2[param1][5] = GetRandomInt(0, 10);
				}
			}
			NewArmorStatsControl(param1, 0);
		}
		else if(param2 > 5 && param2 <= 9)
		{
			new bool: canpay = false;
			switch(param2)
			{
				case 6:
				{
					if(ClientCash >= 500)
						canpay = true;
				}
				case 7:
				{
					if(ClientCash >= 1000)
						canpay = true;
				}
				case 8:
				{
					if(ClientCash >= 5000)
						canpay = true;
				}
				case 9:
				{
					if(ClientCash >= 10000)
						canpay = true;
				}
			}
			
			if(canpay)
			{
				new rand;
				new lvl = param2-4;
				new Float:max = FloatMul(25.0,(FloatDiv(float(Playerlvl[param1]),2.0)));
				ArmorStats2[param1][0] = GetRandomInt(10, RoundFloat(max));
				for(new i = 1; i <= lvl; i++)
				{
					rand = GetRandomInt(0, 3);
					switch(rand)
					{
						case 0:
						{
							ArmorStats2[param1][1] = GetRandomInt(0, (8*lvl));
						}
						case 1:
						{
							ArmorStats2[param1][2] = GetRandomInt(0, (6*lvl));
						}
						case 2:
						{
							ArmorStats2[param1][3] = GetRandomInt(0, (4*lvl));
						}
						case 3:
						{
							ArmorStats2[param1][4] = GetRandomInt(0, (1*lvl));
							ArmorStats2[param1][5] = GetRandomInt(0, 10);
						}
					}
				}
				NewArmorStatsControl(param1, 0);
			}
		}
		else
		PrintCenterText(param1, "%t", "money");
	}
	
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t", "gamblemenu");
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
}

public Action:Gamble_Control(client, args)
{
	new String: buffer[64], String: buffer2[64], String: buffer3[64], String: buffer4[64], String: buffer5[64];
	new String: buffer6[64], String: buffer7[64], String: buffer8[64], String: buffer9[64], String: buffer10[64];
	new String: buffer11[64], String: buffer12[64];
	new Handle:menu = CreateMenu(GambleMenu);
	SetMenuTitle(menu, "%t", "gamble_item");
	Format(buffer, sizeof(buffer), "%T", "knife", LANG_SERVER);
	Format(buffer2, sizeof(buffer2), "%T", "armor", LANG_SERVER);
	Format(buffer3, sizeof(buffer3), "%s $100", buffer);
	Format(buffer4, sizeof(buffer4), "%s $500", buffer);
	Format(buffer5, sizeof(buffer5), "%s $1000", buffer);
	Format(buffer6, sizeof(buffer6), "%s $5000", buffer);
	Format(buffer7, sizeof(buffer7), "%s $10000", buffer);
	Format(buffer8, sizeof(buffer8), "%s $100", buffer2);
	Format(buffer9, sizeof(buffer9), "%s $500", buffer2);
	Format(buffer10, sizeof(buffer10), "%s $1000", buffer2);
	Format(buffer11, sizeof(buffer11), "%s $5000", buffer2);
	Format(buffer12, sizeof(buffer12), "%s $10000", buffer2);
	AddMenuItem(menu, buffer3, buffer3);
	AddMenuItem(menu, buffer4, buffer4);
	AddMenuItem(menu, buffer5, buffer5);
	AddMenuItem(menu, buffer6, buffer6);
	AddMenuItem(menu, buffer7, buffer7);
	AddMenuItem(menu, buffer8, buffer8);
	AddMenuItem(menu, buffer9, buffer9);
	AddMenuItem(menu, buffer10, buffer10);
	AddMenuItem(menu, buffer11, buffer11);
	AddMenuItem(menu, buffer12, buffer12);
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public TeamChooseMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new client;
		new String: info[10];
		GetMenuItem(menu, param2, info, sizeof(info));
		client = StringToInt(info);
		
		if(IsClientInGame(client) && OMA_Teamcount > 0)
		{
			OMA_Teamcount--;
			if(OMA_Team[scoutClient][0] == -1)
				OMA_Team[scoutClient][0] = client;
			else if(OMA_Team[scoutClient][1] == -1)
				OMA_Team[scoutClient][1] = client;
			else if(OMA_Team[scoutClient][2] == -1)
				OMA_Team[scoutClient][2] = client;
			CS_SwitchTeam(client, TEAM_T);
			CS_RespawnPlayer(client);
			if(OMA_Teamcount > 0)
				TeamChoose_Control(param1, 0);
			else
			{
				FreezeTime = false;
				OMAPoints[scoutClient] = 1;
				Weapons_Control(param1, 0);
				UnFreezeAllPlayers();
				OMAmenuActive[client] = false;
			}
		}
	}
	
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			FreezeTime = false;
			UnFreezeAllPlayers();
			OMAPoints[scoutClient] = 1;
			if(OMA_Teamcount > 0)
			{
				for(new c = 1; c <= MaxClients; c++)
				{
					new bool:test = false, check = 0;
					do
					{
						c = GetRandomInt(1, MaxClients);
						if(IsClientInGame(c))
						{
							if(GetClientTeam(c) == TEAM_T && OMA_Teamcount > 0)
							{
								test = true;
								if(OMA_Team[scoutClient][0] == -1)
									OMA_Team[scoutClient][0] = c;
								else if(OMA_Team[scoutClient][1] == -1)
									OMA_Team[scoutClient][1] = c;
								else if(OMA_Team[scoutClient][2] == -1)
									OMA_Team[scoutClient][2] = c;
							}
							check++;
							if(check > 1000)
							{
								LogError("[SM] Infinite Loop at line 4216");
								break;
							}
						}
					}while(!test);
					CS_SwitchTeam(c, TEAM_T);
					CS_RespawnPlayer(c);
				}				
			}
			Weapons_Control(param1, 0);
			OMAmenuActive[param1] = false;
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:TeamChoose_Control(client, args)
{
	new String: ClientName[32], String: info[10];
	new Handle:menu = CreateMenu(TeamChooseMenu);
	SetMenuTitle(menu, "%t", "team_choose", OMA_Teamcount);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == TEAM_CT)
			{
				GetClientName(i, ClientName, sizeof(ClientName));
				IntToString(i, info, sizeof(info));
				AddMenuItem(menu, info, ClientName);
			}
		}
	}
	
	
	OMAmenuActive[client] = true;
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	return Plugin_Handled;
}

public WeaponsTimeOut(client)
{
	new random, bool: IsValidWeapon;
	new String: buffer[32];
	if(IsClientInGame(client))
	{
		IsValidWeapon = false;
		new check = 0;
		do
		{
			random = GetRandomInt(0, 27);
			switch(random)
			{
				case 3:
				{
					IsValidWeapon = false;
				}
				case 4:
				{
					IsValidWeapon = false;
				}
				case 6:
				{
					IsValidWeapon = false;
				}
				case 7:
				{
					IsValidWeapon = false;
				}
				case 10:
				{
					IsValidWeapon = false;
				}
				case 11:
				{
					IsValidWeapon = false;
				}
				case 12:
				{
					IsValidWeapon = false;
				}
				case 13:
				{
					IsValidWeapon = false;
				}
				case 18:
				{
					IsValidWeapon = false;
				}
				case 23:
				{
					IsValidWeapon = false;
				}
				case 26:
				{
					IsValidWeapon = false;
				}
				
				default:
				{
					IsValidWeapon = true;			
				}
			}
			
			if(IsValidWeapon)
			{
				new String: temp[32];
				GetClientWeapon(client, temp, sizeof(temp));
				GetWeaponByID(random, buffer, sizeof(buffer));
				if(StrEqual(temp, buffer, false))
					IsValidWeapon = false;
				else
				IsValidWeapon = true;
			}
			check++;
			if(check > 1000)
			{
				LogError("[SM] Infinite Loop at line 4357");
				break;
			}
			
		}while(!IsValidWeapon);
		
		OMACurrWeapon[client] = random;
	}
}

public WeaponsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if(GetClientTeam(param1) == TEAM_T && IsPlayerAlive(param1))
		{
			new weaponid;
			new String:classname[32];
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if(OMAPoints[param1] > 0)
			{
				PrintDebugMsg("OMA has chosen a weapon");
				OMAPoints[param1]--;
				OMACurrWeapon[param1] = GetWeaponidByName(info);
				weaponid = GetPlayerWeaponSlot(param1, 0);
				if(weaponid != -1)
				{
					GetEdictClassname(weaponid, classname, sizeof(classname));
					if(!StrEqual(classname, info, false))
					{
						RemovePlayerItem(param1, weaponid);
						if(IsValidEdict(weaponid))
							RemoveEdict(weaponid);
						GivePlayerItem(param1, info);
					}
				}
				else
				GivePlayerItem(param1, info);
			}
			
		}
		OMAmenuActive[param1] = false;
		SetEntProp(param1, Prop_Send, "m_iHideHUD", 64);
	}	
	
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			WeaponsTimeOut(param1);
			SetEntProp(param1, Prop_Send, "m_iHideHUD", 64);
			OMAmenuActive[param1] = false;
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Weapons_Control(client, args)
{
	new Handle:menu = CreateMenu(WeaponsMenu);
	SetMenuTitle(menu, "%t", "weapon_credits", OMAPoints[client]);
	new random, bool:IsValidWeapon = false;
	new String: buffer[32], String: buffer2[32];
	for(new i = 1; i <= 5; i++)
	{
		IsValidWeapon = false;
		new check = 0;
		do
		{
			random = GetRandomInt(0, 27);
			switch(random)
			{
				case 3:
				{
					IsValidWeapon = false;
				}
				case 4:
				{
					IsValidWeapon = false;
				}
				case 6:
				{
					IsValidWeapon = false;
				}
				case 7:
				{
					IsValidWeapon = false;
				}
				case 10:
				{
					IsValidWeapon = false;
				}
				case 11:
				{
					IsValidWeapon = false;
				}
				case 12:
				{
					IsValidWeapon = false;
				}
				case 13:
				{
					IsValidWeapon = false;
				}
				case 18:
				{
					IsValidWeapon = false;
				}
				case 23:
				{
					IsValidWeapon = false;
				}
				case 26:
				{
					IsValidWeapon = false;
				}
				
				default:
				{
					IsValidWeapon = true;			
				}
			}
			
			if(IsValidWeapon)
			{
				new String: temp[32];
				GetClientWeapon(client, temp, sizeof(temp));
				GetWeaponByID(random, buffer, sizeof(buffer));
				if(StrEqual(temp, buffer, false))
					IsValidWeapon = false;
				else
				IsValidWeapon = true;
			}
			
			check++;
			if(check > 1000)
			{
				LogError("[SM] Infinite Loop at line 4432");
				break;
			}
		}while(!IsValidWeapon);
		strcopy(buffer2, sizeof(buffer2), buffer);
		ReplaceString(buffer, sizeof(buffer), "weapon_", "", false);
		AddMenuItem(menu, buffer2, buffer);
	}
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
	
	OMAmenuActive[client] = true;
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	return Plugin_Handled;
}

/*
public Scout_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
if (action == MenuAction_End)
{
// This is called after VoteEnd 
CloseHandle(menu);
} 
}

public Scout_VoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
//See if there were multiple winners 
new winner = 1;
for(new i = 1; i <= num_clients; i++)
{
for(new a = 1; a <= num_clients; a++)
{
if (num_items > 1 && (item_info[i][VOTEINFO_ITEM_VOTES] == item_info[a][VOTEINFO_ITEM_VOTES]))
{
winner = GetRandomInt(1, i);
}
}
}

new String:ClientIndex[64], String:ClientName[64];
GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], ClientIndex, sizeof(ClientIndex));
if(GetNumClientsOnTeam(TEAM_T) > 0)
{
for(new i = 1; i <= MaxClients; i++)
{
if(IsClientInGame(i))
{
if(GetClientTeam(i) == TEAM_T)
{
CS_SwitchTeam(i, TEAM_CT);
CS_RespawnPlayer(i);

}
}
}
scoutClient = StringToInt(ClientIndex);
CS_SwitchTeam(scoutClient, TEAM_T);
CS_RespawnPlayer(scoutClient);
}
else
{
scoutClient = StringToInt(ClientIndex);
CS_SwitchTeam(scoutClient, TEAM_T);
CS_RespawnPlayer(scoutClient);
}
GetClientName(scoutClient, ClientName, sizeof(ClientName));
PrintToChatAll("[SM] %s has been chosen as the one man army!", ClientName);
}

public vote_scout()
{
new String:ClientName[64], String:ClientIndex[3];
if (IsVoteInProgress())
{
return;
}

new Handle:menu = CreateMenu(Scout_VoteMenu);
SetVoteResultCallback(menu, Scout_VoteResults);
SetMenuTitle(menu, "Who should be the One man army?");
for(new i = 1; i <= MaxClients; i++)
{
if(IsClientInGame(i))
{	
GetClientName(i, ClientName, sizeof(ClientName));
IntToString(i, ClientIndex, sizeof(ClientIndex));
AddMenuItem(menu, ClientIndex, ClientName);
}
}

SetMenuExitButton(menu, false);
VoteMenuToAll(menu, 20);
}
*/
public GetClientMoney(client)
{
	if (g_Account != -1)
		return GetEntData(client, g_Account);
	
	return 0;
}

public SetClientMoney(client, amount)
{
	if (g_Account != -1)
		SetEntData(client, g_Account, amount);
}

public GetWeaponAmmoOffset(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_deagle", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_ak47", false) || StrEqual(Weapon, "weapon_aug", false) || StrEqual(Weapon, "weapon_g3sg1", false) || StrEqual(Weapon, "weapon_scout", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_famas", false) || StrEqual(Weapon, "weapon_galil", false) || StrEqual(Weapon, "weapon_m4a1", false) || StrEqual(Weapon, "weapon_sg550", false) || StrEqual(Weapon, "weapon_sg552", false))
	{
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_elite", false) || StrEqual(Weapon, "weapon_glock", false) || StrEqual(Weapon, "weapon_mp5navy", false) || StrEqual(Weapon, "weapon_tmp", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false) || StrEqual(Weapon, "weapon_m3", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false) || StrEqual(Weapon, "weapon_ump45", false) || StrEqual(Weapon, "weapon_usp", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false) || StrEqual(Weapon, "weapon_p90", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade", false))
	{
		return 13;
	}
	return -1;
}

stock GetWeaponAmmo(client, slot)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return GetEntData(client, ammoOffset+(slot*4));
}  

stock SetWeaponAmmo(client, slot, ammo)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return SetEntData(client, ammoOffset+(slot*4), ammo, 4, true);
}

public SetClientHealth(client, amount)
{
	SetEntProp(client, Prop_Send, "m_iHealth", amount, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", amount, 1);
}
public SetClientArmor(client, amount)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount, 1);
}

stock GetGrenadeID(client, String: grenade[])
{
	new MyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	if(MyWeapons == -1)
		return -1;
	
	decl String:weapon[64];
	for(new i = 0, ent; i < 188; i += 4)
	{
		ent = GetEntDataEnt2(client, MyWeapons + i);
		
		if(IsValidEntity(ent))
		{
			if(IsValidEdict(ent))
			{
				GetEdictClassname(ent, weapon, sizeof(weapon));
				if(StrEqual(weapon, grenade, false))
					return ent;
			}
		}
	}
	return -1;
}

stock EntityCleanup(String: entity[], bool:HasOwner)
{
	new String: weap[32];
	new MaxEntities = GetMaxEntities();
	for(new x = MAXPLAYERS+1; x <= MaxEntities; x++)
	{
		if(IsValidEdict(x))
		{
			GetEdictClassname(x, weap, sizeof(weap));
			if(StrContains(weap, entity, false) != -1 && StrContains(weap, entity, false) < 2)
			{
				if(HasOwner)
				{
					if(GetEntPropEnt(x, Prop_Data, "m_hOwner") == -1)
					{
						if(IsValidEntity(x))
							RemoveEdict(x);
					}
				}
				else
				{
					if(IsValidEntity(x))
						RemoveEdict(x);
				}
			}
		}
	}
}

stock SpawnGoodieBox(client)
{
	new Float:pos[3], Float:numVel[3];
	numVel[0] = GetRandomFloat(-100.0, 100.0);
	numVel[1] = GetRandomFloat(-100.0, 100.0);
	numVel[2] = GetRandomFloat(1.0, 100.0);
	OMA_Goodie[client] = CreateEntityByName("prop_physics");
	SetEntityModel(OMA_Goodie[client], GOODIEBOX_MODEL);
	DispatchSpawn(OMA_Goodie[client]);
	GetClientAbsOrigin(client, pos);
	TeleportEntity(OMA_Goodie[client], pos, NULL_VECTOR, numVel);
	CreateTimer(15.0, TimedDeleteEntity, OMA_Goodie[client], TIMER_FLAG_NO_MAPCHANGE); 
}

PrintDebugMsg(String: Msg[])
{
	if(GetConVarBool(cvarplugindebug))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(!IsFakeClient(i))
				{
					PrintToConsole(i, "[SM] %s", Msg);
				}
			}
		}
	}
}

public ApplyStats(client, bool:RemoveOld, bool: armor)
{
	if(RemoveOld)
	{
		if(armor)
			PlayerSkills[client][ArmorStats[client][Skilltype_Slot]] -= ArmorStats[client][Skill_Slot];
		else
		PlayerSkills[client][KnifeStats[client][Skilltype_Slot]] -= KnifeStats[client][Skill_Slot];
	}
	else
	{
		if(armor)
			PlayerSkills[client][ArmorStats[client][Skilltype_Slot]] += ArmorStats[client][Skill_Slot];
		else
		PlayerSkills[client][KnifeStats[client][Skilltype_Slot]] += KnifeStats[client][Skill_Slot];
	}
}


/*
* ChanceRoll
* param Percentage : number between 1 and 100
* Purpose: simulates a dice roll by percentage
* returns: true if succeded or false if the roll failed
*/
public bool:ChanceRoll(Percentage)
{
	new maxvalue;
	if(Percentage <= 100)
		maxvalue = 100/Percentage;
	else
	maxvalue = 1;
	new rand = GetRandomInt(1, maxvalue);
	new rand2 = GetRandomInt(1, maxvalue);
	
	if(rand == rand2)
		return true;
	return false;
}

public KnifeStatsView(Handle:menu, MenuAction:action, param1, param2)
{	
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		
		if(GetClientTeam(param1) == TEAM_CT && IsPlayerAlive(param1))
		{
			if(param2 == 1)
			{
				if(KnifeStats2[param1][6] != 0)
					NewKnifeStatsControl(param1, 0);
			}
			
		}
	}
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t", "knife stats chat");
		}
	}
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:KnifeStatsControl(client, args)
{
	new Handle:panel = CreatePanel();
	new String: buffer[64], String: buffer2[32], String: buffer3[32], String: buffer4[32], String: buffer5[32];
	new String: buffer6[32], String: buffer7[32], String: buffer8[64];
	Format(buffer8, sizeof(buffer8), "%T", "equipped_item", LANG_SERVER);
	SetPanelTitle(panel, buffer8);
	
	Format(buffer2, sizeof(buffer2), "%T", "weapon_dmg", LANG_SERVER, KnifeStats[client][0]);
	Format(buffer3, sizeof(buffer3), "%T", "money_steal", LANG_SERVER, KnifeStats[client][1]);
	Format(buffer4, sizeof(buffer4), "%T", "money_find", LANG_SERVER, KnifeStats[client][2]);
	Format(buffer5, sizeof(buffer5), "%T", "item_find", LANG_SERVER, KnifeStats[client][3]);
	
	switch(KnifeStats[client][5])
	{
		case 0:
		Format(buffer6, sizeof(buffer6), "%T", "hplvl", LANG_SERVER, PlayerSkills[client][0]);
		case 1:
		Format(buffer6, sizeof(buffer6), "%T", "mflvl", LANG_SERVER, PlayerSkills[client][1]);
		case 2:
		Format(buffer6, sizeof(buffer6), "%T", "helvl", LANG_SERVER, PlayerSkills[client][2]);
		case 3:
		Format(buffer6, sizeof(buffer6), "%T", "sglvl", LANG_SERVER, PlayerSkills[client][3]);
		case 4:
		Format(buffer6, sizeof(buffer6), "%T", "rhplvl", LANG_SERVER, PlayerSkills[client][4]);
		case 5:
		Format(buffer6, sizeof(buffer6), "%T", "sslvl", LANG_SERVER, PlayerSkills[client][5]);
		case 6:
		Format(buffer6, sizeof(buffer6), "%T", "raplvl", LANG_SERVER, PlayerSkills[client][6]);
		case 7:
		Format(buffer6, sizeof(buffer6), "%T", "slvl", LANG_SERVER, PlayerSkills[client][7]);
		case 8:
		Format(buffer6, sizeof(buffer6), "%T", "ljlvl", LANG_SERVER, PlayerSkills[client][8]);
		case 9:
		Format(buffer6, sizeof(buffer6), "%T", "lslvl", LANG_SERVER, PlayerSkills[client][9]);
		case 10:
		Format(buffer6, sizeof(buffer6), "%T", "mslvl", LANG_SERVER, PlayerSkills[client][10]);
	}
	Format(buffer7, sizeof(buffer7), "%s: +%d", buffer6, KnifeStats[client][4]);
	
	if(KnifeStats2[client][6] != 0)
		Format(buffer, sizeof(buffer), "%T", "backtoprev", LANG_SERVER);
	else
	Format(buffer, sizeof(buffer), "%T", "closemenu", LANG_SERVER);
	
	DrawPanelItem(panel, buffer);
	
	DrawPanelText(panel, buffer2);	
	if(KnifeStats[client][1] > 0)
		DrawPanelText(panel, buffer3);
	if(KnifeStats[client][2] > 0)
		DrawPanelText(panel, buffer4);
	if(KnifeStats[client][3] > 0)
		DrawPanelText(panel, buffer5);
	if(KnifeStats[client][4] > 0)
		DrawPanelText(panel, buffer7);
	
	
	SendPanelToClient(panel, client, KnifeStatsView, 20);
	
	CloseHandle(panel);
	
	
	return Plugin_Handled;
}

public NewKnifeStatsView(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		
		if(GetClientTeam(param1) == TEAM_CT)
		{
			if(param2 == 1)
			{
				ApplyStats(param1, true, false);
				KnifeStats[param1][0] = KnifeStats2[param1][0];
				KnifeStats[param1][1] = KnifeStats2[param1][1];
				KnifeStats[param1][2] = KnifeStats2[param1][2];
				KnifeStats[param1][3] = KnifeStats2[param1][3];
				KnifeStats[param1][4] = KnifeStats2[param1][4];
				KnifeStats[param1][5] = KnifeStats2[param1][5];
				KnifeStats[param1][6] = 1;
				ApplyStats(param1, false, false);
				PrintToChat(param1, "[SM] %t", "equipped item");
				KnifeStats2[param1][0] = 0;
				KnifeStats2[param1][1] = 0;
				KnifeStats2[param1][2] = 0;
				KnifeStats2[param1][3] = 0;
				KnifeStats2[param1][4] = 0;
				KnifeStats2[param1][5] = 0;
				KnifeStats2[param1][6] = 0;
			}
			else if(param2 == 3)
			{
				KnifeStatsControl(param1, 0);
			}
			else
			{
				KnifeStats2[param1][0] = 0;
				KnifeStats2[param1][1] = 0;
				KnifeStats2[param1][2] = 0;
				KnifeStats2[param1][3] = 0;
				KnifeStats2[param1][4] = 0;
				KnifeStats2[param1][5] = 0;
				KnifeStats2[param1][6] = 0;
			}
		}
	}
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			NewKnifeStatsControl(param1, 0);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:NewKnifeStatsControl(client, args)
{
	new Handle:panel = CreatePanel();
	
	new String: buffer[64], String: buffer2[32], String: buffer3[32], String: buffer4[32], String: buffer5[32];
	new  String: buffer6[32], String: buffer7[32], String: buffer8[32], String: buffer9[32], String: buffer10[32];
	Format(buffer, sizeof(buffer), "%T", "equip item", LANG_SERVER);
	SetPanelTitle(panel, buffer);
	
	Format(buffer2, sizeof(buffer2), "%T", "equipthis", LANG_SERVER);
	Format(buffer3, sizeof(buffer3), "%T", "No", LANG_SERVER);
	Format(buffer4, sizeof(buffer4), "%T", "view equipped", LANG_SERVER);
	Format(buffer5, sizeof(buffer5), "%T", "weapon_dmg", LANG_SERVER, KnifeStats2[client][0]);
	Format(buffer6, sizeof(buffer6), "%T", "money_steal", LANG_SERVER, KnifeStats2[client][1]);
	Format(buffer7, sizeof(buffer7), "%T", "money_find", LANG_SERVER, KnifeStats2[client][2]);
	Format(buffer8, sizeof(buffer8), "%T", "item_find", LANG_SERVER, KnifeStats2[client][3]);
	
	switch(KnifeStats[client][5])
	{
		case 0:
		Format(buffer9, sizeof(buffer9), "%T", "hplvl", LANG_SERVER, PlayerSkills[client][0]);
		case 1:
		Format(buffer9, sizeof(buffer9), "%T", "mflvl", LANG_SERVER, PlayerSkills[client][1]);
		case 2:
		Format(buffer9, sizeof(buffer9), "%T", "helvl", LANG_SERVER, PlayerSkills[client][2]);
		case 3:
		Format(buffer9, sizeof(buffer9), "%T", "sglvl", LANG_SERVER, PlayerSkills[client][3]);
		case 4:
		Format(buffer9, sizeof(buffer9), "%T", "rhplvl", LANG_SERVER, PlayerSkills[client][4]);
		case 5:
		Format(buffer9, sizeof(buffer9), "%T", "sslvl", LANG_SERVER, PlayerSkills[client][5]);
		case 6:
		Format(buffer9, sizeof(buffer9), "%T", "raplvl", LANG_SERVER, PlayerSkills[client][6]);
		case 7:
		Format(buffer9, sizeof(buffer9), "%T", "slvl", LANG_SERVER, PlayerSkills[client][7]);
		case 8:
		Format(buffer9, sizeof(buffer9), "%T", "ljlvl", LANG_SERVER, PlayerSkills[client][8]);
		case 9:
		Format(buffer9, sizeof(buffer9), "%T", "lslvl", LANG_SERVER, PlayerSkills[client][9]);
		case 10:
		Format(buffer9, sizeof(buffer9), "%T", "mslvl", LANG_SERVER, PlayerSkills[client][10]);
	}
	Format(buffer10, sizeof(buffer10), "%s: +%d", buffer9, KnifeStats[client][4]);
	
	DrawPanelItem(panel, buffer2);
	DrawPanelItem(panel, buffer3);
	DrawPanelItem(panel, buffer4);
	PrintHintText(client, "%t", "equipping");
	
	DrawPanelText(panel, buffer5);
	if(KnifeStats[client][1] > 0)
		DrawPanelText(panel, buffer6);
	if(KnifeStats[client][2] > 0)
		DrawPanelText(panel, buffer7);
	if(KnifeStats[client][3] > 0)
		DrawPanelText(panel, buffer8);
	if(KnifeStats[client][4] > 0)
		DrawPanelText(panel, buffer10);
	
	
	
	SendPanelToClient(panel, client, NewKnifeStatsView, 15);
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}

public NewArmorStatsView(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		
		if(GetClientTeam(param1) == TEAM_CT && IsPlayerAlive(param1))
		{
			if(param2 == 1)
			{
				ApplyStats(param1, true, true);
				ArmorStats[param1][0] = ArmorStats2[param1][0];
				ArmorStats[param1][1] = ArmorStats2[param1][1];
				ArmorStats[param1][2] = ArmorStats2[param1][2];
				ArmorStats[param1][3] = ArmorStats2[param1][3];
				ArmorStats[param1][4] = ArmorStats2[param1][4];
				ArmorStats[param1][5] = ArmorStats2[param1][5];
				ApplyStats(param1, false, true);
				SetClientArmor(param1, ArmorStats[param1][0]);
				PrintToChat(param1, "[SM] %t", "equipped item");
				ArmorStats2[param1][0] = 0;
				ArmorStats2[param1][1] = 0;
				ArmorStats2[param1][2] = 0;
				ArmorStats2[param1][3] = 0;
				ArmorStats2[param1][4] = 0;
				ArmorStats2[param1][5] = 0;
				
			}
			else if(param2 == 3)
				ArmorStatsControl(param1, 0);
			else
			{
				ArmorStats2[param1][0] = 0;
				ArmorStats2[param1][1] = 0;
				ArmorStats2[param1][2] = 0;
				ArmorStats2[param1][3] = 0;
				ArmorStats2[param1][4] = 1;
				ArmorStats2[param1][5] = 0;
			}
		}
		else if(GetClientTeam(param1) == TEAM_CT)
		{
			if(param2 == 1)
			{
				ApplyStats(param1, true, true);
				ArmorStats[param1][0] = ArmorStats2[param1][0];
				ArmorStats[param1][1] = ArmorStats2[param1][1];
				ArmorStats[param1][2] = ArmorStats2[param1][2];
				ArmorStats[param1][3] = ArmorStats2[param1][3];
				ArmorStats[param1][4] = ArmorStats2[param1][4];
				ArmorStats[param1][5] = ArmorStats2[param1][5];
				ApplyStats(param1, false, true);
				PrintToChat(param1, "[SM] %t", "equipped item");
				ArmorStats2[param1][0] = 0;
				ArmorStats2[param1][1] = 0;
				ArmorStats2[param1][2] = 0;
				ArmorStats2[param1][3] = 0;
				ArmorStats2[param1][4] = 0;
				ArmorStats2[param1][5] = 0;
			}
			else if(param2 == 3)
				ArmorStatsControl(param1, 0);
			else
			{
				ArmorStats2[param1][0] = 0;
				ArmorStats2[param1][1] = 0;
				ArmorStats2[param1][2] = 0;
				ArmorStats2[param1][3] = 0;
				ArmorStats2[param1][4] = 0;
				ArmorStats2[param1][5] = 0;
			}
		}
		
	}
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			NewArmorStatsControl(param1, 0);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:NewArmorStatsControl(client, args)
{
	new Handle:panel = CreatePanel();
	new String: buffer[64], String: buffer2[32], String: buffer3[32], String: buffer4[32], String: buffer5[32];
	new String: buffer6[32], String: buffer7[32], String: buffer8[32], String: buffer9[32], String: buffer10[32];
	
	Format(buffer, sizeof(buffer), "%T", "equip item", LANG_SERVER);
	SetPanelTitle(panel, buffer);
	
	Format(buffer2, sizeof(buffer2), "%T", "equipthis", LANG_SERVER);
	Format(buffer3, sizeof(buffer3), "%T", "No", LANG_SERVER);
	Format(buffer4, sizeof(buffer4), "%T", "view equipped", LANG_SERVER);
	Format(buffer5, sizeof(buffer5), "%T", "armor_def", LANG_SERVER, ArmorStats2[client][0]);
	Format(buffer6, sizeof(buffer6), "%T", "money_steal", LANG_SERVER, ArmorStats2[client][1]);
	Format(buffer7, sizeof(buffer7), "%T", "money_find", LANG_SERVER, ArmorStats2[client][2]);
	Format(buffer8, sizeof(buffer8), "%T", "item_find", LANG_SERVER, ArmorStats2[client][3]);
	switch(ArmorStats[client][5])
	{
		case 0:
		Format(buffer9, sizeof(buffer9), "%T", "hplvl", LANG_SERVER, PlayerSkills[client][0]);
		case 1:
		Format(buffer9, sizeof(buffer9), "%T", "mflvl", LANG_SERVER, PlayerSkills[client][1]);
		case 2:
		Format(buffer9, sizeof(buffer9), "%T", "helvl", LANG_SERVER, PlayerSkills[client][2]);
		case 3:
		Format(buffer9, sizeof(buffer9), "%T", "sglvl", LANG_SERVER, PlayerSkills[client][3]);
		case 4:
		Format(buffer9, sizeof(buffer9), "%T", "rhplvl", LANG_SERVER, PlayerSkills[client][4]);
		case 5:
		Format(buffer9, sizeof(buffer9), "%T", "sslvl", LANG_SERVER, PlayerSkills[client][5]);
		case 6:
		Format(buffer9, sizeof(buffer9), "%T", "raplvl", LANG_SERVER, PlayerSkills[client][6]);
		case 7:
		Format(buffer9, sizeof(buffer9), "%T", "slvl", LANG_SERVER, PlayerSkills[client][7]);
		case 8:
		Format(buffer9, sizeof(buffer9), "%T", "ljlvl", LANG_SERVER, PlayerSkills[client][8]);
		case 9:
		Format(buffer9, sizeof(buffer9), "%T", "lslvl", LANG_SERVER, PlayerSkills[client][9]);
		case 10:
		Format(buffer9, sizeof(buffer9), "%T", "mslvl", LANG_SERVER, PlayerSkills[client][10]);
	}
	Format(buffer10, sizeof(buffer10), "%s: +%d", buffer9, ArmorStats2[client][4]);
	
	DrawPanelItem(panel, buffer2);
	DrawPanelItem(panel, buffer3);
	DrawPanelItem(panel, buffer4);
	PrintHintText(client, "%t", "equipping");
	
	
	DrawPanelText(panel, buffer5);
	if(ArmorStats[client][1] > 0)
		DrawPanelText(panel, buffer6);
	if(ArmorStats[client][2] > 0)
		DrawPanelText(panel, buffer7);
	if(ArmorStats[client][3] > 0)
		DrawPanelText(panel, buffer8);
	if(ArmorStats[client][4] > 0)
		DrawPanelText(panel, buffer10);
	
	
	
	
	
	SendPanelToClient(panel, client, NewArmorStatsView, 15);
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}

public ArmorStatsView(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		
		if(GetClientTeam(param1) == TEAM_CT && IsPlayerAlive(param1))
		{
			if(param2 == 1)
			{
				if(ArmorStats2[param1][5] != 0)
					NewArmorStatsControl(param1, 0);
			}
			
		}
	}
	if(action == MenuAction_Cancel)
	{		
		if(param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t", "armor stats chat");
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:ArmorStatsControl(client, args)
{
	new Handle:panel = CreatePanel();
	new String: buffer[64], String: buffer2[32], String: buffer3[32], String: buffer4[32], String: buffer5[32];
	new String: buffer6[32], String: buffer7[32], String: buffer8[32];
	
	Format(buffer, sizeof(buffer), "%T", "equipped_item", LANG_SERVER);
	SetPanelTitle(panel, buffer);
	
	Format(buffer4, sizeof(buffer4), "%T", "money_steal", LANG_SERVER, ArmorStats2[client][1]);
	Format(buffer5, sizeof(buffer5), "%T", "money_find", LANG_SERVER, ArmorStats2[client][2]);
	Format(buffer6, sizeof(buffer6), "%T", "item_find", LANG_SERVER, ArmorStats2[client][3]);
	switch(ArmorStats[client][5])
	{
		case 0:
		Format(buffer7, sizeof(buffer7), "%T", "hplvl", LANG_SERVER, PlayerSkills[client][0]);
		case 1:
		Format(buffer7, sizeof(buffer7), "%T", "mflvl", LANG_SERVER, PlayerSkills[client][1]);
		case 2:
		Format(buffer7, sizeof(buffer7), "%T", "helvl", LANG_SERVER, PlayerSkills[client][2]);
		case 3:
		Format(buffer7, sizeof(buffer7), "%T", "sglvl", LANG_SERVER, PlayerSkills[client][3]);
		case 4:
		Format(buffer7, sizeof(buffer7), "%T", "rhplvl", LANG_SERVER, PlayerSkills[client][4]);
		case 5:
		Format(buffer7, sizeof(buffer7), "%T", "sslvl", LANG_SERVER, PlayerSkills[client][5]);
		case 6:
		Format(buffer7, sizeof(buffer7), "%T", "raplvl", LANG_SERVER, PlayerSkills[client][6]);
		case 7:
		Format(buffer7, sizeof(buffer7), "%T", "slvl", LANG_SERVER, PlayerSkills[client][7]);
		case 8:
		Format(buffer7, sizeof(buffer7), "%T", "ljlvl", LANG_SERVER, PlayerSkills[client][8]);
		case 9:
		Format(buffer7, sizeof(buffer7), "%T", "lslvl", LANG_SERVER, PlayerSkills[client][9]);
		case 10:
		Format(buffer7, sizeof(buffer7), "%T", "mslvl", LANG_SERVER, PlayerSkills[client][10]);
	}
	Format(buffer8, sizeof(buffer8), "%s: +%d", buffer7, ArmorStats2[client][4]);
	
	if(ArmorStats2[client][0] != 0)
		Format(buffer2, sizeof(buffer2), "%T", "backtoprev", LANG_SERVER);
	else
	Format(buffer2, sizeof(buffer2), "%T", "closemenu", LANG_SERVER);
	DrawPanelItem(panel, buffer2);
	
	Format(buffer3, sizeof(buffer3), "%T", "armor_def", LANG_SERVER, ArmorStats2[client][0]);
	DrawPanelText(panel, buffer3);
	if(ArmorStats[client][1] > 0)
		DrawPanelText(panel, buffer4);
	if(ArmorStats[client][2] > 0)
		DrawPanelText(panel, buffer5);
	if(ArmorStats[client][3] > 0)
		DrawPanelText(panel, buffer6);
	if(ArmorStats[client][4] > 0)
		DrawPanelText(panel, buffer8);
	
	SendPanelToClient(panel, client, ArmorStatsView, 15);
	
	CloseHandle(panel);
	
	
	return Plugin_Handled;
}

public Equip_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new ClientTeam = GetClientTeam(param1);
		new ClientCash = GetClientMoney(param1);
		new xpcost = XPlost[param1]*2;
		new repaircost = RepairArmor(param1);
		new hashelmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");
		new armor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
		new kevprice;
		
		if(Playerlvl[param1] == 1)
			kevprice = kevlar_ct;
		else
		kevprice = kevlar_ct*(Playerlvl[param1]/2);
		
		if(ClientTeam == TEAM_T)
		{
			if(param2 == 0 && ClientCash >= kevlar && kevlar != -1)
			{
				if(GetEntData(param1, armor) < 100)
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", 100, 1);
					SetClientMoney(param1, ClientCash - kevlar);
				}
				else
				PrintCenterText(param1, "%t", "has armor");
			}
			else if(param2 == 1 && ClientCash >= helmet && helmet != -1)
			{
				
				if(GetEntData(param1, hashelmet) == 0)
				{
					SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
					SetClientMoney(param1, ClientCash - helmet);
				}
				else
				PrintCenterText(param1, "%t", "has helmet");
				
			}
		}
		else if(ClientTeam == TEAM_CT)
		{
			if(param2 == 0 && ClientCash >= kevprice && kevlar_ct != -1)
			{
				if(GetEntData(param1, armor) < (10*Playerlvl[param1]))
				{
					SetEntProp(param1, Prop_Send, "m_ArmorValue", (10*Playerlvl[param1]), 1);
					SetClientMoney(param1, ClientCash - kevprice);
					ArmorStats[param1][0] = 10*Playerlvl[param1];
					ArmorStats[param1][1] = 0;
					ArmorStats[param1][2] = 0;
					ArmorStats[param1][3] = 0;
					ArmorStats[param1][4] = 0;
					ArmorStats[param1][5] = 0;
				}
				else
				PrintCenterText(param1, "%t", "has armor");
			}
		}
		
		if(param2 == 0)
		{
		}
		else if(param2 == 1 && ClientCash >= helmet && helmet != -1)
		{
			
			if(GetEntData(param1, hashelmet) == 0)
			{
				SetEntProp(param1, Prop_Send, "m_bHasHelmet", 1, 1);
				SetClientMoney(param1, ClientCash - helmet);
			}
			else
			PrintCenterText(param1, "%t", "has helmet");
			
		}
		else if(param2 == 2 && ClientCash >= hegrenade && hegrenade != -1)
		{
			GivePlayerItem(param1, "weapon_hegrenade");
			SetClientMoney(param1, ClientCash - hegrenade);
		}
		else if(param2 == 3 && ClientCash >= smokegrenade && smokegrenade != -1)
		{
			GivePlayerItem(param1, "weapon_smokegrenade");
			SetClientMoney(param1, ClientCash - smokegrenade);
		}
		else if(param2 == 4 && ClientCash >= nvgoggles && nvgoggles != -1)
		{
			SetEntProp(param1, Prop_Send, "m_bHasNightVision", 1, 1);
			SetClientMoney(param1, ClientCash - 1250);
		}
		else if(param2 == 5 && ClientCash >= repaircost && repaircost != 0)
		{
			if(ArmorStats[param1][0] != 0)
			{
				SetEntProp(param1, Prop_Send, "m_ArmorValue", ArmorStats[param1][0], 1);
				SetClientMoney(param1, ClientCash - repaircost);
				PrintToChat(param1, "[SM] %t", "armor repaired");
			}
		}
		else if(param2 == 6 && ClientCash >= xpcost && xpcost != 0)
		{
			PlayerXP[param1] += XPlost[param1];
			PrintToChat(param1, "[SM] %t", "regained xp", XPlost[param1]);
			XPlost[param1] = 0;
			SetClientMoney(param1, ClientCash - xpcost);
			PrintHintText(param1, "%t", "currxp", PlayerXP[param1], XPlvl[Playerlvl[param1]]);
		}
		else if(param2 == 6 && xpcost == 0)
		{
			PrintCenterText(param1, "%t", "no xp lost");
		}
		else
		PrintCenterText(param1, "%t", "money");
		
		Buy_Equipment_Control(param1, 0);	
	}
	
	
	
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_Exit || param2 == MenuCancel_Timeout)
		{
			PrintToChat(param1, "[SM] %t",  "equipmenu_chat");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}



public Buy_Equipment_Control(client, args)
{
	new String:buffer[32], String:buffer2[32], String:buffer3[32], String:buffer4[32], String:buffer5[32],
	String:buffer6[32], String:buffer7[32], String:buffer8[32], String:buffer9[32];
	new ClientTeam = GetClientTeam(client);
	new xpcost = XPlost[client]*2;
	new Handle:menu = CreateMenu(Equip_Menu);
	Format(buffer, sizeof(buffer), "%T", "equip_menu", LANG_SERVER);
	Format(buffer9, sizeof(buffer9), "%T", "restrict", LANG_SERVER);
	new kevprice;
	
	if(xpcost > 16000)
	{
		XPlost[client] = 8000;
		xpcost = XPlost[client]*2;
	}
	if(Playerlvl[client] == 1)
		kevprice = kevlar_ct;
	else
	kevprice = kevlar_ct*(Playerlvl[client]/2);
	
	if(kevlar != -1)
	{
		if(ClientTeam == TEAM_T)
			Format(buffer2, sizeof(buffer2), "%T", "kevlar", LANG_SERVER, kevlar);
		else if(ClientTeam == TEAM_CT)
			Format(buffer2, sizeof(buffer2), "%T", "kevlar", LANG_SERVER, kevprice);
	}
	else
	Format(buffer2, sizeof(buffer2), "%T", "kevlar r", LANG_SERVER, buffer9);
	if(helmet != -1)
		Format(buffer3, sizeof(buffer3), "%T", "helmet", LANG_SERVER, helmet);
	else
	Format(buffer3, sizeof(buffer3), "%T", "helmet r", LANG_SERVER, buffer9);
	if(hegrenade != -1)
		Format(buffer4, sizeof(buffer4), "%T", "hegrenade", LANG_SERVER, hegrenade);
	else
	Format(buffer4, sizeof(buffer4), "%T", "hegrenade r", LANG_SERVER, buffer9);
	if(smokegrenade != -1)
		Format(buffer5, sizeof(buffer5), "%T", "smokegrenade", LANG_SERVER, smokegrenade);
	else
	Format(buffer5, sizeof(buffer5), "%T", "smokegrenade r", LANG_SERVER, buffer9);
	if(nvgoggles != -1)
		Format(buffer6, sizeof(buffer6), "%T", "nightvision goggles", LANG_SERVER, nvgoggles);
	else
	Format(buffer6, sizeof(buffer6), "%T", "nightvision goggles r", LANG_SERVER, buffer9);
	
	Format(buffer7, sizeof(buffer7), "%T", "repair armor", LANG_SERVER, RepairArmor(client));
	Format(buffer8, sizeof(buffer8), "%T", "buyback xp", LANG_SERVER, xpcost);
	
	
	SetMenuTitle(menu, buffer);
	
	AddMenuItem(menu, buffer2, buffer2);
	AddMenuItem(menu, buffer3, buffer3);
	AddMenuItem(menu, buffer4, buffer4);
	AddMenuItem(menu, buffer5, buffer5);
	AddMenuItem(menu, buffer6, buffer6);
	
	if(ClientTeam == TEAM_CT)
	{
		AddMenuItem(menu, buffer7, buffer7);
		AddMenuItem(menu, buffer8, buffer8);
	}
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
}

RepairArmor(client)
{
	new armor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	new armorneeded = ArmorStats[client][0] - GetEntData(client, armor);
	if(armorneeded > 0)
	{
		new cost = armorneeded * 5;
		return cost;
	}
	return 0;
}

public Action:WeaponCanUse(client, weapon)
{
	new team = GetClientTeam(client);
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (team == TEAM_CT)
	{
		if(!(StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_hegrenade", false) || StrEqual(sWeapon, "weapon_smokegrenade", false)))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}


/* 
* Part of the code written below was originally written by Greyscale
* Modified by InstantDeath
*/
public Action:Entity_Touch(entity1, entity2)
{
	new client, entity;
	if(entity1 > 0 && entity1 <= 64)
	{
		client = entity1;
		entity = entity2;
		//PrintToChatAll("entity 1: %d", client);
		//PrintToChatAll("entity 2: %d", entity);
	}
	else
	{
		client = entity2;
		entity = entity1;
		//PrintToChatAll("-entity 1: %d", client);
		//PrintToChatAll("-entity 2: %d", entity);
	}
	
	if(IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		new bool: omaenable = GetConVarBool(cvarpluginstatus);
		if(omaenable)
		{
			if (IsValidEntity(entity))
			{
				decl String:classname[32];
				GetEdictClassname(entity, classname, sizeof(classname));
				
				if(team == TEAM_CT)
				{
					if(StrEqual(classname, "weapon_hegrenade", false))
					{
						new count = GetClientGrenades(client, Slot_HEgrenade);
						
						if (count < PlayerSkills[client][2])
						{	
							PickupGrenade(client, entity);
						}
					}
					
					else if(StrEqual(classname, "weapon_smokegrenade", false))
					{
						new count = GetClientGrenades(client, Slot_Smokegrenade);
						
						if (count < PlayerSkills[client][3])
						{	
							PickupGrenade(client, entity);
						}
					}
					
					else if(StrEqual(classname, "prop_physics", false) || StrEqual(classname, "prop_physics_multiplayer", false) || StrEqual(classname, "func_physbox", false))
					{
						new bool: doesexist = false, bool: listfull = true;
						
						for(new c = 0; c < 60; c++)
						{
							if(EntityList[c] == entity)
							{
								doesexist = true;
								break;
							}
							
							if(EntityList[c] == 0)
								listfull = false;
							
							
						}
						
						if(!doesexist && !listfull)
						{
							for(new t = 59; t >= 0; t--)
							{
								if(EntityList[t] == 0)
								{
									EntityList[t] = entity;
									break;
								}
							}
							new bool:weaponroll, bool: armorroll, bool: moneyroll;
							
							weaponroll = ChanceRoll((25+KnifeStats[client][ItemFind_Slot]+ArmorStats[client][ItemFind_Slot]));
							armorroll = ChanceRoll((25+KnifeStats[client][ItemFind_Slot]+ArmorStats[client][ItemFind_Slot]));
							moneyroll = ChanceRoll((25+(PlayerSkills[client][1]*5)+KnifeStats[client][MoneyFind_Slot]+ArmorStats[client][MoneyFind_Slot]));
							
							
							if(weaponroll)
							{
								new lvl;
								if(Playerlvl[client] < 3)
								{
									new r = GetRandomInt(0, 4);
									switch(r)
									{
										case 0:
										{
											KnifeStats2[client][0] = GetRandomInt(0, 5);
										}
										case 1:
										{
											KnifeStats2[client][1] = GetRandomInt(0, 7);
										}
										case 2:
										{
											KnifeStats2[client][2] = GetRandomInt(0, 5);
										}
										case 3:
										{
											KnifeStats2[client][3] = GetRandomInt(0, 3);
										}
										case 4:
										{
											KnifeStats2[client][4] = GetRandomInt(0, 1);
											KnifeStats2[client][5] = GetRandomInt(0, 10);
										}
									}
								}
								else if(Playerlvl[client] < 5)
									lvl = 2;
								else if(Playerlvl[client] < 7)
									lvl = 3;
								else if(Playerlvl[client] < 9)
									lvl = 4;
								else if(Playerlvl[client] >= 9)
									lvl = 5;
								
								if(Playerlvl[client] >= 3)
								{
									new rand;
									for(new i = 1; i <= lvl; i++)
									{
										rand = GetRandomInt(0, 4);
										switch(rand)
										{
											case 0:
											{
												KnifeStats2[client][0] = GetRandomInt(0, (6*lvl));
											}
											case 1:
											{
												KnifeStats2[client][1] = GetRandomInt(0, (8*lvl));
											}
											case 2:
											{
												KnifeStats2[client][2] = GetRandomInt(0, (6*lvl));
											}
											case 3:
											{
												KnifeStats2[client][3] = GetRandomInt(0, (4*lvl));
											}
											case 4:
											{
												KnifeStats2[client][4] = GetRandomInt(0, (1*lvl));
												KnifeStats2[client][5] = GetRandomInt(0, 10);
											}
										}
									}		
								}
								KnifeStats2[client][6] = 1;
								NewKnifeStatsControl(client, 0);
							}
							else if(armorroll)
							{
								new lvl;
								if(Playerlvl[client] < 3)
								{
									new r = GetRandomInt(1, 4);
									new Float:max = FloatMul(25.0,(FloatDiv(float(Playerlvl[client]),2.0)));
									ArmorStats2[client][0] = GetRandomInt(10, RoundFloat(max));
									switch(r)
									{
										case 1:
										{
											ArmorStats2[client][1] = GetRandomInt(0, 7);
										}
										case 2:
										{
											ArmorStats2[client][2] = GetRandomInt(0, 5);
										}
										case 3:
										{
											ArmorStats2[client][3] = GetRandomInt(0, 3);
										}
										case 4:
										{
											ArmorStats2[client][4] = GetRandomInt(0, 1);
											ArmorStats2[client][5] = GetRandomInt(0, 10);
										}
									}
								}
								else if(Playerlvl[client] < 5)
									lvl = 2;
								else if(Playerlvl[client] < 7)
									lvl = 3;
								else if(Playerlvl[client] < 9)
									lvl = 4;
								else if(Playerlvl[client] >= 9)
									lvl = 5;
								
								if(Playerlvl[client] >= 3)
								{
									new rand;
									new Float:max = FloatMul(25.0,(FloatDiv(float(Playerlvl[client]),2.0)));
									ArmorStats2[client][0] = GetRandomInt(10, RoundFloat(max));
									for(new i = 1; i <= lvl; i++)
									{
										rand = GetRandomInt(1, 4);
										switch(rand)
										{
											case 1:
											{
												ArmorStats2[client][1] = GetRandomInt(0, (8*lvl));
											}
											case 2:
											{
												ArmorStats2[client][2] = GetRandomInt(0, (6*lvl));
											}
											case 3:
											{
												ArmorStats2[client][3] = GetRandomInt(0, (4*lvl));
											}
											case 4:
											{
												ArmorStats2[client][4] = GetRandomInt(0, (1*lvl));
												ArmorStats2[client][5] = GetRandomInt(0, 10);
											}
										}
									}		
								}
								NewArmorStatsControl(client, 0);
							}
							if(moneyroll)
							{
								new cashwon, ClientCash = GetClientMoney(client);
								new bool: bcashchance = ChanceRoll(5);
								new String:ClientName[64];
								GetClientName(client, ClientName, sizeof(ClientName));
								
								if(bcashchance)
								{
									cashwon = GetRandomInt(1000, 5000);
									SetClientMoney(client, ClientCash+cashwon);
									PrintToChatAll("[SM] %t", "found money large", ClientName, cashwon);
								}
								else
								{
									cashwon = GetRandomInt(1, 1000);
									SetClientMoney(client, ClientCash+cashwon);
									PrintToChat(client, "[SM] %t", "found money", cashwon);
								}
							}
							
							if(!(weaponroll && armorroll && moneyroll))
								PrintToChat(client, "[SM] %t", "found nothing");
							
							CheckedEntity[client] = entity;
						}
						else if(CheckedEntity[client] != entity)
						{	
							PrintToChat(client, "[SM] %t", "found nothing");
							CheckedEntity[client] = entity;
						}
					}
				}
				else if(team == TEAM_T)
				{
					if(StrEqual(classname, "prop_physics", false))
					{
						
						new bool: foundent = false, c;
						for(c = 1; c < MaxClients; c++)
						{
							if(OMA_Goodie[c] == entity)
							{
								PrintDebugMsg("OMA touched Goodie box");
								foundent = true;
								if(IsValidEdict(entity))
								{	
									RemoveEdict(entity);
									OMA_Goodie[c] = -1;
								}
								break;
							}
						}
						if(foundent)
						{
							new bool:lvl2keyroll, random = GetRandomInt(1, 4);
							new cashwon, ClientCash = GetClientMoney(client);
							new Float:pos[3];
							
							GetClientAbsOrigin(client, pos);
							lvl2keyroll = ChanceRoll(OMA_lvl[client]);
							
							switch(random)
							{
								case 1:
								{
									if(lvl2keyroll && !OMAlvl2[client])
									{
										EnableLevel2(client);
									}
									else
									{
										cashwon = GetRandomInt(1, 50);
										SetClientMoney(client, ClientCash+cashwon);
										PrintToChat(client, "[SM] %t", "found money", cashwon);
									}
								}
								
								case 2:
								{
									new randitem = GetRandomInt(1, 3);
									switch(randitem)
									{
										case 1:
										{
											
											if(ChanceRoll(40)) //full medkit
											{	
												SetClientHealth(client, OMA_StartHealth);
											}
											else
											{
												new ClientHealth = GetClientHealth(client);
												if(ChanceRoll(33))
												{
													if(ClientHealth + 40 <= OMA_StartHealth)
														SetClientHealth(client, ClientHealth + 40);
													else
													SetClientHealth(client, OMA_StartHealth);
												}
												else if(ChanceRoll(33))
												{
													if(ClientHealth + 60 <= OMA_StartHealth)
														SetClientHealth(client, ClientHealth + 60);
													else
													SetClientHealth(client, OMA_StartHealth);
												}
												else
												{
													if(ClientHealth + 20 <= OMA_StartHealth)
														SetClientHealth(client, ClientHealth + 20);
													else
													SetClientHealth(client, OMA_StartHealth);
												}
											}
											EmitSoundToAll(HEALTHKIT_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
										}
										case 2:
										{
											new ClientArmor = GetClientArmor(client);
											
											if(ClientArmor < 100)
											{
												SetClientArmor(client, 100);
												EmitSoundToAll(ITEMPICKUP_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
											}
										}
										case 3:
										{
											new ClientArmor = GetClientArmor(client);
											
											if(ClientArmor + 25 <= 125)
											{
												SetClientArmor(client, 125);
											}
											else
											SetClientArmor(client, 125);
											
											EmitSoundToAll(ITEMPICKUP_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
										}
									}
								}
								case 3:
								{
									cashwon = GetRandomInt(1, 5000);
									SetClientMoney(client, ClientCash+cashwon);
									PrintToChat(client, "[SM] %t", "found money", cashwon);
								}
								
								case 4:
								{
									new ent = CreateEntityByName("env_explosion");
									new Float:vec[3];
									DispatchKeyValue(ent, "iMagnitude", "100");
									DispatchKeyValue(ent, "fireballsprite", EXPLODE_SPR);
									DispatchKeyValue(ent, "rendermode", "5");
									DispatchSpawn(ent);
									GetClientAbsOrigin(client, vec);
									TeleportEntity(ent, vec, NULL_VECTOR, NULL_VECTOR);
									AcceptEntityInput(ent, "Explode");
								}
							}
							PrintDebugMsg("OMA successfuly recieved Goodie box");
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/*
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
if(attacker > 0 && attacker <= 64)
{
if(IsClientInGame(attacker))
{
if(GetClientTeam(attacker) == TEAM_CT)
{
damage += float(KnifeStats[attacker][0]);
if(GetConVarBool(cvardmgdetermines))
{
OMAdmgTimer[attacker] = 3;
OMAdmgTotal[attacker]+= damage;
if(!OMAdmgTimerActive[attacker])
	CreateTimer(1.0, DmgReset, attacker,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
return Plugin_Changed;
}
}
}

return Plugin_Continue;
}

public Action:SetTransmit(entity, client)
{
new String: clname[32];

if(IsValidEdict(entity))
	GetEdictClassname(entity, clname, sizeof(clname));
if(StrContains(clname, "grenade", false) == -1)
	return Plugin_Continue;

if(entity > 0 && entity <= 64)
{
if(IsClientInGame(entity))
{
new Owner = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
if(Owner != client && Owner != -1)
{
if(CloakGrenade[Owner])
	return Plugin_Handled;
}
}
}
return Plugin_Continue;
}
*/
PickupGrenade(client, entity)
{
	new Handle:event = CreateEvent("item_pickup");
	decl String:classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (event != INVALID_HANDLE)
	{
		if(StrEqual(classname, "weapon_hegrenade", false))
		{
			SetEventInt(event, "userid", GetClientUserId(client));
			
			SetEventString(event, "item", "hegrenade");
			FireEvent(event);
		}
		
		else if(StrEqual(classname, "weapon_smokegrenade", false))
		{
			SetEventInt(event, "userid", GetClientUserId(client));
			
			SetEventString(event, "item", "smokegrenade");
			FireEvent(event);
		}
	}
	
	RemoveEdict(entity);
	
	if(StrEqual(classname, "weapon_hegrenade", false))
		GiveClientGrenade(client, Slot_HEgrenade);
	else if(StrEqual(classname, "weapon_smokegrenade", false))
		GiveClientGrenade(client, Slot_Smokegrenade);
	
	EmitSoundToClient(client, ITEMPICKUP_SOUND);
}

GetClientGrenades(client, AmmoOffs)
{
	new offsNades = FindDataMapInfo(client, "m_iAmmo") + (AmmoOffs * 4);
	
	return GetEntData(client, offsNades);
}	

GiveClientGrenade(client, AmmoOffset)
{
	new offsNades = FindDataMapInfo(client, "m_iAmmo") + (AmmoOffset * 4);
	
	new count = GetEntData(client, offsNades);
	SetEntData(client, offsNades, ++count);
}


SetAlpha(target, alpha)
{
	if(alpha > -1 && alpha < 256)
	{
		SetEntityRenderMode(target,RENDER_GLOW);
		SetEntityRenderColor(target, 255, 255, 255, alpha);
	}
}

EndGame()
{
	new timeleft;
	GetMapTimeLeft(timeleft);
	ExtendMapTimeLimit(-1*timeleft);
	
}
