#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Weapon Give",
	author = "lacaulac",
	description = "Allows admins to give themselves or drop weapons.",
	version = "1.0",
	url = "http://latente.fr/"
};
 
public void OnPluginStart()
{
	PrintToServer("[WeaponGive]Plugin loaded!");
	RegAdminCmd("sm_weapon", Command_Weapon, ADMFLAG_CHEATS);
}

public Action Command_Weapon(int client, int args)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GivePlayerItem(client, arg1, 0);
	ReplyToCommand(client, "[LBC]Tiens, cher %s, voici ton item :D", name);
}