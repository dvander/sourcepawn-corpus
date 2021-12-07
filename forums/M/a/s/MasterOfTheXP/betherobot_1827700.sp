#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Be the Robot",
	author = "MasterOfTheXP",
	description = "Beep boop son, beep boop.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new bool:isRobot[MAXPLAYERS + 1];
new bool:isRobotModel[MAXPLAYERS + 1];
new bool:isBuster[MAXPLAYERS + 1];
new bool:isAboutToExplode[MAXPLAYERS + 1];
new Float:MdlScale[MAXPLAYERS + 1] = { -1.0, ... };
new Float:LastTransform[MAXPLAYERS + 1];

new Handle:cvarFootsteps;
new Handle:cvarDefault;
new Handle:cvarClasses;
new Handle:cvarSounds;
new Handle:cvarTaunts;
new Handle:cvarFileExists;
new Handle:cvarCooldown;
new Handle:cvarWearables;
new Handle:cvarFF;

#define CLASS_SCOUT   (1 << 0) // 1
#define CLASS_SOLDIER (1 << 1) // 2
#define CLASS_PYRO (1 << 2) // 4
#define CLASS_DEMO (1 << 3) // 8
#define CLASS_HEAVY (1 << 4) // 16
//#define CLASS_ENGI (1 << 4) // Taken tusoon
#define CLASS_MEDIC (1 << 6) // 64
#define CLASS_SNIPER (1 << 7) // 128
#define CLASS_SPY (1 << 8) // 256

