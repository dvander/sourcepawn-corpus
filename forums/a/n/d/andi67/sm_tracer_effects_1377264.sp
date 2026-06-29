#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.1.0 (Public)"
#define PLUGIN_PREFIX "\x04Tracers: \x03"

#define MODE_NONE 0
#define MODE_SPECTATE 1
#define MODE_TEAM_MEMBERS 2
#define MODE_ATTACKERS 3

#define LASER_EFFECT "materials/Sprites/physbeam.vmt"
#define LASER_COLORS 13

new g_iArray[LASER_COLORS][4] = 
{
	{   0, 255, 255, 255 },
	{   0,   0, 255, 255 },
	{ 255,   0, 255, 255 },
	{ 128, 128, 128, 255 },
	{   0, 255,   0, 255 },
	{ 128, 128,   0, 255 },
	{ 128,   0, 128, 255 },
	{ 255, 105, 180, 255 },
	{ 255,   0,   0, 255 },
	{   0, 128, 128, 255 },
	{ 148,   0, 211, 255 },
	{ 255, 255, 255, 255 },
	{ 255, 255,   0, 255 }
	
};

new String:g_sArray[LASER_COLORS][] = 
{
	"Cyan",
	"Blue",
	"Fuschia",
	"Gray",
	"Green",
	"Olive",
	"Purple",
	"Pink",
	"Red",
	"Teal",
	"Violet",
	"White",
	"Yellow"
};

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hClient = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hColor = INVALID_HANDLE;
new Handle:g_hRandom = INVALID_HANDLE;
new Handle:g_hMode = INVALID_HANDLE;
new Handle:g_hTeam = INVALID_HANDLE;
new Handle:g_hTeamT = INVALID_HANDLE;
new Handle:g_hTeamCT = INVALID_HANDLE;
new Handle:g_hTrans = INVALID_HANDLE;
new Handle:g_hLife = INVALID_HANDLE;
new Handle:g_hWidth = INVALID_HANDLE;

new Handle:g_cEnabled = INVALID_HANDLE;
new Handle:g_cColored = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bClient, bool:g_bDefault, bool:g_bTeam, bool:g_bRandom, bool:g_bLateLoad;
new g_iMode, g_iColor, g_iTrans, g_iColors[2][4], g_iLaser;
new Float:g_fLife, Float:g_fWidth;

