#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

new Handle:g_hCvarScout;
new Handle:g_hCvarSoldier;
new Handle:g_hCvarPyro;
new Handle:g_hCvarDemoman;
new Handle:g_hCvarHeavy;
new Handle:g_hCvarEngineer;
new Handle:g_hCvarMedic;
new Handle:g_hCvarSniper;
new Handle:g_hCvarSpy;

new Handle:g_hCvarAdminFlags;
new g_AdminFlags = ADMFLAG_CUSTOM5;

forward OnGetPlayer(client);

public Plugin:myinfo = 
{
	name = "Team Balance Class Immunity",
	author = "Afronanny",
	description = "Give immunity to certain classes",
	version = "1.3",
	url = "http://forums.alliedmods.net/showpost.php?p=1211176&postcount=17"
}

public OnPluginStart()
{
	//tbi = team balance immunity
	g_hCvarScout = CreateConVar("tbi_scout", "0", "Give immunity to scouts", FCVAR_PLUGIN);
	g_hCvarSoldier = CreateConVar("tbi_soldier", "0", "Give immunity to soldiers", FCVAR_PLUGIN);
	g_hCvarPyro = CreateConVar("tbi_pyro", "0", "Give immunity to pyros", FCVAR_PLUGIN);
	g_hCvarDemoman = CreateConVar("tbi_demomen", "0", "Give immunity to demomen", FCVAR_PLUGIN);
	g_hCvarHeavy = CreateConVar("tbi_heavy", "0", "Give immunity to heaviess", FCVAR_PLUGIN);
	g_hCvarEngineer = CreateConVar("tbi_engineer", "0", "Give immunity to engineers", FCVAR_PLUGIN);
	g_hCvarMedic = CreateConVar("tbi_medic", "0", "Give immunity to medics", FCVAR_PLUGIN);
	g_hCvarSniper = CreateConVar("tbi_sniper", "0", "Give immunity to snipers", FCVAR_PLUGIN);
	g_hCvarSpy = CreateConVar("tbi_spy", "0", "Give immunity to spies", FCVAR_PLUGIN);
	g_hCvarAdminFlags = CreateConVar("tbi_adminflags", "s", "Admin flags for immunity based on admin", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarAdminFlags, ConVarChanged_AdminFlags);
	
	AutoExecConfig(true);
}

public OnGetPlayer(client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		
		//If no flags are set, skip admin immunity, so we don't give everyone immunity
		if (g_AdminFlags)
		{
			if (GetUserFlagBits(client) & g_AdminFlags)
			{
				return false;
			}
		}
		if (GetConVarBool(g_hCvarScout) && class == TFClass_Scout)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarSoldier) && class == TFClass_Soldier)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarPyro) && class == TFClass_Pyro)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarDemoman) && class == TFClass_DemoMan)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarHeavy) && class == TFClass_Heavy)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarEngineer) && class == TFClass_Engineer)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarMedic) && class == TFClass_Medic)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarSniper) && class == TFClass_Sniper)
		{
			return false;
		} 
		if (GetConVarBool(g_hCvarSpy) && class == TFClass_Spy)
		{
			return false;
		} 
	}
	return true;
}

public ConVarChanged_AdminFlags(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_AdminFlags = ReadFlagString(newValue);
}

	