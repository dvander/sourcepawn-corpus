#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.1.6"

public Plugin:myinfo =
{
	name = "TF2 Dodge & Resist",
	author = "Tylerst",
	description = "Set dodge chance and/or damage resistance of a target(s)",
	version = PLUGIN_VERSION,
	url = "None"
};

new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;

new Handle:basedodge = INVALID_HANDLE;
new Handle:baseresist = INVALID_HANDLE;
new Handle:classdodge[10] = INVALID_HANDLE;
new Handle:classresist[10] = INVALID_HANDLE;

new dodgechance[MAXPLAYERS+1] = -1;
new damageresist[MAXPLAYERS+1] = -1;
new selfdamagehealth[MAXPLAYERS+1] = -1;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_dodgeresist_version", PLUGIN_VERSION, "Set dodge chance and/or damage resistance of a target(s)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_dodgeresist_chat", "1", "Enable/Disable (1/0) Showing dodge/resist changes in chat", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hLog = CreateConVar("sm_dodgeresist_log", "1", "Enable/Disable (1/0)Logging of dodge/resist changes", FCVAR_PLUGIN|FCVAR_NOTIFY);
	basedodge = CreateConVar("sm_basedodge", "0", "Base dodge for all players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	baseresist = CreateConVar("sm_baseresist", "0", "Base resistance for all players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[1] = CreateConVar("sm_scoutdodge", "0", "Base dodge for scouts", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[1] = CreateConVar("sm_scoutresist", "0", "Base resistance for scouts", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[2] = CreateConVar("sm_sniperdodge", "0", "Base dodge for snipers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[2] = CreateConVar("sm_sniperresist", "0", "Base resistance for snipers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[3] = CreateConVar("sm_soldierdodge", "0", "Base dodge for soldiers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[3] = CreateConVar("sm_soldierresist", "0", "Base resistance for soldiers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[4] = CreateConVar("sm_demomandodge", "0", "Base dodge for demomen", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[4] = CreateConVar("sm_demomanresist", "0", "Base resistance for demomen", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[5] = CreateConVar("sm_medicdodge", "0", "Base dodge for medics", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[5] = CreateConVar("sm_medicresist", "0", "Base resistance for medics", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[6] = CreateConVar("sm_heavydodge", "0", "Base dodge for heavys", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[6] = CreateConVar("sm_heavyresist", "0", "Base resistance for heavys", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[7] = CreateConVar("sm_pyrododge", "0", "Base dodge for pyros", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[7] = CreateConVar("sm_pyroresist", "0", "Base resistance for pyros", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[8] = CreateConVar("sm_spydodge", "0", "Base dodge for spys", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[8] = CreateConVar("sm_spyresist", "0", "Base resistance for spys", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classdodge[9] = CreateConVar("sm_engineerdodge", "0", "Base dodge for engineers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	classresist[9] = CreateConVar("sm_engineerresist", "0", "Base resistance for engineers", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	RegAdminCmd("sm_dodge", Command_Dodge, ADMFLAG_SLAY, "Set dodge chance of a target(s), Usage: sm_dodge <target> <0-100>, -1 to reset");
	RegAdminCmd("sm_resist", Command_Resist, ADMFLAG_SLAY, "Set damage resistance of a target(s), Usage: sm_resist <target> <0-100>, -1 to reset");
	for (new i = 1; i <= MaxClients; i++)

	{
		if(IsClientInGame(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			dodgechance[i] = -1;
			damageresist[i] = -1;
		}		
	}		
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	dodgechance[client] = -1;
	damageresist[client] = -1;
}

public OnClientDisconnect_Post(client)
{
	dodgechance[client] = -1;
	damageresist[client] = -1;
}

public Action:Command_Dodge(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dodge <target> <0-100>, -1 to reset");		
		return Plugin_Handled;
	}

	new String:dodgetarget[32], String:strdodge[32];

	GetCmdArg(1, dodgetarget, sizeof(dodgetarget));
	GetCmdArg(2, strdodge, sizeof(strdodge));
	new dodge = StringToInt(strdodge);
	
	if(dodge != -1 && (dodge < 0 || dodge > 100))
	{
		ReplyToCommand(client, "[SM] Dodge Chance must be from 0 to 100, -1 to reset");
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
	if(dodge == -1)
	{
		for (new i = 0; i < target_count; i++)
		{
			dodgechance[target_list[i]] = -1;
			if(GetConVarBool(hLog))
			{
				LogAction(client, target_list[i], "\"%L\" reset dodge chance of  \"%L\"", client, target_list[i]);	
			}			
		}
		if(GetConVarBool(hChat))
		{
			ShowActivity2(client, "[SM] ","Reset dodge chance of %s to default", target_name);
		}
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
	
	if(GetConVarBool(hChat))
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
	
	if(resist != -1 && (resist < 0 || resist > 100))
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

	if(resist == -1)
	{
		for (new i = 0; i < target_count; i++)
		{
			damageresist[target_list[i]] = -1;
			if(GetConVarBool(hLog))
			{
				LogAction(client, target_list[i], "\"%L\" reset damage resistance of  \"%L\"", client, target_list[i]);	
			}			
		}
		if(GetConVarBool(hChat))
		{
			ShowActivity2(client, "[SM] ","Reset damage resistance of %s to default", target_name);
		}
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
	
	if(GetConVarBool(hChat))
	{
		ShowActivity2(client, "[SM] ","Set damage resistance of %s to %i%", target_name, resist);
	}

	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if((attacker == victim))
	{
		selfdamagehealth[attacker] = GetClientHealth(attacker);
		return Plugin_Continue;
	}	
	if(victim < 1 || victim > MaxClients) return Plugin_Continue;
	new dodge = CalcDodge(victim);
	new resist = CalcResist(victim);
	new rand = GetRandomInt(1, 100);
	if(rand <= dodge) 
	{
		damage = 0.0;
		decl Float:pos[3];
		GetClientEyePosition(victim, pos);
		pos[2] += 4.0;
		if((attacker > 0 && attacker <= MaxClients) && IsPlayerAlive(attacker))
		{
			TE_Particle(attacker, "miss_text", pos);
		}
		return Plugin_Changed;
	}
	if(resist != 0)
	{
		new Float:resistance = 1.0 - (resist/100.0);
		damage *= resistance;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if((attacker != victim)) return;
	if(!IsClientInGame(victim) || !IsPlayerAlive(victim)) return;

	new dodge = CalcDodge(victim);
	new resist = CalcResist(victim);
	new rand = GetRandomInt(1, 100);
	if(rand <= dodge) 
	{
		SetEntityHealth(attacker, selfdamagehealth[attacker]);
		return;
	}
	if(resist != 0)
	{
		new Float:resistance = 1.0 - (resist/100.0);
		damage *= resistance;
		SetEntityHealth(attacker, selfdamagehealth[attacker]-RoundFloat(damage));
		return;
	}
	return;
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

CalcDodge(client)
{
	new bdodge = GetConVarInt(basedodge);
	new TFClassType:class = TF2_GetPlayerClass(client);
	new cdodge = GetConVarInt(classdodge[class]);
	new pdodge = dodgechance[client];
	if(pdodge != -1) return pdodge;
	else if(cdodge != 0) return cdodge;
	else if(bdodge != 0) return bdodge;
	else return 0;
}
CalcResist(client)
{
	new bresist = GetConVarInt(baseresist);
	new TFClassType:class = TF2_GetPlayerClass(client);
	new cresist = GetConVarInt(classresist[class]);
	new presist = damageresist[client];
	if(presist != -1) return presist;
	else if(cresist != 0) return cresist;
	else if(bresist != 0) return bresist;
	else return 0;
}