new bool:g_bColored[MAXPLAYERS + 1];
new bool:g_bAppear[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new g_iTracer[MAXPLAYERS + 1];
new g_iTeam[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Tracer Effects",
	author = "Twisted|Panda (ORIG: Chocolate and Cheese)",
	description = "A tracer plugin (laser beam from gun muzzle to bullet impact) with various settings.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_tracer_effects_version", PLUGIN_VERSION, "Tracer Effects Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_tracer_effects", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hClient = CreateConVar("sm_tracer_effects_client", "1", "If enabled, clients will be able to modify their ability to view tracers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hMode = CreateConVar("sm_tracer_effects_mode", "0", "Determines tracer functionality: (0 = No Special Mode, 1 = Spectators/Dead Only, 2 = Team Members Only, 3 = Attackers w/ Enabled Only)", FCVAR_NONE, true, 0.0, true, 3.0);

	g_hTeam = CreateConVar("sm_tracer_effects_team", "0", "If enabled, client tracers are colored to match their team assigned colors.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTeamT = CreateConVar("sm_tracer_effects_team_t", "255 0 0", "The assigned color for players on the Terrorist team.", FCVAR_NONE);
	g_hTeamCT = CreateConVar("sm_tracer_effects_team_ct", "0 0 255", "The assigned color for players on the Counter-Terrorist team.", FCVAR_NONE);

	g_hDefault = CreateConVar("sm_tracer_effects_default", "1", "If sm_tracer_effects_client is enabled, determines the default display mode for tracers for new clients. (1 = On, 0 = Off)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hColor = CreateConVar("sm_tracer_effects_color", "-1", "The default color clients are assigned upon connecting. (-1 = Random, # = Specific Color Index)", FCVAR_NONE, true, -1.0, true, float(LASER_COLORS));
	g_hRandom = CreateConVar("sm_tracer_effects_random", "0", "If enabled, clients are unable to pick their own colors and every tracer is random.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTrans = CreateConVar("sm_tracer_effects_alpha", "150", "The degree of transparency for all fired tracers. (0 = Invisible, 255 = Full Visible)", FCVAR_NONE, true, 0.0, true, 255.0);
	g_hLife = CreateConVar("sm_tracer_effects_life", "0.3", "The life time of all fired tracers, or in other words, how quickly they disappear after appaering.", FCVAR_NONE, true, 0.1);
	g_hWidth = CreateConVar("sm_tracer_effects_width", "3.0", "The width of the beam for all fired tracers.", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "sm_tracer_effects");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hClient, Action_OnSettingsChange);
	HookConVarChange(g_hMode, Action_OnSettingsChange);
	HookConVarChange(g_hTeam, Action_OnSettingsChange);
	HookConVarChange(g_hTeamT, Action_OnSettingsChange);
	HookConVarChange(g_hTeamCT, Action_OnSettingsChange);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
	HookConVarChange(g_hColor, Action_OnSettingsChange);
	HookConVarChange(g_hRandom, Action_OnSettingsChange);
	HookConVarChange(g_hTrans, Action_OnSettingsChange);
	HookConVarChange(g_hLife, Action_OnSettingsChange);
	HookConVarChange(g_hWidth, Action_OnSettingsChange);

	RegConsoleCmd("sm_tracer", Command_Tracers);
	RegConsoleCmd("sm_tracers", Command_Tracers);
	HookEvent("weapon_fire", Event_OnBulletImpact);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);

	
	g_cEnabled = RegClientCookie("Tracer_Effects", "Tracer Settings", CookieAccess_Protected);
	g_cColored = RegClientCookie("Tracer_Effects", "Tracer Settings", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Display, 0, "Tracer Settings");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnMapStart()
{
	Void_SetDefaults();

	g_iLaser = PrecacheModel(LASER_EFFECT);
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				if(IsPlayerAlive(i))
					g_bAlive[i] = true;
				else
					g_bAlive[i] = false;

				if(!IsFakeClient(i))
					CreateTimer(0.0, Timer_Check, i, TIMER_FLAG_NO_MAPCHANGE);
				else
				{
					g_bAppear[i] = false;
	
					if(!g_bTeam)
					{
						g_bColored[i] = false;
						if(g_iColor == -1)
							g_iTracer[i] = GetRandomInt(0, (LASER_COLORS - 1));
						else
							g_iTracer[i] = g_iColor;
					}
				}
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
	}
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		if(!IsFakeClient(client))
			CreateTimer(0.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			g_bAppear[client] = false;
			if(!g_bTeam)
			{
				g_bColored[client] = false;
				if(g_iColor == -1)
					g_iTracer[client] = GetRandomInt(0, (LASER_COLORS - 1));
				else
					g_iTracer[client] = g_iColor;
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_bAlive[client] = true;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_bAlive[client] = false;
	}

	return Plugin_Continue;
}

public Event_OnBulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
		GetClientEyePosition(attacker, vecOrigin);
		GetClientEyeAngles(attacker, vecAng);
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);
		
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 0;
			
			CloseHandle(trace);

			switch(g_iMode)
			{
				case MODE_NONE:
				{
					if(g_bClient)
					{
						for(new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !IsFakeClient(i))
							{
								if(g_bAppear[i])
								{
									if(!g_bRandom)
									{
										if(!g_bTeam)
										{
											if(!g_bColored[i])
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[attacker]], 0);
											else
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[i]], 0);
										}
										else
											TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iColors[g_iTeam[attacker] - 2], 0);
									}
									else
									{
										new g_iRandom[4];
										for(new j = 0; j <= 2; j++)
											g_iRandom[j] = GetRandomInt(0, 255);
										g_iRandom[3] = g_iTrans;

										TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iRandom, 0);
									}
									TE_SendToClient(i);
								}
							}
						}
					}
					else
					{
						if(!g_bRandom)
						{
							if(!g_bTeam)
								TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[attacker]], 0);
							else
								TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iColors[g_iTeam[attacker] - 2], 0);
						}
						else
						{
							new g_iRandom[4];
							for(new j = 0; j <= 2; j++)
								g_iRandom[j] = GetRandomInt(0, 255);
							g_iRandom[3] = g_iTrans;

							TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iRandom, 0);
						}

						TE_SendToAll();
					}
				}
				case MODE_SPECTATE:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i))
						{
							if(g_iTeam[i] <= 1 || !g_bAlive[i])
							{
								if(!g_bClient || g_bClient && g_bAppear[i])
								{
									if(!g_bRandom)
									{
										if(!g_bTeam)
										{
											if(!g_bColored[i])
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[attacker]], 0);
											else
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[i]], 0);
										}
										else
											TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iColors[g_iTeam[attacker] - 2], 0);
									}
									else
									{
										new g_iRandom[4];
										for(new j = 0; j <= 2; j++)
											g_iRandom[j] = GetRandomInt(0, 255);
										g_iRandom[3] = g_iTrans;

										TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iRandom, 0);
									}
									TE_SendToClient(i);
								}
							}
						}
					}
				}
				case MODE_TEAM_MEMBERS:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i))
						{
							if(g_iTeam[i] == g_iTeam[attacker])
							{
								if(!g_bClient || g_bClient && g_bAppear[i])
								{
									if(!g_bRandom)
									{
										if(!g_bTeam)
										{
											if(!g_bColored[i])
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[attacker]], 0);
											else
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[i]], 0);
										}
										else
											TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iColors[g_iTeam[attacker] - 2], 0);
									}
									else
									{
										new g_iRandom[4];
										for(new j = 0; j <= 2; j++)
											g_iRandom[j] = GetRandomInt(0, 255);
										g_iRandom[3] = g_iTrans;

										TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iRandom, 0);
									}
									TE_SendToClient(i);
								}
							}
						}
					}
				}
				case MODE_ATTACKERS:
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i))
						{
							if(g_bAppear[i])
							{
								if(!g_bClient || g_bClient && g_bAppear[i])
								{
									if(!g_bRandom)
									{
										if(!g_bTeam)
										{
											if(!g_bColored[i])
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[attacker]], 0);
											else
												TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iArray[g_iTracer[i]], 0);
										}
										else
											TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iColors[g_iTeam[attacker] - 2], 0);
									}
									else
									{
										new g_iRandom[4];
										for(new j = 0; j <= 2; j++)
											g_iRandom[j] = GetRandomInt(0, 255);
										g_iRandom[3] = g_iTrans;

										TE_SetupBeamPoints(vecOrigin, vecPos, g_iLaser, 0, 0, 0, g_fLife, g_fWidth, g_fWidth, 1, 0.0, g_iRandom, 0);
									}
									TE_SendToClient(i);
								}
							}
						}
					}
				}
			}
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) 
{
	return entity>MaxClients;
}

