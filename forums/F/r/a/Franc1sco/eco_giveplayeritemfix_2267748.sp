#include <sourcemod>
#include <gniecon>

public Plugin:myinfo =
{
	name = "SM ECO giveplayeritem fix",
	author = "Franc1sco franug",
	description = "Provide a fix for some GivePlayerItem weapons",
	version = "1.0",
	url = "http://www.zeuszombie.com/"
};


public Action:GNIEcon_OnGiveNamedItem(client, iDefIndex, iTeam, iLoadoutSlot, const String:szItem[])
{
/* 	decl String:steamId[64]; // for testing. Removed
	GetClientAuthId(client, AuthId_Steam2,  steamId, sizeof(steamId) );
	if(StrEqual(steamId, "STEAM_1:0:25671458"))
		PrintToChat(client, "iDefIndex = %i | iTeam = %i | iLoadoutSlot = %i | szItem = %s",iDefIndex, iTeam, iLoadoutSlot, szItem); */
		
/* 	if(StrEqual(szItem, "weapon_cz75a") || StrEqual(szItem, "weapon_usp_silencer") || StrEqual(szItem, "weapon_fiveseven") || StrEqual(szItem, "weapon_hkp2000") || StrEqual(szItem, "weapon_m4a1_silencer") || StrEqual(szItem, "weapon_m4a1") || StrEqual(szItem, "weapon_tec9"))
		return Plugin_Handled; */
		
	if(iDefIndex == 63 || iDefIndex == 61 || iDefIndex == 3 || iDefIndex == 32 || iDefIndex == 60 || iDefIndex == 16 || iDefIndex == 30)
		return Plugin_Handled;
		
	return Plugin_Continue;

}