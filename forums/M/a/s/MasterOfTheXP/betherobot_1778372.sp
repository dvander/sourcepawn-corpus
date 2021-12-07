#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Be the Robot",
	author = "MasterOfTheXP",
	description = "Beep boop son, beep boop.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new bool:isRobot[MAXPLAYERS + 1] = { false, ... };
new bool:isBuster[MAXPLAYERS + 1] = { false, ... };
new bool:isAboutToExplode[MAXPLAYERS + 1] = { false, ... };
new Float:MdlScale[MAXPLAYERS + 1] = { -1.0, ... };
new CaberModel;

new Handle:cvarFF;

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
	cvarFF = FindConVar("mp_friendlyfire");
}

public OnMapStart()
{
	for (new i = 1; i <= 18; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/player/footsteps/robostep_%s%i.wav", (i < 10) ? "0" : "", i);
		PrecacheSound(snd, true);
	}
	
	CaberModel = PrecacheModel("models/weapons/c_models/c_caber/c_caber.mdl", true); // I don't think this needs to be done, but oh well.
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
		new String:verb[15]; // Should be a mini-switch statement or whatever those are called (e.g. toggle ? "Disabled" : "Toggled" : "Enabled") but iunno how to do it for integers.
		if (toggle == 0) Format(verb, sizeof(verb), "Disabled");
		if (toggle == 1) Format(verb, sizeof(verb), "Toggled");
		if (toggle == 2) Format(verb, sizeof(verb), "Enabled");
		ShowActivity2(client, "[SM] ", "%s robot on %s.", verb, target_name);
	}
	else if (success < 1) ReplyToCommand(client, "[SM] Robot transformation failed! Remember: You cannot be a robot as Engineer or while taunting.");
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
	if (!isBuster[client]) return Plugin_Continue;
	if (isAboutToExplode[client]) return Plugin_Continue;
	if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav");
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	CreateTimer(2.0, Bewm, GetClientUserId(client));
	isAboutToExplode[client] = true;
	return Plugin_Continue;
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
		DoDamage(client, z, 450);
	}
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_loop.wav", client);
	DoDamage(client, client, 450);
	return Plugin_Handled;
}

public bool:MakeRobot(client, admin, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (isBuster[client])
		return false;
	if (client != admin) TF2_RemoveCondition(client, TFCond_Taunting);
	else if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return false;
	if (toggle == 2 || (toggle == 1 && !isRobot[client]))
	{
		if (SetModel(client)) isRobot[client] = true;
		else return false;
	}
	else if (toggle == 0 || (toggle == 1 && isRobot[client]))
	{
		if (RemoveModel(client)) isRobot[client] = false;
		else return false;
	}
	return true;
}

public bool:MakeBuster(client, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (isRobot[client])
		return false;
	if (toggle == 2 || (toggle == 1 && !isBuster[client]))
	{
		if (TF2_GetPlayerClass(client) != TFClass_DemoMan) TF2_SetPlayerClass(client, TFClass_DemoMan);
		TF2_RemoveAllWeapons(client);
		new weapon = GivePlayerItem(client, "tf_weapon_stickbomb"); // Non-TF2Items weapon giving code from FlaminSarge's Ready Steady Pan Setup
		SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 307);
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 10);
		SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 6);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", CaberModel);
		SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
		SetEntProp(weapon, Prop_Send, "m_hExtraWearable", -1);
		EquipPlayerWeapon(client, weapon);
		for (new Ent = MaxClients + 1; Ent <= GetMaxEntities(); Ent++)
		{
			if (!IsValidEntity(Ent)) continue;
			decl String:cls[20];
			GetEntityClassname(Ent, cls, sizeof(cls));
			if (StrContains(cls, "tf_wearable") != 0) continue;
			if (GetEntPropEnt(Ent, Prop_Send, "m_hOwnerEntity") != client) continue;
			AcceptEntityInput(Ent, "Kill");
		}
		if (SetModelBuster(client))
		{
			isBuster[client] = true;
			PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_intro.wav");
			EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_intro.wav");
			PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav");
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
		}
		else return false;
	}
	return true;
}

public OnClientDisconnect(client)
{
	isRobot[client] = false;
	isBuster[client] = false;
	isAboutToExplode[client] = false;
	MdlScale[client] = -1.0;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (isRobot[client]) SetModel(client);
	if (isBuster[client]) MakeBuster(client, 0);
	return Plugin_Continue;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (isRobot[client])
	{
		if (StrContains(sound, "player/footsteps/", false) != -1)
		{
			new rand = GetRandomInt(1,18);
			Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			EmitSoundToClient(client, sound, _, _, _, _, 0.25, pitch);
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
		if (!FileExists(soundchk, true)) return Plugin_Continue;
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (isBuster[client])
	{
		if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		return Plugin_Stop;
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
	if (StrEqual(Mdl, "")) return false;
	return true;
}

stock bool:SetModelBuster(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	Format(Mdl, sizeof(Mdl), "models/bots/demo/bot_sentry_buster.mdl");
	PrecacheModel(Mdl);
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	MdlScale[client] = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	if (MdlScale[client] != -1.0) SetEntPropFloat(client, Prop_Send, "m_flModelScale", MdlScale[client]);
	MdlScale[client] = -1.0;
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