public Action:Command_Tracers(client, args)
{
	if(!g_bEnabled)
		PrintToChat(client, "%sThis feature is currently disabled!", PLUGIN_PREFIX);
	else
		if(client && IsClientInGame(client))
			Void_CookieMenu(client);
}

public Menu_Display(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Tracer Settings");
		case CookieMenuAction_SelectOption:
		{
			if(!g_bEnabled)
				PrintToChat(client, "%sThis feature is currently disabled", PLUGIN_PREFIX);
			else
				if(client && IsClientInGame(client))
					Void_CookieMenu(client);
		}
	}
}

void:Void_CookieMenu(client)
{
	new Handle:g_hMenu = CreateMenu(Menu_CookieMenu);
	decl String:g_sText[64];

	Format(g_sText, sizeof(g_sText), "Tracer Settings\n=--=--=");
	SetMenuTitle(g_hMenu, g_sText);

	if(!g_bRandom && !g_bTeam)
		AddMenuItem(g_hMenu, "Tracer_Effects", "Select Tracer Color");
	else
		AddMenuItem(g_hMenu, "Tracer_Effects", "Select Tracer Color", ITEMDRAW_DISABLED);

	if(g_bTeam)
		AddMenuItem(g_hMenu, "Tracer_Effects", "Team Coloring Enabled", ITEMDRAW_DISABLED);
	else
	{
		if(g_bColored[client])
			AddMenuItem(g_hMenu, "Tracer_Effects", "Color Own Tracers");
		else
			AddMenuItem(g_hMenu, "Tracer_Effects", "Color All Tracers");
	}

	if(g_bAppear[client])
		AddMenuItem(g_hMenu, "Tracer_Effects", "Disable Tracer Effects");
	else
		AddMenuItem(g_hMenu, "Tracer_Effects", "Enable Tracer Effects");

	SetMenuExitBackButton(g_hMenu, true);
	SetMenuExitButton(g_hMenu, true);
	DisplayMenu(g_hMenu, client, 15);
}

