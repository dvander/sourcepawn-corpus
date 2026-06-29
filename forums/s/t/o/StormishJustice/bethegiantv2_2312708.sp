#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <betherobot>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "2.0b"

public Plugin:myinfo = 
{
	name        = "Be a Giant Mann",
	author      = "Deathreus and Remade by StormishJustice",
	description = "Become a giant tiny robot",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?t=261260&page=4"
}

/*		Stolen from: 			*/
/* 		xXDeathreusXx			*/
/*								*/

new RobotStatus:Status[MAXPLAYERS+1];
new Float:LastTransformTime[MAXPLAYERS+1];
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };
new bool:Locked1[MAXPLAYERS+1], bool:Locked2[MAXPLAYERS+1], bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];
new String:classname[64], String:Mdl[PLATFORM_MAX_PATH];

new /*Handle:cvarFootsteps,*/ Handle:cvarSounds, Handle:cvarTaunts, Handle:cvarCooldown,/*
Handle:cvarFileExists,*/ Handle:cvarWearables, Handle:cvarWearablesKill;

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"
#define SOUND_GUN_FIRE				")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUN_SPIN				")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WIND_UP				")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WIND_DOWN				")mvm/giant_heavy/giant_heavy_gunwinddown.wav"
#define SOUND_DEATH					"mvm/sentrybuster/mvm_sentrybuster_explode.wav"

public OnPluginStart()
{
	RegAdminCmd("sm_begiant", Command_Giant, ADMFLAG_CHEATS);
	RegAdminCmd("sm_begiantrobot", Command_Giant, ADMFLAG_CHEATS);
	/*RegAdminCmd("sm_becphvy", Command_Heavy, ADMFLAG_CHEATS);
	RegAdminCmd("sm_bemcsol", Command_Soldier, ADMFLAG_CHEATS);*/

	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");

	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	CreateConVar("sm_bethegiant_version", PLUGIN_VERSION, "Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	//cvarFootsteps = CreateConVar("sm_bethegiant_footsteps", "1", "If on, players who are robots will make footstep sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSounds = CreateConVar("sm_bethegiant_sounds", "1", "If on, robots will emit robotic class sounds instead of their usual sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_bethegiant_taunts", "1", "If on, robots can taunt. Most robot taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	//cvarFileExists = CreateConVar("sm_bethegiant_fileexists", "1", "If on, any robot sound files must pass a check to see if they actually exist before being played. Recommended to the max. Only disable if robot sounds aren't working.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_bethegiant_cooldown", "2.0", "If greater than 0, players must wait this long between enabling/disabling robot on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarWearables = CreateConVar("sm_bethegiant_wearables", "1", "If on, wearable items will be rendered on robots.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearablesKill = CreateConVar("sm_bethegiant_wearables_kill", "0", "If on, and sm_betherobot_wearables is 0, wearables are removed from robots instead of being turned invisible.", FCVAR_NONE, true, 0.0, true, 1.0);

	HookConVarChange(cvarSounds, OnCvarChanged);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BeTheRobot_GetGiantStatus", Native_GetGiantStatus);
	CreateNative("BeTheRobot_SetGiant", Native_SetGiant);
	CreateNative("BeTheRobot_CheckGiantsRules", Native_CheckGiantsRules);
	RegPluginLibrary("betherobot");
	return APLRes_Success;
}

/*                                               */
/*-=-=-=-=-=-Below here are the events-=-=-=-=-=-*/
/*                                               */
public OnMapStart()
{
	for (new TFClassType:i = TFClass_Scout; i <= TFClass_Engineer; i++)
	{
		TF2_GetNameOfClass(i, classname, sizeof(classname));
		Format(Mdl, sizeof(Mdl), "models/bots/%s_boss/bot_%s_boss.mdl", Mdl, Mdl);
		PrecacheModel(Mdl, true);
	}
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(cvarSounds)) ComeOnPrecacheZeSounds();
}
public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		Status[i] = RobotStatus_Human;
		FixSounds(i);
	}
}

