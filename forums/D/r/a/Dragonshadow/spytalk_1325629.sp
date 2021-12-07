#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#define VERSION "1.1"

new bool:g_bTeamTalk[MAXPLAYERS+1];
new bool:g_bAllTalk;
new Handle:cvAllTalk;

public Plugin:myinfo = 
{
	name = "Spy Talk",
	author = "Xsinthis | Dragonshadow",
	description = "Disables alltalk on spies while cloaked or disguised",
	version = "1.1",
	url = "http://skulshockcommunity.com | http://www.snigsclan.com"
}

public OnPluginStart()
{
	cvAllTalk = FindConVar("sv_alltalk");
	if (cvAllTalk == INVALID_HANDLE)
	{
		SetFailState("SV_ALLTALK NOT FOUND");
	}
	CreateConVar("spytalk_version", VERSION, "Version of spytalk", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookConVarChange(cvAllTalk, ConVarChanged);
	g_bAllTalk = GetConVarBool(cvAllTalk);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bAllTalk = GetConVarBool(cvAllTalk);
}
public OnGameFrame()
{
	if(g_bAllTalk)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				if (TF2_GetPlayerClass(i) == TFClass_Spy)
				{
					switch(TF2_GetPlayerConditionFlags(i))
					{
						case TF_CONDFLAG_CLOAKED:
						{
							g_bTeamTalk[i]=true;
							TalkHandler(i);
						}
						case TF_CONDFLAG_DISGUISED:
						{
							g_bTeamTalk[i]=true;
							TalkHandler(i);
						}
						case TF_CONDFLAG_DEADRINGERED:
						{
							g_bTeamTalk[i]=true;
							TalkHandler(i);
						}
						default:
						{
							g_bTeamTalk[i]=false;
							TalkHandler(i);
						}
					}
				}
			}
		}
	}
}

stock TalkHandler(client)
{
	if (g_bTeamTalk[client] == true)
	{
		SetClientListeningFlags(client, VOICE_LISTENALL|VOICE_TEAM);
	}
	else
	{
		SetClientListeningFlags(client, VOICE_LISTENALL|VOICE_SPEAKALL);
	}
}