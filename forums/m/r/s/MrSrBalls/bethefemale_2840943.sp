#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <bethefemale>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Be The Female",
	author = "MrSrBalls",
	description = "Scout: Hey guys! would you look at this I now have a pair of Bo-. Soldier: Scout! shut up!.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new FemaleStatus:Status[MAXPLAYERS + 1];
new Float:LastTransformTime[MAXPLAYERS + 1];

new Handle:cvarFootsteps, Handle:cvarDefault, Handle:cvarClasses, Handle:cvarSounds, Handle:cvarTaunts,
Handle:cvarFileExists, Handle:cvarCooldown, Handle:cvarWearables, Handle:cvarWearablesKill;

public OnPluginStart()
{
	RegConsoleCmd("sm_female", Command_bethefemale);
	RegConsoleCmd("sm_tobor", Command_bethefemale);
	RegConsoleCmd("sm_bethefemale", Command_bethefemale);
	RegConsoleCmd("sm_befemale", Command_bethefemale);
	
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	
	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	CreateConVar("sm_bethefemale_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarFootsteps = CreateConVar("sm_bethefemale_footsteps","0","The Cvar its useless do not change.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDefault = CreateConVar("sm_bethefemale_default","0","If on, Be the Female will be enabled on players when they join the server.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarClasses = CreateConVar("sm_bethefemale_classes","0","These classes CANNOT be made into females. Add up the numbers to restrict the classes you want. 1=Scout 2=Soldier 4=Pyro 8=Demo 16=Heavy 64=Medic 128=Sniper 256=Spy", FCVAR_NONE, true, 0.0, true, 511.0);
	cvarSounds = CreateConVar("sm_bethefemale_sounds","1","If on, female players will have female voice.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTaunts = CreateConVar("sm_bethefemale_taunts","1","This Cvar its also useless because female players models uses the animations as the default models.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarFileExists = CreateConVar("sm_bethefemale_fileexists","1","Also ignore the Cvar", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_bethefemale_cooldown","2.0","If greater than 0, players must wait this long between enabling/disabling female mode on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarWearables = CreateConVar("sm_bethefemale_wearables","1","If on, wearable items will be rendered on female players.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearablesKill = CreateConVar("sm_bethefemale_wearables_kill","0","If on, and sm_bethefemale_wearables is 0, wearables are removed from female instead of being turned invisible.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvarSounds, OnSoundsCvarChanged);
	
	AddMultiTargetFilter("@females", Filter_Females, "all females", false);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BeTheFemale_GetFemaleStatus", Native_GetFemaleStatus);
	CreateNative("BeTheFemale_SetFemale", Native_SetFemale);
	CreateNative("BeTheFemale_CheckRules", Native_CheckRules);
	RegPluginLibrary("bethefemale");
	return APLRes_Success;
}

public OnMapStart()
{
	new String:classname[10], String:Mdl[PLATFORM_MAX_PATH];
	for (new TFClassType:i = TFClass_Scout; i <= TFClass_Engineer; i++)
	{
		TF2_GetNameOfClass(i, classname, sizeof(classname));
		Format(Mdl, sizeof(Mdl), "models/Female/%s/player/%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl, true);
	}
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(cvarSounds)) ComeOnPrecacheZeSounds();
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Status[i] != FemaleStatus_Female) continue;
		Status[i] = FemaleStatus_WantsToBeFemale;
	}
}

public OnClientConnected(client)
{
	Status[client] = GetConVarBool(cvarDefault) ? FemaleStatus_WantsToBeFemale : FemaleStatus_Human;
	LastTransformTime[client] = 0.0;
}

public Action:Command_bethefemale(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into females.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "bethefemale", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args < 1 || !CheckCommandAccess(client, "bethefemale_admin", ADMFLAG_SLAY))
	{
		if (!ToggleFemale(client)) ReplyToCommand(client, "[SM] You can't become female right now, but you'll be one as soon as you can.");
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
		ToggleFemale(target_list[i], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled female on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled female on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

stock bool:ToggleFemale(client, bool:toggle = bool:2)
{
	if (Status[client] == FemaleStatus_WantsToBeFemale && toggle != false && toggle != true) return true;
	if (!Status[client] && !toggle) return true;
	if (Status[client] == FemaleStatus_Female && toggle == true && CheckTheRules(client)) return true;
	if (!Status[client] || Status[client] == FemaleStatus_WantsToBeFemale)
	{
		new bool:rightnow = true;
		if (!IsPlayerAlive(client)) rightnow = false;
	//	if (isBuster[client]) return false;
		if (!CheckTheRules(client)) rightnow = false;
		if (!rightnow)
		{
			Status[client] = FemaleStatus_WantsToBeFemale;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status[client] == FemaleStatus_Human))
	{
		new String:classname[10];
		TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
		new String:Mdl[PLATFORM_MAX_PATH];
		Format(Mdl, sizeof(Mdl), "models/Female/%s/player/%s.mdl", classname, classname);
		ReplaceString(Mdl, sizeof(Mdl), "demoman", "demo", false);
		SetVariantString(Mdl);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		LastTransformTime[client] = GetTickedTime();
		Status[client] = FemaleStatus_Female;
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == FemaleStatus_Female)) // Can possibly just be else. I am not good with logic.
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		LastTransformTime[client] = GetTickedTime();
		Status[client] = FemaleStatus_Human;
		SetWearableAlpha(client, 255);
	}
	return true;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status[client] == FemaleStatus_Female && !GetConVarBool(cvarTaunts)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Status[client])
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (LastTransformTime[client] + cooldown <= GetTickedTime()) immediate = true;
		ToggleFemale(client, false);
		if (immediate) LastTransformTime[client] = 0.0;
		ToggleFemale(client, true);
	}
}

