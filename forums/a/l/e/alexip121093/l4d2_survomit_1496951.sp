#include <sourcemod>
#include <sdktools>
#pragma semicolon				1
#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0.1"
new	Handle:g_hCvarAllow,Handle:g_hCvarType,Handle:g_hCvarRange,Handle:g_hCvarSound,Handle:g_hCvarTeam,Handle:g_hCvarCool;
new g_fCvarType,g_fCvarRange,g_fCvarAllow,g_fCvarTeam;
new Float:g_fCvarCool;
new String:sound_link[64];
new Handle:trace_attack[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hGameConf = INVALID_HANDLE;
new Handle:sdkVomitInfected = INVALID_HANDLE;
new Handle:sdkVomitSurvivor = INVALID_HANDLE;
new bool:cool[MAXPLAYERS+1];
enum (<<=1)
{
	ENUM_Sur = 1,
	ENUM_SI,
	ENUM_I
}

//boomer_vomit         boomer_vomit_b  boomer_vomit_c boomer_vomit_d boomer_vomit_e boomer_vomit_infected boomer_vomit_screeneffect   boomer_vomit_screeneffect_b
public Plugin:myinfo =  
{ 
	name = "[L4D2] Everyone Vomit", 
	author = "hihi1210", 
	description = "Everyone can vomit like boomer", 
	version = PLUGIN_VERSION, 
	url = "www.sourcemod.net" 
} 

public OnPluginStart() 
{
	decl String:Game_Name[64];
	GetGameFolderName(Game_Name, sizeof(Game_Name));
	if(!StrEqual(Game_Name, "left4dead2", false))
	{
		SetFailState("L4D2 Everyone Vomit plugin %d only support L4D2!", PLUGIN_VERSION);
	}

	RegConsoleCmd("sm_vomitme", Command_VomitMee);  
	CreateConVar("l4d2_vomit",PLUGIN_VERSION,"L4D2 Everyone Vomit plugin version.",	CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	g_hCvarAllow = CreateConVar("l4d2_vomit_allow",	"1","0= L4D2 Everyone Vomit Plugin off, 1=Plugin on. 2 root admin only", CVAR_FLAGS);
	g_hCvarType = CreateConVar(	"l4d2_vomit_type","7","the vomit can only hit 1=sur 2=SI 4 =commoninfected (add the number to it if you want it)", CVAR_FLAGS);
	g_hCvarRange = CreateConVar("l4d2_vomit_range","100","vomit hit detection range", CVAR_FLAGS);
	g_hCvarTeam = CreateConVar(	"l4d2_vomit_team","1","the team that can use !vomitme  1 =sur 2=infected 3=both", CVAR_FLAGS);
	g_hCvarCool = CreateConVar(	"l4d2_vomit_cool","60.0", "cool down time after vomit", CVAR_FLAGS);
	g_hCvarSound = CreateConVar("l4d2_vomit_sound",	"player/boomer/vomit/attack/bv1.wav", "sound file used   leave blank to disable sound", CVAR_FLAGS);
	HookConVarChange(g_hCvarType,ConVarChanged_Mode);
	HookConVarChange(g_hCvarAllow,ConVarChanged_Enable);
	HookConVarChange(g_hCvarRange,ConVarChanged_Range);
	HookConVarChange(g_hCvarSound,ConVarChanged_Sound);
	HookConVarChange(g_hCvarTeam,ConVarChanged_Team);
	HookConVarChange(g_hCvarCool,ConVarChanged_Cool);
	AutoExecConfig(true, "l4d2_vomit");
	g_hGameConf = LoadGameConfigFile("l4d2vomit");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitInfected = EndPrepSDKCall();
	if(sdkVomitInfected == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnHitByVomitJar\" signature, check the file version!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	if(sdkVomitSurvivor == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
}
public OnClientConnected(client)
{
	cool[client] =false;
}
public OnMapStart()
{
	PrecacheParticle("boomer_vomit");
	if (!StrEqual(sound_link,""))
	{
		if (!IsSoundPrecached(sound_link))
		PrecacheSound(sound_link, true);
	}
}
public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarAllow=GetConVarInt(g_hCvarAllow);
}
public ConVarChanged_Mode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarType=GetConVarInt(g_hCvarType);
}
public ConVarChanged_Range(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarRange=GetConVarInt(g_hCvarRange);
}
public ConVarChanged_Team(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarTeam=GetConVarInt(g_hCvarTeam);
}
public ConVarChanged_Cool(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarCool=GetConVarFloat(g_hCvarCool);
}
public ConVarChanged_Sound(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(g_hCvarSound, sound_link, 64);
	if (!StrEqual(sound_link,""))
	{
		if (!IsSoundPrecached(sound_link))
		PrecacheSound(sound_link, true);
	}
}
public OnConfigsExecuted()
{
	g_fCvarAllow=GetConVarInt(g_hCvarAllow);
	g_fCvarType=GetConVarInt(g_hCvarType);
	g_fCvarRange=GetConVarInt(g_hCvarRange);
	g_fCvarTeam=GetConVarInt(g_hCvarTeam);
	g_fCvarCool=GetConVarFloat(g_hCvarCool);
	GetConVarString(g_hCvarSound, sound_link, 64);
	if (!StrEqual(sound_link,""))
	{
		if (!IsSoundPrecached(sound_link))
		PrecacheSound(sound_link, true);
	}
}
PrecacheParticle(const String:ParticleName[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.1, DeleteParticles, EntIndexToEntRef(particle));
	}
}


