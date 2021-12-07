#include <sourcemod>
public Plugin myinfo =
{
	name = "[ONET] Sohbet temizleyici",
	author = "August",
	description = "",
	version = "1.1",
	url = "www.onet.net.tr"
}
public void OnPluginStart()
{
	RegAdminCmd("sm_clear", Eklenti, ADMFLAG_GENERIC);
}
public Action Eklenti(int client, int args)
{
	for(int i = 0; i < 512; i++)
	{
		PrintToChatAll(" ");
	}	
	PrintToChatAll("[ONET.NET.TR] \x02Chat \x04 has been cleared , good games!");   	
}