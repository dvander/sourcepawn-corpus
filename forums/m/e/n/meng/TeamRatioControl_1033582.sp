#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.7"
#define TEAM_AUTO 0
#define TEAM_SPEC 1
#define TEAM_ONE 2
#define TEAM_TWO 3
#define DENY_SOUND "common/wpn_denyselect.wav"

public Plugin:myinfo = 
{
	name = "Team Ratio Control",
	author = "meng",
	version = PLUGIN_VERSION,
	description = "Controls team sizes by way of ratio.",
	url = ""
};

new Handle:g_enabled;
new Handle:g_minplayers;
new Handle:g_ratio;
new Handle:g_grace;
new Handle:g_adjustteams;
new Float:g_teamOneDiv;
new Float:g_teamTwoDiv;
new Float:g_graceMul;

public OnPluginStart()
{
	CreateConVar("sm_trc_version", PLUGIN_VERSION, "team ratio control version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_enabled = CreateConVar("sm_trc_enabled", "1", "enable plugin?");
	g_minplayers = CreateConVar("sm_trc_minplayers", "1", "minimun # of players before controlling teams");
	g_ratio = CreateConVar("sm_trc_ratio", "1:1", "the target team1/team2 ratio");
	g_grace = CreateConVar("sm_trc_ratioeffect", "1.0", "adjusts the effectiveness");
	g_adjustteams = CreateConVar("sm_trc_autoadjust", "1", "auto-adjust teams at round end?");
	HookConVarChange(g_ratio, OnSettingChanged);
	HookConVarChange(g_grace, OnSettingChanged);

	RegConsoleCmd("jointeam", CommandJoinTeam);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted()
{
	GetTargetRatio();
	g_graceMul = GetConVarFloat(g_grace);
	PrecacheSound(DENY_SOUND);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_ratio)
		GetTargetRatio();
	else if (convar == g_grace)
		g_graceMul = GetConVarFloat(g_grace);
}

GetTargetRatio()
{
	decl String:ratio[8], String:teams[2][4];
	GetConVarString(g_ratio, ratio, sizeof(ratio));
	StripQuotes(ratio); TrimString(ratio);
	ExplodeString(ratio, ":", teams, 2, 4);
	g_teamOneDiv = StringToFloat(teams[0]);
	g_teamTwoDiv = StringToFloat(teams[1]);
}

public Action:CommandJoinTeam(client, args)
{
	if (GetConVarInt(g_enabled))
	{
		decl String:info[7];
		GetCmdArg(1, info, sizeof(info));
		new ChosenTeam = StringToInt(info);
		new currTeam = GetClientTeam(client);
		if (ChosenTeam != TEAM_SPEC)
		{
			new Float:TeamOneTotal, Float:TeamTwoTotal;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					switch (GetClientTeam(i))
					{
						case TEAM_ONE:
							TeamOneTotal += 1.0;
						case TEAM_TWO:
							TeamTwoTotal += 1.0;
					}
				}
			}
			if (TeamOneTotal+TeamTwoTotal >= GetConVarFloat(g_minplayers))
			{
				if (ChosenTeam == TEAM_ONE && currTeam != TEAM_ONE && 
				FloatAbs((((TeamOneTotal+1.0)/g_teamOneDiv)-(TeamTwoTotal/g_teamTwoDiv))*g_graceMul) >
				FloatAbs((TeamOneTotal/g_teamOneDiv)-((TeamTwoTotal+1.0)/g_teamTwoDiv)))
				{
					if (currTeam != TEAM_TWO)
						FakeClientCommandEx(client, "jointeam %i", TEAM_TWO);
					if (ChosenTeam != TEAM_AUTO)
						EmitSoundToClient(client, DENY_SOUND);
					PrintCenterText(client, "You've been auto-assigned.");
					return Plugin_Handled;
				}
				else if (ChosenTeam == TEAM_TWO && currTeam != TEAM_TWO && 
				FloatAbs(((TeamOneTotal/g_teamOneDiv)-((TeamTwoTotal+1.0)/g_teamTwoDiv))*g_graceMul) >
				FloatAbs(((TeamOneTotal+1.0)/g_teamOneDiv)-(TeamTwoTotal/g_teamTwoDiv)))
				{
					if (currTeam != TEAM_ONE)
						FakeClientCommandEx(client, "jointeam %i", TEAM_ONE);
					if (ChosenTeam != TEAM_AUTO)
						EmitSoundToClient(client, DENY_SOUND);
					PrintCenterText(client, "You've been auto-assigned.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_enabled) && GetConVarInt(g_adjustteams))
		CreateTimer(2.0, AdjustTeams);
}

public Action:AdjustTeams(Handle:timer)
{
	new Float:TeamOneTotal, Float:TeamTwoTotal;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_ONE:
					TeamOneTotal += 1.0;
				case TEAM_TWO:
					TeamTwoTotal += 1.0;
			}
		}
	}
	if (TeamOneTotal+TeamTwoTotal >= GetConVarFloat(g_minplayers))
	{
		new Swappee;
		while ((Swappee = GetRandomPlayer(TEAM_ONE)) != 0 &&
		FloatAbs(((TeamOneTotal-1.0)/g_teamOneDiv)-((TeamTwoTotal+1.0)/g_teamTwoDiv)) <
		FloatAbs(((TeamOneTotal/g_teamOneDiv)-(TeamTwoTotal/g_teamTwoDiv))*g_graceMul))
		{
			TeamOneTotal -= 1.0;
			TeamTwoTotal += 1.0;
			ChangePlayerTeam(Swappee, TEAM_TWO);
		}
		while ((Swappee = GetRandomPlayer(TEAM_TWO)) != 0 &&
		FloatAbs(((TeamOneTotal+1.0)/g_teamOneDiv)-((TeamTwoTotal-1.0)/g_teamTwoDiv)) <
		FloatAbs(((TeamOneTotal/g_teamOneDiv)-(TeamTwoTotal/g_teamTwoDiv))*g_graceMul))
		{
			TeamOneTotal += 1.0;
			TeamTwoTotal -= 1.0;
			ChangePlayerTeam(Swappee, TEAM_ONE);
		}
	}
}

GetRandomPlayer(team)
{
	new Players[MaxClients+1], PlayerCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
			Players[PlayerCount++] = i;
	}
	if (PlayerCount == 0)
		return 0;
	else
		return Players[GetRandomInt(0, PlayerCount-1)];
}

ChangePlayerTeam(client, team)
{
	new frags = GetClientFrags(client);
	new deaths = GetClientDeaths(client);
	FakeClientCommandEx(client, "jointeam %i", team);
	PrintCenterText(client, "You've been auto-assigned.");
	SetEntProp(client, Prop_Data, "m_iFrags", frags);
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
}