public Action:Command_VomitMee(client, args) 
{ 
	if (g_fCvarAllow ==1 || g_fCvarAllow ==2 && CheckCommandAccess(client,  "", ADMFLAG_ROOT, true))
	{
		new team = GetClientTeam(client);

		if (g_fCvarTeam ==3 && team !=1 || g_fCvarTeam ==1 && team ==2|| g_fCvarTeam ==2 && team ==3)
		{
			if (cool[client])
			{
				return Plugin_Continue;
			}
			if (!IsPlayerAlive(client) || team==3 && IsPlayerGhost(client))
			{
				return Plugin_Continue;
			}
			cool[client] =true;
			new Float:x[3];
			new Float:z[3];
			new Float:j[3];
			new String:y[32];
			new String:tName[32];
			GetCmdArgString(y, 32);
			
			new particle = CreateEntityByName("info_particle_system");

			DispatchKeyValue(particle, "effect_name", "boomer_vomit");

			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "Start");
			Format(tName, sizeof(tName), "part%d", client);
			DispatchKeyValue(client, "targetname", tName);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			SetVariantString("eyes");
			AcceptEntityInput(particle, "SetParentAttachment");
			//j[2]=j[2]+60;
			//j[1]=j[1]+60;
			j[0]=j[0]-30;
			j[1]=j[1]+12;
			x[1]=x[1]+3;

			TeleportEntity(particle, x, j, NULL_VECTOR);
			GetClientEyePosition(client,z);
			z[2]=z[2]-2;
			if (!StrEqual(sound_link,""))
			{
				EmitSoundToAll(sound_link, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, z, NULL_VECTOR, false, 0.0);
			}
			if (trace_attack[client] ==INVALID_HANDLE)
			{
				trace_attack[client] = CreateTimer(0.1,TraceAttack,client, TIMER_REPEAT);
			}
			else
			{
				CloseHandle(trace_attack[client]);
				trace_attack[client] =INVALID_HANDLE;
				trace_attack[client] = CreateTimer(0.1,TraceAttack,client, TIMER_REPEAT);
			}
			CreateTimer(5.0, DeleteParticles, EntIndexToEntRef(particle));
			CreateTimer(4.9, StopTimer, client);
			CreateTimer(g_fCvarCool, ResetBool, client);
		}
	}
	return Plugin_Continue;
}
public Action:TraceAttack(Handle:timer,any:client)
{
	TraceAttack1(client, true);
}
public Action:ResetBool(Handle:timer,any:client)
{
	cool[client]=false;
}
public bool:ExcludeSelf_Filter(entity, contentsMask, any:client)
{
	if( entity == client )
	return false;
	return true;
}
VomitPlayer(target, sender)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Spectators cannot be vomited!");
		return;
	}
	if(GetClientTeam(target) == 3)
	{
		if (g_fCvarType & ENUM_SI)
		{
			if (!IsPlayerGhost(target) && IsPlayerAlive(target))
			{
				SDKCall(sdkVomitInfected, target, sender, true);
			}
		}
	}
	if(GetClientTeam(target) == 2)
	{
		if (g_fCvarType & ENUM_Sur)
		{
			if (IsPlayerAlive(target))
			{
				SDKCall(sdkVomitSurvivor, target, sender, true);
			}
		}
	}
}
stock bool:IsPlayerGhost(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost", 1) == 1)
	return true;
	return false;
}