public OnPluginStart()
{
	RegConsoleCmd("sm_robot", Command_betherobot);
	RegConsoleCmd("sm_tobor", Command_betherobot);
	RegConsoleCmd("sm_betherobot", Command_betherobot);
	RegConsoleCmd("sm_berobot", Command_betherobot);
	RegConsoleCmd("sm_sentrybuster", Command_bethebuster);
	RegConsoleCmd("sm_buster", Command_bethebuster);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	AddNormalSoundHook(SoundHook);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	CreateConVar("sm_betherobot_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarFootsteps = CreateConVar("sm_betherobot_footsteps","1","If on, players who are robots will make footstep sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDefault = CreateConVar("sm_betherobot_default","0","If on, Be the Robot will be enabled on players when they join the server.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarClasses = CreateConVar("sm_betherobot_classes","0","These classes CANNOT be made into robots. Add up the numbers to restrict the classes you want. 1=Scout 2=Soldier 4=Pyro 8=Demo 16=Heavy 64=Medic 128=Sniper 256=Spy", FCVAR_NONE, true, 0.0, true, 511.0);
	cvarSounds = CreateConVar("sm_betherobot_sounds","1","If on, robots will emit robotic class sounds instead of their usual sounds.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_betherobot_taunts","1","If on, robots can taunt. Most robot taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFileExists = CreateConVar("sm_betherobot_fileexists","1","If on, any robot sound files must pass a check to see if they actually exist before being played. Recommended to the max. Only disable if robot sounds aren't working.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_betherobot_cooldown","2.0","If greater than 0, players must wait this long between enabling/disabling robot on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarWearables = CreateConVar("sm_betherobot_wearables","1","If on, wearable items will be rendered on robots.", FCVAR_NONE, true, 0.0, true, 1.0);
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		SDKHook(z, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnMapStart()
{
	for (new i = 1; i <= 18; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/player/footsteps/robostep_%s%i.wav", (i < 10) ? "0" : "", i);
		PrecacheSound(snd, true);
		if (i > 4) continue;
		Format(snd, sizeof(snd), "mvm/sentrybuster/mvm_sentrybuster_step_0%i.wav", i);
		PrecacheSound(snd, true);
	}
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_explode.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_intro.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav", true);
//	PrecacheSound("player/taunt_pyro_balloonicorn.wav", true);
//	PrecacheSound("player/taunt_pyro_hellicorn.wav", true);
	PrecacheModel("models/bots/demo/bot_sentry_buster.mdl", true);
}

public OnConfigsExecuted()
{
	cvarFF = FindConVar("mp_friendlyfire");
}

public Action:Command_betherobot(client, args)
{
	if (client == 0 && args < 1)
	{
		new String:arg0[10];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a robot. Beep boop.", arg0);
		return Plugin_Handled;
	}
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[10], toggle = 1;
	if (!CheckCommandAccess(client, "betherobot", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args < 1 || !CheckCommandAccess(client, "betherobot_admin", ADMFLAG_SLAY))
		Format(arg1, sizeof(arg1), "@me");
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrEqual(arg2, "0", false) || StrEqual(arg2, "off", false) || StrEqual(arg2, "no", false)) toggle = 0;
		if (StrEqual(arg2, "1", false) || StrEqual(arg2, "on", false) || StrEqual(arg2, "yes", false)) toggle = 2;
	}
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		if (StrEqual(arg1, "@me")) MakeRobot(client, client, 1);
		else ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new success;
	for (new i = 0; i < target_count; i++)
	{
		if (MakeRobot(target_list[i], client, toggle)) success++;
	}
	if (success > 0 && !StrEqual(arg1, "@me"))
	{
		new String:verb[15]; // Should be a mini-switch statement or whatever those are called (e.g. toggle ? "Disabled" : "Toggled" : "Enabled") but iunno how to do it for integers. (You probably can't. You should be able to. Somehow.)
		if (toggle == 0) Format(verb, sizeof(verb), "Disabled");
		if (toggle == 1) Format(verb, sizeof(verb), "Toggled");
		if (toggle == 2) Format(verb, sizeof(verb), "Enabled");
		ShowActivity2(client, "[SM] ", "%s robot on %s.", verb, target_name);
	}
	else if (success < 1) ReplyToCommand(client, "[SM] Robot transformation failed!");
	return Plugin_Handled;
}

public Action:Command_bethebuster(client, args)
{
	if (client == 0 && args < 1)
	{
		new String:arg0[10];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a Sentry Buster.", arg0);
		return Plugin_Handled;
	}
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[10], toggle = 1;
	if (!CheckCommandAccess(client, "bethebuster", ADMFLAG_ROOT))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args < 1 || !CheckCommandAccess(client, "bethebuster_admin", ADMFLAG_ROOT))
		Format(arg1, sizeof(arg1), "@me");
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrEqual(arg2, "0", false) || StrEqual(arg2, "off", false) || StrEqual(arg2, "no", false)) toggle = 0;
		if (StrEqual(arg2, "1", false) || StrEqual(arg2, "on", false) || StrEqual(arg2, "yes", false)) toggle = 2;
	}
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		if (StrEqual(arg1, "@me")) MakeBuster(client, 1);
		else ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new success;
	for (new i = 0; i < target_count; i++)
	{
		if (MakeBuster(target_list[i], toggle)) success++;
	}
	if (success > 0 && !StrEqual(arg1, "@me"))
	{
		new String:verb[15];
		if (toggle == 0) Format(verb, sizeof(verb), "Disabled");
		if (toggle == 1) Format(verb, sizeof(verb), "Toggled");
		if (toggle == 2) Format(verb, sizeof(verb), "Enabled");
		ShowActivity2(client, "[SM] ", "%s Sentry Buster on %s.", verb, target_name);
	}
	else if (success < 1) ReplyToCommand(client, "[SM] Transformation failed!");
	return Plugin_Handled;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (isRobotModel[client] && !GetConVarBool(cvarTaunts)) return Plugin_Handled;
	if (isBuster[client])
	{
		if (isAboutToExplode[client]) return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
		GetReadyToExplode(client);
	}
	/*else if (isRobotModel[client])
	{
		new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (TF2_GetPlayerClass(client) != TFClass_Pyro || wep != GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)) return Plugin_Continue;
		if (GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex") != 741) return Plugin_Continue;
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) EmitSoundToAll("player/taunt_pyro_hellicorn.wav", client);
	}*/
	return Plugin_Continue;
}

stock GetReadyToExplode(client) // A.K.A. Ka-
{
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	CreateTimer(2.0, Bewm, GetClientUserId(client));
	isAboutToExplode[client] = true;
}

public Action:Bewm(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	isAboutToExplode[client] = false;
	new explosion = CreateEntityByName("env_explosion");
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	new bool:FF = GetConVarBool(cvarFF);
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsValidClient(z)) continue;
		if (!IsPlayerAlive(z)) continue;
		if (GetClientTeam(z) == GetClientTeam(client) && !FF) continue;
		new Float:zPos[3];
		GetClientAbsOrigin(z, zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		DoDamage(client, z, 2500);
	}
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[20];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		SetVariantInt(2500);
		AcceptEntityInput(z, "RemoveHealth");
	}
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");
	CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll) || ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

