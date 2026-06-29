#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#pragma newdecls required
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_cvEnabled;
ConVar g_cvAdminOnly;
ConVar g_cvSeizureMode;
ConVar g_cvSpookyMode;
ConVar g_cvColorSpeed;

bool g_bDisco[MAXPLAYERS + 1];
bool g_bColorSwitch[MAXPLAYERS + 1][3];
int g_bColorRandomizer[MAXPLAYERS + 1][3];

enum DiscoMode
{
	NONE = 0,
	DISCO_NORMAL,
	DISCO_SEIZURE,
	DISCO_SPOOKY,
	COUNT
}
DiscoMode g_eDiscomode[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Disco Players",
	author = PLUGIN_AUTHOR,
	description = "Cycles through colors on players",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	
	LoadTranslations("common.phrases.txt");
	
	if(g_Game == Engine_CSGO)
		SetConVarBool(FindConVar("sv_disable_immunity_alpha"), true);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
	}
	
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_eDiscomode[i] = DISCO_NORMAL;
		g_bDisco[i] = false;
		for (int j = 0; j < 3;j++)
		{
			g_bColorSwitch[i][j] = false;
			g_bColorRandomizer[i][j] = 0;
		}
	}
		
	g_cvEnabled = CreateConVar("discoplayers_enabled", "1", "Enables/Disables disco players (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAdminOnly = CreateConVar("discoplayers_adminonly", "0", "Disables admin flag restrictions on sm_disco (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSeizureMode = CreateConVar("discoplayers_seizuremode", "0", "Enables/Disables seizuremode (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSpookyMode = CreateConVar("discoplayers_alphamode", "1", "Enables/Disables alphamode (1 or 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvColorSpeed = CreateConVar("discoplayers_speed", "5", "Sets the speed of the colors to transition", FCVAR_NOTIFY, true, 0.0, true, 50.0);
	
	RegConsoleCmd("sm_disco", Command_Disco, "Cycles through colors on your player model");
	
	HookEvent("player_spawn", Event_Spawn);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bDisco[client])
	{
		if(g_eDiscomode[client] == DISCO_NORMAL)
		{
			int alpha;
			int rgba[3];
			GetEntityRenderColor(client, rgba[0], rgba[1], rgba[2], alpha);
			
			for (int i = 0; i < 3;i++)
			{
				g_bColorRandomizer[client][i] = GetRandomInt(0, g_cvColorSpeed.IntValue);
				
				if(rgba[i] >= (255 - g_bColorRandomizer[client][i]))
					g_bColorSwitch[client][i] = false;
				if(rgba[i] <= (0 + g_bColorRandomizer[client][i]))
					g_bColorSwitch[client][i] = true;
				
				if(g_bColorSwitch[client][i])
					rgba[i] = rgba[i] + g_bColorRandomizer[client][i];
				else
					rgba[i] = rgba[i] - g_bColorRandomizer[client][i];
			}
			SetEntityRenderColor(client, rgba[0], rgba[1], rgba[2], 255);
			//PrintToChatAll("R: %i, G: %i, B: %i --- RAND:%i", rgba[0], rgba[1], rgba[2], g_bColorRandomizer[client][0]);
		}
		else if(g_eDiscomode[client] == DISCO_SEIZURE && g_cvSeizureMode.IntValue == 1)
		{
			SetEntityRenderColor(client, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
		}
		else if(g_eDiscomode[client] == DISCO_SPOOKY && g_cvSpookyMode.IntValue == 1)
		{
			int r, g, b, alpha;
			GetEntityRenderColor(client, r, g, b, alpha);
			
			if(alpha >= 255)
				g_bColorSwitch[client][0] = false;
			if(alpha <= 0)
				g_bColorSwitch[client][0] = true;
			
			if(g_bColorSwitch[client][0])
				alpha++;
			else
				alpha--;
			
			SetEntityRenderColor(client, 255, 255, 255, alpha);
		}
	}
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bDisco[client])
		SetEntityRenderColor(client, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
}

public Action Command_Disco(int client, int args)
{	
	if(g_cvEnabled.IntValue == 1)
	{
		if(args == 1)
		{
			if(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
			{
				char arg[65];
				GetCmdArg(1, arg, sizeof(arg));
				char target_name[MAX_TARGET_LENGTH];
				int target_list[MAXPLAYERS + 1];
				int target_count;
				
				bool tn_is_ml;
		
				if ((target_count = ProcessTargetString(
						arg,
						client,
						target_list,
						MAXPLAYERS + 1,
						COMMAND_FILTER_ALIVE,
						target_name,
						sizeof(target_name),
						tn_is_ml)) <= 0)
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}
				
				for (int i = 0; i < target_count; i++)
				{
					if(g_bDisco[target_list[i]])
					{
						SetEntityRenderColor(target_list[i], 255, 255, 255, 255);
						g_bDisco[target_list[i]] = false;
					}
					else
					{
						g_eDiscomode[target_list[i]] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
						if(g_cvSeizureMode.IntValue == 0 && g_cvSpookyMode.IntValue == 0)
						{
							g_eDiscomode[target_list[i]] = DISCO_NORMAL;
						}
						else if(g_cvSpookyMode.IntValue == 0)
						{
							while(g_eDiscomode[target_list[i]] == DISCO_SPOOKY)
							{
								g_eDiscomode[target_list[i]] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
							}
						}
						else if(g_cvSeizureMode.IntValue == 0)
						{
							while(g_eDiscomode[target_list[i]] == DISCO_SEIZURE)
							{
								g_eDiscomode[target_list[i]] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
							}
						}
						SetEntityRenderColor(target_list[i], GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
						g_bDisco[target_list[i]] = true;
					}
				}
			}
			else
			{
				PrintToChat(client, "[SM] You do not have access to this command");
			}
		}
		else if(args == 0)
		{
			if(g_cvAdminOnly.IntValue == 1)
			{
				if(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
				{
					if(g_bDisco[client])
					{
						SetEntityRenderColor(client, 255, 255, 255, 255);
						g_bDisco[client] = false;
					}
					else
					{	
						g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
						if(g_cvSeizureMode.IntValue == 0 && g_cvSpookyMode.IntValue == 0)
						{
							g_eDiscomode[client] = DISCO_NORMAL;
						}
						else if(g_cvSpookyMode.IntValue == 0)
						{
							while(g_eDiscomode[client] == DISCO_SPOOKY)
							{
								g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
							}
						}
						else if(g_cvSeizureMode.IntValue == 0)
						{
							while(g_eDiscomode[client] == DISCO_SEIZURE)
							{
								g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
							}
						}
						
						SetEntityRenderColor(client, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
						g_bDisco[client] = true;
					}
				}
				else
				{
					PrintToChat(client, "[SM] You do not have access to this command");
				}
			}
			else
			{
				if(g_bDisco[client])
				{
					SetEntityRenderColor(client, 255, 255, 255, 255);
					g_bDisco[client] = false;
				}
				else
				{
					g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
					if(g_cvSeizureMode.IntValue == 0 && g_cvSpookyMode.IntValue == 0)
					{
						g_eDiscomode[client] = DISCO_NORMAL;
					}
					else if(g_cvSpookyMode.IntValue == 0)
					{
						while(g_eDiscomode[client] == DISCO_SPOOKY)
						{
							g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
						}
					}
					else if(g_cvSeizureMode.IntValue == 0)
					{
						while(g_eDiscomode[client] == DISCO_SEIZURE)
						{
							g_eDiscomode[client] = view_as<DiscoMode>(GetRandomInt(view_as<int>(NONE) + 1, view_as<int>(COUNT) - 1));
						}
					}
					SetEntityRenderColor(client, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
					g_bDisco[client] = true;
				}
			}
		}
		else
			ReplyToCommand(client, "[SM] Usage: sm_disco (<#userid|name>)");
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
}

public void OnClientDisconnect(int client)
{
	for (int i = 0; i < 3;i++)
	{
		g_bColorSwitch[client][i] = false;
		g_bColorRandomizer[client][i] = 0;
	}
		
	g_eDiscomode[client] = DISCO_NORMAL;	
	g_bDisco[client] = false;
}