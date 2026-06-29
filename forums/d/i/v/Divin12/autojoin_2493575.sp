#include <sourcemod>
#include <cstrike>
#include <sdktools>

new Handle: Team

public Plugin:myinfo = {
	name = "Auto Join On Connect",
	author = "Divin!",
	description = "Based on players number with bug fixed",
	version = "1.0",
	url = "http://wtfcs.com/forum"
}

public OnPluginStart( ) {
	Team = CreateConVar( "sm_join_team", "1", "Do not edit this" )
	AddCommandListener(SelectTeam, "jointeam");
	HookEvent( "player_connect_full", Event_OnFullConnect, EventHookMode_Post )
}

public Event_OnFullConnect( Handle:event, const String:name[ ], bool:dontBroadcast ) {
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) )
	
	if( client != 0 && IsClientInGame( client ) && !IsFakeClient( client ) ) {
		CreateTimer( 0.5, AssignTeam, client )
	}
}

public Action: AssignTeam( Handle: timer, any: client ) {
	if( IsClientInGame( client ) ) {
		int iCvar = GetConVarInt( Team )
		
		switch( iCvar ) {
			case 0 : {
				return Plugin_Handled
			}
			case 1 : {
				new iRed, iBlue;
				for(new i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i))
						continue;

					new iTeam = GetClientTeam(i);
					if(iTeam == CS_TEAM_T)
						iRed++;
					else if(iTeam == CS_TEAM_CT)
						iBlue++;
				}
				if( iRed > iBlue )
				{
					ChangeClientTeam( client, 3 )
				}
				else
				if( iRed < iBlue )
				{
					ChangeClientTeam( client, 2 )
				}
				else
				if( iRed == iBlue )
				{
					ChangeClientTeam( client, 2 )
				}
				CS_RespawnPlayer(client);
							
			}
			
			case 2 : {
				ChangeClientTeam( client, 2 )
			}
			
			case 3 : {
				ChangeClientTeam( client, 3 )
			}
		}
	}
	
	return Plugin_Continue
}

public Action:SelectTeam(client, const String:command[], args)
{
    if (client && args)
    {
        decl String:team[2];
        GetCmdArg(1, team, sizeof(team));
        switch (StringToInt(team))
        {
            case CS_TEAM_SPECTATOR: ChangeClientTeam(client, CS_TEAM_SPECTATOR);
            case CS_TEAM_T: {
				new iRed, iBlue;
				for(new i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i))
						continue;

					new iTeam = GetClientTeam(i);
					if(iTeam == CS_TEAM_T)
						iRed++;
					else if(iTeam == CS_TEAM_CT)
						iBlue++;
				}
				if( iRed < iBlue )
				{
					ForcePlayerSuicide(client);
					ChangeClientTeam( client, 2 )
				}
				else
				if( iRed == iBlue )
				{
					ForcePlayerSuicide(client);
					ChangeClientTeam( client, 2 )
				}
			}
			case CS_TEAM_CT: {
				new iRed, iBlue;
				for(new i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i))
						continue;

					new iTeam = GetClientTeam(i);
					if(iTeam == CS_TEAM_T)
						iRed++;
					else if(iTeam == CS_TEAM_CT)
						iBlue++;
				}
				if( iRed > iBlue )
				{
					ForcePlayerSuicide(client);
					ChangeClientTeam( client, 3 )
				}
				else
				if( iRed == iBlue )
				{
					ForcePlayerSuicide(client);
					ChangeClientTeam( client, 3 )
				}
			}
        }
    }
    return Plugin_Continue;
}