public bool:MakeRobot(client, admin, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (isBuster[client])
		return false;
	if (client != admin) TF2_RemoveCondition(client, TFCond_Taunting);
	else if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return false;
	if (client != admin) TF2_RemoveCondition(client, TFCond_Dazed);
	else if (TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	if (client == admin && cooldowntime > 0 && (LastTransform[client] + cooldowntime) > GetGameTime())
		return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	new bool:allowed = IsAllowedClass(class);
	if (toggle == 2 || (toggle == 1 && !isRobot[client]))
	{
		if (allowed)
		{
			if (SetModel(client)) isRobot[client] = true;
			else return false;
		}
		else isRobot[client] = true;
	}
	else if (toggle == 0 || (toggle == 1 && isRobot[client]))
	{
		if (RemoveModel(client)) isRobot[client] = false;
		else return false;
	}
	LastTransform[client] = GetGameTime();
	return true;
}

public bool:MakeBuster(client, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	isRobot[client] = false;
	if (toggle == 2 || (toggle == 1 && !isBuster[client]))
	{
		if (TF2_GetPlayerClass(client) != TFClass_DemoMan) TF2_SetPlayerClass(client, TFClass_DemoMan);
		TF2_RemoveAllWeapons(client);
		new wepEnt = SpawnWeapon(client, "tf_weapon_stickbomb", 307, 10, 6, "26 ; 2325 ; 107 ; 2.0 ; 252 ; 0.5 ; 329 ; 0.5 ; 330 ; 7 ; 402 ; 1"); // Yes, SpawnWeapon. VSH. Hi Flamin.
		if (IsValidEntity(wepEnt)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wepEnt);
		SetEntityHealth(client, 2500);
		SetWearableAlpha(client, 0, true);
		if (SetModelBuster(client))
		{
			isBuster[client] = true;
			EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_intro.wav", client);
			EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_loop.wav", client);
		}
		else return false;
	}
	else if (toggle == 0 || (toggle == 1 && isBuster[client]))
	{
		if (RemoveModel(client))
		{
			isBuster[client] = false;
			StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
			SetWearableAlpha(client, 255);
		}
		else return false;
	}
	return true;
}

public OnClientPutInServer(client) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
public OnClientDisconnect(client)
{
	isRobot[client] = false;
	isRobotModel[client] = false;
	isBuster[client] = false;
	isAboutToExplode[client] = false;
	MdlScale[client] = -1.0;
}

public OnClientConnected(client)
{
	if (GetConVarBool(cvarDefault))
		isRobot[client] = true;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	new bool:allowed = IsAllowedClass(class);
	if (isRobot[client])
	{
		if (allowed) SetModel(client);
		else RemoveModel(client);
	}
	if (isBuster[client]) MakeBuster(client, 0);
	return Plugin_Continue;
}

public bool:IsAllowedClass(TFClassType:class)
{
	new BannedClasses = GetConVarInt(cvarClasses);
	switch (class)
	{
		case TFClass_Scout: if (BannedClasses & CLASS_SCOUT) return false;
		case TFClass_Soldier: if (BannedClasses & CLASS_SOLDIER) return false;
		case TFClass_Pyro: if (BannedClasses & CLASS_PYRO) return false;
		case TFClass_DemoMan: if (BannedClasses & CLASS_DEMO) return false;
		case TFClass_Heavy: if (BannedClasses & CLASS_HEAVY) return false;
		case TFClass_Medic: if (BannedClasses & CLASS_MEDIC) return false;
		case TFClass_Sniper: if (BannedClasses & CLASS_SNIPER) return false;
		case TFClass_Spy: if (BannedClasses & CLASS_SPY) return false;
	}
	return true;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(cvarSounds)) return Plugin_Continue;
	if (volume == 0.0) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (isRobotModel[client])
	{
		if (StrContains(sound, "player/footsteps/", false) != -1 && class != TFClass_Engineer && class != TFClass_Medic && GetConVarBool(cvarFootsteps))
		{
			new rand = GetRandomInt(1,18);
			Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sound, client, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}
		if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		if (volume == 0.99997) return Plugin_Continue;
		ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false); // yay for valve being smart
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: ReplaceString(sound, sizeof(sound), "scout_", "scout_mvm_", false);
			case TFClass_Soldier: ReplaceString(sound, sizeof(sound), "soldier_", "soldier_mvm_", false);
			case TFClass_Pyro: ReplaceString(sound, sizeof(sound), "pyro_", "pyro_mvm_", false);
			case TFClass_DemoMan: ReplaceString(sound, sizeof(sound), "demoman_", "demoman_mvm_", false);
			case TFClass_Heavy: ReplaceString(sound, sizeof(sound), "heavy_", "heavy_mvm_", false);
			case TFClass_Medic: ReplaceString(sound, sizeof(sound), "medic_", "medic_mvm_", false);
			case TFClass_Sniper: ReplaceString(sound, sizeof(sound), "sniper_", "sniper_mvm_", false);
			case TFClass_Spy: ReplaceString(sound, sizeof(sound), "spy_", "spy_mvm_", false);
		}
		new String:soundchk[PLATFORM_MAX_PATH];
		Format(soundchk, sizeof(soundchk), "sound/%s", sound);
		if (!FileExists(soundchk, true) && GetConVarBool(cvarFileExists)) return Plugin_Continue;
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (isBuster[client])
	{
		if (StrContains(sound, "vo/", false) != -1) return Plugin_Stop;
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		/*if (StrContains(sound, "player/footsteps/", false) != -1 && GetConVarBool(cvarFootsteps))
		{
			Format(sound, sizeof(sound), "mvm/sentrybuster/mvm_sentrybuster_step_0%i.wav", GetRandomInt(1,4));
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sound, client, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}*/
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!isBuster[client]) return Plugin_Continue;
	if (buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK;
		FakeClientCommand(client, "taunt");
		return Plugin_Changed;
	}
	if (buttons & IN_JUMP)
	{
		buttons &= ~IN_JUMP;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:SetModel(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl);
	}
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	if (StrEqual(Mdl, ""))
	{
		isRobotModel[client] = false;
		return false;
	}
	isRobotModel[client] = true;
	if (isRobotModel[client]) SetWearableAlpha(client, 0);
	else SetWearableAlpha(client, 255);
	return true;
}

