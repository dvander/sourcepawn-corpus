#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
//#include <betherobot>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "1.6.0"

public Plugin:myinfo = 
{
	name        = "Be the Giant",
	author      = "Deathreus",
	description = "Mighty robot!",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=2283714"
}

/*Shamelessly stolen code from: */
/* 		MasterOfTheXP			*/
/* 		Leonardo				*/
/* 		FlaminSarge				*/
/* 		Pelipoika				*/
/*								*/

enum RobotStatus {
	RobotStatus_Human = 0, // Client is human
	RobotStatus_WantsToBeRobot, // Client wants to be robot, but can't because of defined rules.
	RobotStatus_Robot, // Client is a robot. Beep boop.
	RobotStatus_WantsToBeGiant,
	RobotStatus_Giant
}
new RobotStatus:Status[MAXPLAYERS+1];
new Float:g_flLastTransformTime[MAXPLAYERS+1], Float:flStepThen[MAXPLAYERS+1];
new bool:Locked1[MAXPLAYERS+1], bool:Locked2[MAXPLAYERS+1], bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];

new Handle:cvarSounds, Handle:cvarTaunts, Handle:cvarCooldown;

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"
#define SOUND_GUN_FIRE				")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUN_SPIN				")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WIND_UP				")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WIND_DOWN				")mvm/giant_heavy/giant_heavy_gunwinddown.wav"
#define SOUND_GRENADE				"^mvm/giant_demoman/giant_demoman_grenade_shoot.wav"
#define SOUND_ROCKET				"mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define SOUND_EXPLOSION				"mvm/giant_soldier/giant_soldier_rocket_explode.wav"
#define SOUND_FLAME_START			"^mvm/giant_pyro/giant_pyro_flamethrower_start.wav"
#define SOUND_FLAME_LOOP			"^mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_DEATH					"mvm/giant_common/giant_common_explodes_01.wav"

public OnPluginStart()
{
	RegAdminCmd("sm_giant", Command_Giant, ADMFLAG_GENERIC);
	RegAdminCmd("sm_giantrobot", Command_Giant, ADMFLAG_GENERIC);

	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");

	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	CreateConVar("sm_bethegiant_version", PLUGIN_VERSION, "Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	cvarSounds = CreateConVar("sm_bethegiant_sounds", "1", "If on, robots will emit robotic class sounds instead of their usual sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_bethegiant_taunts", "1", "If on, robots can taunt. Most robot taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_bethegiant_cooldown", "2.0", "If greater than 0, players must wait this long between enabling/disabling robot on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/*                                               */
/*-=-=-=-=-=-Below here are the events-=-=-=-=-=-*/
/*                                               */
public OnMapStart()
{
	new String:sModel[PLATFORM_MAX_PATH], String:sClassname[PLATFORM_MAX_PATH];
	for (new TFClassType:iClass = TFClass_Scout; iClass <= TFClass_Engineer; iClass++)
	{
		TF2_GetNameOfClass(iClass, sClassname, sizeof(sClassname));
		Format(sModel, sizeof(sModel), "models/bots/%s_boss/bot_%s_boss.mdl", sClassname, sClassname);
		PrecacheModel(sModel, true);
	}
	
	PrecacheSounds();
}
public OnMapEnd()
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		Status[iClient] = RobotStatus_Human;
		g_flLastTransformTime[iClient] = 0.0;
		flStepThen[iClient] = 0.0;
		Locked1[iClient] = false;
		Locked2[iClient] = false;
		Locked3[iClient] = false;
		CanWindDown[iClient] = false;
		FixSounds(iClient);
	}
}

public OnClientConnected(iClient)
{
	g_flLastTransformTime[iClient] = 0.0;
	flStepThen[iClient] = 0.0;
	Locked1[iClient] = false;
	Locked2[iClient] = false;
	Locked3[iClient] = false;
	CanWindDown[iClient] = false;
	FixSounds(iClient);
}
public OnClientDisconnect(iClient)
{
	g_flLastTransformTime[iClient] = 0.0;
	flStepThen[iClient] = 0.0;
	Locked1[iClient] = false;
	Locked2[iClient] = false;
	Locked3[iClient] = false;
	CanWindDown[iClient] = false;
	FixSounds(iClient);
}

public OnPlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(Status[iClient] != RobotStatus_Human)
	{
		FixSounds(iClient);
		UpdatePlayerHitbox(iClient, 1.0);
		EmitSoundToAll(SOUND_DEATH, iClient, _, SNDLEVEL_DISHWASHER);
	}
}

public Action:Listener_taunt(iClient, const String:command[], args)
{
	if (Status[iClient] == RobotStatus_Giant && !GetConVarBool(cvarTaunts))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(Status[iClient] == RobotStatus_Giant)
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (g_flLastTransformTime[iClient] + cooldown <= GetTickedTime()) immediate = true;
		ToggleGiant(iClient, false);
		if (immediate) g_flLastTransformTime[iClient] = 0.0;
		ToggleGiant(iClient, true);
	}
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamagetype, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamagecustom)
{
	if (Status[iVictim] == RobotStatus_Giant && iDamagecustom == TF_CUSTOM_BACKSTAB)
	{
		flDamage = float(GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iVictim)) / 8;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

/*                                                   */
/*-=-=-=-=-=-The commands that do commands-=-=-=-=-=-*/
/*                                                   */
public Action:Command_Giant(iClient, nArgs)
{
	if (!iClient && !nArgs)
	{
		new String:arg0[24];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(iClient, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a giant robot.", arg0);
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (nArgs > 1 && !CheckCommandAccess(iClient, "giant_admin", ADMFLAG_CHEATS))
	{
		//if (!ToggleGiant(iClient)) ReplyToCommand(iClient, "[SM] You can't be a giant right now, but you'll be one as soon as you can.");
		ReplyToCommand(iClient, "[SM] You don't have access to targeting others.");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		if (nArgs > 1)
		{
			GetCmdArg(2, arg2, sizeof(arg2));
			toggle = bool:StringToInt(arg2);
		}
	}
	if (nArgs < 1)
		arg1 = "@me";	// ¯\_(ツ)_/¯ simpler
	
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, (nArgs < 1) ? COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY : COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		if(!IsValidClass(TF2_GetPlayerClass(target_list[i])))
		{
			ReplyToCommand(iClient, "[SM] They can't be a giant. Accepted classes are: Scout, Pyro, Heavy, Demo, Medic, Soldier");
			return Plugin_Handled;
		}
		ToggleGiant(target_list[i], toggle);
	}
	if (toggle != false && toggle != true) ShowActivity2(iClient, "[SM] ", "Toggled being a giant on %s.", target_name);
	else ShowActivity2(iClient, "[SM] ", "%sabled giant robot on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

/*                                                                */
/*-=-=-=-=-=-Below here is where the sounds are defined-=-=-=-=-=-*/
/*-=-=-=-=-=-Sounds that will be played are found here-=-=-=-=-=- */
/*                                                                */

public OnEntityCreated(iEntity, const String:sEntClass[])
{
	if(StrEqual(sEntClass, "tf_projectile_pipe"))
	{
		SDKHook(iEntity, SDKHook_Spawn, OnPipeCreated);
	}
	if(StrEqual(sEntClass, "tf_projectile_rocket"))
	{
		SDKHook(iEntity, SDKHook_Spawn, OnRocketCreated);
	}
}

public OnPipeCreated(iEntity)
{
	new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(iClient) && Status[iClient] == RobotStatus_Giant)
	{
		EmitSoundToAll(SOUND_GRENADE, iClient, SNDCHAN_WEAPON);
	}
}

public OnRocketCreated(iEntity)
{
	new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(iClient) && Status[iClient] == RobotStatus_Giant)
	{
		EmitSoundToAll(SOUND_ROCKET, iClient, SNDCHAN_WEAPON);
	}
}

public OnEntityDestroyed(iEntity)
{
	decl String:sClassname[96];
	if(GetEntityClassname(iEntity, sClassname, sizeof(sClassname)) && (!strcmp(sClassname, "tf_projectile_pipe") || !strcmp(sClassname, "tf_projectile_rocket")))
	{
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher");
		if(IsValidClient(iClient))
			if(Status[iClient] == RobotStatus_Giant)
				EmitSoundToAll(SOUND_EXPLOSION, iEntity, SNDCHAN_WEAPON);
	}
}

public Action:Timer_OnPlayerBecomeGiant(Handle:hTimer, any:iClient)
{
	if(Status[iClient] != RobotStatus_Giant || !GetConVarBool(cvarSounds) || !IsValidClient(iClient))
		return Plugin_Stop;

	SetEntPropFloat(iClient, Prop_Send, "m_flModelScale", 1.6);
	UpdatePlayerHitbox(iClient, 1.6);

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	switch(iClass)
	{
		case TFClass_Scout:
			EmitSoundToAll(GIANTSCOUT_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER, SND_CHANGEVOL, 0.45);
		case TFClass_Soldier,TFClass_Medic:
			EmitSoundToAll(GIANTSOLDIER_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER, SND_CHANGEVOL, 0.45);
		case TFClass_DemoMan:
			EmitSoundToAll(GIANTDEMOMAN_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER, SND_CHANGEVOL, 0.45);
		case TFClass_Heavy:
			EmitSoundToAll(GIANTHEAVY_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER, SND_CHANGEVOL, 0.45);
		case TFClass_Pyro:
			EmitSoundToAll(GIANTPYRO_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER, SND_CHANGEVOL, 0.45);
	}
	
	return Plugin_Handled;
}

public Action:SoundHook(iClients[64], &numClients, String:sSound[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &fFlags)
{
	if (!GetConVarBool(cvarSounds) || !IsValidEntity(iEntity)) 
		return Plugin_Continue;

	decl String:sClassName[96];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
	if(!strcmp(sClassName, "tf_projectile_pipe") || !strcmp(sClassName, "tf_projectile_rocket"))
	{
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher");
		if(!IsValidClient(iClient) || Status[iClient] != RobotStatus_Giant)
			return Plugin_Continue;
		
		if(StrContains(sSound, ")weapons/pipe_bomb", false) != -1 || StrContains(sSound, ")weapons/explode", false) != -1)
			return Plugin_Stop;
	}
	
	if(!strcmp(sClassName, "tf_weapon_grenadelauncher") || !strcmp(sClassName, "tf_weapon_rocketlauncher"))
	{
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(!IsValidClient(iClient) || Status[iClient] != RobotStatus_Giant)
			return Plugin_Continue;
	
		if(StrContains(sSound, ")weapons/grenade_launcher_shoot", false) != -1 || StrContains(sSound, ")weapons/rocket_shoot", false) != -1)
			return Plugin_Stop;
	}
	
	new iClient = iEntity;
	if(!IsValidClient(iClient) || Status[iClient] != RobotStatus_Giant)
		return Plugin_Continue;

	if(StrContains(sSound, "weapons/fx/rics/arrow_impact_flesh", false) != -1)
	{
		Format(sSound, sizeof(sSound), "weapons/fx/rics/arrow_impact_metal%i.wav", GetRandomInt(2,4));
		iPitch = GetRandomInt(90,100);
		EmitSoundToAll(sSound, iClient, SNDCHAN_STATIC, 120, SND_CHANGEVOL, 0.85, iPitch);
		return Plugin_Stop;
	}
	else if(StrContains(sSound, "physics/flesh/flesh_impact_bullet", false) != -1)
	{
		Format(sSound, sizeof(sSound), "physics/metal/metal_solid_impact_bullet%i.wav", GetRandomInt(1,4));
		iPitch = GetRandomInt(95,100);
		EmitSoundToAll(sSound, iClient, SNDCHAN_STATIC, 95, SND_CHANGEVOL, 0.75, iPitch);
		return Plugin_Stop;
	}

	if (StrContains(sSound, "vo/", false) == -1 || StrContains(sSound, "announcer", false) != -1)
		return Plugin_Continue;

	ReplaceString(sSound, sizeof(sSound), "vo/", "vo/mvm/norm/", false);
	ReplaceString(sSound, sizeof(sSound), ".wav", ".mp3", false);
	
	new String:sClassname_MVM[12], String:sClassname[12];
	TF2_GetNameOfClass(TF2_GetPlayerClass(iClient), sClassname, sizeof(sClassname));
	ReplaceString(sClassname, sizeof(sClassname), "demo", "demoman", true);
	Format(sClassname_MVM, sizeof(sClassname_MVM), "%s_mvm", sClassname);
	ReplaceString(sSound, sizeof(sSound), sClassname, sClassname_MVM, false);
	PrecacheSound(sSound);
	return Plugin_Changed;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:flVelocity[3], Float:flAngle[3], &iWeapon)
{
	if (IsValidClient(iClient) && Status[iClient] == RobotStatus_Giant) 
	{
		new TFClassType:iClass = TF2_GetPlayerClass(iClient);
		if(iClass == TFClass_Heavy || iClass == TFClass_Pyro)
		{
			new EqWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
			if(IsValidEntity(EqWeapon))
			{
				new iWeaponState = GetEntProp(EqWeapon, Prop_Send, "m_iWeaponState");
				if(iClass == TFClass_Heavy)
				{
					if (iWeaponState == 1 && !Locked1[iClient])
					{
						EmitSoundToAll(SOUND_WIND_UP, iClient, SNDCHAN_WEAPON);
						
						Locked1[iClient] = true;
						Locked2[iClient] = false;
						Locked3[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_SPIN);
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_FIRE);
					}
					else if (iWeaponState == 2 && !Locked2[iClient])
					{
						EmitSoundToAll(SOUND_GUN_FIRE, iClient, SNDCHAN_WEAPON);
						
						Locked2[iClient] = true;
						Locked1[iClient] = true;
						Locked3[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_SPIN);
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_WIND_UP);
					}
					else if (iWeaponState == 3 && !Locked3[iClient])
					{
						EmitSoundToAll(SOUND_GUN_SPIN, iClient, SNDCHAN_WEAPON);
						
						Locked3[iClient] = true;
						Locked1[iClient] = true;
						Locked2[iClient] = false;
						CanWindDown[iClient] = true;
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_FIRE);
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_WIND_UP);
					}
					else if (iWeaponState == 0)
					{
						if (CanWindDown[iClient])
						{
							EmitSoundToAll(SOUND_WIND_DOWN, iClient, SNDCHAN_WEAPON);
							CanWindDown[iClient] = false;
						}
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_SPIN);
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_GUN_FIRE);
						
						Locked1[iClient] = false;
						Locked2[iClient] = false;
						Locked3[iClient] = false;
					}
				}
				if(iClass == TFClass_Pyro)
				{
					if (iWeaponState == 1 && !Locked1[iClient])
					{
						EmitSoundToAll(SOUND_FLAME_START, iClient, SNDCHAN_WEAPON);
						
						Locked1[iClient] = true;
						Locked2[iClient] = false;
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_FLAME_LOOP);
					}
					else if (iWeaponState == 2 && !Locked2[iClient])
					{
						EmitSoundToAll(SOUND_FLAME_LOOP, iClient, SNDCHAN_WEAPON);
						
						Locked2[iClient] = true;
						Locked1[iClient] = true;
						
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_FLAME_START);
					}
					else if (iWeaponState == 0)
					{
						Locked1[iClient] = false;
						Locked2[iClient] = false;
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_FLAME_LOOP);
						StopSound(iClient, SNDCHAN_WEAPON, SOUND_FLAME_START);
					}
				}
			}
		}
	}
}