VomitEntity(entity)
{
	decl i_InfoEnt, String:s_TargetName[32];
	i_InfoEnt = CreateEntityByName("info_goal_infected_chase");
	if (IsValidEdict(i_InfoEnt))
	{
		new Float:f_Origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", f_Origin);
		f_Origin[2] += 20.0;
		DispatchKeyValueVector(i_InfoEnt, "origin", f_Origin);
		FormatEx(s_TargetName, sizeof(s_TargetName), "goal_infected%d", entity);
		DispatchKeyValue(i_InfoEnt, "targetname", s_TargetName);
		GetEntPropString(entity, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName));
		DispatchKeyValue(i_InfoEnt, "parentname", s_TargetName);
		DispatchSpawn(i_InfoEnt);
		SetVariantString(s_TargetName);
		AcceptEntityInput(i_InfoEnt, "SetParent", i_InfoEnt, i_InfoEnt, 0);
		ActivateEntity(i_InfoEnt);
		AcceptEntityInput(i_InfoEnt, "Enable");
	}

	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", -4713783);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", -4713783);
	CreateTimer(20.0, DisableGlow, entity);
	CreateTimer(5.0, DisableChase, i_InfoEnt);
}

public Action:DisableGlow(Handle:h_Timer, any:i_Ent)
{
	decl String:s_ModelName[64];
	
	if (!IsValidEdict(i_Ent) || !IsValidEntity(i_Ent))
	return Plugin_Handled;
	
	GetEntPropString(i_Ent, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));

	if (StrContains(s_ModelName, "infected") != -1)
	{
		SetEntProp(i_Ent, Prop_Send, "m_iGlowType", 0);
		SetEntProp(i_Ent, Prop_Send, "m_glowColorOverride", 0);
	}
	
	return Plugin_Continue;
}
public Action:DisableChase(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEntity(i_Ent))
	{
		AcceptEntityInput(i_Ent, "kill");
	}
	return Plugin_Continue;
}
TraceAttack1(client, bool:bHullTrace)
{
	decl Float:vPos[3], Float:vAng[3], Float:vEnd[3];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, ExcludeSelf_Filter, client);
	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vEnd, trace);
	}
	else
	{
		CloseHandle(trace);
		return;
	}

	if( bHullTrace )
	{
		CloseHandle(trace);
		decl Float:vMins[3], Float:vMaxs[3];
		vMins = Float: { -15.0, -15.0, -15.0 };
		vMaxs = Float: { 15.0, 15.0, 15.0 };
		trace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_SHOT, ExcludeSelf_Filter, client);
		
		if( !TR_DidHit(trace) )
		{
			CloseHandle(trace);
			return;
		}
	}

	TR_GetEndPosition(vEnd, trace);
	if( GetVectorDistance(vPos, vEnd) > g_fCvarRange )
	{
		CloseHandle(trace);
		return;
	}

	new entity = TR_GetEntityIndex(trace);
	CloseHandle(trace);

	if( entity <= MaxClients && entity > 0 )
	{
		VomitPlayer(entity,client);
	}
	else
	{
		if (g_fCvarType & ENUM_I)
		{
			decl String:classname[16];
			GetEdictClassname(entity, classname, sizeof(classname));
			if( strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 )
			{
				VomitEntity(entity);
			}
		}
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (EntRefToEntIndex(particle) != INVALID_ENT_REFERENCE)
	{
		/* Delete particle */
		if (IsValidEntity(particle) || IsValidEdict(particle))
		{
			new String:classname[64];
			GetEdictClassname(particle, classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
			}
		}
	}
}
public Action:StopTimer(Handle:timer, any:client)
{
	if (trace_attack[client]!=INVALID_HANDLE)
	{
		CloseHandle(trace_attack[client]);
		trace_attack[client] =INVALID_HANDLE;
	}
}