#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"

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

Handle hTimerCount;
ConVar hCritDuration;
bool bRobotStunned, bSoundPlayed;
float fCritDuration, fTimerCount;

float fTimerDuration = 22.5;
float fStunDuration = 22.75;

public void OnPluginStart()
{
	RegAdminCmd("sm_robostun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_robotstun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	
	hCritDuration = CreateConVar("sm_critduration", "10.0", "The crit duration", 0, true, 0.0);
	HookConVarChange(hCritDuration, ConVarChanged);
	
	HookEvent("player_spawn", PlayerSpawned);
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	fCritDuration = GetConVarFloat(hCritDuration);
}

public void OnMapStart()
{
	PrecacheSound("misc/cp_harbor_red_whistle.wav", true);
	PrecacheSound("vo/announcer_security_alert.mp3", true);
	PrecacheSound("mvm/mvm_robo_stun.wav", true);
	
	bRobotStunned = false;
	bSoundPlayed = false;
	fTimerCount = 0.0;
}

public void OnMapEnd()
{
	bRobotStunned = false;
	bSoundPlayed = false;
	fTimerCount = 0.0;
}

public Action PlayerSpawned(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(TF2_GetClientTeam(iClient) == TFTeam_Blue)
	{
		if(bRobotStunned)
		{
			if(IsValidClient(iClient))
			{
				CreateTimer(0.1, StunClient, iClient);
			}
		}
	}
}

public void OnEntityCreated(int iEntity, const char[] cClassname)
{
	if(StrEqual(cClassname, "tank_boss"))
	{
		if(bRobotStunned)
		{
			SetVariantInt(0); 
			AcceptEntityInput(iEntity, "SetSpeed");
			
			float fTimer = fTimerDuration;
			float FinaleTimer = (fTimer - fTimerCount);
			
			if(FinaleTimer < 0.1)
				CreateTimer(0.1, TankSpeed);
				
			else
				CreateTimer(FinaleTimer, TankSpeed);
			
		}
	}
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
			if(!bRobotStunned)
				MVMStunPlayer();
			
			else
				ReplyToCommand(client, "[SM] Blu Team already stunned");
		}
			
	}
	else
	{
		ReplyToCommand(client, "[SM] Command only in MvM");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void MVMStunPlayer()
{
	for (int iTarget; iTarget <= MaxClients; iTarget++)
	{
		if(IsValidClient(iTarget))
		{
			if(TF2_GetClientTeam(iTarget) == TFTeam_Blue)
			{
				if(IsFakeClient(iTarget))
					TF2_AddCondition(iTarget, TFCond_MVMBotRadiowave, fStunDuration);
				
				else
					TF2_StunPlayer(iTarget, fStunDuration, 0.0, TF_STUNFLAG_BONKSTUCK);
				
				int iTank = -1;
				
				while((iTank = FindEntityByClassname(iTank, "tank_boss")) != INVALID_ENT_REFERENCE)
				{
					SetVariantInt(0); 
					AcceptEntityInput(iTank, "SetSpeed");
				}
				
				if(bSoundPlayed)
				{
					for (int i = 0; i <= MaxClients; i++)
					{
						StopSound(i, SNDCHAN_AUTO, "misc/cp_harbor_red_whistle.wav");
					}
				}	
				CreateTimer(fTimerDuration, CritConditions, iTarget);
			}
		}
	}
	hTimerCount = CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);
	CreateTimer(fTimerDuration, TankSpeed);
	fTimerCount = 0.0;
	bRobotStunned = true;
	EmitSoundToAll("vo/announcer_security_alert.mp3", _,  _,SNDLEVEL_CONVO);
	EmitSoundToAll("mvm/mvm_robo_stun.wav", _,  _, SNDLEVEL_CONVO);
}

public Action TimerCount(Handle timer)
{
	if(fTimerCount < 23.0)
	{
		fTimerCount = (fTimerCount + 1.0);
		//PrintToChatAll("Float count = %0.f", fTimerCount);
	}
		
	else
		CreateTimer(0.1, ResetTimer);
}

public Action ResetTimer(Handle timer)
{
	fTimerCount = 0.0;
	KillTimer(hTimerCount);
	//PrintToChatAll("Float count = %0.f Should Be Reset", fTimerCount);
}

public Action CritConditions(Handle timer, any target)
{
	TF2_AddCondition(target, TFCond_CritCanteen, fCritDuration);
	EmitSoundToAll("misc/cp_harbor_red_whistle.wav", _, _, SNDLEVEL_CONVO);
	bRobotStunned = false;
	bSoundPlayed = true;
	CreateTimer(9.0, SoundNotPlaying);
	//PrintToChatAll("Crit Condition");
}

public Action StunClient(Handle timer, any client)
{
	float fDuration = fStunDuration;
	float FinalDuration = (fDuration - fTimerCount);
	float fNewTimer;
	
	if(FinalDuration < 0.1)
		fNewTimer = 0.1;
	
	else
		fNewTimer = FinalDuration;
	
	if(IsFakeClient(client))
		TF2_AddCondition(client, TFCond_MVMBotRadiowave, fNewTimer);
				
	else
		TF2_StunPlayer(client, fNewTimer, 0.0, TF_STUNFLAG_BONKSTUCK);
		
	float fStunCrit = fTimerDuration;
	float FinalStunCrit = (fStunCrit - fTimerCount);
	
	if(FinalStunCrit < 0.1)			
		CreateTimer(0.1, LateStun, client);
	
	else
		CreateTimer(FinalStunCrit, LateStun, client);
}

public Action LateStun(Handle timer, any target)
{
	TF2_AddCondition(target, TFCond_CritCanteen, fCritDuration);
	//PrintToChatAll("Crit Conditions late");
}

public Action TankSpeed(Handle timer)
{
	int tank = -1;
	while((tank = FindEntityByClassname(tank, "tank_boss")) != INVALID_ENT_REFERENCE)
	{
		SetVariantInt(200); 
		AcceptEntityInput(tank, "SetSpeed");
		//PrintToChatAll("Tank Speed Set");
	}
}

public Action SoundNotPlaying(Handle timer)
{
	bSoundPlayed = false;
	//PrintToChatAll("Sound not playing for now");
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock bool IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}