/*                                                             */
/*-=-=-=-=-=-Natives and stocks are below this point-=-=-=-=-=-*/
/*                                                             */

stock bool:ToggleGiant(iClient, bool:toggle = bool:2)
{
	if (Status[iClient] == RobotStatus_WantsToBeGiant && toggle != false && toggle != true) return true;
	if (!Status[iClient] && !toggle) return true;
	if (Status[iClient] == RobotStatus_Giant && toggle == true && CheckTheRules(iClient)) return true;
	if (!IsValidClass(TF2_GetPlayerClass(iClient))) return false;

	if (!Status[iClient] || Status[iClient] == RobotStatus_WantsToBeRobot)
	{
		new bool:rightnow = true;
		if (!IsPlayerAlive(iClient)) rightnow = false;
		if (!CheckTheRules(iClient)) rightnow = false;
		if (!rightnow)
		{
			Status[iClient] = RobotStatus_WantsToBeGiant;
			return false;
		}
	}
	
	static Float:fOldStepTime;
	static Float:fOldStepSize;
	if (toggle && (Status[iClient] == RobotStatus_Human || Status[iClient] == RobotStatus_Robot) && IsValidClass(TF2_GetPlayerClass(iClient)))
	{
		decl String:sClassname[12];
		TF2_GetNameOfClass(TF2_GetPlayerClass(iClient), sClassname, sizeof(sClassname));
		
		decl String:sModel[PLATFORM_MAX_PATH];
		Format(sModel, sizeof(sModel), "models/bots/%s_boss/bot_%s_boss.mdl", sClassname, sClassname);
		if(TF2_GetPlayerClass(iClient) == TFClass_Medic)
			Format(sModel, sizeof(sModel), "models/bots/medic/bot_medic.mdl");
		
		SetVariantString(sModel);
		AcceptEntityInput(iClient, "SetCustomModel");
		SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1);
		
		g_flLastTransformTime[iClient] = GetTickedTime();
		Status[iClient] = RobotStatus_Giant;
		
		SetVariantString("1.6");
		AcceptEntityInput(iClient, "SetModelScale");
		
		new weapon = GetPlayerWeaponSlot(iClient, 2);
		TF2Attrib_RemoveByDefIndex(weapon, 128);
		
		CreateTimer(0.05, Timer_OnPlayerBecomeGiant, iClient);
		CreateTimer(0.25, Timer_ModifyItems, iClient);
		
		SetWearableAlpha(iClient, 0);
		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		
		SetEntProp(iClient, Prop_Send, "m_bIsMiniBoss", 1);
		
		fOldStepTime = GetEntPropFloat(iClient, Prop_Data, "m_flStepSoundTime");
		fOldStepSize = GetEntPropFloat(iClient, Prop_Data, "m_flStepSize");
		
		SetEntPropFloat(iClient, Prop_Data, "m_flStepSize", fOldStepSize * 2.0);
		SetEntPropFloat(iClient, Prop_Data, "m_flStepSoundTime", fOldStepTime * 1.8);
	}
	else if (!toggle || (toggle == bool:2 && Status[iClient] == RobotStatus_Giant))
	{
		SetVariantString("");
		AcceptEntityInput(iClient, "SetCustomModel");
		g_flLastTransformTime[iClient] = GetTickedTime();
		Status[iClient] = RobotStatus_Human;
		SetWearableAlpha(iClient, 255);
		FixSounds(iClient);
		SetVariantString("1.0");
		AcceptEntityInput(iClient, "SetModelScale");
		RemoveAttributes(iClient);
		SetEntProp(iClient, Prop_Send, "m_bIsMiniBoss", 0);
		SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		TF2_RegeneratePlayer(iClient);
		SetEntPropFloat(iClient, Prop_Data, "m_flStepSize", fOldStepSize);
		SetEntPropFloat(iClient, Prop_Data, "m_flStepSoundTime", fOldStepTime);
		TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.1);	// Force-Recalc their speed
	}
	return true;
}

