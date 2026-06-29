#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define VERSION "1.2"

#define BRIEFCASE_MODEL	"models/flag/briefcase.mdl"
#define BOMB_MODEL 		"models/props_td/atom_bomb.mdl"
#define BOMB_UPGRADE	"#*mvm/mvm_warning.wav"

bool g_bHasBomb[MAXPLAYERS+1];
float g_flNextBombUpgradeTime[MAXPLAYERS+1];
int g_iFlagCarrierUpgradeLevel[MAXPLAYERS+1];

Handle g_hCvarEnabled;
Handle g_hCvarMoveSpeedPenalty;
Handle g_hCvarStage1;
Handle g_hCvarStage1_Radius;
Handle g_hCvarStage2;
Handle g_hCvarStage3;

public Plugin myinfo = 
{
	name		= "[TF2] Flags to Bombs with Upgrades",
	author		= "Pelipoika",
	description	= "Turn item_teamflags into MvM Bombs.",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart()
{
	CreateConVar("tf2_flagstobombs_version", VERSION, "Flags to Bombs version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	
	g_hCvarEnabled = CreateConVar("tf2_flagstobombs_enable", "1", "Enable TF2 Flags to Bombs?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hCvarMoveSpeedPenalty = CreateConVar("tf2_flagstobombs_speedpenalty", "0.5", "Movement speed penalty when carrying a bomb", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hCvarStage1 = CreateConVar("tf2_flagstobombs_stage1_time", "5.0", "How long to wait to receive stage 1?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, false);
	g_hCvarStage1_Radius = CreateConVar("tf2_flagstobombs_stage1_buffradius", "380.0", "Size of the radius in which teammates will receive stage 1 buff", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, false);
	g_hCvarStage2 = CreateConVar("tf2_flagstobombs_stage2_time", "15.0", "How long to wait to receive stage 2?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, false);
	g_hCvarStage3 = CreateConVar("tf2_flagstobombs_stage3_time", "15.0", "How long to wait to receive stage 3?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, false);

	HookEvent("teamplay_flag_event", Event_FlagEvent);
}

public void OnClientPutInServer(int client)
{
	g_bHasBomb[client] = false;
	g_iFlagCarrierUpgradeLevel[client] = 0;
	g_flNextBombUpgradeTime[client] = GetGameTime();
}

public void OnMapStart()
{
	PrecacheModel(BOMB_MODEL);
	PrecacheSound(BOMB_UPGRADE);
}

public void Event_FlagEvent(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player");
	int eventtype = event.GetInt("eventtype");
	
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !GameRules_GetProp("m_bPlayingRobotDestructionMode") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		if(eventtype == TF_FLAGEVENT_PICKEDUP)
		{
			g_bHasBomb[client] = true;
			g_iFlagCarrierUpgradeLevel[client] = 0;
			g_flNextBombUpgradeTime[client] = GetGameTime() + GetConVarFloat(g_hCvarStage1);
			
			TF2Attrib_SetByName(client, "move speed penalty", GetConVarFloat(g_hCvarMoveSpeedPenalty));
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		}
		else
		{
			TF2Attrib_RemoveByName(client, "health regen");
			TF2Attrib_RemoveByName(client, "move speed penalty");
			TF2_RemoveCondition(client, TFCond_DefenseBuffNoCritBlock);
			TF2_RemoveCondition(client, TFCond_CritOnWin);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
			
			g_bHasBomb[client] = false;
			g_iFlagCarrierUpgradeLevel[client] = 0;
			g_flNextBombUpgradeTime[client] = GetGameTime();
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	if(IsPlayerAlive(client) && g_bHasBomb[client])
	{
		float pPos[3];
		GetClientAbsOrigin(client, pPos);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && i != client && g_iFlagCarrierUpgradeLevel[client] >= 1)
			{
				float iPos[3];
				GetClientAbsOrigin(i, iPos);
				
				float flDistance = GetVectorDistance(pPos, iPos);
				
				if(flDistance <= GetConVarFloat(g_hCvarStage1_Radius))
				{
					TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 0.5);
				}
			}
		}
	
		if(g_flNextBombUpgradeTime[client] <= GetGameTime() && g_iFlagCarrierUpgradeLevel[client] < 3 && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)	//Time to upgrade
		{
			float flPos[3];
			GetClientEyePosition(client, flPos);
			flPos[2] += 10.0;
			
			g_iFlagCarrierUpgradeLevel[client]++;
			
			switch(g_iFlagCarrierUpgradeLevel[client])
			{
				case 1: 
				{
					g_flNextBombUpgradeTime[client] = GetGameTime() + GetConVarFloat(g_hCvarStage2); 
					TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, TFCondDuration_Infinite);
					CreateParticle("mvm_levelup1", flPos);
				}
				case 2: 
				{
					g_flNextBombUpgradeTime[client] = GetGameTime() +GetConVarFloat(g_hCvarStage3); 
					TF2Attrib_SetByName(client, "health regen", 45.0);
					CreateParticle("mvm_levelup2", flPos);
				}
				case 3: 
				{
					TF2_AddCondition(client, TFCond_CritOnWin, TFCondDuration_Infinite);
					CreateParticle("mvm_levelup3", flPos);
				}
			} 
			
			FakeClientCommand(client, "taunt");
			
			EmitSoundToAll(BOMB_UPGRADE, SOUND_FROM_WORLD, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_NOFLAGS, 0.500, SNDPITCH_NORMAL);
			
			TLK_MVM_BOMB_CARRIER_UPGRADE(client, g_iFlagCarrierUpgradeLevel[client]);
		}
	}
	
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(g_hCvarEnabled) && StrEqual(classname, "item_teamflag") && !GameRules_GetProp("m_bPlayingRobotDestructionMode") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		SDKHook(entity, SDKHook_Spawn, FlagSpawn);
	}
}

public Action FlagSpawn(int entity)
{
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_iszModel", model, sizeof(model));
	
	if (model[0] == '\0' || StrEqual(model, BRIEFCASE_MODEL))
	{
		DispatchKeyValue(entity, "flag_model", BOMB_MODEL);
		DispatchKeyValue(entity, "trail_effect", "3");
	}
	
	return Plugin_Continue;
}

stock void TLK_MVM_BOMB_CARRIER_UPGRADE(int client, int iUpgradeLevel = 1)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !g_bHasBomb[i] && GetClientTeam(i) != GetClientTeam(client))
		{
			SetVariantString("randomnum:100");
			AcceptEntityInput(i, "AddContext");
		
			SetVariantString("IsMvMDefender:1");
			AcceptEntityInput(i, "AddContext");
			
			switch(iUpgradeLevel)
			{
				case 1:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE1");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
				case 2:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE2");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
				case 3:
				{
					SetVariantString("TLK_MVM_BOMB_CARRIER_UPGRADE3");
					AcceptEntityInput(i, "SpeakResponseConcept");
				}
			}
			
			AcceptEntityInput(i, "ClearContext");
		}
	}
}

stock void CreateParticle(char[] particle, float pos[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
    
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_SendToClient(i, 0.0);
	}
}