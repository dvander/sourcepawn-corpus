/*
 *This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * fake_voice_lag.sp written by El Diablo of www.War3Evo.info
 * All rights reserved.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// if you want to check to make sure that players are not already muted,
// then enable this and BaseComm_IsClientMuted below
//#include <basecomm>

#define PLUGIN_VERSION "1.0.1"

new bool:RoboticListen[MAXPLAYERS+1];
new bool:RoboticListenToggle[MAXPLAYERS+1];
new OldPing[MAXPLAYERS+1];

public Plugin:myinfo =
{
				name = "Fake Voice Lag",
				author = "El Diablo",
				description = "Fake Ping and Fake Voice Lag",
				version = PLUGIN_VERSION,
				url = "http://www.nom-nom-nom.us"

}

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}

public OnPluginStart()
{
	CreateTimer(1.0, Timer_Fun, _);
	
	RegAdminCmd("sm_setfakevoicelag", playerRobot, ADMFLAG_BAN);
}

stock ClientPing( iClient, iPing = -1 )
{
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) )
		return 0;
	
	new iResEnt = GetPlayerResourceEntity();
	if( iResEnt == INVALID_ENT_REFERENCE )
		return 0;
	
	if( iPing < 0 )
		return GetEntProp( iResEnt, Prop_Send, "m_iPing", _, iClient );
	else
	{
		SetEntProp( iResEnt, Prop_Send, "m_iPing", iPing, _, iClient );
		return 1;
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	RoboticListen[client] = false;
	RoboticListenToggle[client] = false;
	
	return true;
}

public OnGameFrame()
{
	for (new x=1; x<=MaxClients; x++)
	{
		if(!RoboticListen[x])
			continue;	// Client isnt valid

		if (!ValidPlayer(x))
			continue;	// Client isnt valid
		
		ClientPing( x, GetRandomInt(600, 999) );

		if(!RoboticListenToggle[x])
		{
			SetClientListeningFlags(x,VOICE_NORMAL);
		}
		else if(RoboticListenToggle[x])
		{
			SetClientListeningFlags(x,VOICE_MUTED);
		}

	}
}

public Action:Timer_Fun(Handle:timer, any:user)
{
	for (new iReciever=1; iReciever<=MaxClients; iReciever++)
	{
		//if(BaseComm_IsClientMuted(iReciever))
			//continue;
		
		if (!ValidPlayer(iReciever))
			continue;	// Client isnt valid
		
		if(!RoboticListen[iReciever])
			continue;	// Client isnt valid
		
		if(RoboticListenToggle[iReciever])
		{
			RoboticListenToggle[iReciever]=false;
		}
		else if(!RoboticListenToggle[iReciever])
		{
			RoboticListenToggle[iReciever]=true;
		}
	}
	CreateTimer(0.2, Timer_Fun, _);
}


public Action:playerRobot(client, args)
{
	if(args<2)
	{
		PrintToChat(client,"sm_setfakevoicelag (playername or userid) # (0 = false or 1 = true)\nExample: sm_setfakevoicelag player 1");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:buffer[15];
	GetCmdArg(2, buffer, sizeof(buffer));
	new iSetTrueOrFalse = StringToInt(buffer);
	
	new target = FindTarget(client, arg, true, false);    //bots can't be affected
	if (target == -1)
	{
		PrintToChat(client,"Can't find target");
		return Plugin_Handled;
	}
	
	new String:tClientName[128];
	GetClientName(target,tClientName,sizeof(tClientName));

	if(ValidPlayer(client))
	{
		if(iSetTrueOrFalse>0)
		{
			RoboticListen[target]=true;
			RoboticListenToggle[target]=true;
			PrintToChat(client,"FAKE VOICE LAG SET ON %s",tClientName);
			OldPing[target]=ClientPing( target );
		}
		else
		{
			RoboticListen[target]=false;
			PrintToChat(client,"FAKE VOICE LAG SET OFF %s",tClientName);
			SetClientListeningFlags(target,VOICE_NORMAL);
			RoboticListenToggle[target]=false;
			ClientPing( target, OldPing[target] );
		}
	}
	return Plugin_Handled;
}
