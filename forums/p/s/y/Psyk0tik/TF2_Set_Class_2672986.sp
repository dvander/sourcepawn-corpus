#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2.3"
 
public Plugin myinfo =
{
	name = "TF2 Set Class",
	author = "Tylerst, Psyk0tik",
	description = "Sets a player's class.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=141516"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "The \"TF2 Set Class\" supports Team Fortress 2 only.");

		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

ConVar g_cvChat, g_cvLog;

public void OnPluginStart()
{	
	LoadTranslations("common.phrases");

	CreateConVar("sm_setclass_version", PLUGIN_VERSION, "Set the target(s) class, Usage: sm_setclass \"target\" \"class\"", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_cvChat = CreateConVar("sm_setclass_chat", "1", "Show admin activity relevant to the plugin?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvLog = CreateConVar("sm_setclass_log", "1", "Log admin activity relevant to the plugin?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);

	RegAdminCmd("sm_setclass", cmdSetclass, ADMFLAG_SLAY, "Usage: sm_setclass \"target\" \"class\"");	
}

public Action cmdSetclass(int client, int args)
{
	switch (args)
	{
		case 1, 2:
		{
			char target[32], target_name[32], type[32];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, target, sizeof target);

			if (args == 2)
			{
				GetCmdArg(2, type, sizeof type);
			}

			if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, target_name, sizeof target_name, tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);

				return Plugin_Handled;
			}

			for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
			{
				vSwitchClass(client, target_list[iPlayer], (args == 2 ? type : "random"));
			}
		}
		default: ReplyToCommand(client, "[SM] Usage: sm_setclass <#userid|name> \"class\"");
	}

	return Plugin_Handled;	
}

static void vSwitchClass(int client, int target, const char[] type)
{
	char sClass[32];
	TFClassType tfClass;
	if (StrEqual(type, "scout", false))
	{
		strcopy(sClass, sizeof sClass, "Scout");
		tfClass = TFClass_Scout;
	}
	else if (StrEqual(type, "soldier", false))
	{
		strcopy(sClass, sizeof sClass, "Soldier");
		tfClass = TFClass_Soldier;
	}
	else if (StrEqual(type, "pyro", false))
	{
		strcopy(sClass, sizeof sClass, "Pyro");
		tfClass = TFClass_Pyro;
	}
	else if (StrEqual(type, "demoman", false))
	{
		strcopy(sClass, sizeof sClass, "Demoman");
		tfClass = TFClass_DemoMan;
	}
	else if (StrEqual(type, "heavy", false))
	{
		strcopy(sClass, sizeof sClass, "Heavy");
		tfClass = TFClass_Heavy;
	}
	else if (StrEqual(type, "engineer", false))
	{
		strcopy(sClass, sizeof sClass, "Engineer");
		tfClass = TFClass_Engineer;
	}
	else if (StrEqual(type, "medic", false))
	{
		strcopy(sClass, sizeof sClass, "Medic");
		tfClass = TFClass_Medic;
	}
	else if (StrEqual(type, "sniper", false))
	{
		strcopy(sClass, sizeof sClass, "Sniper");
		tfClass = TFClass_Sniper;
	}
	else if (StrEqual(type, "spy", false))
	{
		strcopy(sClass, sizeof sClass, "Spy");
		tfClass = TFClass_Spy;
	}
	else if (StrEqual(type, "random", false))
	{
		int iClass = 0, iClasses[9] = 0;
		for (int iClassNum = view_as<int>(TFClass_Scout); iClassNum <= view_as<int>(TFClass_Engineer); iClassNum++)
		{
			if (TF2_GetPlayerClass(target) != view_as<TFClassType>(iClassNum))
			{
				iClasses[iClass] = iClassNum;
				iClass++;
			}
		}

		strcopy(sClass, sizeof sClass, "Random");
		tfClass = view_as<TFClassType>(iClasses[GetRandomInt(0, iClass - 1)]);
	}
	else
	{
		ReplyToCommand(client, "[SM] Invalid class");

		return;
	}

	if (0 < target <= MaxClients && IsClientInGame(target) && !IsClientInKickQueue(target))
	{
		TF2_SetPlayerClass(target, tfClass);

		if (IsPlayerAlive(target))
		{
			SetEntityHealth(target, 25);
			TF2_RegeneratePlayer(target);

			int iWeapon = GetPlayerWeaponSlot(target, TFWeaponSlot_Primary);
			if (IsValidEntity(iWeapon))
			{
				SetEntPropEnt(target, Prop_Send, "m_hActiveWeapon", iWeapon);
			}
		}

		if (g_cvChat.BoolValue)
		{
			ShowActivity2(client, "\x01[SM] ","Set class of\x04 %N\x01 to\x03 %s\x01.", target, sClass);
		}

		if (g_cvLog.BoolValue)
		{
			LogAction(client, target, "\"%L\" set class of \"%L\" to \"%s.\"", client, target, sClass);
		}
	}
}