public OnClientConnected(client)
{
	LastTransformTime[client] = 0.0;
}
public OnClientDisconnect(client)
{
	LastTransformTime[client] = 0.0;
	FixSounds(client);
}

public OnPlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(Status[client] != RobotStatus_Human)
	{
		FixSounds(client);
		UpdatePlayerHitbox(client, 1.0);
		/*new weapon[2];
		weapon[0] = GetPlayerWeaponSlot(client, 0);
		weapon[1] = GetPlayerWeaponSlot(client, 2);
		TF2Attrib_RemoveAll(weapon[0]);
		TF2Attrib_RemoveAll(weapon[1]);
		if(Status[client] == RobotStatus_CaptainPunch || Status[client] == RobotStatus_MajorCrits)
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			new weapon[2];
			weapon[0] = GetPlayerWeaponSlot(client, 0);
			weapon[1] = GetPlayerWeaponSlot(client, 2);
			TF2Attrib_RemoveAll(weapon[0]);
			TF2Attrib_RemoveAll(weapon[1]);
			SetVariantString("");
			AcceptEntityInput(client, "SetCustomModel");
			Status[client] = RobotStatus_Human;
		}*/
		EmitSoundToAll(SOUND_DEATH, client, _, SNDLEVEL_DISHWASHER);
	}
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status[client] == RobotStatus_Giant/* 
	|| Status[client] == RobotStatus_MajorCrits 
	|| Status[client] == RobotStatus_CaptainPunch)*/ 
	&& !GetConVarBool(cvarTaunts)) return Plugin_Handled;

	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(Status[client] == RobotStatus_Giant)
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (LastTransformTime[client] + cooldown <= GetTickedTime()) immediate = true;
		ToggleGiant(client, false);
		if (immediate) LastTransformTime[client] = 0.0;
		ToggleGiant(client, true);
	}
	/*else if(Status[client] == RobotStatus_MajorCrits || Status[client] == RobotStatus_CaptainPunch)
	{
		FixSounds(client);
		UpdatePlayerHitbox(client, 1.0);
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		new weapon[2];
		weapon[0] = GetPlayerWeaponSlot(client, 0);
		weapon[1] = GetPlayerWeaponSlot(client, 2);
		TF2Attrib_RemoveAll(weapon[0]);
		TF2Attrib_RemoveAll(weapon[1]);
		TF2_RegeneratePlayer(client);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		Status[client] = RobotStatus_Human;
	}*/
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (Status[victim] == RobotStatus_Giant/* || Status[victim] == RobotStatus_MajorCrits || Status[victim] == RobotStatus_CaptainPunch)*/ && damagecustom == TF_CUSTOM_BACKSTAB)
	{
		new resEntity = GetPlayerResourceEntity();
		damage = float(GetEntProp(resEntity, Prop_Send, "m_iMaxHealth", _, victim)) / 8;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

/*                                                   */
/*-=-=-=-=-=-The commands that do commands-=-=-=-=-=-*/
/*                                                   */
public Action:Command_Giant(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a giant robot.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "begiant", ADMFLAG_GENERIC))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args > 1 && !CheckCommandAccess(client, "begiant_admin", ADMFLAG_CHEATS))
	{
		//if (!ToggleGiant(client)) ReplyToCommand(client, "[SM] You can't be a giant right now, but you'll be one as soon as you can.");
		ReplyToCommand(client, "[SM] You don't have access to targeting others.");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		if (args > 1)
		{
			GetCmdArg(2, arg2, sizeof(arg2));
			toggle = bool:StringToInt(arg2);
		}
	}
	if (args < 1)
		arg1 = "@me";	// Hacky workaround for the recent "Can't find valid target" error
	
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		if(!IsValidClass(target_list[i]))
		{
			ReplyToCommand(target_list[i], "[SM] Your class can't be a giant. Accepted classes are: Scout, Pyro, Heavy, Demo, Medic, Soldier");
			return Plugin_Handled;
		}
		ToggleGiant(target_list[i], toggle);
	}
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled being a giant on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled giant robot on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

