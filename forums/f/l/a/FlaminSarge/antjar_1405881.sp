#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME		"[TF2] Jar of Ants"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.1"
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/showthread.php?t=149150"
#define PLUGIN_DESCRIPTION	"Throw a Jar of Ants at people."

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};

new Float:cvar_antjarduration;
new pAntJar[MAXPLAYERS + 1];
new pJarated[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("antjar_version", PLUGIN_VERSION, "[TF2] Jar of Ants version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	new Handle:antjartime = CreateConVar("antjar_duration", "10.0", "Duration of the bleed effect", FCVAR_PLUGIN);
	RegAdminCmd("sm_antjar", Cmd_AntJar, ADMFLAG_CHEATS, "sm_antjar <target> <0/1>");
	HookConVarChange(antjartime, cvhook_antjartime);
	cvar_antjarduration = GetConVarFloat(antjartime);
	LoadTranslations("common.phrases");
	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);
	HookUserMessage(GetUserMessageId("PlayerJaratedFade"), Event_PlayerJaratedFade);
	HookEvent("player_hurt", Event_PlayerHurt);
}
public cvhook_antjartime(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_antjarduration = GetConVarFloat(cvar); }
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weapon = GetEventInt(event, "weaponid");
	if (weapon == TF_WEAPON_SNIPERRIFLE && TF2_IsPlayerInCondition(client, TFCond_Jarated))
	{
		pJarated[client] = true;
	}
}
public Action:Event_PlayerJaratedFade(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadByte(bf); //client
	new victim = BfReadByte(bf);
	pJarated[victim] = false;
}
public Action:Event_PlayerJarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
	if (pAntJar[client])
	{
		new jar = GetPlayerWeaponSlot(client, 1);
		if (jar != -1 && GetEntProp(jar, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{
			if (!pJarated[victim]) CreateTimer(0.0, Timer_NoPiss, any:victim);	//TF2_RemoveCondition(victim, TFCond_Jarated);
			TF2_MakeBleed(victim, client, cvar_antjarduration);
		}
		else pJarated[victim] = true;
	}
	else pJarated[victim] = true;
	return Plugin_Continue;
}
public Action:Timer_NoPiss(Handle:timer, any:victim) TF2_RemoveCondition(victim, TFCond_Jarated);
public OnMapStart()
{
	for (new i = 1; i < MaxClients; i++)
	{
		pAntJar[i] = false;
		pJarated[i] = false;
	}
}
public OnClientPutInServer(client)
{
	pAntJar[client] = false;
	pJarated[client] = false;
}
public OnClientDisconnect_Post(client)
{
	pAntJar[client] = false;
	pJarated[client] = false;
}
public Action:Cmd_AntJar(client, args)
{
	decl String:arg1[32];
	decl String:arg2[32];
	new antjaronoff = 0;

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_antjar <target> <1/0>");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;		
	if ((target_count = ProcessTargetString(
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
	antjaronoff = StringToInt(arg2);
	for (new i = 0; i < target_count; i++)
	{
		if(antjaronoff == 1)
		{
			pAntJar[target_list[i]] = true;
		}
		if(antjaronoff == 0)
		{
			pAntJar[target_list[i]] = false;
		}
		LogAction(client, target_list[i], "\"%L\" Set Ant Jar for  \"%L\" to (%i)", client, target_list[i], antjaronoff);	
	}

	if(tn_is_ml)
	{
		ShowActivity2(client, "[SM] ","Set Ant Jar For %t to %d", target_name, antjaronoff);
	}
	else
	{
		ShowActivity2(client, "[SM] ","Set Ant Jar For %s to %d", target_name, antjaronoff);
	}
	return Plugin_Handled;
}