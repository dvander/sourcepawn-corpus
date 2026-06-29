#include <cstrike>
#include <sdktools>

public Plugin:myinfo = {
	name = "Join Team",
	author = "Divin!",
	description = "Fix Join Team Bug",
	version = "1.0",
	url = "http://wtfcs.com/forum"
}

public OnPluginStart() AddCommandListener(SelectTeam, "jointeam");

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