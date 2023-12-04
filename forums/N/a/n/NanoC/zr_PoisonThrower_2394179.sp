#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.7"

new g_LastButtons[MAXPLAYERS+1];
new bool:IsAllowed[MAXPLAYERS+1];
new bool:IsAdmin[MAXPLAYERS+1];
new poisonAmount[MAXPLAYERS+1];

new Handle:h_Version;
new Handle:h_Enable, bool:b_enabled;
new Handle:h_PoisonAmount, i_poisonamount;
new Handle:h_PoisonSound, String:s_poisonsound[PLATFORM_MAX_PATH];
new Handle:h_AdminsOnly, bool:b_adminsonly;
new Handle:h_MothersOnly, bool:b_mothersonly;
new Handle:h_AdminsUnlimited, bool:b_adminsunlimited;
new Handle:h_AdminsFlag, String:s_adminsflag[12];
new Handle:h_Delay, Float:f_poisondelay;
new Handle:h_Distance, i_poisondistance;

public Plugin:myinfo = 
{
	name = "Poisonthrower",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Poisonthrower plugin",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru"
};

public OnPluginStart()
{	
	h_Enable		= CreateConVar("zr_poison_enabled", "1", " Enables/Disables the poisonthrower plugin", 0, true, 0.0, true, 1.0);
	h_Version 	 	= CreateConVar("zr_poison_version", PLUGIN_VERSION, "Version of poisonthrower on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_PoisonAmount	= CreateConVar("zr_poison_amount", "2", "The maximum number of poisonthrower per player at spawn (0 = unlimited)", 0, true, 0.0);
	h_PoisonSound  	= CreateConVar("zr_poison_sound", "weapons/rpg/rocketfire1.wav", "Path to the poison blast sound");
	h_AdminsOnly   	= CreateConVar("zr_poison_admins_only", "0", " Allow Admins only to use the poisonthrower", 0, true, 0.0, true, 1.0);
	h_MothersOnly  	= CreateConVar("zr_poison_motherzombies_only", "0", " Allow only mother zombies to use the poisonthrower", 0, true, 0.0, true, 1.0);
	h_AdminsUnlimited = CreateConVar("zr_poison_admins_unlimited", "0", " Allow Admins to have unlimited poisonthrower", 0, true, 0.0, true, 1.0);
	h_AdminsFlag 	= CreateConVar("zr_poison_admins_flag", "b", "Admin flag to access to the poisonthrower. Leave it empty, for any flag");
	h_Delay 		= CreateConVar("zr_poison_delay", "6.0", " Delay between poisonthrower blasts", 0, true, 1.0);
	h_Distance 		= CreateConVar("zr_poison_distance", "400.0", "Distance of the effect of the poison thrower", 0, true, 100.0);
	
	HookConVarChange(h_Version, CvarChanges);
	HookConVarChange(h_Enable, CvarChanges);
	HookConVarChange(h_PoisonAmount, CvarChanges);
	HookConVarChange(h_PoisonSound, CvarChanges);
	HookConVarChange(h_AdminsOnly, CvarChanges);
	HookConVarChange(h_AdminsUnlimited, CvarChanges);
	HookConVarChange(h_AdminsFlag, CvarChanges);
	HookConVarChange(h_MothersOnly, CvarChanges);
	HookConVarChange(h_Delay, CvarChanges);
	HookConVarChange(h_Distance, CvarChanges);
	
	LoadTranslations("zr_poisonthrower");
	
	AutoExecConfig(true, "zombiereloaded/PoisonThrower");
}

public OnConfigsExecuted()
{
	b_enabled = GetConVarBool(h_Enable);
	b_adminsonly = GetConVarBool(h_AdminsOnly);
	b_adminsunlimited = GetConVarBool(h_AdminsUnlimited);
	b_mothersonly = GetConVarBool(h_MothersOnly);
	i_poisonamount = GetConVarInt(h_PoisonAmount);
	i_poisondistance = GetConVarInt(h_Distance);
	f_poisondelay = GetConVarFloat(h_Delay);
	
	GetConVarString(h_PoisonSound, s_poisonsound, sizeof(s_poisonsound));
	GetConVarString(h_AdminsFlag, s_adminsflag, sizeof(s_adminsflag));
	
	PrecacheSound(s_poisonsound, true);
	decl String:downsound[PLATFORM_MAX_PATH];
	Format(downsound, sizeof(downsound), "sound/%s", s_poisonsound);
	AddFileToDownloadsTable(downsound);
}

public OnClientPostAdminCheck(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	new AdminFlag:flag;
	if (adminid != INVALID_ADMIN_ID)
	{
		if(StrEqual(s_adminsflag, "", false))
			IsAdmin[client] = true;
		
		else if (FindFlagByChar(s_adminsflag[0], flag))
		{
			if(GetAdminFlag(adminid, flag))
				IsAdmin[client] = true;
		}
		else
			IsAdmin[client] = false;
	}
	else
		IsAdmin[client] = false;
}

public OnClientDisconnect_Post(client)
{
    g_LastButtons[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!client || !b_enabled || !IsPlayerAlive(client) || ZR_IsClientHuman(client) || !IsAllowed[client] || !poisonAmount[client])
		return Plugin_Continue;
	
	if (!(g_LastButtons[client] & IN_ATTACK2) && buttons & IN_ATTACK2)
		OnButtonPress(client);
	
	g_LastButtons[client] = buttons;
	
	return Plugin_Continue;
}

OnButtonPress(client)
{
	if (i_poisonamount)
	{
		if (IsAdmin[client])
		{
			if (!b_adminsunlimited)
			{
				poisonAmount[client]--;
				PrintToChat(client, "[SM] %t", "Poisons Left", poisonAmount[client]);
			}
		}
		else
		{
			poisonAmount[client]--;
			PrintToChat(client, "[SM] %t", "Poisons Left", poisonAmount[client]);
		}
	}
	
	new Float:vAngles[3];
	new Float:vOrigin[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	CreatePoison(client, vOrigin, vAngles);
	
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] +=3;
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] +=3;
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] +=3;
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] -=12;
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] -=3;
	GetVectors(client, vOrigin, vAngles);
	vAngles[0] -=3;
	GetVectors(client, vOrigin, vAngles);
		
	IsAllowed[client] = false;
	CreateTimer(f_poisondelay, Setpoison, client);
}