stock bool:SetModelBuster(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	Format(Mdl, sizeof(Mdl), "models/bots/demo/bot_sentry_buster.mdl");
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	MdlScale[client] = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetWearableAlpha(client, 0);
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	if (MdlScale[client] != -1.0) SetEntPropFloat(client, Prop_Send, "m_flModelScale", MdlScale[client]);
	MdlScale[client] = -1.0;
	isRobotModel[client] = false;
	SetWearableAlpha(client, 255);
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock DoDamage(client, target, amount)
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
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
		SetEntityRenderMode(z, RENDER_TRANSCOLOR);
		SetEntityRenderColor(z, 255, 255, 255, alpha);
		count++;
	}
	return count;
}

stock bool:AttachParticle(ent, String:particleType[], bool:cache=false)
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	new String:tName[128];
	new Float:f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (!IsValidEntity(particle)) return Plugin_Handled;
	new String:classname[128];
	GetEdictClassname(particle, classname, sizeof(classname));
	if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
	return Plugin_Handled;
}

stock SpawnWeapon(client, String:name[], itemIndex, level, qual, String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, itemIndex);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon == INVALID_HANDLE)
	return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!isBuster[victim] || victim == attacker) return Plugin_Continue;
	if (isAboutToExplode[victim])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if (damage > GetClientHealth(victim))
	{
		damage = 0.0;
		GetReadyToExplode(victim);
		FakeClientCommand(victim, "taunt");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}