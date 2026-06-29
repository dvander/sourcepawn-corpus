#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[TF2] MvM Robot stun effect",
	author = "Whai",
	description = "MvM Stun robot team with mannhattan's stun effect'",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] cError, int iErrMax)
{
	char cGameFolder[32];
	GetGameFolderName(cGameFolder, sizeof(cGameFolder));

	if(!StrEqual(cGameFolder, "tf"))
	{
		Format(cError, iErrMax, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_robostun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effec'");
	
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	PrecacheSound("misc/cp_harbor_red_whistle.wav", true);
	PrecacheSound("vo/announcer_security_alert.mp3", true);
	PrecacheSound("mvm/mvm_robo_stun.wav", true);
}

public Action Command_RobotStun(int client, int args)
{
	if(IsMannVsMachineMode())
	{
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: sm_robostun");
			return Plugin_Handled;
		}
		else
		{
			MVMStunPlayer(client);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Command only in MvM");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void MVMStunPlayer(int client)
{
	for (int iTarget; iTarget <= MaxClients; iTarget++)
	{
		if(IsValidClient(iTarget))
		{
			if(TF2_GetClientTeam(iTarget) == TFTeam_Blue)
			{
				TF2_AddCondition(iTarget, TFCond_MVMBotRadiowave, 23.5);
				
				int iTank = -1;
				
				while((iTank = FindEntityByClassname(iTank, "tank_boss")) != INVALID_ENT_REFERENCE)
				{
					SetVariantInt(0); 
					AcceptEntityInput(iTank, "SetSpeed");
				}
				EmitSoundToAll("vo/announcer_security_alert.mp3");
				EmitSoundToAll("mvm/mvm_robo_stun.wav");
				CreateTimer(23.0, CritConditions, iTarget);
				CreateTimer(23.0, TankSpeed);
			}
		}
	}
	ReplyToCommand(client, "[SM] You stunned Blu Team");
}

public Action CritConditions(Handle timer, any target)
{
	TF2_AddCondition(target, TFCond_CritCanteen, 10.0);
	EmitSoundToAll("misc/cp_harbor_red_whistle.wav");
}

public Action TankSpeed(Handle timer)
{
	int tank = -1;
	while((tank = FindEntityByClassname(tank, "tank_boss")) != INVALID_ENT_REFERENCE)
	{
		SetVariantInt(200); 
		AcceptEntityInput(tank, "SetSpeed");
	}
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock bool IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}