/*public Action:Command_Heavy(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeCaptainPunch(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" into Captain Punch!", client, target_list[i]);
	}
	//EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

public Action:Command_Soldier(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
			arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeMajorCrits(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" into Major Crits!", client, target_list[i]);
	}
	return Plugin_Handled;
}*/

/*                                                                */
/*-=-=-=-=-=-Below here is where the sounds are defined-=-=-=-=-=-*/
/*-=-=-=-=-=-Sounds that will be played are found here-=-=-=-=-=- */
/*                                                                */

public Action:Timer_OnPlayerBecomeGiant(Handle:timer, any:client)
{
	//new client = GetClientOfUserId(userid);
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(Status[client] != RobotStatus_Giant || !GetConVarBool(cvarSounds))
		return Plugin_Stop;

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	UpdatePlayerHitbox(client, 1.75);
	
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	if(Status[client] == RobotStatus_Giant && GetConVarBool(cvarSounds))
	{
		if(class == TFClass_Scout || class == TFClass_Spy)
		{
			PrecacheSound(GIANTSCOUT_SND_LOOP);
			EmitSoundToAll(GIANTSCOUT_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Soldier || class == TFClass_Medic)
		{
			PrecacheSound(GIANTSOLDIER_SND_LOOP);
			EmitSoundToAll(GIANTSOLDIER_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_DemoMan || class == TFClass_Engineer)
		{
			PrecacheSound(GIANTDEMOMAN_SND_LOOP);
			EmitSoundToAll(GIANTDEMOMAN_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Heavy)
		{
			PrecacheSound(GIANTHEAVY_SND_LOOP);
			EmitSoundToAll(GIANTHEAVY_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Pyro || class == TFClass_Sniper)
		{
			PrecacheSound(GIANTPYRO_SND_LOOP);
			EmitSoundToAll(GIANTPYRO_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
	}
	
	return Plugin_Stop;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(cvarSounds) || !IsValidClient(Ent)) 
		return Plugin_Continue;

	new client = Ent;
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(Status[client] != RobotStatus_Giant/* && Status[client] != RobotStatus_MajorCrits && Status[client] != RobotStatus_CaptainPunch*/)
		return Plugin_Continue;

	if(StrContains(sound, "player/footsteps/", false) != -1)
	{
		if(class == TFClass_Medic)
			return Plugin_Handled;

		Format(sound, sizeof(sound), "^mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1,8));
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 25, _, 0.4, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons/fx/rics/arrow_impact_flesh", false) != -1)
	{
		Format(sound, sizeof(sound), "weapons/fx/rics/arrow_impact_metal0%i.wav", GetRandomInt(1,4));
		PrecacheSound(sound);
		pitch = GetRandomInt(90,100);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 75, _, 0.4, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "physics/flesh/flesh_impact_bullet", false) != -1)
	{
		Format(sound, sizeof(sound), "physics/metal/metal_solid_impact_bullet0%i.wav", GetRandomInt(1,4));
		PrecacheSound(sound);
		pitch = GetRandomInt(95,100);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, 0.4, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, ")weapons/rocket_", false) != -1)
	{
		ReplaceString(sound, sizeof(sound), ")weapons/", "mvm/giant_soldier/giant_soldier_");
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons\\quake_rpg_fire_remastered", false) != -1)
	{
		ReplaceString(sound, sizeof(sound), "weapons\\quake_rpg_fire_remastered", "mvm/giant_soldier/giant_soldier_rocket_shoot");
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons/minigun_", false) != -1)
	{
		ReplaceString(sound, sizeof(sound), "weapons/minigun_", "mvm/giant_heavy/giant_heavy_gun");
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons/minigun_shoot", false) != -1)
	{
		ReplaceString(sound, sizeof(sound), "weapons/minigun_shoot", "mvm/giant_heavy/giant_heavy_gunfire");
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons/minigun_wind_", false) != -1)
	{
		ReplaceString(sound, sizeof(sound), "weapons/minigun_", "mvm/giant_heavy/giant_heavy_gunwind");
		PrecacheSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}


	if (StrContains(sound, "vo/", false) == -1)
		return Plugin_Continue;
	if (StrContains(sound, "announcer", false) != -1)
		return Plugin_Continue;

	ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/mght/", false);
	ReplaceString(sound, sizeof(sound), "_", "_m_", false);
	if (StrContains(sound, "vo/", false) != -1)
		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
	new String:classname_mvm[15];
	TF2_GetNameOfClass(class, classname, sizeof(classname));
	Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
	ReplaceString(sound, sizeof(sound), classname, classname_mvm, false);
	new String:soundchk[PLATFORM_MAX_PATH];
	Format(soundchk, sizeof(soundchk), "sound/%s", sound);
	if (!FileExists(soundchk, true)) return Plugin_Continue;
	PrecacheSound(sound);
	return Plugin_Changed;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angle[3], &weapon)
{
	if (IsValidClient(client) && Status[client] == RobotStatus_Giant && (TF2_GetPlayerClass(client) == TFClass_Heavy || TF2_GetPlayerClass(client) == TFClass_Pyro)) 
	{	
		new eqweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		new iWeaponState = GetEntProp(eqweapon, Prop_Send, "m_iWeaponState");
		if(IsValidEntity(eqweapon) && TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			if (iWeaponState == 1 && !Locked1[client])
			{
				EmitSoundToAll(SOUND_WIND_UP, client);
				
				Locked1[client] = true;
				Locked2[client] = false;
				Locked3[client] = false;
				CanWindDown[client] = true;
				
				StopSnd(client, _, SOUND_GUN_SPIN);
				StopSnd(client, _, SOUND_GUN_FIRE);
			}
			else if (iWeaponState == 2 && !Locked2[client])
			{
				EmitSoundToAll(SOUND_GUN_FIRE, client);
				
				Locked2[client] = true;
				Locked1[client] = true;
				Locked3[client] = false;
				CanWindDown[client] = true;
				
				StopSnd(client, _, SOUND_GUN_SPIN);
				StopSnd(client, _, SOUND_WIND_UP);
			}
			else if (iWeaponState == 3 && !Locked3[client])
			{
				EmitSoundToAll(SOUND_GUN_SPIN, client);
				
				Locked3[client] = true;
				Locked1[client] = true;
				Locked2[client] = false;
				CanWindDown[client] = true;
				
				StopSnd(client, _, SOUND_GUN_FIRE);
				StopSnd(client, _, SOUND_WIND_UP);
			}
			else if (iWeaponState == 0)
			{
				if (CanWindDown[client])
				{
					EmitSoundToAll(SOUND_WIND_DOWN, client);
					CanWindDown[client] = false;
				}
				
				StopSnd(client, _, SOUND_GUN_SPIN);
				StopSnd(client, _, SOUND_GUN_FIRE);
				
				Locked1[client] = false;
				Locked2[client] = false;
				Locked3[client] = false;
			}
		}
	}
}
/*                                                             */
/*-=-=-=-=-=-Natives and stocks are below this point-=-=-=-=-=-*/
/*                                                             */

stock bool:ToggleGiant(client, bool:toggle = bool:2)
{
	if (Status[client] == RobotStatus_WantsToBeGiant && toggle != false && toggle != true) return true;
	if (!Status[client] && !toggle) return true;
	if (Status[client] == RobotStatus_Giant && toggle == true && CheckTheRules(client)) return true;
	if (!IsValidClass(client)) return false;

	if (!Status[client] || Status[client] == RobotStatus_WantsToBeRobot)
	{
		new bool:rightnow = true;
		if (!IsPlayerAlive(client)) rightnow = false;
		if (!CheckTheRules(client)) rightnow = false;
		if (!rightnow)
		{
			Status[client] = RobotStatus_WantsToBeGiant;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status[client] == RobotStatus_Human) || (toggle == bool:2 && Status[client] == RobotStatus_Robot) && IsValidClass(client))
	{
		TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
		
		Format(Mdl, sizeof(Mdl), "models/bots/%s_boss/bot_%s_boss.mdl", classname, classname);
		if(TF2_GetPlayerClass(client) == TFClass_Medic || TF2_GetPlayerClass(client) == TFClass_Sniper || TF2_GetPlayerClass(client) == TFClass_Engineer || TF2_GetPlayerClass(client) == TFClass_Spy)
			Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", classname, classname);
			
		ReplaceString(Mdl, sizeof(Mdl), "demoman", "demo", false);
		SetVariantString(Mdl);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Giant;
		
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		UpdatePlayerHitbox(client, 1.75);
		
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
		
		CreateTimer(0.0, Timer_OnPlayerBecomeGiant, client);
		CreateTimer(0.0, Timer_ModifyItems, client);
		SetHealth(client);
		
		SetWearableAlpha(client, 0);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == RobotStatus_Giant)) // Can possibly just be else. I am not good with logic.
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Human;
		SetWearableAlpha(client, 255);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		FixSounds(client);
		g_fClientCurrentScale[client] = 1.0;
		UpdatePlayerHitbox(client, 1.0);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", GetClassMaxHealth(client));
		SetEntProp(client, Prop_Send, "m_iHealth", GetClassMaxHealth(client), 1);
		RemoveAttributes(client);
		TF2Attrib_RemoveByName(client, "aiming movespeed increased");
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		TF2_RegeneratePlayer(client);
	}
	return true;
}

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue)) ComeOnPrecacheZeSounds();
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

public Native_GetGiantStatus(Handle:plugin, args)
	return _:Status[GetNativeCell(1)];

public Native_SetGiant(Handle:plugin, args)
	ToggleGiant(GetNativeCell(1), bool:GetNativeCell(2));

public Native_CheckGiantsRules(Handle:plugin, args)
	return CheckTheRules(GetNativeCell(1));

stock bool:CheckTheRules(client)
{
	if (!IsPlayerAlive(client)) return false;
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting) ||
	TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	if (cooldowntime > 0.0 && (LastTransformTime[client] + cooldowntime) > GetTickedTime()) return false;
	return true;
}

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

stock IsValidClass(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Pyro 
		|| TF2_GetPlayerClass(client) == TFClass_Heavy 
		|| TF2_GetPlayerClass(client) == TFClass_Soldier 
		|| TF2_GetPlayerClass(client) == TFClass_DemoMan 
		|| TF2_GetPlayerClass(client) == TFClass_Scout 
		|| TF2_GetPlayerClass(client) == TFClass_Medic 
		|| TF2_GetPlayerClass(client) == TFClass_Engineer 
		|| TF2_GetPlayerClass(client) == TFClass_Spy 
		|| TF2_GetPlayerClass(client) == TFClass_Sniper 
		|| TF2_GetPlayerClass(client) == TFClass_Unknown)
		return true;
	
	return false;
}

public Action:Timer_HalfSecond(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		else if (Status[i] == RobotStatus_WantsToBeGiant) ToggleGiant(i, true);
	}
}

stock SetHealth(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout: SetEntProp(client, Prop_Send, "m_iHealth", 1600, 1);
		case TFClass_Soldier: SetEntProp(client, Prop_Send, "m_iHealth", 3800, 1);
		case TFClass_Pyro: SetEntProp(client, Prop_Send, "m_iHealth", 3000, 1);
		case TFClass_DemoMan: SetEntProp(client, Prop_Send, "m_iHealth", 3300, 1);
		case TFClass_Heavy: SetEntProp(client, Prop_Send, "m_iHealth", 5000, 1);
		case TFClass_Engineer: SetEntProp(client, Prop_Send, "m_iHealth", 3250, 1);
		case TFClass_Medic: SetEntProp(client, Prop_Send, "m_iHealth", 4500, 1);
		case TFClass_Sniper: SetEntProp(client, Prop_Send, "m_iHealth", 3360, 1);
		case TFClass_Spy: SetEntProp(client, Prop_Send, "m_iHealth", 2467, 1);
	}
}

public Action:Timer_ModifyItems(Handle:timer, any:client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Soldier: SetAttributes(client, 3800.0, _, 0.4, 0.4, 3.0);
		case TFClass_Pyro: SetAttributes(client, _, _, 0.6, 0.6, 6.0);
		case TFClass_Scout: SetAttributes(client, 1600.0, 1.0, 0.7, 0.7, 5.0);
		case TFClass_DemoMan: SetAttributes(client, 3300.0, _, 0.5, 0.5, 4.0);
		case TFClass_Heavy: SetAttributes(client, 5000.0, _, 0.3, 0.3, 2.0);
		case TFClass_Engineer: SetAttributes(client, 3250.0, _, 0.6, 0.6, 3.0);
		case TFClass_Medic: SetAttributes(client, 4500.0, _, 0.6, 0.6, 0.0);
		case TFClass_Sniper: SetAttributes(client, 3360.0, _, 0.5, 0.5, 3.0);
		case TFClass_Spy: SetAttributes(client, 2467.0, _, 0.6, 0.6, 5.0);
	}
}

