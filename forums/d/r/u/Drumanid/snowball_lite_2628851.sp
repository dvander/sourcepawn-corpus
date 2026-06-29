// Old plugin: boomix
// Plugin rework: https://forums.alliedmods.net/showthread.php?t=291669

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <vip_core>

public Plugin myinfo =
{
	name = "Snowball Lite",
	description = "Replaces a decoy grenade to snowball",
	author = "Drumanid",
	version = "1.0.2 [ENG]",
	url = "Discrod: Drumanid#9108 | Telegram: t.me/drumanid"
};

#define IsEntityValid(%0) (%0 > 0 && IsValidEdict(%0))
#define SZF(%0) %0, sizeof(%0)
#define IsValidClient(%0) (0 < %0 <= MaxClients && IsClientInGame(%0))
#define Hook(%0,%1) %0.AddChangeHook(view_as<ConVarChanged>(%1))

Handle	g_hTimer[MAXPLAYERS +1];
static const char g_sFeature[] = "Snowball";

int		g_iModel[2],
		g_iTrail,
		g_iBlot;

bool	g_bCvarEndless,
		g_bCvarTrail,
		g_bCvarBlot,
		//g_bVipCore,
		g_bCvarVipUse;

float	g_fCvarDamage,
		g_fCvarFreeze;

public void OnMapStart()//OnConfigsExecuted
{
	AddFileToDownloadsTable("models/weapons/v_snowball.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/v_snowball.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/v_snowball.mdl");
	AddFileToDownloadsTable("models/weapons/v_snowball.sw.vtx");
	AddFileToDownloadsTable("models/weapons/v_snowball.vvd");
	AddFileToDownloadsTable("models/weapons/w_snowball.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/w_snowball.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/w_snowball.mdl");
	AddFileToDownloadsTable("models/weapons/w_snowball.phy");
	AddFileToDownloadsTable("models/weapons/w_snowball.sw.vtx");
	AddFileToDownloadsTable("models/weapons/w_snowball.vvd");
	AddFileToDownloadsTable("materials/models/weapons/v_models/sball/v_hands.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/sball/v_hands.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/sball/v_hands_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/Snooball/s.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/Snooball/s.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/Snooball/s_norm.vtf");
	AddFileToDownloadsTable("materials/snowball/snowball.vmt");
	AddFileToDownloadsTable("materials/snowball/snowball.vtf");
	AddFileToDownloadsTable("sound/snowball/hit.mp3");
	
	g_iModel[0] = PrecacheModel("models/weapons/w_snowball.mdl");
	g_iModel[1] = PrecacheModel("models/weapons/v_snowball.mdl");
	g_iTrail = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iBlot = PrecacheDecal("snowball/snowball.vtf", true);

	PrecacheSound("*snowball/hit.mp3", true);
	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
}

/*public void OnAllPluginsLoaded() { g_bVipCore = LibraryExists("vip_core"); }
public void OnLibraryRemoved(const char[] sName) { if(StrEqual(sName, "vip_core")) g_bVipCore = false; }
public void OnLibraryAdded(const char[] sName) { if(StrEqual(sName, "vip_core")) g_bVipCore = true; }*/

public void OnPluginStart()
{
	ConVar hCvar = CreateConVar("snowball_lite_endless", "1", "Endless snowballs? 1 - yes / 0 - no"); Hook(hCvar, CvarHookEndless); g_bCvarEndless = hCvar.BoolValue;
	hCvar = CreateConVar("snowball_lite_trail", "1", "Create a trail for a snowball? 1 - yes / 0 - no"); Hook(hCvar, CvarHookTrail); g_bCvarTrail = hCvar.BoolValue;
	hCvar = CreateConVar("snowball_lite_blot", "1", "Create a blot on the wall? 1 - yes / 0 - no"); Hook(hCvar, CvarHookBlot); g_bCvarBlot = hCvar.BoolValue;
	hCvar = CreateConVar("snowball_lite_freeze", "2.0", "How many seconds will the player be frozen? 0 - do not freeze"); Hook(hCvar, CvarHookFreeze); g_fCvarFreeze = hCvar.FloatValue;
	hCvar = CreateConVar("snowball_lite_damage", "50.0", "What is the snowball damage?"); Hook(hCvar, CvarHookDamage); g_fCvarDamage = hCvar.FloatValue;
	hCvar = CreateConVar("snowball_lite_vip", "0", "Snow issue only VIP players? 1 - only VIP / 0 - all\nVIP_Core: https://github.com/R1KO/VIP-Core"); Hook(hCvar, CvarHookVip); g_bCvarVipUse = hCvar.BoolValue;
	AutoExecConfig(true, "snowball_lite");

	HookEvent("player_spawn", view_as<EventHook>(PlayerSpawn));
	AddNormalSoundHook(SoundHook);

	for(int iClient = 1; iClient <= MaxClients; ++iClient)
	{
		if(IsClientInGame(iClient)) OnClientPutInServer(iClient);
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") ==
	FeatureStatus_Available) VIP_UnregisterFeature(g_sFeature);
}

