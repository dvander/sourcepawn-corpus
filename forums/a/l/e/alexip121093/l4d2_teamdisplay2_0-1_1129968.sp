#include <sourcemod>
#include <sdktools>
#include <left4downtown>
#pragma semicolon 1
#define PLUGIN_VERSION "2.0"
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:PanelModeCVAR = INVALID_HANDLE;
new Handle:PanelDisplayCVAR = INVALID_HANDLE;
new Handle:PanelDeadCVAR = INVALID_HANDLE;
new Handle:PanelSeCVAR = INVALID_HANDLE;
new Handle:SedCVAR = INVALID_HANDLE;
new Handle:AutoDisableCVAR = INVALID_HANDLE;
new Handle:showscoreCVAR = INVALID_HANDLE;
new Handle:timeoutCVAR = INVALID_HANDLE;
new Handle:ADSCVAR = INVALID_HANDLE;
new propinfoghost;
new bool:dp[MAXPLAYERS + 1];
new bool:se[MAXPLAYERS + 1];
public Plugin:myinfo =
{
	name = "L4D2 Team Displayer",
	author = "hihi1210",
	description = "This plug-in display a team panel.",
	version = PLUGIN_VERSION,
	url = "http://kdt.poheart.com"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("L4D2 Team Displayer supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_teampanel_version", PLUGIN_VERSION, " Version of L4D2 Team Displayer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	PanelModeCVAR = CreateConVar("l4d2_teampanel_mode", "2", "0: Disable  ,1: 1 Display without auto refresh  ,2: Auto refresh", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	PanelDisplayCVAR = CreateConVar("l4d2_teampanel_display", "2", "0 : Display all information of both teams ,1 : just display your team name ,hp & status,2: display your team name ,hp & status and only display name for other team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	PanelDeadCVAR = CreateConVar("l4d2_teampanel_deadautodisplay", "1", "Auto display panel to dead players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	PanelSeCVAR = CreateConVar("l4d2_teampanel_Spectatorautodisplay", "1", "Auto display panel to Spectator", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	SedCVAR = CreateConVar("l4d2_teampanel_Spectatordisplay", "1", "Display Spectator in the panel", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoDisableCVAR = CreateConVar("l4d2_teampanel_AutoDisable", "1", "Auto disable the panel when player spawn (only work with l4d2_teampanel_mode 2)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ADSCVAR = CreateConVar("l4d2_teampanel_ads", "1", "Message display method (3= display both chat and hint text,2=just hint text, 1=just chat text,0=disable)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	showscoreCVAR  = CreateConVar("l4d2_teampanel_Autoshowafterscore", "1", "Auto display the panel when player activate the score board (press Tab)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	timeoutCVAR = CreateConVar("l4d2_teampanel_timeout", "1", "How many seconds the panel will disappear(will not stop the panel when it auto refreshs)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 999.0);
	RegConsoleCmd("sm_showteam", Command_Say);
	AutoExecConfig(true, "l4d2_teamdisplay");
	cvar_Gamemode = FindConVar("mp_gamemode");
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	HookEvent("player_death", Event_Death);
	HookEvent("player_team", Event_Team);
	HookEvent("player_spawn", PlayerSpawn);
}
public OnMapEnd()
{
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		dp[i]=false;
	}
}
public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (GetConVarInt(AutoDisableCVAR) == 1)
	{
		decl Client;
		Client = GetClientOfUserId(GetEventInt(Event, "userid"));
		if (Client == 0) return;
		if (IsFakeClient(Client)) return;
		if (dp[Client])
		{
			dp[Client] = false;
		}
	}
}
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(PanelDeadCVAR) == 1)
	{
		new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (Victim == 0) return;
		if (IsFakeClient(Victim)) return;
		if (GetConVarInt(PanelModeCVAR) == 2)
		{
			if (dp[Victim]) return;
		}
		FakeClientCommand(Victim, "sm_showteam");
		if (GetConVarInt(PanelModeCVAR) == 1)
		{
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(Victim,"[Team Displayer] You can type !showteam to show the team panel");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(Victim,"[Team Displayer] You can type !showteam to show the team panel");
			}
		}
	}
}
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(PanelSeCVAR) == 1)
	{
		new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (Victim == 0) return;
		if (IsFakeClient(Victim)) return;
		if (GetEventInt(event, "team") !=1) return;
		if (GetConVarInt(PanelModeCVAR) == 2)
		{
			if (dp[Victim]) return;
		}
		FakeClientCommand(Victim, "sm_showteam");
		if (GetConVarInt(PanelModeCVAR) == 1)
		{
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(Victim,"[Team Displayer] You can type !showteam to show the team panel");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(Victim,"[Team Displayer] You can type !showteam to show the team panel");
			}
		}
	}
}
public OnClientPostAdminCheck(client)
{
	dp[client] = false;
	se[client] = false;
}
public OnClientDisconnect(client)
{
	dp[client] = false;
	se[client] = false;
}

