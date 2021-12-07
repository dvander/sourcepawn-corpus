#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "TF2 Dodge & Resist",
	author = "Tylerst (Fixes by FlaminSarge)",
	description = "Set dodge chance and/or damage resistance of a target(s)",
	version = PLUGIN_VERSION,
	url = "None"
};

new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new dodgechance[MAXPLAYERS+1] = 0;
new damageresist[MAXPLAYERS+1] = 0;

public OnPluginStart()
{
	TF2only();
	LoadTranslations("common.phrases");
	CreateConVar("sm_dodgeresist_version", PLUGIN_VERSION, "Set dodge chance and/or damage resistance of a target(s)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_dodgeresist_chat", "1", "Enable/Disable (1/0) Showing dodge/resist changes in chat", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hLog = CreateConVar("sm_dodgeresist_log", "1", "Enable/Disable (1/0 )Logging of dodge/resist changes", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_dodge", Command_Dodge, ADMFLAG_SLAY, "Set dodge chance of a target(s), Usage: sm_dodge <target> <0-100>");
	RegAdminCmd("sm_resist", Command_Resist, ADMFLAG_SLAY, "Set damage resistance of a target(s), Usage: sm_resist <target> <0-100>");
	for (new client = 1; client < MAXPLAYERS + 1; client++)
	{
		if (IsClientInGame(client)) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	dodgechance[client] = 0;
	damageresist[client] = 0;
}
public OnClientDisconnect_Post(client)
{
	dodgechance[client] = 0;
	damageresist[client] = 0;
}
public Action:Command_Dodge(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dodge <target> <0-100>");		
		return Plugin_Handled;
	}

	new String:dodgetarget[32], String:strdodge[32];

	GetCmdArg(1, dodgetarget, sizeof(dodgetarget));
	GetCmdArg(2, strdodge, sizeof(strdodge));
	new dodge = StringToInt(strdodge);
	
	if(dodge < 0 || dodge > 100)
	{
		ReplyToCommand(client, "[SM] Dodge Chance must be from 0 to 100");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;		
	if ((target_count = ProcessTargetString(
			dodgetarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		dodgechance[target_list[i]] = dodge;
		if(GetConVarBool(hLog))
		{
			LogAction(client, target_list[i], "\"%L\" set dodge chance of  \"%L\" to (%i)", client, target_list[i], dodge);	
		}
	}
	
	if(hChat)
	{
		ShowActivity2(client, "[SM] ","Set dodge chance of %s to %i%", target_name, dodge);
	}

	return Plugin_Handled;
}

public Action:Command_Resist(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_resist <target> <0-100>");		
		return Plugin_Handled;
	}

	new String:resisttarget[32], String:strresist[32];

	GetCmdArg(1, resisttarget, sizeof(resisttarget));
	GetCmdArg(2, strresist, sizeof(strresist));
	new resist = StringToInt(strresist);
	
	if(resist < 0 || resist > 100)
	{
		ReplyToCommand(client, "[SM] Resistance must be from 0 to 100");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;		
	if ((target_count = ProcessTargetString(
			resisttarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		damageresist[target_list[i]] = resist;
		if(GetConVarBool(hLog))
		{
			LogAction(client, target_list[i], "\"%L\" set damage resistance of  \"%L\" to (%i)", client, target_list[i], resist);	
		}
	}
	
	if(hChat)
	{
		ShowActivity2(client, "[SM] ","Set damage resistance of %s to %i%", target_name, resist);
	}

	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsClientInGame(victim) || !IsPlayerAlive(victim)) return Plugin_Continue;
	new rand = GetRandomInt(1, 100);
	if (rand <= dodgechance[victim]) 
	{
		damage *= 0;
		decl Float:pos[3];
		GetClientEyePosition(victim, pos);
		pos[2] += 4.0;
		TE_Particle(attacker, "miss_text", pos);
		return Plugin_Changed;
	}
	if (damageresist[victim] != 0)
	{
		new Float:resist = 1.0 - (damageresist[victim]/100.0);
		damage *= resist;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

TE_Particle(client,
	String:Name[],
        Float:origin[3]=NULL_VECTOR,
        Float:start[3]=NULL_VECTOR,
        Float:angles[3]=NULL_VECTOR,
        entindex=-1,
        attachtype=-1,
        attachpoint=-1,
        bool:resetParticles=true,
        Float:delay=0.0)
{
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToClient(client, delay);
}

TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}
}