GetVectors(client, const Float:vOrigin[3], const Float:vAngles[3])
{
	new Float:newAngle[3];
	
	newAngle[0] = vAngles[0];
	newAngle[1] = vAngles[1];
	newAngle[2] = vAngles[2];
	
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] += 3;
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] += 3;
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] += 3;
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] = vAngles[1]-3;
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] -= 3;
	GetAndTrace(client, vOrigin, newAngle);
	
	newAngle[1] -= 3;
	GetAndTrace(client, vOrigin, newAngle);
}

GetAndTrace(client, const Float:vOrigin[3], const Float:vAngles[3])
{
	new Float:AnglesVec[3];
	new Float:EndPoint[3];
	
	GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
	
	EndPoint[0] = vOrigin[0] + (AnglesVec[0]*float(i_poisondistance));
	EndPoint[1] = vOrigin[1] + (AnglesVec[1]*float(i_poisondistance));
	EndPoint[2] = vOrigin[2] + (AnglesVec[2]*float(i_poisondistance));
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
	
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
	if (data != entity && (1 <= entity <= MaxClients) && ZR_IsClientHuman(entity))
		ZR_InfectClient(entity, data);
	return false;
} 

CreatePoison(client, const Float:origin[3], const Float:angles[3])
{
	decl String:Distance[16];
	IntToString(i_poisondistance, Distance, sizeof(Distance));
	
	// Ident the player
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%i", client);
	DispatchKeyValue(client, "targetname", tName);
	
	EmitSoundToClient(client, s_poisonsound, _, _, _, _, 0.7);
			
	// Create the poison
	decl String:poison_name[128];
	Format(poison_name, sizeof(poison_name), "poison%i", client);
	new poison = CreateEntityByName("env_steam");
	DispatchKeyValue(poison,"targetname", poison_name);
	DispatchKeyValue(poison, "parentname", tName);
	DispatchKeyValue(poison,"SpawnFlags", "1");
	DispatchKeyValue(poison,"Type", "0");
	DispatchKeyValue(poison,"InitialState", "1");
	DispatchKeyValue(poison,"Spreadspeed", "10");
	DispatchKeyValue(poison,"Speed", "800");
	DispatchKeyValue(poison,"Startsize", "15");
	DispatchKeyValue(poison,"EndSize", "250");
	DispatchKeyValue(poison,"Rate", "30");
	DispatchKeyValue(poison,"JetLength", Distance);
	DispatchKeyValue(poison,"RenderColor", "20 225 8");
	DispatchKeyValue(poison,"RenderAmt", "180");
	DispatchSpawn(poison);
	TeleportEntity(poison, origin, angles, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(poison, "SetParent", poison, poison, 0);
		
	CreateTimer(0.5, Killpoison, poison);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (i_poisonamount)
	{
		if (b_mothersonly)
		{
			if (!motherInfect)
				return;
			
			if (b_adminsonly)
			{
				if (!IsAdmin[client])
				{
					IsAllowed[client] = false;
					return;
				}
				poisonAmount[client] = i_poisonamount;
			}
			else
				poisonAmount[client] = i_poisonamount;
		}
		else 
		{
			if (b_adminsonly)
			{
				if (!IsAdmin[client])
				{
					IsAllowed[client] = false;
					return;
				}
				poisonAmount[client] = i_poisonamount;
			}
			else
				poisonAmount[client] = i_poisonamount;
		}
	}
	else
	{
		if (b_adminsonly)
		{
			if (!IsAdmin[client])
			{
				IsAllowed[client] = false;
				return;
			}
			poisonAmount[client] = 1;
		}
		else
			poisonAmount[client] = 1;
	}
	IsAllowed[client] = true;
}

public Action:Setpoison(Handle:timer, any:client)
{
	IsAllowed[client] = true;
}

public Action:Killpoison(Handle:timer, any:poison)
{
	if (IsValidEntity(poison))
	{
		new String:classname[256];
		GetEdictClassname(poison, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
			AcceptEntityInput(poison, "kill");
	}
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_Enable)
		b_enabled = GetConVarBool(convar); else
	if (convar == h_AdminsOnly)
		b_adminsonly = GetConVarBool(convar); else
	if (convar == h_AdminsUnlimited)
		b_adminsunlimited = GetConVarBool(convar); else
	if (convar == h_MothersOnly)
		b_mothersonly = GetConVarBool(convar); else
	if (convar == h_PoisonAmount)
		i_poisonamount = StringToInt(newValue); else
	if (convar == h_Delay)
		f_poisondelay = StringToFloat(newValue); else
	if (convar == h_Distance)
		i_poisondistance = StringToInt(newValue); else
	if (convar == h_PoisonSound)
	{
		strcopy(s_poisonsound, sizeof(s_poisonsound), newValue);
		PrecacheSound(s_poisonsound);
		decl String:downsound[PLATFORM_MAX_PATH];
		Format(downsound, sizeof(downsound), "sound/%s", s_poisonsound);
		AddFileToDownloadsTable(downsound);
	} else
	if (convar == h_Version)
	{
		if (!StrEqual(newValue, PLUGIN_VERSION))
			SetConVarString(h_Version, PLUGIN_VERSION);
	} else
	if (convar == h_AdminsFlag)
	{
		strcopy(s_adminsflag, sizeof(s_adminsflag), newValue);
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientConnected(client))
				OnClientPostAdminCheck(client);
		}
	}
}