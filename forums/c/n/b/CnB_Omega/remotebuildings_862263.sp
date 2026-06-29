#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
 
public Plugin:myinfo = {
	name = "Remote Control Sentries",
	author = "twistedeuphoria - Modded by Omega",
	description = "Remotely control your sentries",
	version = "0.1",
	url = "dsfsdf"
};

new isRemoting[128];

new remoteWatcher[128];

new maxclients;

new Handle:remotecvar;
new Handle:remotespeed;

public OnPluginStart()
{		
	remotecvar = CreateConVar("sm_remote_sentries_enable", "1", "Enable or disable remote sentries.");
	CreateConVar("sm_remote_sentries_version", "0.1", "Remote Control Sentries Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	remotespeed = CreateConVar("sm_remote_sentries_speed", "1", "Multiplier for how fast sentries move and how high they jump.");
	HookConVarChange(remotecvar, RemoteCvarChange);

	RegAdminCmd("sm_sentry", sentryon, ADMFLAG_ROOT, "Start remote controlling your sentry gun.");
	RegAdminCmd("sm_remote_off", remoteoff, ADMFLAG_ROOT, "Stop remote controlling your buildings.");
	RegAdminCmd("sm_enter", entranceon, ADMFLAG_ROOT, "Start remote controlling your teleport entrance.");
	RegAdminCmd("sm_exit", exiton, ADMFLAG_ROOT, "Start remote controlling your teleport exit.");
	RegAdminCmd("sm_disp", dispon, ADMFLAG_ROOT, "Start remote controlling your dispenser.");
	
	//RegConsoleCmd("sm_sentry_on", sentryon, "Start remote controlling your sentry gun.", 0);
	//RegConsoleCmd("sm_remote_off", sentryoff, "Stop remote controlling your sentry gun.", 0);
		
	RegAdminCmd("sm_remote_god", remotegod, ADMFLAG_ROOT, "Gives Sentry godmode (experimental).");
		
	maxclients = GetMaxClients();
}

public RemoteCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == remotecvar)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(oldValue);
		
		if( (newval != 0) && (newval != 1) )
		{
			PrintToServer("Value for sm_remote_sentries_enable is invalid %s, switching back to %s.", newValue, oldValue);
			SetConVarInt(remotecvar, oldval);
			return;
		}
		
		if( (oldval == 1) && (newval == 0) )
		{
			for(new i=1;i<maxclients;i++)
			{
				if(IsClientConnected(i))
				{
					remoteoff(i, 0);
				}
			}
		}
	}
}

public OnGameFrame()
{
	for(new i=1;i<maxclients;i++)
	{
		if(IsClientConnected(i) && (isRemoting[i] != 0))
		{
			if(!IsValidEntity(isRemoting[i]))
			{
				if(isRemoting[i] != 0) remoteoff(i, 0);
			}
			else
			{
				new Float:angles[3];
				GetClientEyeAngles(i, angles);
				angles[0] = 0.0;
				
				new Float:fwdvec[3];
				new Float:rightvec[3];
				new Float:upvec[3];
				GetAngleVectors(angles, fwdvec, rightvec, upvec);
			
				new Float:vel[3];		
				vel[2] = -50.0;
				new buttons = GetClientButtons(i);
				
				if(buttons & IN_FORWARD)
				{
					vel[0] += fwdvec[0] * 200.0 * GetConVarFloat(remotespeed);
					vel[1] += fwdvec[1] * 600.0 * GetConVarFloat(remotespeed);
				}
				if(buttons & IN_BACK)
				{
					vel[0] += fwdvec[0] * -200.0 * GetConVarFloat(remotespeed);
					vel[1] += fwdvec[1] * -200.0 * GetConVarFloat(remotespeed);
				}
				if(buttons & IN_MOVELEFT)
				{
					vel[0] += rightvec[0] * -200.0 * GetConVarFloat(remotespeed);
					vel[1] += rightvec[1] * -200.0 * GetConVarFloat(remotespeed);
				}
				if(buttons & IN_MOVERIGHT)
				{
					vel[0] += rightvec[0] * 200.0 * GetConVarFloat(remotespeed);
					vel[1] += rightvec[1] * 200.0 * GetConVarFloat(remotespeed);
				}
				if(buttons & IN_JUMP)
				{
					new flags = GetEntityFlags(isRemoting[i]);
					if(flags & FL_ONGROUND)
					{
					vel[2] += 200.0 * GetConVarFloat(remotespeed);
					}
				}
				
				TeleportEntity(isRemoting[i], NULL_VECTOR, angles, vel);
				
								
				new Float:sentrypos[3];
				GetEntPropVector(isRemoting[i], Prop_Data, "m_vecOrigin", sentrypos);
				
				sentrypos[0] += fwdvec[0] * -150.0;
				sentrypos[1] += fwdvec[1] * -150.0;
				sentrypos[2] += upvec[2] * 75.0;
				
				TeleportEntity(remoteWatcher[i], sentrypos, angles, NULL_VECTOR);
		
			}
		}
	}
}

