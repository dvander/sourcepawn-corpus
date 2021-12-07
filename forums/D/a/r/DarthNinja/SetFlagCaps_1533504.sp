#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#define PLUGIN_VERSION "1.0.1"

//#define INCLUDE_SPEC_TEAMS

//Vars to hold the team indexes:
#if defined INCLUDE_SPEC_TEAMS
new g_iTeamUnasIndex, g_iTeamSpecIndex;
#endif
new g_iTeamRedIndex, g_iTeamBlueIndex;

public Plugin:myinfo = {
	name             = "[TF2] SetFlagCaps",
	author         = "DarthNinja",
	description     = "Set a Team's number of Flag Caps",
	version         = PLUGIN_VERSION,
	url             = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_setflagcaps_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_getflagcaps", Debug, ADMFLAG_BAN);
	RegAdminCmd("sm_setflagcaps", SetFlagCaps, ADMFLAG_BAN);
}

public OnMapStart()
{
#if defined INCLUDE_SPEC_TEAMS
	g_iTeamUnasIndex = -1;
	g_iTeamSpecIndex = -1;
#endif
	g_iTeamRedIndex = -1;
	g_iTeamBlueIndex = -1;

	new iTeam = -1;
	new iTeamNum;
	while ((iTeam = FindEntityByClassname2(iTeam, "tf_team")) != -1)
	{
		iTeamNum = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");

		switch (TFTeam:iTeamNum)
		{
#if defined INCLUDE_SPEC_TEAMS
			case TFTeam_Unassigned:
				g_iTeamUnasIndex = iTeam;
			case TFTeam_Spectator:
				g_iTeamSpecIndex = iTeam;
#endif
			case TFTeam_Red:
				g_iTeamRedIndex = iTeam;
			case TFTeam_Blue:
				g_iTeamBlueIndex = iTeam;
		}
	}

	if (g_iTeamRedIndex == -1 || g_iTeamBlueIndex == -1) //could check spec and unassigned, but theres no point
		SetFailState("Unable to find the correct ent id for red team or blue team!");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SetFlagCaps_Red", SetRedCaps);
	CreateNative("SetFlagCaps_Blue", SetBlueCaps);
	
	CreateNative("GetFlagCaps_Red", GetRedCaps);
	CreateNative("GetFlagCaps_Blue", GetBlueCaps);
	
	RegPluginLibrary("SetFlagCaps");
	return APLRes_Success;
}

public GetRedCaps(Handle:plugin, numParams)
{
	return GetEntProp(g_iTeamRedIndex, Prop_Send, "m_nFlagCaptures");
}
public GetBlueCaps(Handle:plugin, numParams)
{
	return GetEntProp(g_iTeamBlueIndex, Prop_Send, "m_nFlagCaptures");
}

public SetRedCaps(Handle:plugin, numParams)
{
	new iCaps = GetNativeCell(1);
	if (iCaps < 0 || iCaps > 127)
		return false;
	SetEntProp(g_iTeamRedIndex, Prop_Send, "m_nFlagCaptures", iCaps);
	if (GetEntProp(g_iTeamRedIndex, Prop_Send, "m_nFlagCaptures") == iCaps)
		return true;
	return false;
}
public SetBlueCaps(Handle:plugin, numParams)
{
	new iCaps = GetNativeCell(1);
	if (iCaps < 0 || iCaps > 127)
		return false;
	SetEntProp(g_iTeamBlueIndex, Prop_Send, "m_nFlagCaptures", iCaps);
	if (GetEntProp(g_iTeamBlueIndex, Prop_Send, "m_nFlagCaptures") == iCaps)
		return true;
	return false;
}

public Action:SetFlagCaps(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_setflagcaps <Red/Blue> <Value>");
		return Plugin_Handled;
	}
	
	decl String:sTeam[10];
	decl String:sCaps[64];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	GetCmdArg(2, sCaps, sizeof(sCaps));
	new iCaps = StringToInt(sCaps);
	
	if (iCaps < 0 || iCaps > 127)
	{
		ReplyToCommand(client, "The number of flag caps can only be from 0 to 127");
		return Plugin_Handled;
	}
	
	if (StrEqual(sTeam, "Red", false))
		SetEntProp(g_iTeamRedIndex, Prop_Send, "m_nFlagCaptures", iCaps);
	else if (StrEqual(sTeam, "Blue", false)) //check could be removed, but lets leave it
		SetEntProp(g_iTeamBlueIndex, Prop_Send, "m_nFlagCaptures", iCaps);
	else
	{
		ReplyToCommand(client, "Error: Please specify a valid team! Use Red or Blue as the first arg.");
		return Plugin_Handled;
	}
	ShowActivity2(client, "[SM] ", "Set %s team's number of caps to %i", sTeam, iCaps);
	LogAction(client, -1, "%L Set %s team's number of caps to %i", client, sTeam, iCaps);
	return Plugin_Handled;
}


public Action:Debug(client, args)
{
	//Vars to hold the team indexes:
#if defined INCLUDE_SPEC_TEAMS
	new iTeamUnasIndex = -1;
	new iTeamSpecIndex = -1;
#endif
	new iTeamRedIndex = -1;
	new iTeamBlueIndex = -1;
	//------
	new iTeam = -1;
	new iTeamNum;
	while ((iTeam = FindEntityByClassname2(iTeam, "tf_team")) != -1)
	{
		iTeamNum = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
		//ReplyToCommand(client, "iTeam Index: %i, iTeamNum: %i", iTeam, iTeamNum);	//debug

		switch (TFTeam:iTeamNum)
		{
#if defined INCLUDE_SPEC_TEAMS
			case TFTeam_Unassigned:
				iTeamUnasIndex = iTeam;
			case TFTeam_Spectator:
				iTeamSpecIndex = iTeam;
#endif
			case TFTeam_Red:
				iTeamRedIndex = iTeam;
			case TFTeam_Blue:
				iTeamBlueIndex = iTeam;
		}
	}

	new iRedCaps = GetEntProp(iTeamRedIndex, Prop_Send, "m_nFlagCaptures");
	new iBlueCaps = GetEntProp(iTeamBlueIndex, Prop_Send, "m_nFlagCaptures");

	ReplyToCommand(client, "Red captures: %i\nBlue captures: %i", iRedCaps, iBlueCaps);

	return Plugin_Handled;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
