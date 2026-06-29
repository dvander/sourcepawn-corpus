#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <sdktools_functions>

#define PLUGIN_VERSION  "1.1.0"
#define PLUGIN_NAME  "[TF2-MvM] Mobile Upgrades"
#define PLUGIN_AUTHOR  "[GNC] Matt"
#define PLUGIN_DESCRIPTION  "Allows you to upgrade on the go."
#define PLUGIN_URL  "http://www.mattsfiles.com"


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

new Handle:g_hcvEnabled = INVALID_HANDLE;
new Handle:g_hcvAllowMedic = INVALID_HANDLE;
new Handle:g_hcvAllowCommand = INVALID_HANDLE;
new Handle:g_hcvRequireDispenser = INVALID_HANDLE;
new Handle:g_hcvRequireBetweenWaves = INVALID_HANDLE;

new bool:g_bEnabled = false;
new bool:g_bAllowMedic = false;
new bool:g_bAllowCommand = false;
new bool:g_bRequireDispenser = false;
new bool:g_bRequireBetweenWaves = false;

new g_iObjectiveResource = -1;

new bool:g_bUpgrading[MAXPLAYERS+1];
new Float:g_faUpgradingAngle[MAXPLAYERS+1][3];

public OnPluginStart()
{
	CreateConVar("sm_mobileupgrades_version", PLUGIN_VERSION, "Mobile Upgrades Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hcvEnabled = CreateConVar("sm_mu_enabled", "1", "Globally enable/disable the Mobile Upgrades plugin.", _, true, 0.0, true, 1.0);
	g_hcvAllowMedic = CreateConVar("sm_mu_allowmedic", "1", "Allow calling for medic to trigger opening upgrade station if other requirements are met.", _, true, 0.0, true, 1.0);
	g_hcvAllowCommand = CreateConVar("sm_mu_allowcommand", "1", "Allow using sm_upgrade to trigger opening upgrade station if other requirements are met.", _, true, 0.0, true, 1.0);
	g_hcvRequireDispenser = CreateConVar("sm_mu_requiredispenser", "1", "Only allow upgrading if near a dispenser.", _, true, 0.0, true, 1.0);
	g_hcvRequireBetweenWaves = CreateConVar("sm_mu_requirebetweenwaves", "0", "Only allow upgrading in-between waves.", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hcvEnabled, OnConVarChanged);
	HookConVarChange(g_hcvAllowMedic, OnConVarChanged);
	HookConVarChange(g_hcvAllowCommand, OnConVarChanged);
	HookConVarChange(g_hcvRequireDispenser, OnConVarChanged);
	HookConVarChange(g_hcvRequireBetweenWaves, OnConVarChanged);
	
	AddCommandListener(OnVoiceMenu, "voicemenu");
	RegConsoleCmd("sm_upgrade", cmdUpgrade, "Open upgrade window (if allowed).");
	
	AutoExecConfig(true, "mobileupgrades");
}

public OnMapStart()
{
	g_iObjectiveResource = -1;
}

public OnClientConnected(client)
{
	g_bUpgrading[client] = false;
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_hcvEnabled);
	g_bAllowMedic = GetConVarBool(g_hcvAllowMedic);
	g_bAllowCommand = GetConVarBool(g_hcvAllowCommand);
	g_bRequireDispenser = GetConVarBool(g_hcvRequireDispenser);
	g_bRequireBetweenWaves = GetConVarBool(g_hcvRequireBetweenWaves);
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == g_hcvEnabled)
		g_bEnabled = bool:StringToInt(newValue);
	else if(cvar == g_hcvAllowMedic)
		g_bAllowMedic = bool:StringToInt(newValue);
	else if(cvar == g_hcvAllowCommand)
		g_bAllowCommand = bool:StringToInt(newValue);
	else if(cvar == g_hcvRequireDispenser)
		g_bRequireDispenser = bool:StringToInt(newValue);
	else if(cvar == g_hcvRequireBetweenWaves)
		g_bRequireBetweenWaves = bool:StringToInt(newValue);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:fVelocity[3], Float:fAngles[3], &weapon)
{
	if(g_bUpgrading[client] && (buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) || (g_faUpgradingAngle[client][0] != fAngles[0] || g_faUpgradingAngle[client][1] != fAngles[1])))
	{
		SetUpgrading(client, false);
	}
	
	return Plugin_Continue;
}

public Action:cmdUpgrade(client, args)
{
	if(!g_bEnabled)
	{
		ReplyToCommand(client, "Mobile Upgrades is currently disabled.");
		return Plugin_Handled;
	}
	
	if(!g_bAllowCommand)
	{
		ReplyToCommand(client, "[Mobile Upgrades] This command is disabled.");
		return Plugin_Handled;
	}
	
	if(g_bRequireDispenser && !NearDispenser(client))
	{
		ReplyToCommand(client, "[Mobile Upgrades] You must be near a dispenser to use this command.");
		return Plugin_Handled;
	}
	
	if(g_bRequireBetweenWaves && !IsBetweenWaves())
	{
		ReplyToCommand(client, "[Mobile Upgrades] You can only use this between waves.");
		return Plugin_Handled;
	}
	
	SetUpgrading(client, true);
	return Plugin_Handled;
}

public Action:OnVoiceMenu(client, const String:szCommand[], iArgc)
{
	if(!g_bEnabled || !g_bAllowMedic) return Plugin_Continue;
	if(iArgc < 2 || !IsPlayerAlive(client)) return Plugin_Continue;
	
	decl String:sArg[255];
	GetCmdArgString(sArg, sizeof(sArg));
	StripQuotes(sArg);
	TrimString(sArg);
	if(!StrEqual(sArg, "0 0")) return Plugin_Continue;
	
	if(g_bRequireDispenser && !NearDispenser(client)) return Plugin_Continue;
	if(g_bRequireBetweenWaves && !IsBetweenWaves()) return Plugin_Continue;
	
	SetUpgrading(client, true);
	return Plugin_Continue;
}

stock bool:IsBetweenWaves()
{
	if(g_iObjectiveResource < 0)
	{
		g_iObjectiveResource = FindEntityByClassname(-1, "tf_objective_resource");
	}
	
	return bool:GetEntProp(g_iObjectiveResource, Prop_Send, "m_bMannVsMachineBetweenWaves");
}

stock SetUpgrading(client, bool:upgrading)
{
	if(upgrading)
	{
		g_bUpgrading[client] = true;
		GetClientEyeAngles(client, g_faUpgradingAngle[client]);
		SetEntProp(client, Prop_Send, "m_bInUpgradeZone", 1);
	}
	else
	{
		g_bUpgrading[client] = false;
		SetEntProp(client, Prop_Send, "m_bInUpgradeZone", 0);
	}
}

stock bool:NearDispenser(client)
{
	new TFTeam:tClientTeam = TFTeam:GetClientTeam(client);
	decl Float:fClientPos[3]; GetClientAbsOrigin(client, fClientPos);
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_dispenser")) != -1)
	{
		
		if(tClientTeam != TFTeam:GetEntProp(entity, Prop_Send, "m_iTeamNum")) continue;
		decl Float:fObjPos[3]; GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fObjPos);
		if(GetVectorDistance(fClientPos, fObjPos) <= 100.0)
			return true;
	}
	return false;
}


