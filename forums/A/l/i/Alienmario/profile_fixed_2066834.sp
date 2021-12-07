#include <sourcemod>

#define MAX_STEAMID_LENGTH 21 
#define MAX_COMMUNITYID_LENGTH 18 

public OnPluginStart(){
	RegConsoleCmd("sm_profile", profile);
	LoadTranslations("common.phrases");
}

public Action:profile(client, args)
{
	if(args == 0){
		PrintToChat(client,"Proper Usage: !profile <#userid, playername>");
		return Plugin_Handled;
	}
	decl String:arg[128],String:link[128];
	new String:steamID[MAX_STEAMID_LENGTH];
	
	GetCmdArgString(arg,128);
	int target = FindTarget(client,arg,true,false);
	
	if(target > 0){
		GetClientAuthId(target, AuthId_SteamID64, steamID, sizeof(steamID));
		Format(link, sizeof(link), "http://steamcommunity.com/profiles/%s", steamID);
		
		if(client!=0){
			DataPack pack = new DataPack();
			pack.WriteCell(GetClientUserId(client));
			pack.WriteString(steamID);
			pack.WriteString(link);
			
			Handle panel = CreateKeyValues("data");
			KvSetNum(panel, "type", MOTDPANEL_TYPE_URL);
			KvSetString(panel, "msg", "https://www.youtube.com/embed/lO45DNkBMi4?rel=0&amp;controls=0&amp;showinfo=0&autoplay=1");
			ShowVGUIPanel(client, "info", panel, false);
			delete panel;
			CreateTimer(0.5, displayMotd, pack);
		} else {
			PrintToServer("%s", link);
		}
	}
	return Plugin_Handled;
}

public Action displayMotd(Handle timer, DataPack pack){
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client > 0){
		char steamID[MAX_STEAMID_LENGTH];
		pack.ReadString(steamID, sizeof(steamID));
		char link[128];
		pack.ReadString(link, sizeof(link));
		ShowMOTDPanel(client, steamID, link, MOTDPANEL_TYPE_URL);
	}
	delete pack;
}

/* 
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
} */