public OnCvarChanged(Handle:hConvar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue)) PrecacheSounds();
}

public bool:Filter_Robots(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == RobotStatus_Giant) PushArrayCell(clients, i);
	}
	return true;
}

stock bool:CheckTheRules(iClient)
{
	if (!IsPlayerAlive(iClient)) return false;
	if (TF2_IsPlayerInCondition(iClient, TFCond_Taunting) || TF2_IsPlayerInCondition(iClient, TFCond_Dazed)) return false;
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	if (cooldowntime > 0.0 && (g_flLastTransformTime[iClient] + cooldowntime) > GetTickedTime()) return false;
	return true;
}

stock TF2_GetNameOfClass(TFClassType:iClass, String:sName[], iMaxlen)
{
	switch (iClass)
	{
		case TFClass_Scout: Format(sName, iMaxlen, "scout");
		case TFClass_Soldier: Format(sName, iMaxlen, "soldier");
		case TFClass_Pyro: Format(sName, iMaxlen, "pyro");
		case TFClass_DemoMan: Format(sName, iMaxlen, "demo");
		case TFClass_Heavy: Format(sName, iMaxlen, "heavy");
		case TFClass_Engineer: Format(sName, iMaxlen, "engineer");
		case TFClass_Medic: Format(sName, iMaxlen, "medic");
		case TFClass_Sniper: Format(sName, iMaxlen, "sniper");
		case TFClass_Spy: Format(sName, iMaxlen, "spy");
	}
}

