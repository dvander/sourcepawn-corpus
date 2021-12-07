#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
 
public Plugin:myinfo = {
	name = "Remote Control Sentries",
	author = "twistedeuphoria",
	description = "Remotely control your sentries",
	version = "0.1",
	url = "dsfsdf"
};

new isRemoting[128];

new sentryWatcher[128];

new maxclients;

new Handle:remotecvar;

public OnPluginStart()
{		
	remotecvar = CreateConVar("sm_remote_sentries_enable", "1", "Enable or disable remote sentries.");
	CreateConVar("sm_remote_sentries_version", "0.1", "Remote Control Sentries Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(remotecvar, RemoteCvarChange);

	RegConsoleCmd("sm_remote_on", remoteon, "Start remote controlling your sentry gun.", 0);
	RegConsoleCmd("sm_remote_off", remoteoff, "Stop remote controlling your sentry gun.", 0);
		
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
					vel[0] += fwdvec[0] * 200.0;
					vel[1] += fwdvec[1] * 200.0;
				}
				if(buttons & IN_BACK)
				{
					vel[0] += fwdvec[0] * -200.0;
					vel[1] += fwdvec[1] * -200.0;
				}
				if(buttons & IN_MOVELEFT)
				{
					vel[0] += rightvec[0] * -200.0;
					vel[1] += rightvec[1] * -200.0;
				}
				if(buttons & IN_MOVERIGHT)
				{
					vel[0] += rightvec[0] * 200.0;
					vel[1] += rightvec[1] * 200.0;
				}
				if(buttons & IN_JUMP)
				{
					new flags = GetEntityFlags(isRemoting[i]);
					if(flags & FL_ONGROUND)
					{
						vel[2] += 2000.0;
					}
				}
				
				TeleportEntity(isRemoting[i], NULL_VECTOR, angles, vel);
				
								
				new Float:sentrypos[3];
				GetEntPropVector(isRemoting[i], Prop_Data, "m_vecOrigin", sentrypos);
				
				sentrypos[0] += fwdvec[0] * -150.0;
				sentrypos[1] += fwdvec[1] * -150.0;
				sentrypos[2] += upvec[2] * 75.0;
				
				TeleportEntity(sentryWatcher[i], sentrypos, angles, NULL_VECTOR);
		
			}
		}
	}
}

public Action:remoteon(client, args)
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
	new sentryid = -1;
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
					sentryid = i;
					break;
				}
			}
		}
	}
	
	if(sentryid < 0)
	{
		PrintToChat(client, "No sentry gun found!");
	}
	else
	{		
		SetEntityMoveType(sentryid, MOVETYPE_STEP);
		SetEntityMoveType(client, MOVETYPE_STEP);
		isRemoting[client] = sentryid;
		
		sentryWatcher[client] = CreateEntityByName("info_observer_point");
		DispatchSpawn(sentryWatcher[client]);
		
		//SetClientViewEntity(client, isRemoting[client]);
		
		
		new Float:angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		
		new Float:fwdvec[3];
		new Float:rightvec[3];
		new Float:upvec[3];
		GetAngleVectors(angles, fwdvec, rightvec, upvec);	
		new Float:sentrypos[3];
		GetEntPropVector(sentryid, Prop_Data, "m_vecOrigin", sentrypos);
		sentrypos[0] += fwdvec[0] * -150.0;
		sentrypos[1] += fwdvec[1] * -150.0;
		sentrypos[2] += upvec[2] * 75.0;
		TeleportEntity(sentryWatcher[client], sentrypos, angles, NULL_VECTOR);
		
		SetClientViewEntity(client, sentryWatcher[client]);
	}
	return Plugin_Handled;
}

public Action:remoteoff(client, args)
{
	if( (sentryWatcher[client] > 0) && IsValidEntity(sentryWatcher[client]) ) RemoveEdict(sentryWatcher[client]);
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