stock SetAttributes(client, Float:Health = 3000.0, Float:Speed = 0.5, Float:ForceReduct, Float:AirblastVuln, Float:Footstep)
{
	new ClientHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	new Float:NewHealth = Health-ClientHealth;
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth);
	
	TF2Attrib_SetByName(client, "damage force reduction", ForceReduct);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "overheal bonus", 0.0);
	TF2Attrib_SetByName(client, "move speed bonus", Speed);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", AirblastVuln);
	TF2Attrib_SetByName(client, "overheal fill rate reduced", 0.05);
	TF2Attrib_SetByName(client, "max health additive bonus", NewHealth);
	TF2Attrib_SetByName(client, "override footstep sound set", Footstep);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 1.5);
}

stock RemoveAttributes(client)
{
	new ClientHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	SetEntProp(client, Prop_Data, "m_iMaxHealth", ClientHealth);
	
	TF2Attrib_RemoveByName(client, "damage force reduction");
	TF2Attrib_RemoveByName(client, "health from packs decreased");
	TF2Attrib_RemoveByName(client, "move speed bonus");
	TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier");
	TF2Attrib_RemoveByName(client, "overheal fill rate reduced");
	TF2Attrib_RemoveByName(client, "max health additive bonus");
	TF2Attrib_RemoveByName(client, "override footstep sound set");
	TF2Attrib_RemoveByName(client, "ammo regen");
	TF2Attrib_RemoveByName(client, "cannot be backstabbed");
	TF2Attrib_RemoveByName(client, "aiming movespeed increased");
}

