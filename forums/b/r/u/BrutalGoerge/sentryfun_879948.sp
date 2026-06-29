#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define TEAM_RED 2
#define TEAM_BLU 3
#define VERSION "1.4"

new Handle:cvar_Enabled = INVALID_HANDLE;
new Handle:cvar_WinningBetry = INVALID_HANDLE;
new Handle:cvar_BetrayChance = INVALID_HANDLE;
new Handle:cvar_ReactiveChance = INVALID_HANDLE;
new bool:g_bHooked = false;
new bool:g_bBonusRound = false;
public Plugin:myinfo = 
{
	name = "Sentry Fun",
	author = "Goerge",
	description = "Restores sentry operation for losing team and turns the winning team's sentries against them",
	version = VERSION,
	url = "https://tf2tmng.googlecode.com"
};

public OnPluginStart()
{
	cvar_Enabled = CreateConVar("sentryfun_enabled", "1", "Enable/disable the plugin and its hook", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_WinningBetry = CreateConVar("sentryfun_betray", "1", "Winning team's sentries attack members of the winning team.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_BetrayChance = CreateConVar("sentryfun_betray_chance", "1.00", "% chance that a sentry will betray its teammates.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ReactiveChance = CreateConVar("sentryfun_reactivate_chance", "1.00", "% chance that a sentry will reactivate if its been disabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sentryfun_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookConVarChange(cvar_Enabled, EnabledChange);
	AutoExecConfig(true, "plugin.sentryfun");
}

public OnConfigsExecuted()
{
	if (GetConVarBool(cvar_Enabled))
	{
		if (!g_bHooked)
		{
			HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		}
		g_bHooked = true;
	}
	else
	{
		if (g_bHooked)
		{
			UnhookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
			UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		}
		g_bHooked = false;
	}
}
public EnabledChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		if (g_bHooked)
		{
			UnhookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
			UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		}
		g_bHooked = false;
	}
	else if (StringToInt(newValue) == 1)
	{
		if (!g_bHooked)
		{
			HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		}
		g_bHooked = true;
	}
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBonusRound = true;
	if (GetTeamClientCount(2) && GetTeamClientCount(3))
		CreateTimer(0.5, timer_SentryDelay, GetEventInt(event, "team"), TIMER_FLAG_NO_MAPCHANGE);	
	return Plugin_Continue;
}	

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBonusRound = false;
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (g_bBonusRound)
		DestroySentry(client);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bBonusRound)
		DestroySentry(GetEventInt(event, "userid"));
}

public Action:timer_SentryDelay(Handle:timer, any:team)
{
	ManipulateSentries(team);
	return Plugin_Handled;
}

stock ManipulateSentries(winningTeam)
{
	new	client, iEnt = -1, iTeamser = GetOppositeTeamMember(winningTeam), Float:location[3], Float:angle[3], iPrev = 0,
		Float:fBetrayChance = GetConVarFloat(cvar_BetrayChance), Float:fAtivateChance = GetConVarFloat(cvar_ReactiveChance), Float:ran,
		bool:bMini = false,
		bool:bDisposable = false;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	{
		if ((client = GetEntDataEnt2(iEnt, FindSendPropOffs("CObjectSentrygun", "m_hBuilder"))) == -1)
			continue;
		ran = GetRandomFloat(0.0, 1.0);
		if (GetClientTeam(client) == winningTeam)
		{
			if (GetConVarBool(cvar_WinningBetry))
			{
				if (fBetrayChance >= ran)
				{
					GetEntDataVector(iEnt, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"), location);
					GetEntDataVector(iEnt, FindSendPropOffs("CObjectSentrygun","m_angRotation"), angle);
					if (iPrev > 0)
						RemoveEdict(iPrev);
					iPrev = iEnt;
					if (GetEntProp(iEnt, Prop_Send, "m_bMiniBuilding"))
						bMini = true;
					if (GetEntProp(iEnt, Prop_Send, "m_bMiniBuilding"))
						bDisposable = true;
					TF2_BuildSentry(iTeamser, location, angle, GetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel"), bMini, bDisposable);
				}
			}
		}
		else if (fAtivateChance >= ran)
		{
			SetEntProp(iEnt, Prop_Send, "m_bDisabled", 0);
			SetEntData(iEnt, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"), (GetEntProp(iEnt, Prop_Send, "m_iMaxHealth") + 100), 4, true);
			SetEntData(iEnt, FindSendPropOffs("CObjectSentrygun","m_iHealth"), (GetEntProp(iEnt, Prop_Send, "m_iMaxHealth") + 100), 4, true);
		}
		
	}
	if (iPrev)
		RemoveEdict(iPrev);
}

stock GetOppositeTeamMember(team)	// returns a client on the opposite team!
{
	new client, highScore = 0, tempScore;
	team = team == TEAM_RED ? TEAM_BLU : TEAM_RED;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if ((tempScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, client)) >= highScore)
			{
				client = i;
				highScore = tempScore;
			}
		}
	}
	return client;
}

DestroySentry(client)
{
	new iEnt = -1;
	
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	if (GetEntDataEnt2(iEnt, FindSendPropOffs("CObjectSentrygun", "m_hBuilder")) == client)
	{
		SetVariantInt(9999);
		AcceptEntityInput(iEnt, "RemoveHealth");
	}
}

//code from Pelipoika
stock TF2_BuildSentry(builder, Float:fOrigin[3], Float:fAngle[3], level, bool:mini=false, bool:disposable=false, bool:carried=false, flags=4)
{
	static const Float:m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, Float:m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const Float:m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, Float:m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	new sentry = CreateEntityByName("obj_sentrygun");
	
	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);

		DispatchKeyValueVector(sentry, "origin", fOrigin);
		DispatchKeyValueVector(sentry, "angles", fAngle);
		
		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
		}
	}
}


/*
stock TF2_BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1)							//Not my code, credit goes to The JCS and Muridas
{
	new Float:fBuildMaxs[3];
	fBuildMaxs[0] = 24.0;
	fBuildMaxs[1] = 24.0;
	fBuildMaxs[2] = 66.0;

	new Float:fMdlWidth[3];
	fMdlWidth[0] = 1.0;
	fMdlWidth[1] = 0.5;
	fMdlWidth[2] = 0.0;
    
	decl String:sModel[64];
    
	new iTeam = GetClientTeam(iBuilder);

	new iShells, iHealth, iRockets;

	if(iLevel == 1)
	{
		sModel = "models/buildables/sentry1.mdl";
		iShells = 100;
		iHealth = 200;
	}
	else if(iLevel == 2)
	{
		sModel = "models/buildables/sentry2.mdl";
		iShells = 120;
		iHealth = 230;
	}
	else if(iLevel == 3)
	{
		sModel = "models/buildables/sentry3.mdl";
		iShells = 144;
		iHealth = 250;
		iRockets = 20;
	}
    
	new iSentry = CreateEntityByName("obj_sentrygun");  
	DispatchSpawn(iSentry);
	TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"),         4, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"),         4, 4 , true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") ,                 iShells, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"),                 iHealth, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"),                     iHealth, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"),                 0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"),                     0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"),                 0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"),                 3, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"),                     1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"),             0, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"),                 0, 2, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"),                     (iTeam-2), 1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"),     1, 1, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"),             iLevel, 4, true);
	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"),                 iRockets, 4, true);
    
	SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
	SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"),     iBuilder, true);

	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"),                     0.0, true);
	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"),             1.0, true);
	SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"),     1.0, true);

	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0);    
	SetEntityModel(iSentry,sModel);
}  
*/