public Menu_CookieMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					Void_ColorMenu(param1);
				case 1:
				{
					if(g_bColored[param1])
					{
						g_bColored[param1] = false;
						SetClientCookie(param1, g_cColored, "-1");

						PrintToChat(param1, "%sYour color preference will only be applied to personal tracers!", PLUGIN_PREFIX);
					}
					else
					{
						g_bColored[param1] = true;
						SetClientCookie(param1, g_cColored, "1");

						PrintToChat(param1, "%sYour color preference will be applied to all tracers!", PLUGIN_PREFIX);
					}
				}
				case 2:
				{
					if(g_iTracer[param1] == -1)
					{
						if(g_iColor == -1)
							g_iTracer[param1] = GetRandomInt(0, LASER_COLORS);
						else
							g_iTracer[param1] = g_iColor;
					}
					
					if(g_bAppear[param1])
					{
						g_bAppear[param1] = false;
						SetClientCookie(param1, g_cEnabled, "-1");

						PrintToChat(param1, "%sYou've disabled the ability to see tracers!", PLUGIN_PREFIX);
					}
					else
					{
						new String:g_sTemp[3];
						IntToString(g_iTracer[param1], g_sTemp, sizeof(g_sTemp));
						
						g_bAppear[param1] = true;
						SetClientCookie(param1, g_cEnabled, g_sTemp);
						
						PrintToChat(param1, "%sYou've enabled the ability to see tracers!", PLUGIN_PREFIX);
					}
				}
			}
		}
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					ShowCookieMenu(param1);
			}
		}
		case MenuAction_End:
			CloseHandle(menu);
	}
}

void:Void_ColorMenu(client)
{
	new Handle:g_hMenu = CreateMenu(Menu_ColorMenu);
	decl String:g_sText[64];

	Format(g_sText, sizeof(g_sText), "Tracer Colors\n-==-==-==-==-");
	SetMenuTitle(g_hMenu, g_sText);

	for(new i = 0; i < LASER_COLORS; i++)
		AddMenuItem(g_hMenu, "Tracer_Effects", g_sArray[i]);

	SetMenuExitBackButton(g_hMenu, true);
	SetMenuExitButton(g_hMenu, true);
	DisplayMenu(g_hMenu, client, 15);
}

