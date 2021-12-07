#pragma semicolon 1

#define PLUGIN_VERSION		"1.2.1"

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

public Plugin:myinfo = 
{
	name		= "JetPack",
	author		= "FrozDark (HLModders.ru LLC)",
	description	= "JetPack",
	version		= PLUGIN_VERSION,
	url			= "www.hlmod.ru"
};

new
	Handle:h_Version,
	Handle:h_Enable, bool:b_enabled,
	Handle:h_AdminsOnly, bool:b_adminsonly,
	Handle:h_AdminsUnlimited, bool:b_adminsunlimited,
	Handle:h_AdminsFlag, String:s_adminsflag[12],
	Handle:h_ReloadDelay, Float:f_reloaddelay,
	Handle:h_JetPackBoost, Float:f_boost,
	Handle:h_JetPackMax, i_jetpackmax,
	bool:Delay[MAXPLAYERS+1],
	bool:IsAdmin[MAXPLAYERS+1],
	Handle:h_Timer[MAXPLAYERS+1],
	i_jumps[MAXPLAYERS+1];
	
	
public OnPluginStart()
{
	h_Version = CreateConVar("zr_jetpack_version", PLUGIN_VERSION, "JetPack Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_Enable = CreateConVar("zr_jetpack_enabled", "1", "Enables JetPack.", 0, true, 0.0, true, 1.0);
	h_AdminsOnly = CreateConVar("zr_jetpack_admins_only", "0", "Only admins will be able to use JetPack.", 0, true, 0.0, true, 1.0);
	h_AdminsUnlimited = CreateConVar("zr_jetpack_admins_unlimited", "0", "Allow admins to have unlimited JetPack.", 0, true, 0.0, true, 1.0);
	h_AdminsFlag = CreateConVar("zr_jetpack_admins_flag", "b", "Admin flag to access to the JetPack. Leave it empty for any flag", 0, true, 0.0, true, 1.0);
	h_ReloadDelay = CreateConVar("zr_jetpack_reloadtime", "60", "Time in seconds to reload JetPack.", 0, true, 1.0);
	h_JetPackBoost = CreateConVar("zr_jetpack_boost", "500.0", "The amount of boost to apply to JetPack.", 0, true, 100.0);
	h_JetPackMax = CreateConVar("zr_jetpack_max", "10", "Time in seconds of using JetPacks.", 0, true, 0.0);
	
	HookConVarChange(h_Enable, ConVarChanges);
	HookConVarChange(h_AdminsOnly, ConVarChanges);
	HookConVarChange(h_AdminsUnlimited, ConVarChanges);
	HookConVarChange(h_AdminsFlag, ConVarChanges);
	HookConVarChange(h_Version, ConVarChanges);
	HookConVarChange(h_ReloadDelay, ConVarChanges);
	HookConVarChange(h_JetPackBoost, ConVarChanges);
	HookConVarChange(h_JetPackMax, ConVarChanges);
	
	HookEvent("player_death", OnPlayerDeath);
	
	LoadTranslations("zr_jetpack");
	
	AutoExecConfig(true, "zombiereloaded/JetPack");
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientAuthorized(client))
			OnClientPostAdminCheck(client);
	}
}

public OnConfigsExecuted()
{
	b_enabled			= GetConVarBool(h_Enable);
	b_adminsonly		= GetConVarBool(h_AdminsOnly);
	b_adminsunlimited	= GetConVarBool(h_AdminsUnlimited);
	f_reloaddelay		= GetConVarFloat(h_ReloadDelay);
	f_boost				= GetConVarFloat(h_JetPackBoost);
	i_jetpackmax		= GetConVarInt(h_JetPackMax)*10;
	GetConVarString(h_AdminsFlag, s_adminsflag, sizeof(s_adminsflag));
}

public ConVarChanges(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if (convar == h_JetPackBoost)
		f_boost = StringToFloat(newVal); else
	if (convar == h_JetPackMax)
		i_jetpackmax = StringToInt(newVal)*10; else
	if (convar == h_AdminsOnly)
		b_adminsonly = GetConVarBool(convar); else
	if (convar == h_AdminsUnlimited)
		b_adminsunlimited = GetConVarBool(convar); else
	if (convar == h_AdminsFlag)
		strcopy(s_adminsflag, sizeof(s_adminsflag), newVal); else
	if (convar == h_Version)
	{
		if (!StrEqual(newVal, PLUGIN_VERSION))
			SetConVarString(h_Version, PLUGIN_VERSION);
	} else
	if (convar == h_Enable)
		b_enabled = GetConVarBool(convar); else
	if (convar == h_ReloadDelay)
		f_reloaddelay = StringToFloat(newVal);
}

public OnClientPostAdminCheck(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	new AdminFlag:flag;
	if (adminid != INVALID_ADMIN_ID)
	{
		if(!s_adminsflag[0])
			IsAdmin[client] = true;
		
		else if (FindFlagByChar(s_adminsflag[0], flag))
		{
			if(GetAdminFlag(adminid, flag))
				IsAdmin[client] = true;
		}
	}
	else
		IsAdmin[client] = false;
}

