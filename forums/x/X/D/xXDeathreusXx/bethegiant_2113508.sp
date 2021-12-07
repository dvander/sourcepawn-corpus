#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <betherobot>
#include <tf2items>
//#include <morecolors>

#define PLUGIN_VERSION "1.05"

public Plugin:myinfo = 
{
	name = "Be the Giant",
	author = "Deathreus, code snippets from MasterOfTheXP",
	description = "Mighty robot!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new RobotStatus:Status[MAXPLAYERS+1];
new Float:LastTransformTime[MAXPLAYERS+1];
//new Float:LastStun[MAXPLAYERS+1];
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };
new bool:g_bHitboxAvailable = false;
new bool:g_bIsTF2 = false;

new Handle:cvarFootsteps, Handle:cvarSounds, Handle:cvarTaunts, Handle:cvarCooldown,
Handle:cvarFileExists, Handle:cvarWearables, Handle:cvarWearablesKill, Handle:cvarGiantFlag;

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"
#define STUN_SND_1					"weapons/sapper_plant.wav"
#define STUN_SND_2					"weapons/sapper_timer.wav"
#define STUN_SND_3					"weapons/sapper_removed.wav"

public OnPluginStart()
{
	RegAdminCmd("sm_giant", Command_giant, ADMFLAG_CHEATS);
	RegAdminCmd("sm_giantrobot", Command_giant, ADMFLAG_CHEATS);
	
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	
	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	CreateConVar("sm_bethegiant_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarFootsteps = CreateConVar("sm_bethegiant_footsteps","1","If on, players who are robots will make footstep sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSounds = CreateConVar("sm_bethegiant_sounds","1","If on, robots will emit robotic class sounds instead of their usual sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_bethegiant_taunts","1","If on, robots can taunt. Most robot taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFileExists = CreateConVar("sm_bethegiant_fileexists","1","If on, any robot sound files must pass a check to see if they actually exist before being played. Recommended to the max. Only disable if robot sounds aren't working.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_bethegiant_cooldown","2.0","If greater than 0, players must wait this long between enabling/disabling robot on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarWearables = CreateConVar("sm_bethegiant_wearables","1","If on, wearable items will be rendered on robots.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearablesKill = CreateConVar("sm_bethegiant_wearables_kill","0","If on, and sm_betherobot_wearables is 0, wearables are removed from robots instead of being turned invisible.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarGiantFlag = CreateConVar("sm_bethegiant_flag","n","Flag to determine admin rights to use the !giant command", FCVAR_NONE);
	HookConVarChange(cvarSounds, OnCvarChanged);
	HookConVarChange(cvarGiantFlag, OnCvarChanged);
	
	AddMultiTargetFilter("@robots", Filter_Robots, "all robots", false);
	
	g_bHitboxAvailable = ((FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
	decl String:szDir[64];
	GetGameFolderName(szDir, sizeof(szDir));
	if (strcmp(szDir, "tf") == 0 || strcmp(szDir, "tf_beta") == 0)
		g_bIsTF2 = true;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BeTheRobot_GetRobotStatus", Native_GetRobotStatus);
	CreateNative("BeTheRobot_SetGiant", Native_SetGiant);
	CreateNative("BeTheRobot_CheckRules", Native_CheckRules);
	RegPluginLibrary("betherobot");
	return APLRes_Success;
}

public OnMapStart()
{
	new String:classname[10], String:Mdl[PLATFORM_MAX_PATH];
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
		if (Status[i] != RobotStatus_Giant) continue;
		Status[i] = RobotStatus_Human;
	}
}

public OnClientConnected(client)
{
	LastTransformTime[client] = 0.0;
	FixSounds(client);
}
public OnClientDisconnect(client)
{
	LastTransformTime[client] = 0.0;
	FixSounds(client);
}

public OnPlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	FixSounds(client);
	g_fClientCurrentScale[client] = 1.0;
	if (g_bHitboxAvailable)
		UpdatePlayerHitbox(client);
}

public OnPlayerSpawn(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	FixSounds(client);
	if(Status[client] == RobotStatus_Giant)
	{
		CreateTimer(0.1, Timer_OnPlayerBecomeGiant, GetClientUserId(client));
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.8);
		g_fClientCurrentScale[client] = 1.8;
		if (g_bHitboxAvailable)
			UpdatePlayerHitbox(client);
	}
}

/*public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;
	LastStun[client] = GetTickedTime();

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	if(buttons&IN_ATTACK)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			new index = -1;
	
			if(weapon && IsValidEdict(weapon))
			{
				index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				switch(index)
				{
					case 735, 736, 810, 831, 933, 1080:		// All the sappers
					{
						if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!= GetClientTeam(client))
						{
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
							distance = GetVectorDistance(pos, pos2);
							new Float:cooldown = 20.0, bool:immediate;
							if (LastStun[client] + cooldown <= GetTickedTime())
								immediate = true;
							else
								PrintToChat(client, "Please wait for the cooldown to expire before attempting to sap");
				
							if (distance < 400 && i != client && (immediate) && (Status[i] == RobotStatus_Giant || Status[i] == RobotStatus_Robot))
							{
								TF2_StunPlayer(i, Float:4.5, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
								TF2_AddCondition(i, TFCond_Sapped, Float:4.5);
								immediate = false;
								LastStun[client] = 0.0;

								CreateTimer(0.0, Timer_StunSound_1, GetClientUserId(i));
								CreateTimer(0.5, Timer_StunSound_2, GetClientUserId(i));
								CreateTimer(2.5, Timer_StunSound_2, GetClientUserId(i));
								CreateTimer(4.5, Timer_StunSound_3, GetClientUserId(i));
					
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Changed;
}
public Action:Timer_StunSound_1(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	decl Float:pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	
	if(GetConVarBool(cvarSounds))
		EmitSoundToAll(STUN_SND_1, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
}
public Action:Timer_StunSound_2(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	decl Float:pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	
	if(GetConVarBool(cvarSounds))
		EmitSoundToAll(STUN_SND_2, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
}
public Action:Timer_StunSound_3(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	decl Float:pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	
	if(GetConVarBool(cvarSounds))
		EmitSoundToAll(STUN_SND_3, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
}*/

public Action:Command_giant(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a giant robot.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "giant", 0) || !(cvarGiantFlag))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args < 1 || !CheckCommandAccess(client, "giant_admin", ADMFLAG_CHEATS))
	{
		if (!ToggleGiant(client)) ReplyToCommand(client, "[SM] You can't be a giant right now, but you'll be one as soon as you can.");
		if(!IsValidClass(client)) ReplyToCommand(client, "[SM] Your class can't be a giant. Accepted classes are: Scout, Pyro, Heavy, Demo, Medic, Soldier");
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
	
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
		ToggleGiant(target_list[i], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled being a giant on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled giant robot on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

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
		new String:classname[10];
		TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
		new String:Mdl[PLATFORM_MAX_PATH];
		
		Format(Mdl, sizeof(Mdl), "models/bots/%s_boss/bot_%s_boss.mdl", classname, classname);
		if(TF2_GetPlayerClass(client) == TFClass_Medic)
			Format(Mdl, sizeof(Mdl), "models/bots/medic/bot_medic.mdl");
			
		ReplaceString(Mdl, sizeof(Mdl), "demoman", "demo", false);
		SetVariantString(Mdl);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		CreateTimer(0.3, SetHealth, GetClientUserId(client));
		
		g_fClientCurrentScale[client] = 1.8;
		if (g_bHitboxAvailable)
			UpdatePlayerHitbox(client);
		
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Giant;
		
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.8);
		
		CreateTimer(0.1, Timer_OnPlayerBecomeGiant, GetClientUserId(client));
		CreateTimer(0.2, Timer_ModifyItems, GetClientUserId(client));
		
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == RobotStatus_Giant)) // Can possibly just be else. I am not good with logic.
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		LastTransformTime[client] = GetTickedTime();
		Status[client] = RobotStatus_Human;
		SetWearableAlpha(client, 255);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		FixSounds(client);
		g_fClientCurrentScale[client] = 1.0;
		TF2_RegeneratePlayer(client);
		if (g_bHitboxAvailable)
			UpdatePlayerHitbox(client);
	}
	return true;
}

