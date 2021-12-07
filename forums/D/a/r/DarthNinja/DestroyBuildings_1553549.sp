#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.2.0"

new g_iLastThingPlayerBuilt[MAXPLAYERS+1] = -1;

public Plugin:myinfo =
{
	name = "[TF2] Destroy Engineer Buildings",
	author = "DarthNinja",
	description = "Destroy or remove an engineer's buildings",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_destroy_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_destroy", DestroyBuilding, ADMFLAG_SLAY, "sm_destroy <#userid|name> [sentry/dispenser/entrance/exit/all/last]");
	HookEvent("player_builtobject", OnPlayerBuiltCrap);
}


public Action:OnPlayerBuiltCrap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iLastThingPlayerBuilt[client] = GetEventInt(event, "index");
}

public OnClientDisconnect(client)
{
	g_iLastThingPlayerBuilt[client] = -1;
}

public Action:DestroyBuilding(client, args)
{
	if (args < 1 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_destroy <client> [sentry/dispenser/tele/entrance/exit/all/last] [clean 1/0]");
		return Plugin_Handled;
	}

	decl String:target[64];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			target,
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
	
	new iTargetBuilding = 0; //All buildings (default)
	if (args > 1)
	{
		decl String:TargetBuilding[64];
		GetCmdArg(2, TargetBuilding, sizeof(TargetBuilding));
		
		if (StrEqual(TargetBuilding, "sentry", false))		//Sentry Gun
			iTargetBuilding = 1;
		else if (StrEqual(TargetBuilding, "dispenser", false))	//Dispenser
			iTargetBuilding = 2;
		else if (StrEqual(TargetBuilding, "tele", false))		//Tele entrance + exit
			iTargetBuilding = 3;
		else if (StrEqual(TargetBuilding, "entrance", false))	//Tele entrance only
			iTargetBuilding = 4;
		else if (StrEqual(TargetBuilding, "exit", false))		//Tele exit only
			iTargetBuilding = 5;
		else if (StrEqual(TargetBuilding, "last", false))		//Last building
			iTargetBuilding = 6;
		else if (!StrEqual(TargetBuilding, "all", false))
		{
			ReplyToCommand(client, "Invalid building specified, please use sentry, dispenser, tele, entrance, exit, last, or all");
			return Plugin_Handled;
		}
	}
	
	new bool:iCleanDestroy = false;
	if (args == 3)
	{
		decl String:clean[12];
		GetCmdArg(3, clean, sizeof(clean));
		if (StringToInt(clean) != 0)
		{
			iCleanDestroy = true;
		}
	}
	
	new iCount = 0;

	for (new i = 0; i < target_count; i++)
	{
		new iEnt = -1;
		if (iTargetBuilding == 1 || iTargetBuilding == 0)
		{
			while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
			{
				if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == target_list[i])
				{
					if (iCleanDestroy)
						AcceptEntityInput(iEnt, "Kill");
					else
					{
						SetVariantInt(1000);
						AcceptEntityInput(iEnt, "RemoveHealth");
					}
					iCount++;
				}
			}
		}
		if (iTargetBuilding == 2 || iTargetBuilding == 0)
		{
			while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == target_list[i])
				{
					if (iCleanDestroy)
						AcceptEntityInput(iEnt, "Kill");
					else
					{
						SetVariantInt(1000);
						AcceptEntityInput(iEnt, "RemoveHealth");
					}
					iCount++;
				}
			}
		}
		if (iTargetBuilding == 3 || iTargetBuilding == 4 || iTargetBuilding == 0)
		{
			while ((iEnt = FindEntityByClassname(iEnt, "obj_teleporter")) != INVALID_ENT_REFERENCE)
			{
				if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == target_list[i] && TF2_GetObjectMode(iEnt) == TFObjectMode_Entrance)
				{
					if (iCleanDestroy)
						AcceptEntityInput(iEnt, "Kill");
					else
					{
						SetVariantInt(1000);
						AcceptEntityInput(iEnt, "RemoveHealth");
					}
					iCount++;
				}
			}
		}
		if (iTargetBuilding == 3 || iTargetBuilding == 5 || iTargetBuilding == 0)
		{
			while ((iEnt = FindEntityByClassname(iEnt, "obj_teleporter")) != INVALID_ENT_REFERENCE)
			{
				if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == target_list[i] && TF2_GetObjectMode(iEnt) == TFObjectMode_Exit)
				{
					if (iCleanDestroy)
						AcceptEntityInput(iEnt, "Kill");
					else
					{
						SetVariantInt(1000);
						AcceptEntityInput(iEnt, "RemoveHealth");
					}
					iCount++;
				}
			}
		}
		if (iTargetBuilding == 6)
		{
			if (IsValidEntity(g_iLastThingPlayerBuilt[target_list[i]]))
			{
				//Slightly anal-retentive validation:
				decl String:clsname[128];
				GetEntPropString(g_iLastThingPlayerBuilt[target_list[i]], Prop_Data, "m_iClassname", clsname, sizeof(clsname));
				
				if (StrContains("obj_sentrygun obj_dispenser obj_teleporter", clsname, false) != -1 && GetEntPropEnt(g_iLastThingPlayerBuilt[target_list[i]], Prop_Send, "m_hBuilder") == target_list[i])
				{
					if (iCleanDestroy)
						AcceptEntityInput(g_iLastThingPlayerBuilt[target_list[i]], "Kill");
					else
					{
						SetVariantInt(1000);
						AcceptEntityInput(g_iLastThingPlayerBuilt[target_list[i]], "RemoveHealth");
					}
					iCount++;
				}
			}
		}
	}
	if (iCount == 0)
		ReplyToCommand(client, "[SM] Target player has nothing built!");
	else
		ReplyToCommand(client, "[SM] Destroyed %i buildings belonging to %s", iCount, target_name);
	return Plugin_Handled;
}