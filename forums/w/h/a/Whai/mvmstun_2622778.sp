#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.2"

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
int g_iParticle;

public void OnPluginStart()
{
	RegAdminCmd("sm_robostun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_robotstun", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	RegAdminCmd("sm_stunrobot", Command_RobotStun, ADMFLAG_KICK, "Stun Blu team with mannhattan's stun effect'");
	
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
				MVMStunPlayer(client);
			
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

void MVMStunPlayer(int client)
{
	for (int iTarget; iTarget <= MaxClients; iTarget++)
	{
		if(IsValidClient(iTarget))
		{
			if(TF2_GetClientTeam(iTarget) == TFTeam_Blue)
			{
				if(IsPlayerAlive(iTarget))
				{
					if(IsFakeClient(iTarget))
						TF2_AddCondition(iTarget, TFCond_MVMBotRadiowave, fStunDuration);
					
					else
					{
						TF2_StunPlayer(iTarget, fStunDuration, 0.0, TF_STUNFLAG_BONKSTUCK);
						AttachParticle(iTarget, "bot_radio_waves");
					}
					
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
					bRobotStunned = true;
				}
			}
		}
	}
	if(bRobotStunned)
	{
		hTimerCount = CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);
		CreateTimer(fTimerDuration, TankSpeed);
		fTimerCount = 0.0;
		EmitSoundToAll("vo/announcer_security_alert.mp3");
		EmitSoundToAll("mvm/mvm_robo_stun.wav");
		ReplyToCommand(client, "[SM] Blu Team Stunned");
	}
}

void AttachParticle(int iEnt, char[] cParticleType)
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	char cName[128];
	if(IsValidEdict(iParticle))
	{
		float pos[3];
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 10;
		TeleportEntity(iParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(cName, sizeof(cName), "target%i", iEnt);
		DispatchKeyValue(iEnt, "targetname", cName);
		
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", cName);
		DispatchKeyValue(iParticle, "effect_name", cParticleType);
		DispatchSpawn(iParticle);
		SetVariantString(cName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		g_iParticle = iParticle;
	}
}

void DeleteParticle(int iParticle)
{
    if (IsValidEntity(iParticle))
    {
        char cClassname[256];
        GetEdictClassname(iParticle, cClassname, sizeof(cClassname));
        if (StrEqual(cClassname, "info_particle_system", false))
        {
            RemoveEdict(iParticle);
        }
    }
}

public Action TimerCount(Handle timer)
{
	if(fTimerCount < (fTimerDuration + 0.5))
	{
		fTimerCount++; //= (fTimerCount + 1.0);
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
	TF2_RemoveCondition(target, TFCond_MVMBotRadiowave);
	
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
	{
		TF2_StunPlayer(client, fNewTimer, 0.0, TF_STUNFLAG_BONKSTUCK);
		AttachParticle(client, "bot_radio_waves");
	}
		
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
	TF2_RemoveCondition(target, TFCond_MVMBotRadiowave);
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
	EmitSoundToAll("misc/cp_harbor_red_whistle.wav");
	bRobotStunned = false;
	bSoundPlayed = true;
	CreateTimer(9.0, SoundNotPlaying);
	DeleteParticle(g_iParticle);
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