stock IsValidClass(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Pyro 
		|| TF2_GetPlayerClass(client) == TFClass_Heavy 
		|| TF2_GetPlayerClass(client) == TFClass_Soldier
		|| TF2_GetPlayerClass(client) == TFClass_DemoMan 
		|| TF2_GetPlayerClass(client) == TFClass_Scout 
		|| TF2_GetPlayerClass(client) == TFClass_Medic)
		return true;
	else if(TF2_GetPlayerClass(client) == TFClass_Engineer 
		|| TF2_GetPlayerClass(client) == TFClass_Spy 
		|| TF2_GetPlayerClass(client) == TFClass_Sniper 
		|| TF2_GetPlayerClass(client) == TFClass_Unknown)
		return false;
	
	return false;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status[client] == RobotStatus_Giant && !GetConVarBool(cvarTaunts)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Status[client] == RobotStatus_Giant)
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (LastTransformTime[client] + cooldown <= GetTickedTime()) immediate = true;
		ToggleGiant(client, false);
		if (immediate) LastTransformTime[client] = 0.0;
		ToggleGiant(client, true);
	}
}

public Action:Timer_HalfSecond(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		else if (Status[i] == RobotStatus_WantsToBeGiant) ToggleGiant(i, true);
		if (Status[i] != RobotStatus_Giant) FixSounds(i);
	}
}