stock bool:IsValidClass(TFClassType:iClass)
{
	return (iClass == TFClass_Pyro || iClass == TFClass_Heavy || iClass == TFClass_Soldier || iClass == TFClass_DemoMan || iClass == TFClass_Scout || iClass == TFClass_Medic);
}

public Action:Timer_HalfSecond(Handle:hTimer)
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient))
			continue;
			
		if (Status[iClient] == RobotStatus_WantsToBeGiant)
			ToggleGiant(iClient, true);
		else if (Status[iClient] != RobotStatus_Giant)
			FixSounds(iClient);
	}
}

public Action:Timer_ModifyItems(Handle:hTimer, any:iClient)
{
	switch(TF2_GetPlayerClass(iClient))
	{
		case TFClass_Soldier: SetAttributes(iClient, 3800, _, 0.4, 0.4, 3.0);
		case TFClass_Pyro: SetAttributes(iClient, _, _, 0.6, 0.6, 6.0);
		case TFClass_Scout: SetAttributes(iClient, 1600, 1.0, 0.7, 0.7, 5.0);
		case TFClass_DemoMan: SetAttributes(iClient, 3300, _, 0.5, 0.5, 4.0);
		case TFClass_Heavy: SetAttributes(iClient, 5000, 0.45, 0.3, 0.3, 2.0);
		case TFClass_Medic: SetAttributes(iClient, _, _, 0.6, 0.6);
	}
}