public Action:Command_Say(client, args)
{
	if (GetConVarInt(PanelModeCVAR) == 1)
	{
		Teampanel(client);
		return;
	}
	else if (GetConVarInt(PanelModeCVAR) == 0)
	{
		return;
	}
	else if (GetConVarInt(PanelModeCVAR) == 2)
	{
		if (dp[client] == false)
		{
			dp[client] = true;
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(client,"[Team Displayer] You can type !showteam to enable/disable the panel");
				PrintToChat(client,"[Team Displayer] Auto Refreshing Enabled");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(client,"[Team Displayer] \n You can type !showteam to enable/disable the panel \n  Auto Refreshing Enabled");
			}
			CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		else
		{
			dp[client] = false;
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(client,"[Team Displayer] Auto Refreshing Disabled");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(client,"[Team Displayer] \n Auto Refreshing Disabled");
			}
			return;
		}
	}
	else
	{
		return;
	}
}

public Action:PAd(Handle:Timer, any:client)
{
	if(dp[client])
	{
		Teampanel(client);
		CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	else
	{
		dp[client] = false;
		return;
	}
}
public Teampanel(client)
{
	new surcount = 0;
	new infcount = 0;
	new sepcount = 0;
	new surbotcount = 0;
	new infbotcount = 0;
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
	new Handle:downtownrun = FindConVar("l4d_maxplayers");
	new Handle:toolzrun = FindConVar("sv_maxplayers");
	new maxcl;
	if (downtownrun == INVALID_HANDLE)
	{
		//Nothing
	}
	if (downtownrun != INVALID_HANDLE)
	{
		new downtown = GetConVarInt(FindConVar("l4d_maxplayers"));
		if (downtown >= 1)
		{
			maxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
		}
	}
	if (toolzrun == INVALID_HANDLE)
	{
		//Nothing
	}
	if (toolzrun != INVALID_HANDLE)
	{
		new toolz = GetConVarInt(FindConVar("sv_maxplayers"));
		if (toolz >= 1)
		{
			maxcl = GetConVarInt(FindConVar("sv_maxplayers"));
		}
	}
	if (downtownrun == INVALID_HANDLE && toolzrun == INVALID_HANDLE)
	{
		maxcl = (MaxClients);
	}
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i) || !IsClientConnected(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		if(!IsFakeClient(i)) continue;
		surbotcount++;
	}
	for (new i = 1; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i) || !IsClientConnected(i)) continue;
		if(GetClientTeam(i) != 3) continue;
		if(!IsFakeClient(i)) continue;
		infbotcount++;
	}
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "Team Displayer");
	DrawPanelText(TeamPanel, " \n");
	if (GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==0 || GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==0 || GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==2 || GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==2|| GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==0|| GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==2 || GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==1 || GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==1  )
	{
		DrawPanelText(TeamPanel, "Survivor:");
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != 2) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			surcount++;
			if (GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==2)
			{
				DrawPanelText(TeamPanel, name);
			}
			else
			{
				if (!IsPlayerAlive(i))
				{
					new String:addoutput[256];
					Format(addoutput, sizeof(addoutput), "%s (Dead) ", name);
					DrawPanelText(TeamPanel, addoutput);
				}
				else if (IsPlayerAlive(i))
				{
					new hp = GetClientHealth(i);
					new String:i1[32];
					new String:i2[32];
					new String:i3[32];
					new i1d = GetPlayerWeaponSlot(i, 3);
					if (i1d == -1||i1d == 0)
					{
						Format(i1, sizeof(i1), "Empty");
					}
					else if (!IsValidEntity(i1d))
					{
						Format(i1, sizeof(i1), "Empty");
					}
					else
					{
						decl String:i1string[64];
						GetEdictClassname(i1d, i1string, sizeof(i1string));
						if (StrEqual(i1string, "weapon_first_aid_kit", false))
						{
							Format(i1, sizeof(i1), "Medkit");
						}
						else if (StrEqual(i1string, "weapon_defibrillator", false))
						{
							Format(i1, sizeof(i1), "Defib");
						}
						else if (StrEqual(i1string, "weapon_upgradepack_explosive", false))
						{
							Format(i1, sizeof(i1), "E Ammo Pack");
						}
						else if (StrEqual(i1string, "weapon_upgradepack_incendiary", false))
						{
							Format(i1, sizeof(i1), "I Ammo Pack");
						}
					}
					new i2d = GetPlayerWeaponSlot(i, 2);
					if (i2d == -1||i2d == 0)
					{
						Format(i2, sizeof(i2), "Empty");
					}
					else if (!IsValidEntity(i2d))
					{
						Format(i2, sizeof(i2), "Empty");
					}
					else
					{
						decl String:i2string[64];
						GetEdictClassname(i2d, i2string, sizeof(i2string));
						if (StrEqual(i2string, "weapon_molotov", false))
						{
							Format(i2, sizeof(i2), "Molotov");
						}
						else if (StrEqual(i2string, "weapon_pipe_bomb", false))
						{
							Format(i2, sizeof(i2), "Pipe Bomb");
						}
						else if (StrEqual(i2string, "weapon_vomitjar", false))
						{
							Format(i2, sizeof(i2), "Vomitjar");
						}
					}
					new i3d = GetPlayerWeaponSlot(i, 4);
					if (i3d == -1||i3d == 0)
					{
						Format(i3, sizeof(i3), "Empty");
					}
					else if (!IsValidEntity(i3d))
					{
						Format(i3, sizeof(i3), "Empty");
					}
					else
					{
						decl String:i3string[64];
						GetEdictClassname(i3d, i3string, sizeof(i3string));
						if (StrEqual(i3string, "weapon_adrenaline", false))
						{
							Format(i3, sizeof(i3), "Adrenaline");
						}
						else if (StrEqual(i3string, "weapon_pain_pills", false))
						{
							Format(i3, sizeof(i3), "Pills");
						}
					}
					if (IsPlayerIncapped(i))
					{
						new String:addoutput[256];
						Format(addoutput, sizeof(addoutput), "%s (Incapped) HP:%d %s %s %s", name, hp,i2,i1,i3);
						DrawPanelText(TeamPanel, addoutput);
					}
					else
					{
						new String:addoutput[256];
						Format(addoutput, sizeof(addoutput), "%s HP:%d %s %s %s", name, hp,i2,i1,i3);
						DrawPanelText(TeamPanel, addoutput);
					}
				}
			}
		}
	}
	if (GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==0 || GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==0 || GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==2 || GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==2|| GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==0|| GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==2 || GetClientTeam(client)==1 && GetConVarInt(PanelDisplayCVAR)==1 || GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==1 )
	{
		DrawPanelText(TeamPanel, "Infected:");
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(i) != 3) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			infcount++;
			if (GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==2)
			{
				DrawPanelText(TeamPanel, name);
			}
			else
			{
				if (!IsPlayerAlive(i))
				{
					new String:addoutput[256];
					if (L4D_GetPlayerSpawnTime(i) < 0)
					{
						Format(addoutput, sizeof(addoutput), "%s (Dead)", name);
					}
					else
					{
						Format(addoutput, sizeof(addoutput), "%s (Dead %f)", name ,L4D_GetPlayerSpawnTime(i));
					}
					DrawPanelText(TeamPanel, addoutput);
				}
				else
				{
					new n = GetEntProp(i, Prop_Send, "m_zombieClass");
					new String:Class[32];
					if (n==1)
					{
						Format(Class, sizeof(Class), "Smoker");
					}
					else if(n==2)
					{
						Format(Class, sizeof(Class), "Boomer");
					}
					else if(n==3)
					{
						Format(Class, sizeof(Class), "Hunter");
					}
					else if(n==4)
					{
						Format(Class, sizeof(Class), "Spitter");
					}
					else if(n==5)
					{
						Format(Class, sizeof(Class), "Jockey");
					}
					else if(n==6)
					{
						Format(Class, sizeof(Class), "Charger");
					}
					else if(n==8)
					{
						Format(Class, sizeof(Class), "Tank");
					}
					if (IsPlayerSpawnGhost(i))
					{
						new String:addoutput[256];
						Format(addoutput, sizeof(addoutput), "%s %s (Ghost)", name,Class);
						DrawPanelText(TeamPanel, addoutput);
					}
					else
					{
						new String:addoutput[256];
						new hp = GetClientHealth(i);
						Format(addoutput, sizeof(addoutput), "%s %s HP:%d", name,Class, hp);
						DrawPanelText(TeamPanel, addoutput);
					}
				}
			}
		}
		
	}
	if (GetConVarInt(SedCVAR) == 1)
	{
		DrawPanelText(TeamPanel, " \n");
		DrawPanelText(TeamPanel, "Spectator:");
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientConnected(i) ) continue;
			if (!IsClientInGame(i)) continue;
			if(GetClientTeam(i) != 1) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			sepcount++;
			DrawPanelText(TeamPanel, name);
		}
	}
	new String:addoutput1[256];
	new total = surcount + infcount + sepcount;
	new surreal = surcount - surbotcount;
	new infreal = infcount - infbotcount;
	new totalreal =  surreal + infreal + sepcount;
	if (GetConVarInt(SedCVAR) == 1)
	{
		if (GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==1)
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivor: %d(%d)/%d  Spectator: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), sepcount);
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivor: %d(%d)/%d Spectator: %d", total, totalreal, surcount,surreal, maxcl, sepcount);
			}
		}
		else if (GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==1)
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Infected: %d(%d)/%d Spectator: %d", total, totalreal,maxcl, infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Infected: %d(%d) Spectator: %d", total, totalreal,  infcount,infreal, sepcount);
			}
		}
		else
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivor: %d(%d)/%d Infected: %d(%d)/%d Spectator: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivor: %d(%d)/%d Infected: %d(%d) Spectator: %d", total, totalreal, surcount,surreal, maxcl, infcount,infreal, sepcount);
			}
		}
	}
	else
	{
		if (GetClientTeam(client)==2 && GetConVarInt(PanelDisplayCVAR)==1)
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivor: %d(%d)/%d ", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")));
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivor: %d(%d)/%d ", total, totalreal, surcount,surreal, maxcl);
			}
		}
		else if (GetClientTeam(client)==3 && GetConVarInt(PanelDisplayCVAR)==1)
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Infected: %d(%d)/%d ", total, totalreal,maxcl, infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Infected: %d(%d) ", total, totalreal,infcount,infreal);
			}
		}
		else
		{
			if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivor: %d(%d)/%d Infected: %d(%d)/%d ", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
			}
			else
			{
				Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivor: %d(%d)/%d Infected: %d(%d) ", total, totalreal, surcount,surreal, maxcl, infcount,infreal);
			}
		}
	}

	DrawPanelText(TeamPanel, addoutput1);
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, GetConVarInt(timeoutCVAR));
	CloseHandle(TeamPanel);
}
public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		dp[param1] = false;
	}
}
stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
bool:IsPlayerSpawnGhost(client)
{
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}
public Action:Reset(Handle:Timer, any:client)
{
	if (se[client])
	{
		se[client] = false;
	}
}
public Action:PAe(Handle:Timer, any:client)
{
	Teampanel(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check if its a valid player
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client)) return;
	if (GetConVarInt(showscoreCVAR) == 1)
	{
		if (buttons & IN_SCORE)
		{
			if (se[client]) return;
			if (dp[client]) return;
			if (se[client] == false)
			{
				se[client] = true;
				if (GetConVarInt(PanelModeCVAR) == 1)
				{
					if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
					{
						PrintToChat(client,"[Team Displayer] You can type !showteam to show the panel");
					}
					if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
					{
						PrintHintText(client,"[Team Displayer] You can type !showteam to show the panel");
					}
				}
				else if (GetConVarInt(PanelModeCVAR) == 2)
				{
					if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
					{
						PrintToChat(client,"[Team Displayer] You can type !showteam to enable/disable the panel");
					}
					if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
					{
						PrintHintText(client,"[Team Displayer] You can type !showteam to enable/disable the panel");
					}
				}
				CreateTimer(2.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(4.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(5.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(6.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(7.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(8.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);

				CreateTimer(8.1, Reset,client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}  
}  