/*MakeCaptainPunch(client)
{
	TF2_SetPlayerClass(client, TFClass_Heavy);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	CreateTimer(0.0, Timer_OnPlayerBecomeGiant, GetClientUserId(client));
	Format(Mdl, sizeof(Mdl), "models/bots/heavy_boss/bot_heavy_boss.mdl");
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 0);
	
	SetEntProp(client, Prop_Send, "m_iHealth", 50000, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", 50000, 1);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.6);
	UpdatePlayerHitbox(client, 1.6);
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	Status[client] = RobotStatus_CaptainPunch;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

stock GiveFists(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2); 
	
	TF2Attrib_SetByName(weapon, "max health additive bonus", 49700.0);
	TF2Attrib_SetByName(weapon, "damage bonus", 3.0);
	TF2Attrib_SetByName(weapon, "move speed bonus", 0.4);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.0);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(weapon, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(weapon, "health regen", 300.0);
	TF2Attrib_SetByName(weapon, "airblast vertical vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(weapon, "health from healers reduced", 0.0);
}

MakeMajorCrits(client)
{
	TF2_SetPlayerClass(client, TFClass_Soldier);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	CreateTimer(0.0, Timer_OnPlayerBecomeGiant, GetClientUserId(client));
	Format(Mdl, sizeof(Mdl), "models/bots/soldier_boss/bot_soldier_boss.mdl");
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
   
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 2);
	TF2_RemoveWeaponSlot(client, 1);
   
	SetEntProp(client, Prop_Send, "m_iHealth", 40000, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", 40000, 1);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.9);
	UpdatePlayerHitbox(client, 1.9);
	TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
   
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritOnFirstBlood, -1.0);
	Status[client] = RobotStatus_MajorCrits;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

stock GiveRocket(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0);
   
	TF2Attrib_SetByName(weapon, "max health additive bonus", 39800.0);
	TF2Attrib_SetByName(weapon, "ammo regen", 100.0);
	TF2Attrib_SetByName(weapon, "clip size upgrade atomic", 26.0);
	TF2Attrib_SetByName(weapon, "fire rate bonus", 0.2);
	TF2Attrib_SetByName(weapon, "move speed bonus", 0.4);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.0);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(weapon, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(weapon, "faster reload rate", 0.4);
	TF2Attrib_SetByName(weapon, "projectile spread angle penalty", 5.0);
	TF2Attrib_SetByName(weapon, "health regen", 200.0);
	TF2Attrib_SetByName(weapon, "airblast vertical vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(weapon, "maxammo primary increased", 6.0);
	TF2Attrib_SetByName(weapon, "health from healers reduced", 0.0);
	TF2Attrib_SetByName(weapon, "Projectile speed increased", 0.4);
}*/