SetAttributes(iClient, iHealth = 3000, Float:flSpeed = 0.5, Float:flForceReduct, Float:flAirblastVuln, Float:flFootstep = 0.0)
{
	new iNewHealth = iHealth-GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
	
	TF2Attrib_SetByName(iClient, "damage force reduction", flForceReduct);
	TF2Attrib_SetByName(iClient, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(iClient, "move speed bonus", flSpeed);
	TF2Attrib_SetByName(iClient, "airblast vulnerability multiplier", flAirblastVuln);
	TF2Attrib_SetByName(iClient, "max health additive bonus", float(iNewHealth));
	
	if(flFootstep > 0.0)
		TF2Attrib_SetByName(iClient, "override footstep sound set", flFootstep);
	
	new iWeapon = GetPlayerWeaponSlot(iClient, 0);
	if(TF2_GetPlayerClass(iClient)==TFClass_Heavy)
		TF2Attrib_SetByName(iWeapon, "aiming movespeed increased", 2.0);
	
	TF2_SetHealth(iClient, iHealth);
	
	TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.1);	// Force-Recalc their speed
}

RemoveAttributes(iClient)
{
	TF2Attrib_RemoveByName(iClient, "damage force reduction");
	TF2Attrib_RemoveByName(iClient, "health from packs decreased");
	TF2Attrib_RemoveByName(iClient, "move speed bonus");
	TF2Attrib_RemoveByName(iClient, "airblast vulnerability multiplier");
	TF2Attrib_RemoveByName(iClient, "overheal fill rate reduced");
	TF2Attrib_RemoveByName(iClient, "max health additive bonus");
	TF2Attrib_RemoveByName(iClient, "override footstep sound set");
	
	new iWeapon = GetPlayerWeaponSlot(iClient, 0);
	if(TF2_GetPlayerClass(iClient)==TFClass_Heavy)
		TF2Attrib_RemoveByName(iWeapon, "aiming movespeed increased");
		
	TF2_RegeneratePlayer(iClient);
}

stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;

	return true;
}

stock bool:IsHumanVoice(String:sSound[])
{
	if(StrContains(sSound, "vo/demoman_", false) != -1
	|| StrContains(sSound, "vo/engineer_", false) != -1
	|| StrContains(sSound, "vo/heavy_", false) != -1
	|| StrContains(sSound, "vo/medic_", false) != -1
	|| StrContains(sSound, "vo/pyro_", false) != -1
	|| StrContains(sSound, "vo/scout_", false) != -1
	|| StrContains(sSound, "vo/sniper_", false) != -1
	|| StrContains(sSound, "vo/soldier_", false) != -1
	|| StrContains(sSound, "vo/spy_", false) != -1
	|| StrContains(sSound, "vo/taunts/", false) != -1)
		return true;

	return false;
}

stock SetWearableAlpha(iClient, iAlpha)
{
	new iCount, iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable*")) != -1)
	{
		new String:sBuffer[64];
		GetEntityClassname(iEntity, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "tf_wearable_demoshield")) continue;
		if (iClient != GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iEntity, 255, 255, 255, iAlpha);
		if (iAlpha == 0) AcceptEntityInput(iEntity, "Kill");
		iCount++;
	}
	return iCount;
}

stock TF2_SetHealth(iClient, iHealth)
{
	if(IsValidClient(iClient))
	{
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iClient, Prop_Data, "m_iHealth", iHealth);
	}
}

stock UpdatePlayerHitbox(iClient, const Float:flScale)
{
	new Float:vecPlayerMin[3]={-24.5, -25.5, 0.0}, Float:vecPlayerMax[3]={24.5, 24.5, 83.0};
	
	ScaleVector(vecPlayerMin, flScale);
	ScaleVector(vecPlayerMax, flScale);
   
	SetEntPropVector(iClient, Prop_Send, "m_vecSpecifiedSurroundingMins", vecPlayerMin);
	SetEntPropVector(iClient, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecPlayerMax);
}

FixSounds(iEntity)
{
	if(iEntity <= 0 || !IsValidEntity(iEntity))
		return;
	
	StopSnd(iEntity, GIANTSCOUT_SND_LOOP);
	StopSnd(iEntity, GIANTSOLDIER_SND_LOOP);
	StopSnd(iEntity, GIANTPYRO_SND_LOOP);
	StopSnd(iEntity, GIANTDEMOMAN_SND_LOOP);
	StopSnd(iEntity, GIANTHEAVY_SND_LOOP);
}

stock StopSnd(iEntity, const String:sSound[PLATFORM_MAX_PATH], iChannel = SNDCHAN_AUTO)
{
	if(!IsValidEntity(iEntity))
		return;
	StopSound(iEntity, iChannel, sSound);
}

PrecacheSounds()
{
	for(new i = 1; i < 9; i++)
	{
		decl String:sBuffer[PLATFORM_MAX_PATH];
		Format(sBuffer, sizeof(sBuffer), "^mvm/giant_common/giant_common_step_0%i.wav", i);
		PrecacheSound(sBuffer, true);
	}
	PrecacheSound(GIANTSCOUT_SND_LOOP, true);
	PrecacheSound(GIANTSOLDIER_SND_LOOP, true);
	PrecacheSound(GIANTPYRO_SND_LOOP, true);
	PrecacheSound(GIANTDEMOMAN_SND_LOOP, true);
	PrecacheSound(GIANTHEAVY_SND_LOOP, true);
	PrecacheSound(SOUND_GUN_FIRE, true);
	PrecacheSound(SOUND_GUN_SPIN, true);
	PrecacheSound(SOUND_WIND_UP, true);
	PrecacheSound(SOUND_WIND_DOWN, true);
	PrecacheSound(SOUND_GRENADE, true);
	PrecacheSound(SOUND_ROCKET, true);
	PrecacheSound(SOUND_EXPLOSION, true);
	PrecacheSound(SOUND_FLAME_START, true);
	PrecacheSound(SOUND_FLAME_LOOP, true);
	PrecacheSound(SOUND_DEATH, true);
}