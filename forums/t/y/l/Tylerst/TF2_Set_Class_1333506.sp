#pragma semicolon 1;

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2.2"
 
public Plugin:myinfo =
{
	name = "TF2 Set Class",
	author = "Tylerst",
	description = "Set the target(s) class",
	version = PLUGIN_VERSION,
};

new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	CreateConVar("sm_setclass_version", PLUGIN_VERSION, "Set the target(s) class, Usage: sm_setclass \"target\" \"class\"", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_setclass_chat", "1", "Enable/Disable(1/0) Showing setclass changes in chat", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hLog = CreateConVar("sm_setclass_log", "1", "Enable/Disable(1/0) Logging of setclass changes", FCVAR_PLUGIN|FCVAR_NOTIFY);	
	RegAdminCmd("sm_setclass", Command_Setclass, ADMFLAG_SLAY, "Usage: sm_setclass \"target\" \"class\"");	
}

public Action:Command_Setclass(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setclass \"target\" \"class\"");
	}
	else
	{
		new String:setclasstarget[MAX_NAME_LENGTH], String:strclass[10], TFClassType:class, String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml, random = false;
		GetCmdArg(1, setclasstarget, sizeof(setclasstarget));
		GetCmdArg(2, strclass, sizeof(strclass));
		if(StrEqual(strclass, "scout", false))
		{
			class = TFClass_Scout;
			Format(strclass, sizeof(strclass), "Scout");	
		}
		else if(StrEqual(strclass, "soldier", false))
		{
			class = TFClass_Soldier;
			Format(strclass, sizeof(strclass), "Soldier");	
		}
		else if(StrEqual(strclass, "pyro", false))
		{
			class = TFClass_Pyro;
			Format(strclass, sizeof(strclass), "Pyro");	
		}
		else if(StrEqual(strclass, "demoman", false))
		{
			class = TFClass_DemoMan;
			Format(strclass, sizeof(strclass), "Demoman");	
		}
		else if(StrEqual(strclass, "heavy", false))
		{
			class = TFClass_Heavy;
			Format(strclass, sizeof(strclass), "Heavy");	
		}
		else if(StrEqual(strclass, "engineer", false))
		{
			class = TFClass_Engineer;
			Format(strclass, sizeof(strclass), "Engineer");	
		}
		else if(StrEqual(strclass, "medic", false))
		{
			class = TFClass_Medic;
			Format(strclass, sizeof(strclass), "Medic");	
		}
		else if(StrEqual(strclass, "sniper", false))
		{
			class = TFClass_Sniper;
			Format(strclass, sizeof(strclass), "Sniper");	
		}
		else if(StrEqual(strclass, "spy", false))
		{
			class = TFClass_Spy;
			Format(strclass, sizeof(strclass), "Spy");	
		}
		else if(StrEqual(strclass, "random", false))
		{
			random = true;
			Format(strclass, sizeof(strclass), "Random");	
		}
		else
		{
			ReplyToCommand(client, "[SM] Invalid Class (\"%s\")", strclass);
			return Plugin_Handled;
		}
		if((target_count = ProcessTargetString(
				setclasstarget,
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
		for(new i = 0; i < target_count; i++)
		{
			if(random) class = TFClassType:GetRandomInt(1, 9);
			if(IsValidEntity(target_list[i]))
			{
				TF2_SetPlayerClass(target_list[i], class);
				if(IsPlayerAlive(target_list[i]))
				{
					SetEntityHealth(target_list[i], 25);
					TF2_RegeneratePlayer(target_list[i]);
					new weapon = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Primary);
					if(IsValidEntity(weapon))
					{
						SetEntPropEnt(target_list[i], Prop_Send, "m_hActiveWeapon", weapon);
					}
				}

			}
			if(GetConVarBool(hLog))
			{
				LogAction(client, target_list[i], "\"%L\" set class of  \"%L\" to (class %s)", client, target_list[i], strclass);	
			}
		}
		if(GetConVarBool(hChat))
		{
			ShowActivity2(client, "[SM] ","Set class of %s to %s", target_name, strclass);
		}	
	}
	return Plugin_Handled;	
}