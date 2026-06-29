#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>

public Plugin:myinfo = 
{
	name = "[TF2] Red2Robot",
	author = "Bitl",
	description = "Change your team to robot!",
	version = "1.5.1",
	url = ""
}

public OnPluginStart()
{
	CheckGame();
	
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_spawn", event_PlayerSpawn);
	
	RegAdminCmd("sm_bot", Command_Help, ADMFLAG_CHEATS);
	RegAdminCmd("sm_machine", Command_Robot_Me, ADMFLAG_CHEATS);
	RegAdminCmd("sm_mann", Command_Human_Me, ADMFLAG_CHEATS);
	RegConsoleCmd("sm_giant", Command_Giant);
	RegConsoleCmd("sm_small", Command_Small);
	
}

public OnMapStart()
{
	if (IsMvM())
	{
		PrintToServer("[Red2Robot] MvM Detected. Red2Robot activated and ready for use!");
	}
	else
	{
		SetFailState("[Red2Robot] Error #1: This plugin is only usable on MvM maps.");
	}
}

CheckGame()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public Action:Command_Robot_Me(client, args)
{
	if (args == 0)
	{
		if (GetClientTeam(client) == 2)
		{
			new entflags = GetEntityFlags(client);
			SetEntityFlags(client, entflags | FL_FAKECLIENT);
			ChangeClientTeam(client, _:TFTeam_Blue);
			SetEntityFlags(client, entflags);
			ReplyToCommand(client, "[Red2Robot] You are now in the Machine team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to Machine!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the Machine team!");
		}
	}
	else if (args == 1)
	{
		new String:arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
				buffer,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==2)
			{
				new entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], _:TFTeam_Blue);
				SetEntityFlags(target_list[i], entflags);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the Machine team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to Machine!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the Machine team!");
			}
		}	
	}

	return Plugin_Handled;
}


public Action:Command_Human_Me(client, args)
{
	if (args == 0)
	{
		if (GetClientTeam(client) ==3)
		{
			new entflags = GetEntityFlags(client);
			SetEntityFlags(client, entflags | FL_FAKECLIENT);
			ChangeClientTeam(client, _:TFTeam_Red);
			SetEntityFlags(client, entflags);
			ReplyToCommand(client, "[Red2Robot] You are now in the Mann team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to Mann!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the Mann team!");
		}
	}
	else if (args == 1)
	{
		new String:arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
				buffer,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==3)
			{
				new entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], _:TFTeam_Red);
				SetEntityFlags(target_list[i], entflags);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the Mann team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to Mann!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the Mann team!");
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_Giant(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.8);
		TF2Attrib_SetByName(client, "move speed penalty", 0.5);
		TF2Attrib_SetByName(client, "max health additive bonus", 1000.0);
		TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		SetEntityHealth(client, 1000);
		SetModelGiant(client);
		ReplyToCommand(client, "[Red2Robot] You are now Giant!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now giant!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn giant.");
	}
}

public Action:Command_Small(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		TF2Attrib_RemoveByName(client, "move speed penalty");
		TF2Attrib_RemoveByName(client, "max health additive bonus");
		TF2Attrib_RemoveByName(client, "override footstep sound set");
		TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier");
		TF2Attrib_RemoveByName(client, "cannot be backstabbed");
		SetModel(client);
		ReplyToCommand(client, "[Red2Robot] You are now Small!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now small!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn small.");
	}
}

public OnClientDisconnect(client)
{
	RemoveModel(client);
}

public Action:Command_Help(client, args)
{
	ReplyToCommand(client, "[Red2Robot] !bot, !machine [target], !mann [target], !giant, !small");
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	TF2Attrib_RemoveByName(client, "move speed penalty");
	TF2Attrib_RemoveByName(client, "max health additive bonus");
	TF2Attrib_RemoveByName(client, "override footstep sound set");
	TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier");
	TF2Attrib_RemoveByName(client, "cannot be backstabbed");
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsMvM())
	{
		if (GetClientTeam(client) ==3)
		{
			SetModel(client);
		}
		else
		{
			RemoveModel(client);
		}
	}
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
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
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

stock bool:SetModelGiant(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout_boss");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier_boss");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro_boss");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo_boss");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy_boss");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
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

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock bool:IsMvM(bool:forceRecalc = false)
{
    static bool:found = false;
    static bool:ismvm = false;
    if (forceRecalc)
    {
        found = false;
        ismvm = false;
    }
    if (!found)
    {
        new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
        if (i > MaxClients && IsValidEntity(i)) ismvm = true;
        found = true;
    }
    return ismvm;
}