public Action:Timer_HalfSecond(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == FemaleStatus_WantsToBeFemale) ToggleFemale(i, true);
	}
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(cvarSounds)) return Plugin_Continue;
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(Ent)) return Plugin_Continue;
	new client = Ent;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (Status[client] == FemaleStatus_Female)
	{
		if (StrContains(sound, "player/footsteps/", false) != -1 && class != TFClass_Medic && GetConVarBool(cvarFootsteps))
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
		ReplaceString(sound, sizeof(sound), "vo/", "female/vo/", false);
		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
		new String:classname[10], String:classname_female[15];
		TF2_GetNameOfClass(class, classname, sizeof(classname));
		Format(classname, sizeof(classname), "%s", classname);
		ReplaceString(sound, sizeof(sound), classname, classname, false);
		new String:soundchk[PLATFORM_MAX_PATH];
		Format(soundchk, sizeof(soundchk), "sound/%s", sound);
		if (!FileExists(soundchk, true) && GetConVarBool(cvarFileExists)) return Plugin_Continue;
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnSoundsCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	if (StringToInt(newValue)) ComeOnPrecacheZeSounds();
	
public bool:Filter_Females(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == FemaleStatus_Female) PushArrayCell(clients, i);
	}
	return true;
}

public Native_GetFemaleStatus(Handle:plugin, args)
	return _:Status[GetNativeCell(1)];

public Native_SetFemale(Handle:plugin, args)
	ToggleFemale(GetNativeCell(1), bool:GetNativeCell(2));

public Native_CheckRules(Handle:plugin, args)
	return CheckTheRules(GetNativeCell(1));

stock bool:CheckTheRules(client)
{
	if (!IsPlayerAlive(client)) return false;
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting) ||
	TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	if (cooldowntime > 0.0 && (LastTransformTime[client] + cooldowntime) > GetTickedTime()) return false;
	if (GetConVarInt(cvarClasses) & (1 << TF2_ClassTypeToRole(TF2_GetPlayerClass(client)) - 1)) return false;
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

ComeOnPrecacheZeSounds()
{
	for (new i = 1; i <= 18; i++)
	{
		decl String:snd[PLATFORM_MAX_PATH];
		Format(snd, sizeof(snd), "mvm/player/footsteps/robostep_%s%i.wav", (i < 10) ? "0" : "", i);
		PrecacheSound(snd, true);
		if (i <= 4)
		{
			Format(snd, sizeof(snd), "mvm/sentrybuster/mvm_sentrybuster_step_0%i.wav", i);
			PrecacheSound(snd, true);
		}
		if (i <= 6)
		{
			Format(snd, sizeof(snd), "vo/mvm_sentry_buster_alerts0%i.wav", i);
			PrecacheSound(snd, true);
		}
	}
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_explode.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_intro.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav", true);
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav", true);
	PrecacheModel("models/bots/demo/bot_sentry_buster.mdl", true);
}