void CvarHookEndless(ConVar hCvar) { g_bCvarEndless = hCvar.BoolValue; }
void CvarHookTrail(ConVar hCvar) { g_bCvarTrail = hCvar.BoolValue; }
void CvarHookBlot(ConVar hCvar) { g_bCvarBlot = hCvar.BoolValue; }
void CvarHookFreeze(ConVar hCvar) { g_fCvarFreeze = hCvar.FloatValue; }
void CvarHookDamage(ConVar hCvar) { g_fCvarDamage = hCvar.FloatValue; }
void CvarHookVip(ConVar hCvar) { g_bCvarVipUse = hCvar.BoolValue; }

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, HIDE);
}

void PlayerSpawn(Event hEvent)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	SetEntityRenderColor(iClient, 255, 255, 255, 255);
	if(g_bCvarEndless && CheckVip(iClient)) GivePlayerItem(iClient, "weapon_decoy");
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient)) SDKHook(iClient, SDKHook_WeaponSwitchPost, WeaponSwitchPost); 
}

void WeaponSwitchPost(int iClient, int iEntity)
{
	char sWeapon[32]; GetEntityClassname(iEntity, SZF(sWeapon));
	if(!StrEqual(sWeapon, "weapon_decoy") || !CheckVip(iClient)) return;

	SetEntPropFloat(iEntity, Prop_Send, "m_flTimeWeaponIdle", 0.0);
	SetEntPropFloat(iEntity, Prop_Send, "m_flNextPrimaryAttack", 0.0);
	SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", 0.0);

	int iModel = GetEntPropEnt(iEntity, Prop_Send, "m_hWeaponWorldModel");
	if(IsEntityValid(iModel)) SetEntProp(iModel, Prop_Send, "m_nModelIndex", g_iModel[0]);

	if(!IsEntityValid((iModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel")))) return;
	SetEntProp(iModel, Prop_Send, "m_nModelIndex", g_iModel[1]);
	SetEntProp(iEntity, Prop_Send, "m_nModelIndex", 0);
}

public Action SoundHook(int iClients[64], int &iNumClients, char sSimple[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags)
{
	char sWeapon[32]; GetEntityClassname(iEntity, SZF(sWeapon));
	if(!StrEqual(sWeapon, "decoy_projectile") || !CheckVip(iEntity)) return Plugin_Continue;

	float fPos[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	EmitAmbientSound("*snowball/hit.mp3", fPos, iEntity, iLevel, iFlags, 1.0, iPitch);

	return Plugin_Stop;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{ 	
	if(StrEqual(sClassname, "decoy_projectile")) SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost);
}

void SpawnPost(int iEntity)
{
	RequestFrame(SpawnPostFrame, iEntity);
}

void SpawnPostFrame(int iEntity)
{
	if(!CheckVip(iEntity)) return;
	
	SetEntityModel(iEntity, "models/weapons/w_snowball.mdl");
	SDKHook(iEntity, SDKHook_StartTouch, StartTouch);

	if(!g_bCvarTrail) return;
	TE_SetupBeamFollow(iEntity, g_iTrail, 0, 1.0, 1.0, 1.0, 5, {255, 255, 255, 255});
	TE_SendToAll();
}

void StartTouch(int iEntity, int iVictim)
{
	int iAttacker = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	float fPos[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	if(IsValidClient(iAttacker) && IsValidClient(iVictim) &&
	GetClientTeam(iVictim) != GetClientTeam(iAttacker))
	{
		SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, g_fCvarDamage, DMG_CRUSH);
		if(g_fCvarFreeze > 0.0)
		{
			OnClientDisconnect(iVictim);
			SetEntityMoveType(iVictim, MOVETYPE_NONE);
			SetEntityRenderColor(iVictim, 0, 157, 255, 255);
			g_hTimer[iVictim] = CreateTimer(g_fCvarFreeze, FreezeClientTimer, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
			EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", fPos, iEntity);
		}
	}
	else if(g_bCvarBlot)
	{
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", fPos);
		TE_WriteNum("m_nIndex", g_iBlot);
		TE_SendToAll();
	}

	AcceptEntityInput(iEntity, "Kill");
	if(g_bCvarEndless) GivePlayerItem(iAttacker, "weapon_decoy");
}

public Action FreezeClientTimer(Handle hTimer, any iClient)
{
	iClient = GetClientOfUserId(iClient);
	if(IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
	}

	g_hTimer[iClient] = null;
	return Plugin_Stop;
}

public void OnClientDisconnect(int iClient)
{
	if(g_hTimer[iClient] == null) return;

	KillTimer(g_hTimer[iClient]);
	g_hTimer[iClient] = null;
}

bool CheckVip(int iEntity)
{
	int iClient = iEntity > MaxClients ? GetEntPropEnt(iEntity, Prop_Send, "m_hThrower"):iEntity;
	if(iClient > 0 && !IsFakeClient(iClient) && (!g_bCvarVipUse ||
	/*g_bVipCore && */VIP_IsClientFeatureUse(iClient, g_sFeature))) return true;
	return false;
}