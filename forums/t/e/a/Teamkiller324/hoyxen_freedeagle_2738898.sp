#include	<sdktools>
#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=	{
    name		=	"Free Deagle",
    author		=	"hoyxen",
    version		=	"1.1",
    description	=	"free deagle for vips",
    url			=	"https://steamcommunity.com/id/HOYXEN/"
};

public void OnPluginStart()	{
    LoadTranslations("hoyxen_freedeagle.phrases");
    RegAdminCmd("sm_freedeagle", Command_freedeagle, ADMFLAG_RESERVATION);
}

Action Command_freedeagle(int client, int args)	{
	if(IsValidClient(client))	{
		int deagle = CreateEntityByName("weapon_deagle");
		if(IsValidEdict(deagle))
			EquipPlayerWeapon(client, deagle);
		PrintToChat(client, "[ \x10Free Deagle \x01] %t", "Receive free deagle");
	}
}

bool IsValidClient(int client)	{
	if(client == 0)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(!IsPlayerAlive(client))
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}