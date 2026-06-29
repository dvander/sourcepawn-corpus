#include <sourcemod>

//UPDATE INFO
//1.1 - Formated the weapon name to take out the 'weapon_' and capitalized the name
//2 - Fixed bug where K/D weren't adding up on push or skirmish
new g_kills[MAXPLAYERS+1];
new g_deaths[MAXPLAYERS+1];
new Handle:g_CvarEnabled;
new bool:Enabled = true;

public Plugin:myinfo = 
{
	name = "SpecDetails",
	author = "wribit",
	description = "while spectating, shows a panel with details about the person the spectator is watching",
	version = "2",
	url = ""
}

public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_specDetails_enabled","1","Enables(1) or disables(0) the plugin.",FCVAR_NOTIFY);
	HookEvent("round_start", EventRoundStart,EventHookMode_PostNoCopy);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	
	HookConVarChange(g_CvarEnabled, OnCVarChange);
	
	AutoExecConfig(true,"plugin.SpecDetails");
	
	if(Enabled)
	{
		CreateTimer(1.5, getSpecDetails, _ ,TIMER_REPEAT);
	}
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
		
		if(victim == killer || GetClientTeam(victim) == GetClientTeam(killer)) //DON'T COUNT FRIENDLY KILLS
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
		}
		//V2 - took out because was causing push and skirmish players not to accumulate k/D amounts
		//else if(IsFakeClient(victim) && !IsFakeClient(killer))
		//{
		//	g_kills[killer] = g_kills[killer] + 1;
		//}
		//else if(!IsFakeClient(victim) && IsFakeClient(killer))
		//{
		//	g_deaths[victim] = g_deaths[victim] + 1;
		//}
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

public Action:getSpecDetails(Handle:timer)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(Client_IsValid(i,true))
		{
			if(Client_IsIngame(i) && (IsClientObserver(i) || GetClientHealth(i) == 0))
			{
				//get target client
				new ObsTarget = Client_GetObserverTarget(i);
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
					SendPanelToClient(DetailsPanel, i, NullMenuHandler, 1);
					CloseHandle(DetailsPanel);
				}
			}
		}
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
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