public OnClientDisconnect_Post(client)
{
	i_jumps[client] = 0;
	Delay[client] = false;
	
	if (h_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(h_Timer[client]);
		h_Timer[client] = INVALID_HANDLE;
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!b_enabled)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Delay[client])
		OnClientDisconnect_Post(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!b_enabled || !IsPlayerAlive(client) || ZR_IsClientZombie(client) || Delay[client] || (b_adminsonly && !IsAdmin[client]))
		return Plugin_Continue;
		
	if (buttons & IN_JUMP && buttons & IN_DUCK)
	{
		if (0 <= i_jumps[client] <= i_jetpackmax)
		{
			if (i_jetpackmax)
			{
				if (IsAdmin[client])
				{
					if (!b_adminsunlimited)
						i_jumps[client]++;
				}
				else
					i_jumps[client]++;
			}
	
			new Float:ClientEyeAngle[3];
			new Float:ClientAbsOrigin[3];
			new Float:Velocity[3];
			
			GetClientEyeAngles(client, ClientEyeAngle);
			GetClientAbsOrigin(client, ClientAbsOrigin);
			
			ClientEyeAngle[0] = -40.0;
			GetAngleVectors(ClientEyeAngle, Velocity, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(Velocity, f_boost);
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
			
			Delay[client] = true;
			CreateTimer(0.1, DelayOff, client);
			
			CreateEffect(client, ClientAbsOrigin, ClientEyeAngle);
			
			if (i_jumps[client] == i_jetpackmax && f_reloaddelay)
			{
				h_Timer[client] = CreateTimer(f_reloaddelay, Reload, client);
				PrintCenterText(client, "%t", "Jetpack Empty");
			}
		}
	}
	return Plugin_Continue;
}

CreateEffect(client, Float:vecorigin[3], Float:vecangle[3])
{
	vecangle[0] = 110.0;
	vecorigin[2] += 25.0;
	
	new String:tName[128];
	Format(tName, sizeof(tName), "target%i", client);
	DispatchKeyValue(client, "targetname", tName);
	
	// Create the fire
	new String:fire_name[128];
	Format(fire_name, sizeof(fire_name), "fire%i", client);
	new fire = CreateEntityByName("env_steam");
	DispatchKeyValue(fire,"targetname", fire_name);
	DispatchKeyValue(fire, "parentname", tName);
	DispatchKeyValue(fire,"SpawnFlags", "1");
	DispatchKeyValue(fire,"Type", "0");
	DispatchKeyValue(fire,"InitialState", "1");
	DispatchKeyValue(fire,"Spreadspeed", "10");
	DispatchKeyValue(fire,"Speed", "400");
	DispatchKeyValue(fire,"Startsize", "20");
	DispatchKeyValue(fire,"EndSize", "600");
	DispatchKeyValue(fire,"Rate", "30");
	DispatchKeyValue(fire,"JetLength", "200");
	DispatchKeyValue(fire,"RenderColor", "255 100 30");
	DispatchKeyValue(fire,"RenderAmt", "180");
	DispatchSpawn(fire);
	
	TeleportEntity(fire, vecorigin, vecangle, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(fire, "SetParent", fire, fire, 0);
	
	AcceptEntityInput(fire, "TurnOn");
		
	
	new String:fire_name2[128];
	Format(fire_name2, sizeof(fire_name2), "fire2%i", client);
	new fire2 = CreateEntityByName("env_steam");
	DispatchKeyValue(fire2,"targetname", fire_name2);
	DispatchKeyValue(fire2, "parentname", tName);
	DispatchKeyValue(fire2,"SpawnFlags", "1");
	DispatchKeyValue(fire2,"Type", "1");
	DispatchKeyValue(fire2,"InitialState", "1");
	DispatchKeyValue(fire2,"Spreadspeed", "10");
	DispatchKeyValue(fire2,"Speed", "400");
	DispatchKeyValue(fire2,"Startsize", "20");
	DispatchKeyValue(fire2,"EndSize", "600");
	DispatchKeyValue(fire2,"Rate", "10");
	DispatchKeyValue(fire2,"JetLength", "200");
	DispatchSpawn(fire2);
	TeleportEntity(fire2, vecorigin, vecangle, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(fire2, "SetParent", fire2, fire2, 0);
	AcceptEntityInput(fire2, "TurnOn");
			
	new Handle:firedata = CreateDataPack();
	WritePackCell(firedata, fire);
	WritePackCell(firedata, fire2);
	CreateTimer(0.5, Killfire, firedata);
}

public Action:Killfire(Handle:timer, Handle:firedata)
{
	
	ResetPack(firedata);
	new ent1 = ReadPackCell(firedata);
	new ent2 = ReadPackCell(firedata);
	CloseHandle(firedata);
	
	new String:classname[256];
	
	if (IsValidEntity(ent1))
    {
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (!strcmp(classname, "env_steam", false))
            AcceptEntityInput(ent1, "kill");
    }
	
	if (IsValidEntity(ent2))
    {
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
            AcceptEntityInput(ent2, "kill");
    }
}
	
public Action:DelayOff(Handle:timer, any:client)
{
	Delay[client] = false;
}

public Action:Reload(Handle:timer, any:client)
{
	if (h_Timer[client] != INVALID_HANDLE)
	{
		i_jumps[client] = 0;
		PrintCenterText(client, "%t", "Jetpack Reloaded");
		h_Timer[client] = INVALID_HANDLE;
	}
}