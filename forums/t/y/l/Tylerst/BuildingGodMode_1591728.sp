#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
public Plugin:myinfo =
{
	name = "TF2 Building God Mode",
	author = "Tylerst",
	description = "Set god mode(invincibility) on a targets' buildings and immune to sappers",
	version = PLUGIN_VERSION,
	url = "none"
}

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




new bool:g_bBGod[MAXPLAYERS+1] = false;

new Handle:g_hBGodAuto = INVALID_HANDLE;
new Handle:g_hChat = INVALID_HANDLE;
new Handle:g_hLog = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_bgod_version", PLUGIN_VERSION, "Set God mode(invincibility) on a targets' buildings and make immune to sappers", FCVAR_NOTIFY);

	g_hBGodAuto = CreateConVar("sm_bgod_auto", "0", "Set Building God Mode on clients automatically. Set override for sm_bgod_autoflag to only allow clients with specific admin flags");
	g_hChat = CreateConVar("sm_bgod_chat", "1", "Enable/Disable Showing BGod changes in chat");
	g_hLog = CreateConVar("sm_bgod_log", "1", "Enable/Disable Logging BGod changes");

	HookConVarChange(g_hBGodAuto, CvarChange_BGodAuto);
	
	RegAdminCmd("sm_bgod", Command_Bgod, ADMFLAG_SLAY, "Set god mode on a targets' buildings, Usage: sm_bgod \"target\" \"1/0\"");

	HookEvent("player_builtobject", Object_Built);
	HookEvent("player_sapped_object", Object_Sapped);

	AddNormalSoundHook(Hook_NormalSound);
}

public CvarChange_BGodAuto(Handle:cvar, const String:strOldValue[], const String:strNewValue[])
{
	new bool:bOnOff = false;
	if(StringToInt(strNewValue)) bOnOff = true;

	if(bOnOff)
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && CheckCommandAccess(client, "sm_bgod_autoflag", 0))
			{
				g_bBGod[client] = true;
				BGod(client, true);
			}
		}
	}
}


public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrEqual(sample, "weapons/sapper_timer.wav", false)
	|| (StrContains(sample, "spy_tape_01.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_02.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_03.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_04.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_05.wav", false) != -1))
	{
		if(!IsValidEntity(GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity"))) return Plugin_Stop;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	g_bBGod[client] = false;
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarBool(g_hBGodAuto) && CheckCommandAccess(client, "sm_bgod_autoflag", 0)) g_bBGod[client] = true;
}

public Action:Command_Bgod(client, args)
{
	switch(args)
	{
		case 0:
		{
			if(g_bBGod[client])
			{
				g_bBGod[client] = false;
				BGod(client, false);
				if(GetConVarBool(g_hLog)) LogAction(client, client, "\"%L\" Disabled Bgod for themselves", client);
				PrintToChat(client, "[SM] Building God Mode disabled.");
				
			}
			else
			{
				g_bBGod[client] = true;
				BGod(client, true);
				if(GetConVarBool(g_hLog)) LogAction(client, client, "\"%L\" Enabled Bgod for themselves", client);
				PrintToChat(client, "[SM] Building God Mode enabled.");
			}			
		}
		case 2:
		{
			new String:strTarget[MAX_TARGET_LENGTH], String:strOnOff[2], bool:bOnOff, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			if((target_count > 1 || target_list[0] != client) && !CheckCommandAccess(client, "sm_bgod_multi", ADMFLAG_SLAY))
			{
				ReplyToCommand(client, "[SM] You do not have access to targeting others");
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = bool:StringToInt(strOnOff);
			new bool:bLogging = GetConVarBool(g_hLog);
			if(bOnOff)
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bBGod[target_list[i]] = true;
					BGod(target_list[i], true);
					if(bLogging) LogAction(client, target_list[i], "\"%L\" Enabled Bgod for  \"%L\"", client, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Enabled Building God Mode for %s", target_name);
			}
			else 
			{
				for(new i = 0; i < target_count; i++)
				{
					g_bBGod[target_list[i]] = false;
					BGod(target_list[i], false);
					if(bLogging) if(GetConVarBool(g_hLog)) LogAction(client, target_list[i], "\"%L\" Disabled Bgod for  \"%L\"", client, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Disabled Building God Mode for %s", target_name);				
			}
		}
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_bgod \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

public Object_Built(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new building = GetEventInt(event, "index");
	if(g_bBGod[client])
	{
		SetEntProp(building, Prop_Data, "m_takedamage", 0);
	}
}

public Object_Sapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new sapper = GetEventInt(event, "sapperid");

	if(g_bBGod[client]) 
	{
		AcceptEntityInput(sapper, "Kill");
	}
}


BGod(client, bool:bOnOff)
{
	SetBGod(client, "obj_sentrygun", bOnOff);
	SetBGod(client, "obj_dispenser", bOnOff);
	SetBGod(client, "obj_teleporter", bOnOff);
}

stock RemoveActiveSapper(building)
{
	new sapper = -1; 
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sapper) && GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == building)
		{
			AcceptEntityInput(sapper, "Kill");
		}
	}	
}

stock SetBGod(client, const String:strClassname[], bool:bOnOff)
{
	new building = -1;
	while ((building = FindEntityByClassname(building, strClassname))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(building) && GetEntPropEnt(building, Prop_Send, "m_hBuilder") == client)
		{
			if(bOnOff)
			{
				RemoveActiveSapper(building);
				SetEntProp(building, Prop_Data, "m_takedamage", 0);
			} 
			else SetEntProp(building, Prop_Data, "m_takedamage", 2);
		}
	}
}