public Action:SetHealth(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (Status[client] == RobotStatus_Giant)
	{
		if(TF2_GetPlayerClass(client) == TFClass_Scout)
			SetEntityHealth(client, 1600);
		else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
			SetEntityHealth(client, 3800);
		else if(TF2_GetPlayerClass(client) == TFClass_Pyro)
			SetEntityHealth(client, 3000);
		else if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
			SetEntityHealth(client, 3300);
		else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
			SetEntityHealth(client, 5000);
		else if(TF2_GetPlayerClass(client) == TFClass_Medic)
			SetEntityHealth(client, 3000);
	}
}

public Action:Timer_ModifyItems(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(Status[client] != RobotStatus_Giant)
		return Plugin_Continue;

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_shovel", 128, 101, 5, "107 ; 0.5 ; 252 ; 0.4 ; 329 ; 0.4 ; 26 ; 3600");
	else if(TF2_GetPlayerClass(client)==TFClass_Pyro && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_fireaxe", 38, 101, 5, "107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 26 ; 2825");
	else if(TF2_GetPlayerClass(client)==TFClass_Scout && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_bat", 44, 101, 5, "252 ; 0.7 ; 329 ; 0.7 ; 26 ; 1490");
	else if(TF2_GetPlayerClass(client)==TFClass_DemoMan && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_sword", 132, 101, 5, "107 ; 0.5 ; 252 ; 0.5 ; 329 ; 0.5 ; 26 ; 3175");
	else if(TF2_GetPlayerClass(client)==TFClass_Heavy && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_fists", 331, 101, 5, "107 ; 0.5 ; 252 ; 0.3 ; 329 ; 0.3 ; 26 ; 4700");
	else if(TF2_GetPlayerClass(client)==TFClass_Medic && Status[client]==RobotStatus_Giant)
		SpawnWeapon(client, "tf_weapon_bonesaw", 37, 101, 5, "107 ; 0.5 ; 252 ; 0.6 ; 329 ; 0.6 ; 8 ; 100 ; 26 ; 2850");
	return Plugin_Continue;
}

public Action:Timer_OnPlayerBecomeGiant(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(Status[client] != RobotStatus_Giant || !GetConVarBool(cvarSounds))
		return Plugin_Stop;
	
	if(Status[client] == RobotStatus_Giant && GetConVarBool(cvarSounds))
	{
		if(class == TFClass_Scout)
		{
			PrecacheSound(GIANTSCOUT_SND_LOOP, true);
			EmitSoundToAll(GIANTSCOUT_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Soldier || class == TFClass_Medic)
		{
			PrecacheSound(GIANTSOLDIER_SND_LOOP, true);
			EmitSoundToAll(GIANTSOLDIER_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_DemoMan)
		{
			PrecacheSound(GIANTDEMOMAN_SND_LOOP, true);
			EmitSoundToAll(GIANTDEMOMAN_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Heavy)
		{
			PrecacheSound(GIANTHEAVY_SND_LOOP, true);
			EmitSoundToAll(GIANTHEAVY_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
		else if(class == TFClass_Pyro)
		{
			PrecacheSound(GIANTPYRO_SND_LOOP, true);
			EmitSoundToAll(GIANTPYRO_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		}
	}
	
	return Plugin_Stop;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(cvarSounds)) 
		return Plugin_Continue;
	if (!IsValidClient(Ent)) 
		return Plugin_Continue;
	/*if (StrContains(sound, "weapons/", false) != -1) 
		CPrintToChatAll("{red}Played: %s %d %f %d %d %d", sound, channel, volume, level, pitch, flags);*/

	new client = Ent;
	new TFClassType:class = TF2_GetPlayerClass(client);

	if(StrContains(sound, "player/footsteps/", false) != -1)
	{
		if(class == TFClass_Medic)
			return Plugin_Stop;
		if(class == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_DeadRingered) || TF2_IsPlayerInCondition(client, TFCond_Disguised )))
			return Plugin_Continue;

		if(Status[client] == RobotStatus_Giant  && GetConVarBool(cvarFootsteps))
		{
			pitch = 100;
			Format(sound, sizeof(sound), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1,8));
		}
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, ")weapons/rocket_", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), ")weapons/", "mvm/giant_soldier/giant_soldier_");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "weapons\\quake_rpg_fire_remastered", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "weapons\\quake_rpg_fire_remastered", "mvm/giant_soldier/giant_soldier_rocket_shoot");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, ")weapons/grenade_launcher_", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), ")weapons/grenade_launcher_", "mvm/giant_demoman/giant_demoman_genade_");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	/*else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_pyro/giant_pyro_flame_thrower_start");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_pyro/giant_pyro_flame_thrower_loop");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_heavy/giant_heavy_gunwinddown");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_heavy/giant_heavy_gunwindup");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_heavy/giant_heavy_gunspin");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}
	else if(StrContains(sound, "", false) != -1 && Status[client] == RobotStatus_Giant)
	{
		ReplaceString(sound, sizeof(sound), "", "mvm/giant_heavy/giant_heavy_gunfire");
		PrecacheSound(sound, true);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
		return Plugin_Stop;
	}*/
	else if(StrContains(sound, "vo/", false) != -1)
	{
		if(
			StrContains(sound, "vo/mvm/", false) != -1
			|| StrContains(sound, "/demoman_", false) == -1
			&& StrContains(sound, "/engineer_", false) == -1
			&& StrContains(sound, "/heavy_", false) == -1
			&& StrContains(sound, "/medic_", false) == -1
			&& StrContains(sound, "/pyro_", false) == -1
			&& StrContains(sound, "/scout_", false) == -1
			&& StrContains(sound, "/sniper_", false) == -1
			&& StrContains(sound, "/soldier_", false) == -1
			&& StrContains(sound, "/spy_", false) == -1
			&& StrContains(sound, "/engineer_", false) == -1
		)
			return Plugin_Continue;
		
		if(Status[client] == RobotStatus_Giant)
		{
			switch(class)
			{
				case TFClass_Scout:		ReplaceString(sound, sizeof(sound), "scout_", "scout_mvm_m_", false);
				case TFClass_Soldier:	ReplaceString(sound, sizeof(sound), "soldier_", "soldier_mvm_m_", false);
				case TFClass_DemoMan:	ReplaceString(sound, sizeof(sound), "demoman_", "demoman_mvm_m_", false);
				case TFClass_Medic:		ReplaceString(sound, sizeof(sound), "medic_", "medic_mvm_", false);
				case TFClass_Heavy:		ReplaceString(sound, sizeof(sound), "heavy_", "heavy_mvm_m_", false);
				case TFClass_Pyro:		ReplaceString(sound, sizeof(sound), "pyro_", "pyro_mvm_m_", false);
				default:				return Plugin_Continue;
			}
			PrecacheSound(sound, true);
		}

		if(StrContains(sound, "_mvm_m_", false ) > -1)
			ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/mght/", false);
		else
			ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);

		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
		PrecacheSound(sound, true);
		
		decl String:soundCheck[PLATFORM_MAX_PATH];
		Format(soundCheck, sizeof(soundCheck), "sound/%s", sound);

		if(!FileExists(soundCheck) && GetConVarBool(cvarFileExists))
		{
			PrintToServer("Missing sound: %s", sound);
			return Plugin_Stop;
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	if (StringToInt(newValue)) ComeOnPrecacheZeSounds();
	else if (convar == cvarGiantFlag) GetConVarInt(cvarGiantFlag);
	
public bool:Filter_Robots(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == RobotStatus_Giant) PushArrayCell(clients, i);
	}
	return true;
}

public Native_GetRobotStatus(Handle:plugin, args)
	return _:Status[GetNativeCell(1)];

public Native_SetGiant(Handle:plugin, args)
	ToggleGiant(GetNativeCell(1), bool:GetNativeCell(2));

public Native_CheckRules(Handle:plugin, args)
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

stock TF2_ClassTypeToRole(TFClassType:class)
{
	switch (class)
	{
		case TFClass_Scout: return 1;
		case TFClass_Soldier: return 2;
		case TFClass_Pyro: return 3;
		case TFClass_DemoMan: return 4;
		case TFClass_Heavy: return 5;
		case TFClass_Engineer: return 6;
		case TFClass_Medic: return 7;
		case TFClass_Sniper: return 8;
		case TFClass_Spy: return 9;
	}
	return 1; // wat
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

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
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

stock UpdatePlayerHitbox(const client)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	static const Float:vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 }, Float:vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	if (g_bIsTF2)
	{
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;
	}
	else
	{
		vecScaledPlayerMin = vecGenericPlayerMin;
		vecScaledPlayerMax = vecGenericPlayerMax;
	}
	ScaleVector(vecScaledPlayerMin, g_fClientCurrentScale[client]);
	ScaleVector(vecScaledPlayerMax, g_fClientCurrentScale[client]);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock FixSounds(iEntity)
{
	if(iEntity <= 0 || !IsValidEntity(iEntity))
		return;
	
	StopSnd(iEntity, _, GIANTSCOUT_SND_LOOP);
	StopSnd(iEntity, _, GIANTSOLDIER_SND_LOOP);
	StopSnd(iEntity, _, GIANTPYRO_SND_LOOP);
	StopSnd(iEntity, _, GIANTDEMOMAN_SND_LOOP);
	StopSnd(iEntity, _, GIANTHEAVY_SND_LOOP);
}

stock StopSnd(iClient, iChannel = SNDCHAN_AUTO, const String:strSample[PLATFORM_MAX_PATH])
{
	if(!IsValidEntity(iClient))
		return;
	StopSound(iClient, iChannel, strSample);
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
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
}

ComeOnPrecacheZeSounds()
{
	for (new i = 1; i <= 8; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/giant_common/giant_common_step_0%i.wav", i);
		PrecacheSound(snd, true);
	}
	PrecacheSound(GIANTSCOUT_SND_LOOP, true);
	PrecacheSound(GIANTSOLDIER_SND_LOOP, true);
	PrecacheSound(GIANTPYRO_SND_LOOP, true);
	PrecacheSound(GIANTDEMOMAN_SND_LOOP, true);
	PrecacheSound(GIANTHEAVY_SND_LOOP, true);
	/*PrecacheSound(STUN_SND_1, true);
	PrecacheSound(STUN_SND_2, true);
	PrecacheSound(STUN_SND_3, true);*/
}