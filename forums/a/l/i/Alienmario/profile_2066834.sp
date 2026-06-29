#include <sourcemod>

#define MAX_STEAMID_LENGTH 21 
#define MAX_COMMUNITYID_LENGTH 18 

public OnPluginStart(){
	RegConsoleCmd("sm_profile", profile);
}

public Action:profile(client, args)
{
	if(args==0){
		PrintToChat(client,"Proper Usage: !profile<steamid, userid, playername>");
		return Plugin_Handled;
	}
	decl String:arg[128],String:link[128];
	new String:steamID[MAX_STEAMID_LENGTH];
	new String:CommunityID[MAX_COMMUNITYID_LENGTH];
	
	GetCmdArgString(arg,128);
	new Targ=FindTarget(client,arg,true,false);
	
	if(Targ<=0){
		Format(steamID,sizeof(steamID),"%s",arg);
	}else{
		GetClientAuthString(Targ,steamID,sizeof(steamID));
	}
	GetCommunityIDString(steamID, CommunityID, sizeof(CommunityID)); 
	Format(link,sizeof(link),"http://steamcommunity.com/profiles/%s",CommunityID);
	
	if(client!=0){
		ShowMOTDPanel(client,"steamID",link,MOTDPANEL_TYPE_URL);
	}else{
		PrintToServer("%s",link);
	}
	return Plugin_Handled;
}

stock bool:GetCommunityIDString(const String:SteamID[], String:CommunityID[], const CommunityIDSize) 
{ 
    decl String:SteamIDParts[3][11]; 
    new const String:Identifier[] = "76561197960265728"; 
     
    if ((CommunityIDSize < 1) || (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3)) 
    { 
        CommunityID[0] = '\0'; 
        return false; 
    } 

    new Current, CarryOver = (SteamIDParts[1][0] == '1'); 
    for (new i = (CommunityIDSize - 2), j = (strlen(SteamIDParts[2]) - 1), k = (strlen(Identifier) - 1); i >= 0; i--, j--, k--) 
    { 
        Current = (j >= 0 ? (2 * (SteamIDParts[2][j] - '0')) : 0) + CarryOver + (k >= 0 ? ((Identifier[k] - '0') * 1) : 0); 
        CarryOver = Current / 10; 
        CommunityID[i] = (Current % 10) + '0'; 
    } 

    CommunityID[CommunityIDSize - 1] = '\0'; 
    return true; 
}