#include <sourcemod>

public Plugin myinfo = 
{
	name = "Wiadomosc Stealth", 
	author = "Danielek", 
	description = "", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_stealth", OnCommandStealth);
}

public Action OnCommandStealth(int client, int args)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("VIP - \x10[%s] \x01Wyszedl z Serwera \x10RamdomSkills\x01.", name);
} 