#include <sourcemod>

//UPDATE INFO
//1.1 - Formated the weapon name to take out 'weapon_' and capitalized the name
//2 - Fixed bug where K/D weren't adding up on pvp modes
//3 - Created timers for each client as they die, rather than one timer - to have more control over the display.
//	- Added two commands to turn the spec details display on or off. This was implemented so the sourcemod admin panel would be accessible.

new g_kills[MAXPLAYERS+1];
new g_deaths[MAXPLAYERS+1];
new Handle:PanelTimers[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_CvarEnabled;
new bool:Enabled = true;

public Plugin:myinfo = 
{
	name = "SpecDetails",
	author = "wribit",
	description = "while spectating, shows a panel with details about the person the spectator is watching",
	version = "3",
	url = ""
}

public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_specDetails_enabled","1","Enables(1) or disables(0) the plugin.",FCVAR_NOTIFY);
	HookEvent("round_start", EventRoundStart,EventHookMode_PostNoCopy);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("round_end", EventRoundEnd);
	
	HookConVarChange(g_CvarEnabled, OnCVarChange);
	//V3 - commands
	RegAdminCmd("spec_details_on", Command_SpecDetailsOn, ADMFLAG_SLAY, "Turns on the spectator details display");
	RegAdminCmd("spec_details_off", Command_SpecDetailsOff, ADMFLAG_SLAY, "Turns off the spectator details display");
	
	AutoExecConfig(true,"plugin.SpecDetails");
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		init_kd();
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if(victim == killer || GetClientTeam(victim) == GetClientTeam(killer)) //DON'T COUNT FRIENDLY KILLS OR DEATHS
		{
			return;
		}
		if(IsFakeClient(victim) && IsFakeClient(killer))
		{
			return;
		}
		else
		{
			g_kills[killer] = g_kills[killer] + 1;
			g_deaths[victim] = g_deaths[victim] + 1;
			
			if(!IsFakeClient(victim)) //don't create panel for bots
			{
				//v3 create the timer for each client when they die.
				PanelTimers[victim] = CreateTimer (1.0, getSpecDetails, victim, TIMER_REPEAT);
			}	
		}
	}
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (PanelTimers[client] != INVALID_HANDLE)
	{
		KillTimer(PanelTimers[client]);
		PanelTimers[client] = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client)
{
	if (PanelTimers[client] != INVALID_HANDLE)
	{
		KillTimer(PanelTimers[client]);
		PanelTimers[client] = INVALID_HANDLE;
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{	
		init_kd();
	}
}

public Action:init_kd()
{
	//initialize clients k/d
	for(new i=1;i<=MaxClients;i++)
	{
		g_kills[i] = 0;
		g_deaths[i] = 0;
	}
}

public Action:getSpecDetails(Handle:timer, any:client)
{
	if(Client_IsValid(client,true))
	{
		if(Client_IsIngame(client) && (IsClientObserver(client) || GetClientHealth(client) == 0))
		{
			//get target client
			new ObsTarget = Client_GetObserverTarget(client);
			if(Client_IsValid(ObsTarget,true))
			{
				//get kills
				new TargetKills = g_kills[ObsTarget];
				new String:sPrintKills[10];
				Format(sPrintKills, sizeof(sPrintKills), "Kills: %i", TargetKills);
				//get deaths
				new TargetDeaths = g_deaths[ObsTarget];
				new String:sPrintDeaths[11];
				Format(sPrintDeaths, sizeof(sPrintDeaths), "Deaths: %i", TargetDeaths);
				//get health
				new TargetHealth = GetClientHealth(ObsTarget);
				new String:sPrintHealth[20];
				Format(sPrintHealth, sizeof(sPrintHealth), "Health: %i", TargetHealth);
				//get name
				new String:TargetName[56];
				GetClientName(ObsTarget, TargetName, sizeof(TargetName))
				//get class
				//TODO
				//get weapon
				new String:TargetWeapon[20];
				new String:sPrintWeapon[40];
				Client_GetActiveWeaponName(ObsTarget, TargetWeapon, sizeof(TargetWeapon));
				ReplaceString(TargetWeapon,sizeof(TargetWeapon),"weapon_","");
				String_ToUpper(TargetWeapon,TargetWeapon,sizeof(TargetWeapon));
				Format(sPrintWeapon, sizeof(sPrintWeapon), "Weapon: %s", TargetWeapon);
				
				new Handle:DetailsPanel = CreatePanel(INVALID_HANDLE);
				//DRAW PANEL DETAILS
				DrawPanelText(DetailsPanel, TargetName);
				DrawPanelText(DetailsPanel, sPrintWeapon);
				DrawPanelText(DetailsPanel, sPrintKills);
				DrawPanelText(DetailsPanel, sPrintDeaths);
				DrawPanelText(DetailsPanel, sPrintHealth);
				SendPanelToClient(DetailsPanel, client, NullMenuHandler, 1);
				CloseHandle(DetailsPanel);
			}
		}
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

//COMMANDS
public Action:Command_SpecDetailsOn(client, args)
{
	if (args)
	{
		ReplyToCommand(client, "[SM] Usage: spec_details_on takes no arguments.");
	}
	else
	{
		if(Client_IsValid(client,true))
		{
			if(Client_IsIngame(client) && (IsClientObserver(client) || GetClientHealth(client) == 0))
			{
				if(PanelTimers[client] == INVALID_HANDLE)
				{
					PanelTimers[client] = CreateTimer(1.0, getSpecDetails, client, TIMER_REPEAT);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SpecDetailsOff(client, args)
{
	if (args)
	{
		ReplyToCommand(client, "[SM] Usage: spec_details_off takes no arguments.");
	}
	else
	{
		if(Client_IsValid(client,true))
		{
			if(Client_IsIngame(client) && (IsClientObserver(client) || GetClientHealth(client) == 0))
			{
				if (PanelTimers[client] != INVALID_HANDLE)
				{
					KillTimer(PanelTimers[client]);
					PanelTimers[client] = INVALID_HANDLE;
				}
			}
		}
	}
	
	return Plugin_Handled;
}

//FUNCTIONS
public GetCVars()
{
	Enabled = GetConVarBool(g_CvarEnabled);
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
}

static Client_IsValid(client, bool:checkConnected)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

static Client_IsIngame(client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
}

static Client_GetObserverTarget(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}

static Client_GetActiveWeapon(client)
{
	new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (!Entity_IsValid(weapon)) {
		return INVALID_ENT_REFERENCE;
	}
	
	return weapon;
}

static Client_GetActiveWeaponName(client, String:buffer[], size)
{
	new weapon = Client_GetActiveWeapon(client);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		buffer[0] = '\0';
		return INVALID_ENT_REFERENCE;
	}
	
	Entity_GetClassName(weapon, buffer, size);
	
	return weapon;
}

static String_ToUpper(const String:input[], String:output[], size)
{
	size--;

	new x=0;
	while (input[x] != '\0' && x < size) {
		
		output[x] = CharToUpper(input[x]);
		
		x++;
	}

	output[x] = '\0';
}

static Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}

static Entity_GetClassName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}