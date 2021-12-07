#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PL_VERSION "1.2.6"

new Handle:Cvar_Enabled;
new Handle:Cvar_ChangeMessage;
new Handle:Cvar_DestroySentries;
new Handle:Cvar_ForceMini;
new Handle:Cvar_Cookies;
new Handle:Cvar_EnableDefault;

new Handle:EnableCookie;

new client_enabled[MAXPLAYERS+1] = 1;

public Plugin:myinfo = 
{
	name = "[TF2]Level 3 mini-sentries",
	author = "KalaPihvi",
	description = "Allows admins to toggle building of lv3 mini-sentries on clients",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_lv3minisg_version", PL_VERSION, "Lv3-MiniSG version");
	Cvar_Enabled = CreateConVar("sm_lv3minisg_enabled", "1", "Enable usage of level 3 mini sentries", _, true, 0.0, true, 1.0);
	Cvar_ChangeMessage = CreateConVar("sm_lv3minisg_message", "1", "Show message to (1= everyone, 2= who have lv3 mini-sentries enabled) when plugin is enabled/disabled", _, true, 0.0, true, 2.0);
	Cvar_DestroySentries = CreateConVar("sm_lv3minisg_destroy", "1", "Destroy level 3 mini-sentries when plugin is disabled", _, true, 0.0, true, 1.0);
	Cvar_ForceMini = CreateConVar("sm_lv3minisg_force", "1", "Force engineer's sentry to be mini even if he dosent have gunslinger", _, true, 0.0, true, 1.0);
	Cvar_Cookies = CreateConVar("sm_lv3minisg_cookies","1","Should the plugin use client cookies",_,true, 0.0, true, 1.0);
	Cvar_EnableDefault = CreateConVar("sm_lv3minisg_default","0","Clients with permission to use the command will have lv3 mini-sg enabled by default",_,true, 0.0, true, 1.0);
	
	HookConVarChange(Cvar_Enabled, CvarChange);

	RegConsoleCmd("sm_minisg", Command_ToggleMini);
	
	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Pre);
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig(true,"lv3minisg");
	
	EnableCookie = RegClientCookie("lv3minisg_enabled", "Defines if lv3 mini-sentries are enabled on client", CookieAccess_Protected);
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Cvar_Enabled)==0) return Plugin_Handled;
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(client_enabled[client]==1)
	{
		new index = GetEventInt(event, "index");

		decl String:classname[32];
		GetEdictClassname(index, classname, sizeof(classname));

		if( strcmp("obj_sentrygun", classname ) == 0 )
		{
			if(GetConVarInt(Cvar_ForceMini)==1)
			{
				if(GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel")==1 && GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 0 )
				{
					SetEntPropFloat(index, Prop_Send, "m_flModelScale",0.75); 
					SetEntProp(index, Prop_Send, "m_bMiniBuilding",1);
					SetEntProp(index, Prop_Send, "m_iHealth", 100);
					SetEntProp(index, Prop_Send, "m_iMaxHealth", 100);
					
					static Float:g_fSentryMaxs[] = {9.0, 9.0, 29.7};
					SetEntPropVector(index, Prop_Send, "m_vecMaxs", g_fSentryMaxs);
					
					new OldMetal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
					SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), OldMetal+30, 4, true);
					new Metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
					if(Metal>200)
						SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 200, 4, true);
				}
			}		
			if((GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 1 ))
				SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 3);
			
			CreateTimer(1.0, SkinFix, index);
		}
	}
	return Plugin_Continue;
}