public Menu_ColorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			PrintToChat(param1, "%sYou've changed your tracer color to %s!", PLUGIN_PREFIX, g_sArray[param2]);
			g_iTracer[param1] = param2;
			
			new String:g_sTemp[3];
			IntToString(g_iTracer[param1], g_sTemp, sizeof(g_sTemp));
			SetClientCookie(param1, g_cEnabled, g_sTemp);
		}
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					Void_CookieMenu(param1);
			}
		}
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public Action:Timer_Check(Handle:timer, any:client)
{
	if(client)
	{
		if(AreClientCookiesCached(client))
			CreateTimer(0.0, Timer_Process, client, TIMER_FLAG_NO_MAPCHANGE);
		else if(IsClientInGame(client))
			CreateTimer(5.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Timer_Process(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintToChat(client, "%sType !tracers in chat to modify your settings!", PLUGIN_PREFIX);

		decl String:g_sCookie[3] = "";
		GetClientCookie(client, g_cEnabled, g_sCookie, sizeof(g_sCookie));

		if(StrEqual(g_sCookie, ""))
		{
			if(g_iColor == -1)
				g_iTracer[client] = GetRandomInt(0, (LASER_COLORS - 1));
			else
				g_iTracer[client] = g_iColor;

			if(!g_bDefault)
			{
				g_bAppear[client] = false;
				SetClientCookie(client, g_cEnabled, "-1");
			}
			else
			{
				new String:g_sTemp[3];
				IntToString(g_iTracer[client], g_sTemp, sizeof(g_sTemp));
			
				g_bAppear[client] = true;
				SetClientCookie(client, g_cEnabled, g_sTemp);
			}

			SetClientCookie(client, g_cColored, "-1");
			g_bColored[client] = false;
		}
		else
		{
			if(StrEqual(g_sCookie, "-1"))
			{
				g_bAppear[client] = false;
				if(g_iColor == -1)
					g_iTracer[client] = GetRandomInt(0, (LASER_COLORS - 1));
				else
					g_iTracer[client] = g_iColor;
			}
			else
			{
				g_bAppear[client] = true;
				g_iTracer[client] = StringToInt(g_sCookie);

				GetClientCookie(client, g_cEnabled, g_sCookie, sizeof(g_sCookie));
				if(StrEqual(g_sCookie, "1"))
					g_bColored[client] = true;
				else
					g_bColored[client] = false;
			}
		}
	}

	return Plugin_Continue;
}

void:Void_SetDefaults()
{
	new g_iTemp;
	decl String:g_sTemp[32], String:g_sEffects[3][5];

	g_iTemp = GetConVarInt(g_hEnabled);
	if(g_iTemp)
		g_bEnabled = true;
	else
		g_bEnabled = false;

	g_iTemp = GetConVarInt(g_hClient);
	if(g_iTemp)
		g_bClient = true;
	else
		g_bClient = false;

	g_iTemp = GetConVarInt(g_hDefault);
	if(g_iTemp)
		g_bDefault = true;
	else
		g_bDefault = false;

	g_iColor = GetConVarInt(g_hColor);

	g_iMode = GetConVarInt(g_hMode);

	g_iTemp = GetConVarInt(g_hTeam);
	if(g_iTemp)
		g_bTeam = true;
	else
		g_bTeam = false;

	GetConVarString(g_hTeamT, g_sTemp, sizeof(g_sTemp));
	ExplodeString(g_sTemp, " ", g_sEffects, 3, 5);
	for(new i = 0; i <= 2; i++)
		g_iColors[0][i] = StringToInt(g_sEffects[i]);
	g_iColors[0][3] = g_iTrans;

	GetConVarString(g_hTeamCT, g_sTemp, sizeof(g_sTemp));
	ExplodeString(g_sTemp, " ", g_sEffects, 3, 5);
	for(new i = 0; i <= 2; i++)
		g_iColors[1][i] = StringToInt(g_sEffects[i]);
	g_iColors[1][3] = g_iTrans;

	g_iTrans = GetConVarInt(g_hTrans);
	for(new i = 0; i < LASER_COLORS; i++)
		g_iArray[i][3] = g_iTrans;

	g_fLife = GetConVarFloat(g_hLife);

	g_fWidth = GetConVarFloat(g_hWidth);
	
	g_iTemp = GetConVarInt(g_hRandom);
	if(g_iTemp)
		g_bRandom = true;
	else
		g_bRandom = false;
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	new g_iTemp;
	decl String:g_sEffects[3][5];

	if(cvar == g_hEnabled)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bEnabled = true;
		else
			g_bEnabled = false;
	}
	else if(cvar == g_hClient)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bClient = true;
		else
			g_bClient = false;
	}
	else if(cvar == g_hDefault)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bDefault = true;
		else
			g_bDefault = false;
	}
	else if(cvar == g_hColor)
		g_iColor = StringToInt(newvalue);
	else if(cvar == g_hMode)
		g_iMode = StringToInt(newvalue);
	else if(cvar == g_hTeam)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bTeam = true;
		else
			g_bTeam = false;
	}
	else if(cvar == g_hTeamT)
	{
		ExplodeString(newvalue, " ", g_sEffects, 3, 5);
		for(new i = 0; i <= 2; i++)
			g_iColors[0][i] = StringToInt(g_sEffects[i]);
		g_iColors[0][3] = g_iTrans;
	}
	else if(cvar == g_hTeamCT)
	{
		ExplodeString(newvalue, " ", g_sEffects, 3, 5);
		for(new i = 0; i <= 2; i++)
			g_iColors[1][i] = StringToInt(g_sEffects[i]);
		g_iColors[1][3] = g_iTrans;
	}
	else if(cvar == g_hTrans)
	{
		g_iTrans = StringToInt(newvalue);
		for(new i = 0; i < LASER_COLORS; i++)
			g_iArray[i][3] = g_iTrans;
	}
	else if(cvar == g_hLife)
		g_fLife = StringToFloat(newvalue);
	else if(cvar == g_hWidth)
		g_fWidth = StringToFloat(newvalue);
	else if(cvar == g_hRandom)
	{
		g_iTemp = StringToInt(newvalue);
		if(g_iTemp)
			g_bRandom = true;
		else
			g_bRandom = false;
	}
}