public Action:sentryon(client, args)
{
	if(GetConVarInt(remotecvar) != 1)
	{
		PrintToChat(client, "Remote sentries are not enabled.");
		return Plugin_Handled;
	}
	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		PrintToChat(client, "You are not an engineer.");
		return Plugin_Handled;
	}
	new remoteid = -1;
	new entcount = GetEntityCount();
	for(new i=0;i<entcount;i++)
	{
		if(IsValidEntity(i))
		{
			new String:classname[50];
			GetEdictClassname(i, classname, 50);
			
			if(strcmp(classname, "obj_sentrygun") == 0)
			{
				if(GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
				{
					remoteid = i;
					break;
				}
			}
		}
	}
	
	if(remoteid < 0)
	{
		PrintToChat(client, "No sentry gun found!");
	}
	else
	{		
		SetEntityMoveType(remoteid, MOVETYPE_STEP);
		SetEntityMoveType(client, MOVETYPE_NONE);
		isRemoting[client] = remoteid;
		
		remoteWatcher[client] = CreateEntityByName("info_observer_point");
		DispatchSpawn(remoteWatcher[client]);
		
		//SetClientViewEntity(client, isRemoting[client]);
		
		
		new Float:angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		
		new Float:fwdvec[3];
		new Float:rightvec[3];
		new Float:upvec[3];
		GetAngleVectors(angles, fwdvec, rightvec, upvec);	
		new Float:sentrypos[3];
		GetEntPropVector(remoteid, Prop_Data, "m_vecOrigin", sentrypos);
		sentrypos[0] += fwdvec[0] * -150.0;
		sentrypos[1] += fwdvec[1] * -150.0;
		sentrypos[2] += upvec[2] * 75.0;
		TeleportEntity(remoteWatcher[client], sentrypos, angles, NULL_VECTOR);
		
		SetClientViewEntity(client, remoteWatcher[client]);
	}
	return Plugin_Handled;
}

public Action:remoteoff(client, args)
{
	if( (remoteWatcher[client] > 0) && IsValidEntity(remoteWatcher[client]) ) RemoveEdict(remoteWatcher[client]);
	if(IsValidEntity(isRemoting[client]))
	{
		new Float:angles[3];
		GetClientEyeAngles(client, angles);	
		angles[0] = 0.0;
	
		TeleportEntity(isRemoting[client], NULL_VECTOR, angles, NULL_VECTOR);	
	}	
	
	SetClientViewEntity(client, client);
	isRemoting[client] = 0;
	SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action:remotegod(client, args)
{
	if(isRemoting[client] < 0)
	{
		PrintToChat(client, "Not controlling a building!");
	}
	else
	{
		//isRemoting[client] = remoteid;
		new sValue = GetEntProp(isRemoting[client], Prop_Data, "m_takedamage", 1);
		if(sValue) // mortal
		{
			SetEntProp(isRemoting[client], Prop_Data, "m_takedamage", 0, 1)
			PrintToChat(client,"\x01\x04Building god mode on")
		}
		else // godmode
		{
			SetEntProp(isRemoting[client], Prop_Data, "m_takedamage", 1, 1)
			PrintToChat(client,"\x01\x04Building god mode off")
		}
	}
}

public Action:entranceon(client, args)
{
	if(GetConVarInt(remotecvar) != 1)
	{
		PrintToChat(client, "Remote buildings are not enabled.");
		return Plugin_Handled;
	}
	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		PrintToChat(client, "You are not an engineer.");
		return Plugin_Handled;
	}
	new remoteid = -1;
	new entcount = GetEntityCount();
	for(new i=0;i<entcount;i++)
	{
		if(IsValidEntity(i))
		{
			new String:classname[50];
			GetEdictClassname(i, classname, 50);
			
			if(strcmp(classname, "obj_teleporter_entrance") == 0)
			{
				if(GetEntDataEnt2(i, FindSendPropOffs("CObjectTeleporter","m_hBuilder")) == client)
				{
					remoteid = i;
					break;
				}
			}
		}
	}
	
	if(remoteid < 0)
	{
		PrintToChat(client, "No teleport entrance found!");
	}
	else
	{		
		SetEntityMoveType(remoteid, MOVETYPE_STEP);
		SetEntityMoveType(client, MOVETYPE_NONE);
		isRemoting[client] = remoteid;
		
		remoteWatcher[client] = CreateEntityByName("info_observer_point");
		DispatchSpawn(remoteWatcher[client]);
		
		//SetClientViewEntity(client, isRemoting[client]);
		
		
		new Float:angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		
		new Float:fwdvec[3];
		new Float:rightvec[3];
		new Float:upvec[3];
		GetAngleVectors(angles, fwdvec, rightvec, upvec);	
		new Float:sentrypos[3];
		GetEntPropVector(remoteid, Prop_Data, "m_vecOrigin", sentrypos);
		sentrypos[0] += fwdvec[0] * -150.0;
		sentrypos[1] += fwdvec[1] * -150.0;
		sentrypos[2] += upvec[2] * 75.0;
		TeleportEntity(remoteWatcher[client], sentrypos, angles, NULL_VECTOR);
		
		SetClientViewEntity(client, remoteWatcher[client]);
	}
	return Plugin_Handled;
}