/*public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		if(Status[client] == RobotStatus_CaptainPunch)
			GiveFists(client);
		else if(Status[client] == RobotStatus_MajorCrits)
			GiveRocket(client);
	}
}*/

GetClassMaxHealth(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new Health;
	switch(class)
	{
		case TFClass_Scout: Health = 125;
		case TFClass_Soldier: Health = 200;
		case TFClass_Pyro: Health = 175;
		case TFClass_DemoMan: Health = 175;
		case TFClass_Heavy: Health = 300;
		case TFClass_Medic: Health = 150;
	}
	return Health;
}

stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

stock bool:IsHumanVoice(String:sound[])
{
	if(StrContains(sound, "vo/demoman_", false) != -1
	|| StrContains(sound, "vo/engineer_", false) != -1
	|| StrContains(sound, "vo/heavy_", false) != -1
	|| StrContains(sound, "vo/medic_", false) != -1
	|| StrContains(sound, "vo/pyro_", false) != -1
	|| StrContains(sound, "vo/scout_", false) != -1
	|| StrContains(sound, "vo/sniper_", false) != -1
	|| StrContains(sound, "vo/soldier_", false) != -1
	|| StrContains(sound, "vo/spy_", false) != -1
	|| StrContains(sound, "vo/taunts/", false) != -1)
		return true;

	return false;
}

