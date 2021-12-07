#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <betheskeleton>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Be the Skeleton",
	author = "Mitchell",
	description = "Halloween Skeleton skin for the sniper!",
	version = PLUGIN_VERSION,
	url = "http://mitch.dev/"
}

new SkeletonStatus:Status[MAXPLAYERS + 1];
new Float:LastTransformTime[MAXPLAYERS + 1];

new Handle:cvarDefault, Handle:cvarCooldown, Handle:cvarWearables, Handle:cvarWearablesKill, Handle:cvarTaunts;

public OnPluginStart()
{
	RegConsoleCmd("sm_skeleton", Command_betheskeleton);
	RegConsoleCmd("sm_noteleks", Command_betheskeleton);
	RegConsoleCmd("sm_betheskeleton", Command_betheskeleton);
	RegConsoleCmd("sm_beskeleton", Command_betheskeleton);
	
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	
//	AddNormalSoundHook(SoundHook);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	CreateConVar("sm_betheskeleton_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarDefault = CreateConVar("sm_betheskeleton_default","0","If on, Be the Skeleton will be enabled on players when they join the server.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCooldown = CreateConVar("sm_betheskeleton_cooldown","2.0","If greater than 0, players must wait this long between enabling/disabling skeleton on themselves. Set to 0.0 to disable.", FCVAR_NONE, true, 0.0);
	cvarTaunts = CreateConVar("sm_betheskeleton_taunts","1","If on, skeleton can taunt. Most skeleton taunts are...incorrect. And some taunt kills don't play an animation for the killing part.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearables = CreateConVar("sm_betheskeleton_wearables","1","If on, wearable items will be rendered on skeletons.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWearablesKill = CreateConVar("sm_betheskeleton_wearables_kill","0","If on, and sm_betheskeleton_wearables is 0, wearables are removed from skeletons instead of being turned invisible.", FCVAR_NONE, true, 0.0, true, 1.0);
	//HookConVarChange(cvarSounds, OnSoundsCvarChanged);
	
	AddMultiTargetFilter("@skeletons", Filter_Skeletons, "all skeletons", false);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BeTheSkeleton_GetSkeletonStatus", Native_GetSkeletonStatus);
	CreateNative("BeTheSkeleton_SetSkeleton", Native_SetSkeleton);
	CreateNative("BeTheSkeleton_CheckRules", Native_CheckRules);
	RegPluginLibrary("betheskeleton");
	return APLRes_Success;
}

public OnMapStart()
{	
	PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
	CreateTimer(0.5, Timer_HalfSecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Status[i] != SkeletonStatus_Skeleton) continue;
		Status[i] = SkeletonStatus_WantsToBeSkeleton;
	}
}

public OnClientConnected(client)
{
	Status[client] = GetConVarBool(cvarDefault) ? SkeletonStatus_WantsToBeSkeleton : SkeletonStatus_Human;
	LastTransformTime[client] = 0.0;
}

public Action:Command_betheskeleton(client, args)
{
	if (!client && !args)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a skeleton. Beep boop.", arg0);
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "betheskeleton", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[4], bool:toggle = bool:2;
	if (args < 1 || !CheckCommandAccess(client, "betheskeleton_admin", ADMFLAG_SLAY))
	{
		if (!ToggleSkeleton(client)) ReplyToCommand(client, "[SM] You can't be a skeleton right now, but you'll be one as soon as you can.");
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
		ToggleSkeleton(target_list[i], toggle);
	if (toggle != false && toggle != true) ShowActivity2(client, "[SM] ", "Toggled skeleton on %s.", target_name);
	else ShowActivity2(client, "[SM] ", "%sabled skeleton on %s.", toggle ? "En" : "Dis", target_name);
	return Plugin_Handled;
}

stock bool:ToggleSkeleton(client, bool:toggle = bool:2)
{
	if (Status[client] == SkeletonStatus_WantsToBeSkeleton && toggle != false && toggle != true) return true;
	if (!Status[client] && !toggle) return true;
	if (Status[client] == SkeletonStatus_Skeleton && toggle == true && CheckTheRules(client)) return true;
	if (!Status[client] || Status[client] == SkeletonStatus_WantsToBeSkeleton)
	{
		new bool:rightnow = true;
		if (!IsPlayerAlive(client)) rightnow = false;
	//	if (isBuster[client]) return false;
		if (!CheckTheRules(client)) rightnow = false;
		if (!rightnow)
		{
			Status[client] = SkeletonStatus_WantsToBeSkeleton;
			return false;
		}
	}
	if (toggle == true || (toggle == bool:2 && Status[client] == SkeletonStatus_Human))
	{
		SetVariantString("models/bots/skeleton_sniper/skeleton_sniper.mdl");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		LastTransformTime[client] = GetTickedTime();
		Status[client] = SkeletonStatus_Skeleton;
		SetWearableAlpha(client, 0);
	}
	else if (!toggle || (toggle == bool:2 && Status[client] == SkeletonStatus_Skeleton)) // Can possibly just be else. I am not good with logic.
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		LastTransformTime[client] = GetTickedTime();
		Status[client] = SkeletonStatus_Human;
		SetWearableAlpha(client, 255);
	}
	return true;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (Status[client] == SkeletonStatus_Skeleton && !GetConVarBool(cvarTaunts)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Status[client])
	{
		new Float:cooldown = GetConVarFloat(cvarCooldown), bool:immediate;
		if (LastTransformTime[client] + cooldown <= GetTickedTime()) immediate = true;
		ToggleSkeleton(client, false);
		if (immediate) LastTransformTime[client] = 0.0;
		ToggleSkeleton(client, true);
	}
}

public Action:Timer_HalfSecond(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == SkeletonStatus_WantsToBeSkeleton) ToggleSkeleton(i, true);
	}
}
	
public bool:Filter_Skeletons(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (Status[i] == SkeletonStatus_Skeleton) PushArrayCell(clients, i);
	}
	return true;
}

public Native_GetSkeletonStatus(Handle:plugin, args)
	return _:Status[GetNativeCell(1)];

public Native_SetSkeleton(Handle:plugin, args)
	ToggleSkeleton(GetNativeCell(1), bool:GetNativeCell(2));

public Native_CheckRules(Handle:plugin, args)
	return CheckTheRules(GetNativeCell(1));

stock bool:CheckTheRules(client)
{
	if (!IsPlayerAlive(client)) return false;
	
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting) || TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	
	new Float:cooldowntime = GetConVarFloat(cvarCooldown);
	
	if (cooldowntime > 0.0 && (LastTransformTime[client] + cooldowntime) > GetTickedTime()) return false;
	
	if (TF2_GetPlayerClass(client) != TFClass_Sniper) return false;
	return true;
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