public Action:exiton(client, args)
{
	if(GetConVarInt(remotecvar) != 1)
	{
		PrintToChat(client, "Remote buildings are not enabled.");
		return Plugin_Handled;
	}
	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		PrintToChat(client, "You are not an engineer.");
		return Plugin_Handled;
	}
	new remoteid = -1;
	new entcount = GetEntityCount();
	for(new i=0;i<entcount;i++)
	{
		if(IsValidEntity(i))
		{
			new String:classname[50];
			GetEdictClassname(i, classname, 50);
			
			if(strcmp(classname, "obj_teleporter_exit") == 0)
			{
				if(GetEntDataEnt2(i, FindSendPropOffs("CObjectTeleporter","m_hBuilder")) == client)
				{
					remoteid = i;
					break;
				}
			}
		}
	}
	
	if(remoteid < 0)
	{
		PrintToChat(client, "No teleport exit found!");
	}
	else
	{		
		SetEntityMoveType(remoteid, MOVETYPE_STEP);
		SetEntityMoveType(client, MOVETYPE_NONE);
		isRemoting[client] = remoteid;
		
		remoteWatcher[client] = CreateEntityByName("info_observer_point");
		DispatchSpawn(remoteWatcher[client]);
		
		//SetClientViewEntity(client, isRemoting[client]);
		
		
		new Float:angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		
		new Float:fwdvec[3];
		new Float:rightvec[3];
		new Float:upvec[3];
		GetAngleVectors(angles, fwdvec, rightvec, upvec);	
		new Float:sentrypos[3];
		GetEntPropVector(remoteid, Prop_Data, "m_vecOrigin", sentrypos);
		sentrypos[0] += fwdvec[0] * -150.0;
		sentrypos[1] += fwdvec[1] * -150.0;
		sentrypos[2] += upvec[2] * 75.0;
		TeleportEntity(remoteWatcher[client], sentrypos, angles, NULL_VECTOR);
		
		SetClientViewEntity(client, remoteWatcher[client]);
	}
	return Plugin_Handled;
}

public Action:dispon(client, args)
{
	if(GetConVarInt(remotecvar) != 1)
	{
		PrintToChat(client, "Remote buildings are not enabled.");
		return Plugin_Handled;
	}
	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		PrintToChat(client, "You are not an engineer.");
		return Plugin_Handled;
	}
	new remoteid = -1;
	new entcount = GetEntityCount();
	for(new i=0;i<entcount;i++)
	{
		if(IsValidEntity(i))
		{
			new String:classname[50];
			GetEdictClassname(i, classname, 50);
			
			if(strcmp(classname, "obj_dispenser") == 0)
			{
				if(GetEntDataEnt2(i, FindSendPropOffs("CObjectDispenser","m_hBuilder")) == client)
				{
					remoteid = i;
					break;
				}
			}
		}
	}
	
	if(remoteid < 0)
	{
		PrintToChat(client, "No dispenser found!");
	}
	else
	{		
		SetEntityMoveType(remoteid, MOVETYPE_STEP);
		SetEntityMoveType(client, MOVETYPE_NONE);
		isRemoting[client] = remoteid;
		
		remoteWatcher[client] = CreateEntityByName("info_observer_point");
		DispatchSpawn(remoteWatcher[client]);
		
		//SetClientViewEntity(client, isRemoting[client]);
		
		
		new Float:angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		
		new Float:fwdvec[3];
		new Float:rightvec[3];
		new Float:upvec[3];
		GetAngleVectors(angles, fwdvec, rightvec, upvec);	
		new Float:sentrypos[3];
		GetEntPropVector(remoteid, Prop_Data, "m_vecOrigin", sentrypos);
		sentrypos[0] += fwdvec[0] * -150.0;
		sentrypos[1] += fwdvec[1] * -150.0;
		sentrypos[2] += upvec[2] * 75.0;
		TeleportEntity(remoteWatcher[client], sentrypos, angles, NULL_VECTOR);
		
		SetClientViewEntity(client, remoteWatcher[client]);
	}
	return Plugin_Handled;
}