public Action:SkinFix(Handle:timer, any:sentry) 
{
	decl String:classname[32];
	
	if(!IsValidEntity(sentry)) return Plugin_Continue;
	
	if(GetEntityClassname(sentry, classname, sizeof(classname)) && StrEqual(classname, "obj_sentrygun", false))
	{
		if((GetEntProp(sentry, Prop_Send, "m_bPlacing") == 0))
		{
			new client = GetEntDataEnt2(sentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
			if(!IsValidClient(client)) return Plugin_Continue;

			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(client)-2);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_ToggleMini(client, args)
{
	if (!CheckCommandAccess(client, "minisg_self", ADMFLAG_SLAY) && !CheckCommandAccess(client, "minisg_both", ADMFLAG_SLAY))
	{
		PrintToChat(client, "\x04[SM]\x01You do not have permission to use this command");
		return Plugin_Handled;
	}
		
	if(GetConVarInt(Cvar_Enabled)==0)
	{
		PrintToChat(client, "\x04[SM]\x01Lv3 mini-sentries are currently disabled");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	decl String:arg2[64];
	GetCmdArg(2, arg2, sizeof(arg2));
	new value = StringToInt(arg1);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if (!StrEqual(arg2, ""))
	{
		if (CheckCommandAccess(client, "minisg_both", ADMFLAG_SLAY))
		{
			if ((target_count = ProcessTargetString(
				arg2,
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
		
			for (new i = 0; i < target_count; i++)
			{
				if (CheckCommandAccess(target_list[i], "minisg_target", 0))
				{
					if(value==1)
					{
						if(client_enabled[target_list[i]]==0)
						{
							client_enabled[target_list[i]]=1;
							PrintToChat(target_list[i], "\x04[SM]\x01Lv3 mini-sentry enabled");
							UpdateSentry(target_list[i]);
							
							UpdateCookie(target_list[i],1);
							return Plugin_Handled;
						}
					}
					else
					{
						if(client_enabled[target_list[i]]==1)
						{
							client_enabled[target_list[i]]=0;
							PrintToChat(target_list[i], "\x04[SM]\x01Lv3 mini-sentry disabled");
							DestroySentry(target_list[i]);
							UpdateCookie(target_list[i],0);
							return Plugin_Handled;
						}
					}
				}
				else if(target_count==1)
				{
					PrintToChat(client, "\x04[SM]\x01%N dosent have permission to be targeted",target_list[i]);
				}
			}
		}
		else
		{
			PrintToChat(client, "\x04[SM]\x01You do not have permission to target clients");
		}
	}

	if (StrEqual(arg2, ""))
	{
		if (CheckCommandAccess(client, "minisg_self", ADMFLAG_SLAY) || CheckCommandAccess(client, "minisg_both", ADMFLAG_SLAY))
		{
			if (StrEqual(arg1, ""))
			{
				if(client_enabled[client]==0)
				{
					client_enabled[client]=1;
					PrintToChat(client, "\x04[SM]\x01Lv3 mini-sentry enabled");
					UpdateSentry(client);
					UpdateCookie(client,1);
					return Plugin_Handled;
				}
				if(client_enabled[client]==1)
				{
					client_enabled[client]=0;
					PrintToChat(client, "\x04[SM]\x01Lv3 mini-sentry disabled");
					DestroySentry(client);
					UpdateCookie(client,0);
					return Plugin_Handled;
				}
			}
			else
			{
				if(value==1)
				{
					if(client_enabled[client]==0)
					{
						client_enabled[client]=1;
						PrintToChat(client, "\x04[SM]\x01Lv3 mini-sentry enabled");
						return Plugin_Handled;
					}
				}
				else
				{
					if(client_enabled[client]==1)
					{
						client_enabled[client]=0;
						PrintToChat(client, "\x04[SM]\x01Lv3 mini-sentry disabled");
						DestroySentry(client);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Value = StringToInt(newValue);
	if(Value==0)
	{
		if(GetConVarInt(Cvar_ChangeMessage)==1)
			PrintToChatAll("\x04[SM]\x01Usage of lv3 mini-sentries disabled");
		
		if(GetConVarInt(Cvar_DestroySentries)==1)
		{
			DestroySentries();
		}
	}
	if(Value==1)
	{
		PrintToChatAll("\x04[SM]\x01Usage of lv3 mini-sentries enabled");
	}
	return _:Plugin_Continue;
}

stock DestroySentries()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			if((GetEntProp(entity, Prop_Send, "m_bMiniBuilding") == 1 ))
			{
				if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")>=2)
				{
					new client = GetEntDataEnt2(entity, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
					if(GetConVarInt(Cvar_ChangeMessage)==2)
						PrintToChat(client,"\x04[SM]\x01Usage of lv3 mini-sentries disabled");	
						
					SetVariantInt(1000);
					AcceptEntityInput(entity, "RemoveHealth");
				}
			}
		}
	}
}

stock DestroySentry(Client)
{
	if(!IsValidClient(Client)) return _:Plugin_Continue;
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			if((GetEntProp(entity, Prop_Send, "m_bMiniBuilding") == 1 ))
			{
				new client = GetEntDataEnt2(entity, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
				if(client == Client)
				{
					if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")>=2)
					{							
						SetVariantInt(1000);
						AcceptEntityInput(entity, "RemoveHealth");
					}
				}
			}
		}
	}
	return _:Plugin_Continue;
}

stock UpdateSentry(Client)
{
	if(!IsValidClient(Client)) return _:Plugin_Continue;
	new entity = -1;
	new MiniHealth = 100;
	while ((entity=FindEntityByClassname(entity, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			new client = GetEntDataEnt2(entity, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
			if(client == Client)
			{
				if((GetEntProp(entity, Prop_Send, "m_bMiniBuilding") == 0 ))
				{
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale",0.75);
					SetEntProp(entity, Prop_Send, "m_bMiniBuilding", 1);
					
					static Float:g_fSentryMaxs[] = {9.0, 9.0, 29.7};
					SetEntPropVector(entity, Prop_Send, "m_vecMaxs", g_fSentryMaxs);
				}
					
				if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")==3) MiniHealth = 144;
				if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")==2) MiniHealth = 120;
				if(GetEntProp(entity, Prop_Send, "m_iUpgradeLevel")==1) MiniHealth = 100;
				
				SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", 3);
				SetEntProp(entity, Prop_Data, "m_iMaxHealth", MiniHealth);
				SetEntProp(entity, Prop_Data, "m_iHealth", MiniHealth);
			}
		}
	}
	return _:Plugin_Continue;
}

stock UpdateCookie(client, value)
{
	if(!IsValidClient(client)) return _:Plugin_Continue;
	if(GetConVarInt(Cvar_Cookies)==0) return _:Plugin_Continue;
	
	decl String:StrValue[32];
	IntToString(value, StrValue, sizeof(StrValue));
	SetClientCookie(client, EnableCookie, StrValue);
	
	return _:Plugin_Continue;
}

public OnClientDisconnect(client)
{
	client_enabled[client]=0;
	return _:Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(!IsValidClient(client)) return _:Plugin_Continue;
	
	if(GetConVarInt(Cvar_Cookies)==1)
	{	
		decl String:cookiestring[32];
		GetClientCookie(client, EnableCookie, cookiestring, sizeof(cookiestring));
		new Value = StringToInt(cookiestring);
		client_enabled[client] = Value;
	}

	if(GetConVarInt(Cvar_EnableDefault)==1)
	{
		CreateTimer(1.0, EnableDefault, client);
	}
	
	return _:Plugin_Continue;
}

public Action:EnableDefault(Handle:timer, any:client) 
{
	if(!IsValidClient(client)) return Plugin_Continue;
	if (CheckCommandAccess(client, "minisg_self", ADMFLAG_SLAY) || CheckCommandAccess(client, "minisg_both", ADMFLAG_SLAY))
	{
		client_enabled[client]=1;
	}
	return Plugin_Continue;
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}