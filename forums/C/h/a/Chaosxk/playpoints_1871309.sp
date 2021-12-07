#pragma semicolon 1
#include <playpoints>

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo =
{
	name = "[TF2] Play Points Ability Pack",
	description = "Get points, Get abilities.",
	author = "Tak (Chaosxk)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[PlayPoints] This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	Version = CreateConVar("sm_playpoints_version", PLUGIN_VERSION, "Version of play points.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("sm_playpoints_enabled", "1", "Enable playpoints plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvarTimerPoints = CreateConVar("sm_points_timer", "180.0", "How many seconds to add points to player.");
	cvarTimerPoints2 = CreateConVar("sm_addpoints_timer", "5", "How many points to add with the timer.");
	cvarTimerAd = CreateConVar("sm_playpoints_timer", "120", "How many seconds to display to clients about playpoints.");
	cvarSentryTime = CreateConVar("sm_playpoints_sentryremove", "5.0", "How many seconds until sentry is removed when using Karma Sentry?");
	cvarSpeed = CreateConVar("sm_playpoints_disguisespeed", "100.0", "What should the player's speed be when using Disguise Jutsu?");
	cvarPyroPushForce = CreateConVar("sm_playpoints_pyropushforce", "450.0", "What should the player's force be when using Fly Blasting?");
	cvarBonkDuration = CreateConVar("sm_playpoints_bonkduration", "5.0", "What should the bonk duration be when using bonk shoes?");
	cvarTracerDuration = CreateConVar("sm_playpoints_tracerduration", "5.0", "How long should tracer bullets last?");
	cvarExplosiveDamage = CreateConVar("sm_playpoints_exparrowdamage", "50.0", "How much damage should explosive arrows do?");
	cvarExplosiveRadius = CreateConVar("sm_playpoints_exparrowradius", "200.0", "What should the radius be for explosive arrows?");
	cvarBoomDamage = CreateConVar("sm_playpoints_boomdamage", "200.0", "How much damage should High Explosive rockets do?");
	cvarBoomRadius = CreateConVar("sm_playpoints_boomradius", "350.0", "What should the radius be for High Explosive rockets?");
	cvarLightDmg = CreateConVar("sm_playpoints_lightdmg", "50.0", "How much damage should a lightning strike do?");
	cvarLightRadius = CreateConVar("sm_playpoints_lightradius", "400.0", "What should the radius of lightning strike be?");
	disabledAbilities = CreateConVar("sm_playpoints_disabled", "", "What abilities should be disabled?");
	cvarSapRadius = CreateConVar("sm_playpoints_sapradius", "300.0", "Radius of Sapper Throw.");
	
	g_Price[1] = CreateConVar("sm_disguise_price", "50", "Price for Disguise Jutsu.");
	g_Price[2] = CreateConVar("sm_slapping_price", "50", "Price for Machine Slapping.");
	g_Price[3] = CreateConVar("sm_hyper_price", "100", "Price for Hyper Heavy.");
	g_Price[4] = CreateConVar("sm_blasting_price", "50", "Price for Fly Blasting.");
	g_Price[5] = CreateConVar("sm_bonk_price", "50", "Price for Bonk Shoes.");
	g_Price[6] = CreateConVar("sm_speed_price", "50", "Price for 520 Speed.");
	g_Price[7] = CreateConVar("sm_tracer_price", "50", "Price for Tracer Bullets.");
	g_Price[8] = CreateConVar("sm_exparrow_price", "100", "Price for Explosive Arrows.");
	g_Price[9] = CreateConVar("sm_homearrow_price", "125", "Price for Homing Arrows.");
	g_Price[10] = CreateConVar("sm_homerocket_price", "100", "Price for Homing Rockets.");
	g_Price[11] = CreateConVar("sm_ball_price", "50", "Price for Homing Balls.");
	g_Price[12] = CreateConVar("sm_boom_price", "100", "Price for High Explosive Rockets.");
	g_Price[13] = CreateConVar("sm_karma_price", "50", "Price for Karma Sentry.");
	g_Price[14] = CreateConVar("sm_charger_price", "50", "Price for Super Charger.");
	g_Price[15] = CreateConVar("sm_fifty_price", "50", "Price for 50. Cal.");
	g_Price[16] = CreateConVar("sm_drug_price", "50", "Price for Drug Syringe.");
	g_Price[17] = CreateConVar("sm_lightning_price", "75", "Price for Lightning Strike.");
	g_Price[18] = CreateConVar("sm_shield_price", "100", "Price for Dispenser Shield.");
	g_Price[19] = CreateConVar("sm_sapper_price", "100", "Price for Sapper Throw.");
	g_Price[20] = CreateConVar("sm_napalm_price", "75", "Price for Napalm Rockets.");
	
	PointKill = CreateConVar("sm_playpoints_kill", "2", "How much points does killing someone give?");
	HSPointKill = CreateConVar("sm_playpoints_hs", "1", "How much points does a headshot give?");
	PointAssist = CreateConVar("sm_playpoints_assist", "1", "How much points should an assist give?");
	
	RegConsoleCmd("sm_playpoints", BuyMenu, "Buy MOAR!");
	RegConsoleCmd("sm_buy", BuyMenu, "Buy MOAR!");
	RegConsoleCmd("sm_menu", BuyMenu, "Buy MOAR!");
	RegConsoleCmd("sm_shop", BuyMenu, "Buy MOAR!");
	RegAdminCmd("sm_addpoints", AddPoints, ADMFLAG_GENERIC, "Add Points");
	RegAdminCmd("sm_subpoints", SubPoints, ADMFLAG_GENERIC, "Subtract Points");
	
	HookEvent("player_death", Player_Death);
	HookEvent("player_death", Pre_Death, EventHookMode_Pre);
	HookEvent("player_hurt", Player_Hurt);
	HookEvent("player_builtobject", Built_Event);
	HookEvent("object_removed", Bye_Event1);
	HookEvent("player_carryobject", Bye_Event2);
	HookEvent("object_destroyed", Bye_Event3);

	HookConVarChange(cvarTimerAd, cvarChange);
	HookConVarChange(cvarTimerPoints, cvarChange);
	HookConVarChange(disabledAbilities, cvarChange);
	AutoExecConfig(true, "playpoints");
	
	LoadTranslations("common.phrases");
	
	LoadCookieDatabase();
	LoadDisabledNames();
	LoadDisabledAbilities();
	
	for(new client = 0; client <= MaxClients; client++)
	{	
		if(!IsValidClient(client)) continue;
		
		CreateTimer(0.1, Timer_ChargeMe, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_ChargeMe2, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_Points, client);
		CreateTimer(0.1, Timer_Price, client);
		
		RemoveShield2(client);
		FindDispenser(client);
		
		SDKHook(client, SDKHook_StartTouch, OnStartTouch);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		GetCookie(client);
	}
	g_hArrayHoming = CreateArray(2, 0);
	hHudText = CreateHudSynchronizer();
	hHudCharge = CreateHudSynchronizer();
	hHudCosts = CreateHudSynchronizer();
	
	if(GetConVarFloat(cvarTimerAd) > 0.0)
	{
		g_TimerAd = CreateTimer(GetConVarFloat(cvarTimerAd), Timer_Ads, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	if(GetConVarFloat(cvarTimerPoints) > 0.0)
	{
		g_TimerPoints = CreateTimer(GetConVarFloat(cvarTimerPoints), GivePoints, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	//Uncomment if you do not want updater//
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
//Uncomment if you do not want updater//
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnMapStart()
{
	PrecacheModel(BARREL, true);
	PrecacheModel(BARREL_GIB1, true);
	PrecacheModel(BARREL_GIB2, true);
	PrecacheModel(BARREL_GIB3, true);
	PrecacheModel(BARREL_GIB4, true);
	PrecacheModel(BARREL_GIB5, true);
	PrecacheGeneric(SMALL_EXPLOSION, true);
	PrecacheModel(SENTRY_ROCKET, true);
	PrecacheModel(BOMB, true);
	PrecacheModel(LIGHTNING, true);
	PrecacheModel(STEAM, true);
	PrecacheSound(EXPLOSION, true);
	
	PrecacheModel(MDL_THROW_SAPPER, true);
	PrecacheSound(SOUND_SAPPER_REMOVED, true);
	PrecacheSound(SOUND_SAPPER_NOISE2, true);
	PrecacheSound(SOUND_SAPPER_NOISE, true);
	PrecacheSound(SOUND_SAPPER_PLANT, true);
	PrecacheSound(SOUND_SAPPER_THROW, true);
	PrecacheSound(SOUND_BOOT, true);
	PrecacheGeneric(EFFECT_TRAIL_RED, true);
	PrecacheGeneric(EFFECT_TRAIL_BLU, true);
	PrecacheGeneric(EFFECT_CORE_FLASH, true);
	PrecacheGeneric(EFFECT_DEBRIS, true);
	PrecacheGeneric(EFFECT_FLASH, true);
	PrecacheGeneric(EFFECT_FLASHUP, true);
	PrecacheGeneric(EFFECT_FLYINGEMBERS, true);
	PrecacheGeneric(EFFECT_SMOKE, true);
	PrecacheGeneric(EFFECT_SENTRY_FX, true);
	PrecacheGeneric(EFFECT_SENTRY_SPARKS1, true);
	PrecacheGeneric(EFFECT_SENTRY_SPARKS2, true);
	g_EffectSprite = PrecacheModel(SPRITE_ELECTRIC_WAVE, true);
	
	PrecacheSound(HEADBONK1, true);
	PrecacheSound(HEADBONK2, true);
	PrecacheSound(HEADBONK3, true);
	PrecacheSound(BOOM1, true);
	PrecacheSound(BOOM2, true);
	PrecacheSound(BOOM3, true);
	PrecacheSound(HYPER, true);
	
	ClearArray(g_hArrayHoming);
}

public Action:Timer_Ads(Handle:timer)
{
	new random = GetRandomInt(0, 1);
	if(random == 0)
	{
		CPrintToChatAll("{lawngreen}[PlayPoints] {orange}Type !buy to open the PlayPoints Ability Pack menu for awesome abilities!");
	}
	if(random == 1)
	{
		CPrintToChatAll("{lawngreen}[PlayPoints] {orange}PlayPoints Ability Pack is active, type !buy to open the menu.");
	}
}

public Action:GivePoints(Handle:timer)
{
	for(new client = 0; client < MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			g_Abilities[client][Points] += GetConVarInt(cvarTimerPoints2);
			saveCookie(client);
		}
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[])
{
	if(convar == Version)
	{
		SetConVarString(Version, PLUGIN_VERSION, false, false);
	}
	if(convar == cvarTimerAd)
	{
		if(StringToFloat(newValue) <= 0)
		{
			if(g_TimerAd != INVALID_HANDLE)
			{
				ClearTimer(g_TimerAd);
			}
		}
		else
		{
			ClearTimer(g_TimerAd);
			g_TimerAd = CreateTimer(StringToFloat(newValue), Timer_Ads, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if(convar == cvarTimerPoints)
	{
		if(StringToFloat(newValue) <= 0)
		{
			ClearTimer(g_TimerPoints);
		}
		else
		{
			ClearTimer(g_TimerPoints);
			g_TimerPoints = CreateTimer(StringToFloat(newValue), GivePoints, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if(convar == disabledAbilities)
	{
		LoadDisabledNames();
		LoadDisabledAbilities();
	}
}

public OnConfigsExecuted()
{
	if(GetConVarBool(cvarEnabled)) Enabled = true;
	else Enabled = false;
}

public OnGameFrame()
{
	if(!Enabled) return;

	for(new i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(TF2_GetPlayerClass(i) == TFClass_Pyro
			&& g_Disable[Disguise] == 0)
			{
				if((GetEntityFlags(i) & FL_DUCKING) 
				&& (GetEntityFlags(i) & FL_ONGROUND) 
				&& !(GetEntityFlags(i) & FL_INWATER) 
				&& g_Abilities[i][Disguise] == 1 
				&& g_Count[i] == 0)
				{
					EnableDisguise(i);
					g_Count[i] = 1;
					SetEntProp(i, Prop_Send, "m_iHealth", GetClientHealth(i) - 25);
					if(GetClientHealth(i) <= 0)
					{
						ForcePlayerSuicide(i);
					}
				}
				if(!(GetEntityFlags(i) & FL_DUCKING) 
				&& g_Abilities[i][Disguise] == 1 
				&& g_Count[i] == 1)
				{
					DisableDisguise(i);
					g_Count[i] = 0;
				}
			}
			if((TF2_GetPlayerClass(i) == TFClass_Scout
			&& g_Abilities[i][Speed] == 1
			&& g_Disable[Speed] == 0) ||
			(TF2_GetPlayerClass(i) == TFClass_Heavy
			&& g_Abilities[i][Hyper] == 1
			&& g_Disable[Hyper] == 0))
			{
				SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 520.0);
			}
		}
	}
	for(new i=GetArraySize(g_hArrayHoming)-1; i>=0; i--)
	{
		new iData[2];
		GetArrayArray(g_hArrayHoming, i, iData);
		
		if(iData[ARRAY_ENTITY] == 0)
		{
			RemoveFromArray(g_hArrayHoming, i);
			continue;
		}
		
		new iProjectile = EntRefToEntIndex(iData[ARRAY_ENTITY]);
		if(iProjectile > MaxClients)
		{
			HomingProjectile_Think(iProjectile, g_eProjectile:iData[ARRAY_TYPE]);
		}
		else
		{
			RemoveFromArray(g_hArrayHoming, i);
		}
	}
	new entity = -1;
	new client = -1;
	new entity2 = -1;
	new Float:pos[3];
	new Float:dpos[3];
	while((entity=FindEntityByClassname(entity, "obj_dispenser"))!=INVALID_ENT_REFERENCE)
	{
		if(!IsValidEntity(entity)) return;
		client = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if(!IsValidClient(client)) return;
		if(g_Abilities[client][Shield] == 1)
		{
			while((entity2=FindEntityByClassname(entity2, "tf_projectile_*"))!=INVALID_ENT_REFERENCE)
			{
				if(!IsValidEntity(entity2)) return;
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
				GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", dpos);
				if(GetVectorDistance(pos,dpos) <= 60)
				{
					AcceptEntityInput(entity2, "Kill");
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(!Enabled) return;
	
	if(IsValidClient(client))
	{
		if(g_Abilities[client][Shield] == 1 && IsValidEntity(g_ShieldModel[client]))
		{
			new entity = -1; 
			while ((entity=FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE)
			{
				if(IsValidEntity(entity))
				{
					new String:Name[128];
					GetEntPropString(entity, Prop_Data, "m_iName", Name, 128, 0);
					if(StrEqual(Name, "shield&me"))
					{
						new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
						if(owner == client)
						{
							AcceptEntityInput(entity, "Kill");
						}
					}
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(!Enabled) return;
	
	if(IsValidClient(client))
	{
		CreateTimer(0.1, Timer_ChargeMe, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_ChargeMe2, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_Points, client);
		CreateTimer(0.1, Timer_Price, client);
		
		weapon2[client] = 0;
		g_Count[client] = 0;
		isStunned[client] = 0;
		g_projArrowOn[client] = 0;
		g_projRocketOn[client] = 0;
		g_BoomClicked[client] = 0;
		g_mSentry[client] = 0;
		g_DmgSpy[client] = 0;
		g_CalCharge[client] = 0;
		iFOVDeathCheck[client] = 0;
		g_FOVT[client] = 0;
		g_ShieldModel[client] = 0;
		g_SapperModel[client] = 0;
		g_class[client] = 0;
		g_abilitynum[client] = 0;
		
		GetCookie(client);
		
		SDKHook(client, SDKHook_StartTouch, OnStartTouch);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
		for(new i = 0; i < MAX_TARGET_BUILDING; i++)
		{
			g_TargetBuilding[client][i] = 0;
			g_SoundCount[i] = 0;
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(!IsValidEntity(entity)) return;
	for(new i = 0; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;
		
		if(StrEqual(classname, "tf_projectile_arrow"))
		{
			if(g_ExplodeArrowsOn[i] == 1 && g_Disable[ExplodeArrows] == 0)
			{
				g_CalCharge[i] = 0;
				SDKHook(entity, SDKHook_StartTouch, OnEntityTouch);
			}
			if(g_projArrowOn[i] == 1 && g_Disable[projArrow] == 0)
			{
				g_CalCharge[i] = 0;
				CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(entity));
			}
		}
		if(StrEqual(classname, "tf_projectile_rocket"))
		{
			if(g_projRocketOn[i] == 1 && g_Disable[projRocket] == 0)
			{
				g_CalCharge[i] = 0;
				CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(entity));
			}
			if(g_BoomClicked[i] == 1)
			{
				SDKHook(entity, SDKHook_StartTouch, OnEntityTouch2);
				//SetEntityModel(entity, SENTRY_ROCKET); broken; dunno how to fix for now
				SetEntProp(weapon2[i], Prop_Data, "m_iClip1", 1);
				g_BoomClicked[i] = 0;
			}
		}
		if(StrEqual(classname, "tf_projectile_stun_ball"))
		{
			if(g_Abilities[i][projBall] == 1 && g_Disable[projBall] == 0)
			{
				CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(entity));
			}
		}
	}
}

public Action:Timer_CheckOwnership(Handle:hTimer, any:iRef)
{
	new iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile > MaxClients && IsValidEntity(iProjectile))
	{
		new iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
		if(iLauncher >= 1 && iLauncher <= MaxClients 
		&& IsClientInGame(iLauncher) 
		&& IsPlayerAlive(iLauncher)
		&& (g_Abilities[iLauncher][projBall] == 1
		|| g_projRocketOn[iLauncher] == 1
		|| g_projArrowOn[iLauncher] == 1))
		{
			new String:strClassname[40];
			GetEdictClassname(iProjectile, strClassname, sizeof(strClassname));
			
			new g_eProjectiles:type = PROJECTILE_ROCKET;
			switch(strClassname[14])
			{
				case 'a': type = PROJECTILE_ARROW;
				case 'h': type = PROJECTILE_ARROW;
				case 'f': type = PROJECTILE_FLARE;
				case 's': type = PROJECTILE_STUN_BALL;
			}
			
			new iData[2];
			iData[ARRAY_ENTITY] = EntIndexToEntRef(iProjectile);
			iData[ARRAY_TYPE] = _:type;
			PushArrayArray(g_hArrayHoming, iData);
			g_projRocketOn[iLauncher] = 0;
			g_projArrowOn[iLauncher] = 0;
		}
	}
	return Plugin_Handled;
}

public HomingProjectile_Think(iProjectile, g_eProjectile:pType)
{	
	new iCurrentTarget = GetEntProp(iProjectile, Prop_Send, "m_nForceBone");
	
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
	{
		HomingProjectile_FindTarget(iProjectile, pType);
	}
	else
	{
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile, pType);
	}
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		{
			return false;
		}
		
		new Float:flStart[3];
		GetClientEyePosition(client, flStart);
		new Float:flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		
		new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients)) return false;
	else return true;
}

HomingProjectile_FindTarget(iProjectile, g_eProjectile:pType)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	new Float:flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	new iBestTarget;
	new Float:flBestLength = 99999.9;
	for(new i=1; i<=MaxClients; i++)
	{
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			new Float:flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			
			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		SetEntProp(iProjectile, Prop_Send, "m_nForceBone", iBestTarget);
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile, pType);
	}
	else
	{
		SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 0);
	}
}

HomingProjectile_TurnToTarget(client, iProjectile, pType)
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);
	
	new Float:flRocketVel[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", flRocketVel);
	
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);
	
	new Float:flSpeed = 1100.0;
	switch(pType)
	{
		case PROJECTILE_ARROW: flSpeed = 1800.0;
		case PROJECTILE_FLARE: flSpeed = 1450.0;
		case PROJECTILE_STUN_BALL: flSpeed = 1750.0;
	}
	
	flSpeed *= 0.5;	
	flSpeed += GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * (flSpeed * 0.1);
	
	ScaleVector(flNewVec, flSpeed);
	
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

public Action:OnEntityTouch(entity, other)
{
	new Float:g_pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_pos);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new explode = CreateEntityByName("env_explosion");
	if(!IsValidEntity(explode) && !IsValidClient(client)) return Plugin_Continue;
	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		DispatchKeyValue(explode, "targetname", "explode");
		SetEntPropEnt(explode, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(explode, Prop_Data, "m_iMagnitude", GetConVarInt(cvarExplosiveDamage));
		SetEntProp(explode, Prop_Data, "m_iRadiusOverride", GetConVarInt(cvarExplosiveRadius));
		DispatchKeyValue(explode, "spawnflags", "2");
		DispatchKeyValue(explode, "rendermode", "5");
		DispatchKeyValue(explode, "fireballsprite", "sprites/zerogxplode.spr");
		DispatchSpawn(explode);
		TeleportEntity(explode, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(explode);
		AcceptEntityInput(explode, "Explode");
		CreateTimer(0.2, Explosion_Kill, explode);
		g_ExplodeArrowsOn[client] = 0;
		g_CalCharge[client] = 0;
	}
	return Plugin_Handled;
}

public Action:Explosion_Kill(Handle:timer, any:explode)
{
	if(!IsValidEntity(explode)) return;
	AcceptEntityInput(explode, "kill");
}

public Action:OnEntityTouch2(entity, other)
{
	new Float:g_pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_pos);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new info_particle_system = CreateEntityByName("info_particle_system");
	new env_shake = CreateEntityByName("env_shake");
	new explode = CreateEntityByName("env_explosion");
	if(!IsValidEntity(info_particle_system)
	&& !IsValidEntity(env_shake)
	&& !IsValidEntity(explode)
	&& !IsValidClient(client)) return Plugin_Continue;
	if(TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		DispatchKeyValue(info_particle_system, "targetname", "boom");
		DispatchKeyValue(info_particle_system, "effect_name", "cinefx_goldrush");
		DispatchSpawn(info_particle_system);
		TeleportEntity(info_particle_system, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(info_particle_system);
		AcceptEntityInput(info_particle_system, "Start");
		CreateTimer(6.0, Timer_Stop, info_particle_system);
		CreateTimer(7.0, Timer_Kill, info_particle_system);

		DispatchKeyValue(env_shake, "targetname", "tf2_shake");
		DispatchKeyValue(env_shake, "amplitude", "14");
		DispatchKeyValue(env_shake, "duration", "5");
		DispatchKeyValue(env_shake, "frequency", "300");
		DispatchKeyValue(env_shake, "radius", "800");
		DispatchSpawn(env_shake);
		TeleportEntity(env_shake, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(env_shake);
		AcceptEntityInput(env_shake, "StartShake");
		CreateTimer(5.0, Timer_Shake, env_shake);
		
		DispatchKeyValue(explode, "targetname", "explode");
		SetEntPropEnt(explode, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(explode, Prop_Data, "m_iMagnitude", GetConVarInt(cvarBoomDamage), 4, 0);
		SetEntProp(explode, Prop_Data, "m_iRadiusOverride", GetConVarInt(cvarBoomRadius), 4, 0);
		DispatchKeyValue(explode, "spawnflags", "25470");
		DispatchKeyValue(explode, "rendermode", "5");
		DispatchKeyValue(explode, "fireballsprite", "sprites/zerogxplode.spr");
		DispatchSpawn(explode);
		TeleportEntity(explode, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(explode);
		AcceptEntityInput(explode, "Explode");
		CreateTimer(0.2, Explosion_Kill, explode);
		
		new random = GetRandomInt(0, 2);
		if(random == 0)
		{
			EmitSoundToAll(BOOM1, client, _, _, _, 1.0);
		}
		else if(random == 1)
		{
			EmitSoundToAll(BOOM2, client, _, _, _, 1.0);
		}
		else if(random == 2)
		{
			EmitSoundToAll(BOOM3, client, _, _, _, 1.0);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Stop(Handle:timer, any:info_particle_system)
{
	if(!IsValidEntity(info_particle_system)) return;
	AcceptEntityInput(info_particle_system, "Stop");
}

public Action:Timer_Kill(Handle:timer, any:info_particle_system)
{
	if(!IsValidEntity(info_particle_system)) return;
	AcceptEntityInput(info_particle_system, "kill");
}

public Action:Timer_Shake(Handle:timer, any:env_shake)
{
	if(!IsValidEntity(env_shake)) return;
	AcceptEntityInput(env_shake, "kill");
}

public Action:Player_Hurt(Handle:event, String:name[], bool:dontBroadcast)
{
	if(!Enabled) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(client) || !IsValidClient(attacker)) return;
	
	new wep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(wep)) return;
	new String:cls[64];
	GetEntityClassname(wep, cls, sizeof(cls));
	if(g_Abilities[attacker][Slap] == 1
	&& g_Disable[Slap] == 0
	&& TF2_GetPlayerClass(attacker) == TFClass_Heavy
	&& StrEqual(cls, "tf_weapon_minigun"))
	{
		SlapPlayer(client, 0, true);
	}
	if(g_Abilities[attacker][Tracer] == 1
	&& g_Disable[Tracer] == 0
	&& TF2_GetPlayerClass(attacker) == TFClass_Sniper)
	{
		if(StrEqual(cls, "tf_weapon_sniperrifle"))
		{
			CreateTimer(GetConVarFloat(cvarTracerDuration), Timer_StopG, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
		else if(StrEqual(cls, "tf_weapon_sniperrifle_decap"))
		{
			CreateTimer(GetConVarFloat(cvarTracerDuration), Timer_StopG, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
	if(g_Abilities[attacker][Drug] == 1
	&& g_Disable[Drug] == 0
	&& TF2_GetPlayerClass(attacker) == TFClass_Medic)
	{
		if(g_FOVT[client] == 0)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
			g_FOVT[client] = 1;
		}
		new iFOV = GetEntProp(client, Prop_Send, "m_iFOV");
		if(iFOV <= 160)
		{
			if(StrEqual(cls, "tf_weapon_syringegun_medic"))
			{
				SetEntProp(client, Prop_Send, "m_iFOV", iFOV + 3);
			}
			if(StrEqual(cls, "tf_weapon_crossbow", false))
			{
				SetEntProp(client, Prop_Send, "m_iFOV", iFOV + 12);
			}
		}
		else if(iFOV > 160)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 160);
		}
		ClearTimer(g_TimerFOV);
		g_TimerFOV = CreateTimer(5.0, Timer_ResetFOV, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		iFOVDeathCheck[client] = 1;
	}
}

public Action:Timer_ResetFOV(Handle:timer, any:client)
{
	if(!IsValidClient(client)) return;
	new iFOV = GetEntProp(client,Prop_Send, "m_iFOV");
	new dFOV = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
	if(dFOV < iFOV)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", iFOV - 1);
	}
	else if(iFOV <= dFOV)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", dFOV);
		ClearTimer(g_TimerFOV);
	}
}

public Action:Timer_StopG(Handle:timer, any:client)
{
	if(!IsValidClient(client)) return;
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
}

public Action:Player_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	if(!Enabled) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new type = GetEventInt(event, "customkill");
	new deathflags = GetEventInt(event, "death_flags");
	if(IsValidClient(attacker) && client != 0)
	{
		if(attacker != client)
		{
			if(type == TF_CUSTOM_HEADSHOT
			|| type == TF_CUSTOM_HEADSHOT_DECAPITATION)
			{
				g_Abilities[attacker][Points] += GetConVarInt(HSPointKill);
			}
			if(deathflags != TF_DEATHFLAG_DEADRINGER)
			{
				if(attacker)
				{
					g_Abilities[attacker][Points] += GetConVarInt(PointKill);
				}
				else if(assister)
				{
					if(IsValidClient(assister))
					{
						g_Abilities[assister][Points] += GetConVarInt(PointAssist);
					}
				}
			}
			saveCookie(attacker);
			saveCookie(assister);
		}
	}
	if(IsValidClient(client))
	{
		if(iFOVDeathCheck[client] == 1)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
			ClearTimer(g_TimerFOV);
			iFOVDeathCheck[client] = 0;
		}
		g_FOVT[client] = 0;
		g_CalCharge[client] = 0;
	}
}

public Action:Built_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	new client = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	if(IsValidClient(client) && IsValidEntity(ent) && g_Abilities[client][Shield] == 1)
	{
		new String:classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "obj_dispenser"))
		{
			new Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			g_ShieldModel[client] = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(g_ShieldModel[client]))
			{	
				DispatchKeyValue(g_ShieldModel[client], "targetname", "shield&me");
				SetEntityModel(g_ShieldModel[client], "models/buildables/sentry_shield.mdl");
				SetEntPropEnt(g_ShieldModel[client], Prop_Send, "m_hOwnerEntity", client);
				
				if(GetClientTeam(client) == 2)
				{
					DispatchKeyValue(g_ShieldModel[client], "skin", "0");
				}
				else if(GetClientTeam(client) == 3)
				{
					DispatchKeyValue(g_ShieldModel[client], "skin", "1");
				}
			
				DispatchSpawn(g_ShieldModel[client]);
				TeleportEntity(g_ShieldModel[client], pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(g_ShieldModel[client], "TurnOn");
				ActivateEntity(g_ShieldModel[client]);
			}
		}
	}
}

FindDispenser(client)
{
	new ent = -1; 
	while ((ent=FindEntityByClassname(ent, "obj_dispenser"))!=INVALID_ENT_REFERENCE)
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
		g_ShieldModel[client] = CreateEntityByName("prop_dynamic");
		if(IsValidEntity(g_ShieldModel[client]) && g_Abilities[client][Shield] == 1)
		{	
			if(owner == client)
			{
				DispatchKeyValue(g_ShieldModel[client], "targetname", "shield&me");
				SetEntityModel(g_ShieldModel[client], "models/buildables/sentry_shield.mdl");
				SetEntPropEnt(g_ShieldModel[client], Prop_Send, "m_hOwnerEntity", client);
				
				if(GetClientTeam(client) == 2)
				{
					DispatchKeyValue(g_ShieldModel[client], "skin", "0");
				}
				else if(GetClientTeam(client) == 3)
				{
					DispatchKeyValue(g_ShieldModel[client], "skin", "1");
				}
				
				DispatchSpawn(g_ShieldModel[client]);
				TeleportEntity(g_ShieldModel[client], pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(g_ShieldModel[client], "TurnOn");
				ActivateEntity(g_ShieldModel[client]);
			}
		}
	}
}

public Action:Bye_Event1(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	if(!IsValidEntity(ent)) return;
	RemoveShield(ent);
}

public Action:Bye_Event2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	if(!IsValidEntity(ent)) return;
	RemoveShield(ent);
}

public Action:Bye_Event3(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	if(!IsValidEntity(ent)) return;
	RemoveShield(ent);
}

RemoveShield(ent)
{
	new String:classname[32];
	GetEdictClassname(ent, classname, sizeof(classname));
	if(StrEqual(classname, "obj_dispenser"))
	{
		new client = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
		if(IsValidClient(client) && g_Abilities[client][Shield] == 1 && IsValidEntity(g_ShieldModel[client]))
		{
			new entity = -1; 
			while ((entity=FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE)
			{
				if(IsValidEntity(entity))
				{
					new String:Name[128];
					GetEntPropString(entity, Prop_Data, "m_iName", Name, 128, 0);
					if(StrEqual(Name, "shield&me"))
					{
						new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
						if(owner == client)
						{
							AcceptEntityInput(entity, "Kill");
						}
					}
				}
			}
		}
	}
}

RemoveShield2(client)
{
	if(IsValidClient(client) && IsValidEntity(g_ShieldModel[client]))
	{
		new entity = -1; 
		while ((entity=FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE)
		{
			if(IsValidEntity(entity))
			{
				new String:Name[128];
				GetEntPropString(entity, Prop_Data, "m_iName", Name, 128, 0);
				if(StrEqual(Name, "shield&me"))
				{
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if(owner == client)
					{
						AcceptEntityInput(entity, "Kill");
					}
				}
			}
		}
	}
}

public Action:OnStartTouch(client, other)
{
	if(!Enabled) return;
	
	if(g_Abilities[client][Stun] == 1 
	&& TF2_GetPlayerClass(client) == TFClass_Scout
	&& other > 0 && other <= MaxClients
	&& IsPlayerAlive(client)
	&& g_Disable[Stun] == 0)
	{
		new Float:ClientPos[3];
		new Float:VictimPos[3];
		new Float:VictimVecMaxs[3];
		GetClientAbsOrigin(client, ClientPos);
		GetClientAbsOrigin(other, VictimPos);
		GetEntPropVector(other, Prop_Send, "m_vecMaxs", VictimVecMaxs);
		new Float:victimHeight = VictimVecMaxs[2];
		new Float:HeightDiff = ClientPos[2] - VictimPos[2];
		if(HeightDiff > victimHeight)
		{
			new Float:vec[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
			if(vec[2] < -360 && isStunned[other] == 0)
			{
				TF2_StunPlayer(other, GetConVarFloat(cvarBonkDuration), 0.0, TF_STUNFLAGS_BIGBONK, 0);
				CreateTimer(GetConVarFloat(cvarBonkDuration), resetStun, other);
				new random = GetRandomInt(0, 2);
				if(random == 0)
				{
					EmitSoundToAll(HEADBONK1, client, _, _, _, 1.0);
				}
				else if(random == 1)
				{
					EmitSoundToAll(HEADBONK2, client, _, _, _, 1.0);
				}
				else if(random == 2)
				{
					EmitSoundToAll(HEADBONK3, client, _, _, _, 1.0);
				}
				isStunned[other] = 1;
			}
		}
    }
}

public Action:resetStun(Handle:timer, any:other)
{
	if(!IsValidClient(other)) return;
	isStunned[other] = 0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if((1 <= attacker <= MaxClients) && IsValidClient(attacker)
	&& IsValidClient(victim) && IsValidEntity(weapon))
	{
		new String:cls[64];
		GetEntityClassname(weapon, cls, 64);
		if(g_Abilities[attacker][Dmg] == 1
		&& g_DmgSpy[attacker] == 1
		&& g_Disable[Dmg] == 0)
		{
			if(StrEqual(cls, "tf_weapon_revolver"))
			{
				damage = damage * 10;
				g_DmgSpy[attacker] = 0;
			}
		}
		if(g_Abilities[attacker][Napalm] == 1
		&& g_Disable[Napalm] == 0)
		{
			if(GetClientTeam(victim) != GetClientTeam(attacker))
			{
				if(StrEqual(cls, "tf_weapon_rocketlauncher"))
				{
					TF2_IgnitePlayer(victim, attacker);
					damage = damage * 0.25;
				}
			}
		}
		if(g_Abilities[attacker][Hyper] == 1
		&& g_Disable[Hyper] == 0)
		{
			if(StrEqual(cls, "tf_weapon_minigun"))
			{
				damage = damage * 0.75;
			}
		}
	}
	return Plugin_Changed;
}

public Action:Pre_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	if(!Enabled) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return;
	
	if(g_Abilities[client][Karma] == 1
	&& g_Disable[Karma] == 0
	&& TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		g_mSentry[client] = CreateEntityByName("obj_sentrygun");
		
		if(g_activeSentry[client] == 0
		&& IsValidEntity(g_mSentry[client]))
		{
			if(GetClientTeam(client) == 3)
			{
				DispatchKeyValue(g_mSentry[client], "TeamNum", "3");
			}
			if(GetClientTeam(client) == 2)
			{
				DispatchKeyValue(g_mSentry[client], "TeamNum", "2");
			}
			DispatchKeyValue(g_mSentry[client], "targetname", "model");
			DispatchKeyValue(g_mSentry[client], "spawnflags", "0");
			DispatchKeyValue(g_mSentry[client], "defaultupgrade", "0");
			DispatchSpawn(g_mSentry[client]);
			TeleportEntity(g_mSentry[client], pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(g_mSentry[client]);
			SetEntPropEnt(g_mSentry[client], Prop_Send, "m_hBuilder", client, 0);
			g_activeSentry[client] = 1;
			CreateTimer(GetConVarFloat(cvarSentryTime), KillSentry, client);
		}
	}
}

public Action:KillSentry(Handle:timer, any:client)
{
	if(!IsValidClient(client) && !IsValidEntity(g_mSentry[client])) return;
	SetVariantInt(1000);
	AcceptEntityInput(g_mSentry[client], "RemoveHealth");
	g_activeSentry[client] = 0;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(!Enabled && !IsValidClient(client)) return;
	if(condition == TFCond_Charging
	&& g_Abilities[client][Charge] == 1
	&& g_Disable[Charge] == 0)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) - 10);
		if(GetClientHealth(client) <= 0)
		{
			ForcePlayerSuicide(client);
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(!Enabled && !IsValidClient(client)) return;

	if(condition == TFCond_Charging
	&& g_Abilities[client][Charge] == 1
	&& g_Disable[Charge] == 0)
	{
		SetChargeMeter(client, 100.0);
	}
	if(g_Abilities[client][Light] == 1 
	&& condition == TFCond_Taunting
	&& g_Disable[Light] == 0
	&& TF2_GetPlayerClass(client) == TFClass_Scout
	&& g_CalCharge[client] == 100)
	{
		Strike(client);
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	if(Enabled && IsValidClient(client))
	{
		//NO COOKIES 4 YOU
		if(g_Abilities[client][Hyper] == 1
		&& (StrEqual(strClassName, "tf_weapon_minigun")
		|| StrEqual(strClassName, "tf_weapon_shotgun")
		|| StrEqual(strClassName, "tf_weapon_lunchbox")))
		{
			new random = GetRandomInt(0, 10);
			if(random == 0)
			{
				EmitSoundToAll(HYPER, client, _, _, _, 1.0);
			}
			return Plugin_Handled;
		}
		
		//kills shield when a player changes melee weapons
		if(g_Abilities[client][Shield] == 1 && IsValidEntity(g_ShieldModel[client]))
		{
			if(StrEqual(strClassName, "tf_weapon_wrench") 
			|| StrEqual(strClassName, "tf_weapon_robot_arm")
			|| StrEqual(strClassName, "saxxy"))
			{
				new entity = -1; 
				while ((entity=FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE)
				{
					if(IsValidEntity(entity))
					{
						new String:Name[128];
						GetEntPropString(entity, Prop_Data, "m_iName", Name, 128, 0);
						if(StrEqual(Name, "shield&me"))
						{
							new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
							if(owner == client)
							{
								AcceptEntityInput(entity, "Kill");
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:AddPoints(client, args)
{
	if(!Enabled || !IsValidClient(client)) return Plugin_Continue;
	
	new String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new button = StringToInt(arg2);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2)
	{
		ReplyToCommand(client, "{lawngreen}[PlayPoints] {orange}Usage: sm_addpoints <client> <ammount>");
		return Plugin_Handled;
	}
	
	if(args == 2)
	{
		for(new i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i]))
			{
				new target = target_list[i];
				if(button > 0)
				{
					CPrintToChat(client, "{lawngreen}[PlayPoints] {orange}You have added %d points to %N.", button, target);
					g_Abilities[target][Points] += button;
					saveCookie(target);
				}
				if(button == 0)
				{
					CPrintToChat(client, "{lawngreen}[PlayPoints] {orange}You have added no points.");
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:SubPoints(client, args)
{
	if(!Enabled || !IsValidClient(client)) return Plugin_Continue;
	
	new String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new button = StringToInt(arg2);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2)
	{
		ReplyToCommand(client, "{lawngreen}[PlayPoints] {orange}Usage: sm_subpoints <client> <ammount>");
		return Plugin_Handled;
	}
	
	if(args == 2)
	{
		for(new i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i]))
			{
				new target = target_list[i];
				if(button > 0)
				{
					CPrintToChat(client, "{lawngreen}[PlayPoints] {orange}You have subtracted %d points from %N.", button, target);
					g_Abilities[target][Points] -= button;
					saveCookie(target);
				}
				if(button == 0)
				{
					CPrintToChat(client, "{lawngreen}[PlayPoints] {orange}You have subtracted no points.");
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:BuyMenu(client, args)
{
	if(Enabled && IsValidClient(client))
	{
		ShowMainMenu(client);
	}
	return Plugin_Handled;
}

public Action:Timer_Price(Handle:timer, any:i)
{
	if(!IsValidClient(i)) return;
	if(g_hPriceCheck[i] == 1)
	{
		SetHudTextParams(-0.9, 0.30, 30.0, 255, 0, 0, 255);
		ShowSyncHudText(i, hHudCosts, "Price: %d", g_hPrice[i]);
		g_hPriceCheck[i] = 0;
	}
	CreateTimer(0.1, Timer_Price, i);
}

public Action:Timer_Points(Handle:timer, any:i)
{
	if(!IsValidClient(i)) return;
	if(TF2_GetPlayerClass(i) == TFClass_Engineer)
	{
		SetHudTextParams(-0.7, 0.05, 1.0, 255, 0, 0, 255);
	}
	else if(TF2_GetPlayerClass(i) != TFClass_Engineer)
	{
		SetHudTextParams(-0.85, 0.05, 1.0, 255, 0, 0, 255);
	}
	ShowSyncHudText(i, hHudText, "Points: %d", g_Abilities[i][Points]);
	CreateTimer(0.1, Timer_Points, i);
}

public Action:Timer_ChargeMe(Handle:timer, any:i)
{
	if(!IsValidClient(i)) return;
	ChargeNow(i);
}

public Action:Timer_ChargeMe2(Handle:timer, any:i)
{
	if(!IsValidClient(i)) return;
	ChargeNow2(i);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!Enabled && !IsValidClient(client) && !IsPlayerAlive(client)) return;
	
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if(g_Abilities[client][Blasting] == 1 && g_Disable[Blasting] == 0)
		{
			new entvalue = 0;
			new ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			entvalue = GetEntData(client, ammoOffset + 4, 4);
			new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(!IsValidEntity(wep)) return;
			new index = GetEntProp(wep,  Prop_Send, "m_iItemDefinitionIndex");
			new String:cls[64];
			GetEntityClassname(wep, cls, sizeof(cls));
			if(buttons & IN_ATTACK2)
			{
				if(index == 594) return;
				if(index == 40)
				{
					if(entvalue >= 50)
					{
						Blast(client);
					}
				}
				else if(StrEqual(cls, "tf_weapon_flamethrower"))
				{
					if(entvalue >= 20)
					{
						Blast(client);
					}
				}
			}
		}
		if(g_Abilities[client][Disguise] == 1 && g_Disable[Disguise] == 0
		&& (GetEntityFlags(client) & FL_DUCKING) 
		&& (GetEntityFlags(client) & FL_ONGROUND) 
		&& !(GetEntityFlags(client) & FL_INWATER))
		{
			if(buttons & IN_ATTACK)
			{
				buttons &= ~IN_ATTACK;
			}
			if(buttons & IN_ATTACK2)
			{
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	if(TF2_GetPlayerClass(client) == TFClass_Soldier
	&& g_Abilities[client][Boom] == 1
	&& g_Disable[Boom] == 0)
	{
		weapon2[client] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(weapon2[client])) return;
		new clip = GetEntProp(weapon2[client], Prop_Data, "m_iClip1");
		new index = GetEntProp(weapon2[client], Prop_Send, "m_iItemDefinitionIndex");
		if(buttons & IN_ATTACK2)
		{
			if(clip == 3 && (index == 228 || index == 414))
			{
				buttons |= IN_ATTACK;
				g_BoomClicked[client] = 1;
			}
			else if(clip == 4 && (index != 441 || index != 730))
			{
				buttons |= IN_ATTACK;
				g_BoomClicked[client] = 1;
			}
		}
	}
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if(g_Abilities[client][Dmg] == 1 && g_Disable[Dmg] == 0)
		{
			if(g_CalCharge[client] == 100)
			{
				ClientCommand(client, "r_screenoverlay \"%s.vtf\"", "effects/combine_binocoverlay");
				g_DmgSpy[client] = 1;
				if(buttons & IN_ATTACK)
				{
					g_CalCharge[client] = 0;
				}
			}
			else
			{
				ClientCommand(client, "r_screenoverlay \"\"");
			}
		}
		
		if(g_Abilities[client][Sapper] == 1 && g_Disable[Sapper] == 0)
		{
			if(g_CalCharge[client] == 100)
			{
				new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(!IsValidEntity(wep)) return;
				new String:cls[64];
				GetEntityClassname(wep, cls, sizeof(cls));
				if(StrEqual(cls, "tf_weapon_builder") || StrEqual(cls, "tf_weapon_sapper"))
				{
					if(buttons & IN_ATTACK3)
					{
						g_CalCharge[client] = 0;
						ThrowSapper(client);
					}
				}
			}
		}
	}
}

public Action:LoopSapping(Handle:timer, any:client)
{
	if(IsValidClient(client) && IsValidEntity(g_SapperModel[client]) && IsPlayerAlive(client))
	{
		new red[4] = {255, 0, 0, 255};
		new blue[4] = {0, 0, 255, 255};
		
		new Float:pos[3];
		GetEntPropVector(g_SapperModel[client], Prop_Data, "m_vecAbsOrigin", pos);
		new Float:radius = GetConVarFloat(cvarSapRadius);
		
		if(GetClientTeam(client) == 2)
		{
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, red, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, red, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, red, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, red, 15, 0);
			TE_SendToAll();
		}
		else if(GetClientTeam(client) == 3)
		{
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, blue, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, blue, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, blue, 15, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, radius, g_EffectSprite, g_EffectSprite, 1, 1, 0.6, 3.0, 10.0, blue, 15, 0);
			TE_SendToAll();
		}
		
		for(new i = 0; i < MAX_TARGET_BUILDING; i++)
		{
			if(IsValidEntity(g_TargetBuilding[client][i]))
			{
				SetVariantInt(1);
				AcceptEntityInput(g_TargetBuilding[client][i], "RemoveHealth");
			}
		}
		
		new Float:effectPos[3];
		new Float:spos[3];
		new targetCount = 0;
		GetEntPropVector(g_SapperModel[client], Prop_Data, "m_vecAbsOrigin", spos);
		
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)
		{
			if(!IsValidEntity(ent)) return;
			new Float:dispPos[3];
			GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", dispPos);
			new owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			
			if(GetClientTeam(owner) != GetClientTeam(client) && g_Abilities[owner][Shield] == 0)
			{
				if(GetVectorDistance(spos,dispPos) <= GetConVarFloat(cvarSapRadius))
				{
					if(targetCount < MAX_TARGET_BUILDING)
					{
						SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
						effectPos[0] = GetRandomFloat(-25.0, 25.0);
						effectPos[1] = GetRandomFloat(-25.0, 25.0);
						effectPos[2] = GetRandomFloat(10.0, 65.0);
						
						ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.5, effectPos);
						
						g_TargetBuilding[client][targetCount] = ent;
						targetCount += 1;
					}
				}
			}
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
		{
			if(!IsValidEntity(ent)) return;
			new Float:sentPos[3];
			GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", sentPos);
			new owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			if(GetClientTeam(owner) != GetClientTeam(client))
			{
				if(GetVectorDistance(spos,sentPos) <= GetConVarFloat(cvarSapRadius))
				{
					if(targetCount < MAX_TARGET_BUILDING)
					{
						SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
						new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
						effectPos[0] = GetRandomFloat(-20.0, 20.0);
						effectPos[1] = GetRandomFloat(-20.0, 20.0);
						switch(level)
						{
							case 1:
								effectPos[2] = GetRandomFloat(10.0, 55.0);
							case 2:
								effectPos[2] = GetRandomFloat(10.0, 65.0);
							case 3:
								effectPos[2] = GetRandomFloat(10.0, 75.0);
						}
						ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.5, effectPos);
						
						g_TargetBuilding[client][targetCount] = ent;
						targetCount += 1;
					}
				}
			}
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
		{
			if(!IsValidEntity(ent)) return;
			new Float:entraPos[3];
			GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", entraPos);
			new owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			if(GetClientTeam(owner) != GetClientTeam(client))
			{
				if(GetVectorDistance(spos,entraPos) <= GetConVarFloat(cvarSapRadius))
				{
					if(targetCount < MAX_TARGET_BUILDING)
					{
						SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
						effectPos[0] = GetRandomFloat(-25.0, 25.0);
						effectPos[1] = GetRandomFloat(-25.0, 25.0);
						effectPos[2] = GetRandomFloat(5.0, 15.0);
						
						ShowParticleEntity(ent, EFFECT_SENTRY_FX, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS1, 0.5, effectPos);
						ShowParticleEntity(ent, EFFECT_SENTRY_SPARKS2, 0.5, effectPos);
						
						g_TargetBuilding[client][targetCount] = ent;
						targetCount += 1;
					}
				}
			}
		}
		new Float:cpos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cpos);
		if(GetVectorDistance(cpos,spos) <= GetConVarFloat(cvarSapRadius))
		{
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") - 5);
		}
	}
}

public Action:StartSapping(Handle:timer, any:client)
{
	if(!IsValidClient(client) && !IsValidEntity(g_SapperModel[client])) return;
	for(new i = 0; i < MAX_TARGET_BUILDING; i++)
	{
		if(IsValidEntity(g_TargetBuilding[client][i]) && g_TargetBuilding[client][i] > 0)
		{
			new isSapped = GetEntProp(g_TargetBuilding[client][i], Prop_Send, "m_bDisabled");
			if(isSapped == 1 && g_SoundCount[i] == 0)
			{
				EmitSoundToAll(SOUND_SAPPER_NOISE, g_TargetBuilding[client][i], _, _, SND_CHANGEPITCH, 1.0, 150);
				EmitSoundToAll(SOUND_SAPPER_NOISE2, g_TargetBuilding[client][i], _, _, SND_CHANGEPITCH, 1.0, 60);
				EmitSoundToAll(SOUND_SAPPER_PLANT, g_TargetBuilding[client][i], _, _, _, 1.0);
				g_SoundCount[i] = 1;
			}
		}
	}
}

public Action:StopSapping(Handle:timer, any:client)
{
	if(!IsValidClient(client) && !IsValidEntity(g_SapperModel[client])) return;

	ClearTimer(tTimerLoop);
	ClearTimer(tTimerSap);
	new String:Name[128];
	GetEntPropString(g_SapperModel[client], Prop_Data, "m_iName", Name, 128, 0);
	if(StrEqual(Name, "tf2sapper%d"))
	{
		AcceptEntityInput(g_SapperModel[client], "Kill");

		new Float:SapperPos[3];
		GetEntPropVector(g_SapperModel[client], Prop_Data, "m_vecAbsOrigin", SapperPos);

		ShowParticle(EFFECT_CORE_FLASH, 1.0, SapperPos);
		ShowParticle(EFFECT_DEBRIS, 1.0, SapperPos);
		ShowParticle(EFFECT_FLASH, 1.0, SapperPos);
		ShowParticle(EFFECT_FLASHUP, 1.0, SapperPos);
		ShowParticle(EFFECT_FLYINGEMBERS, 1.0, SapperPos);
		ShowParticle(EFFECT_SMOKE, 1.0, SapperPos);

		StopSound(g_SapperModel[client], 0, SOUND_BOOT);
		EmitSoundToAll(SOUND_SAPPER_REMOVED, g_SapperModel[client], _, _, _, 1.0);
	
		for(new i = 0; i < MAX_TARGET_BUILDING; i++)
		{
			if(IsValidEntity(g_TargetBuilding[client][i]) && g_TargetBuilding[client][i] > 0)
			{
				StopSound(g_TargetBuilding[client][i], 0, SOUND_SAPPER_NOISE);
				StopSound(g_TargetBuilding[client][i], 0, SOUND_SAPPER_NOISE2);
				StopSound(g_TargetBuilding[client][i], 0, SOUND_SAPPER_PLANT);
				
				SetEntProp(g_TargetBuilding[client][i], Prop_Send, "m_bDisabled", 0);
				g_TargetBuilding[client][i] = 0;
				g_SoundCount[i] = 0;
			}
		}
	}
}