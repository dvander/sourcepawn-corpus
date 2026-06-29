#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"


public Plugin:myinfo = 
{
	
	name = "TF2 Infi-Targe",
	
	author = "FlaminSarge (credits to Tylerst for idea)",

	description = "YAAAAAAAAAAAAAAAAAAAH!",

	version = PLUGIN_VERSION,
	
	url = "http://gaming.calculatedchaos.com/"

};



new bool:infitarge[MAXPLAYERS+1];


public OnPluginStart()

{

	TF2only()
	CreateConVar("sm_infitarge_version", PLUGIN_VERSION, "Infinite Targe TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_infitarge", SetInfiTarge, ADMFLAG_SLAY, "Give Infinite Targe to a target - Usage: sm_infitarge <target> <1/0>");

	LoadTranslations("common.phrases");
}



public OnClientConnected(client)
{
	infitarge[client] = false;
}

public OnClientDisconnect(client)
{
	infitarge[client] = false;
}



public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (infitarge[i])
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{
				//Infinite Targe
				new condflags = TF2_GetPlayerConditionFlags(i);
				if(FindPlayerTarge(i) && (GetClientButtons(i) & IN_ATTACK2))		
				{
					if (!(condflags & TF_CONDFLAG_CHARGING)) TF2_AddCondition(i, TFCond_Charging, 999999999.0);
				}
				else if (condflags & TF_CONDFLAG_CHARGING)
				{
					TF2_RemoveCondition(i, TFCond_Charging); 
				}
			}
		}
	}
}


public Action:SetInfiTarge(client, args)
{
	new String:infitarget[32], String:infitargeswitch[32], targe;

	GetCmdArg(1, infitarget, sizeof(infitarget));
	GetCmdArg(2, infitargeswitch, sizeof(infitargeswitch));

	if(args != 2)
	{
		ReplyToCommand(client, "Usage: sm_infitarge <target> <1/0>");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;		
	if ((target_count = ProcessTargetString(
			infitarget,
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
	targe = StringToInt(infitargeswitch);
	for (new i = 0; i < target_count; i++)
	{
		if (targe == 1)
		{
			infitarge[target_list[i]] = true;
		}
		if (targe == 0)
		{
			infitarge[target_list[i]] = false;
		}
		LogAction(client, target_list[i], "\"%L\" Set Infinite Targe for  \"%L\" to (%i)", client, target_list[i], targe);	
	}

	if(tn_is_ml)
	{
		ShowActivity2(client, "[SM] ","Set Infinite Targe For %t to %d", target_name, targe);
	}
	else
	{
		ShowActivity2(client, "[SM] ","Set Infinite Targe For %s to %d", target_name, targe);
	}
	return Plugin_Handled;
}

TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}
}
stock bool:FindPlayerTarge(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable_item_demoshield")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if (idx == 131 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
		{
			return true;
		}
	}
	return false;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}