stock SetWearableAlpha(client, alpha, bool:override = false)
{
	if (GetConVarBool(cvarWearables) && !override) return 0;
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		if (!GetConVarBool(cvarWearablesKill))
		{
			SetEntityRenderMode(z, RENDER_TRANSCOLOR);
			SetEntityRenderColor(z, 255, 255, 255, alpha);
		}
		else if (alpha == 0) AcceptEntityInput(z, "Kill");
		count++;
	}
	return count;
}

stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
   
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
   
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
   
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock FixSounds(entity)
{
	if(entity <= 0 || !IsValidEntity(entity))
		return;
	
	StopSnd(entity, _, GIANTSCOUT_SND_LOOP);
	StopSnd(entity, _, GIANTSOLDIER_SND_LOOP);
	StopSnd(entity, _, GIANTPYRO_SND_LOOP);
	StopSnd(entity, _, GIANTDEMOMAN_SND_LOOP);
	StopSnd(entity, _, GIANTHEAVY_SND_LOOP);
}

stock StopSnd(client, channel = SNDCHAN_AUTO, const String:sound[PLATFORM_MAX_PATH])
{
	if(!IsValidEntity(client))
		return;
	StopSound(client, channel, sound);
}

/*stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new String:wepclassname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}*/

/*stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, ";", atts, 32, 32);

	if(count%2!=0)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for(new i=0; i<count; i+=2)
		{
			new attrib = StringToInt(atts[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}
			
			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}*/

ComeOnPrecacheZeSounds()
{
	for (new i = 1; i <= 8; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/giant_common/giant_common_step_0%i.mp3", i);
		PrecacheSound(snd, true);
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
	PrecacheSound(SOUND_DEATH, true);
}