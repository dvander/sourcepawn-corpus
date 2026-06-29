#pragma semicolon 1;
#include <sourcemod>
#include <sdktools>

#define SWAP_ADMIN_FLAG ADMFLAG_RESERVATION

new maxplayers;

public Plugin:myinfo = 
{
    name = "SwapMyTeam TF2",
    author = "Nican132",
    description = "Allow admins to swap teams.",
    version = "1.0",
    url = "http://www.nican132.com/"
};

public OnPluginStart()
{
    CreateConVar("sm_swapteam_version", "1.0", "Allow admins to swap teams", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
}

public OnMapStart(){
	maxplayers = GetMaxClients();
}

public Action:Command_Say(client, argc)
{
    decl String:args[192];
    GetCmdArgString(args,192);
    
    TrimString( args );

    if( StrContains(args, "swapmyteam", false) == 1 ){
        new AdminId:admin;
        admin = GetUserAdmin(client);
        
        if( admin == INVALID_ADMIN_ID){
            PrintToChat(client, "You are not an admin!");  
            return;         
        }
        
        new flags = GetAdminFlags( admin, Access_Real);
        
        if(!(flags &  SWAP_ADMIN_FLAG || flags & ADMFLAG_ROOT)){
            PrintToChat(client, "You do not have enough acess!");  
            return;          
        }
    
    	new team = GetClientTeam(client);
    	new targetteam;
    	
    	switch(team){
            case 2:{
                targetteam = 3;
            }
            case 3:{
                targetteam = 2;
            }
            default:{
                PrintToChat(client, "You are not on a team!");  
                return; 
            }                 
        }
        
        new i;
        new Float:dumptime, Float:lowesttime, lowestplayer; 
        for(i=1; i<= maxplayers; i++){
            if(!IsClientInGame(i))
                continue;
                
            if(IsFakeClient(i))
                continue;
                
            if(GetClientTeam(client) == team)
                continue;
			 
            dumptime = GetClientTime(client);
            
            if(lowesttime == 0.0 || dumptime < lowesttime){
                lowestplayer = i;
                lowesttime = dumptime;
            }
        }
        
        if(lowestplayer == 0){
            ChangeClientTeam( client, targetteam );            
            return;
        }
        
        new teamcount[2];
        teamcount[0] = GetTeamClientCount(team);
        teamcount[1] = GetTeamClientCount(targetteam);
        
        if(teamcount[0] > teamcount[1]){
            ChangeClientTeam( client, targetteam );
            ChangeClientTeam( lowestplayer, team );
        }
        else if(teamcount[1] < teamcount[0]){
            ChangeClientTeam( lowestplayer, team );
            ChangeClientTeam( client, targetteam );
        } else {
            ChangeClientTeam( lowestplayer, 1 );
            ChangeClientTeam( client, targetteam );
            ChangeClientTeam( lowestplayer, team );
        }    	
    }
}
