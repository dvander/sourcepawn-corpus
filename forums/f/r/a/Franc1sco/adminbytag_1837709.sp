#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "b0.2"

new bool:admin_tag[MAXPLAYERS+1];

new String:g_Tag[MAXPLAYERS+1][24];

public Plugin:myinfo =
{
	name = "SM Admin By Tag",
	author = "Franc1sco Steam: franug",
	description = "Add admin based in tag",
	version = PLUGIN_VERSION,
	url = "http://www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_adminbytag_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnClientPostAdminCheck(client)
{
	admin_tag[client] = false;

/*
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		LoadAdmin(client);
*/
}

public OnClientSettingsChanged(client)
{
	if (IsClientInGame(client))
	{
		PrintToChatAll("Clientsettings alcanzado");

		if(admin_tag[client])
		{
			decl String:tag2[24];
			CS_GetClientClanTag(client, tag2, sizeof(tag2));
			if(!StrEqual(tag2, g_Tag[client]))
			{
				new MyEnum:iAdminID = MyEnum:GetUserAdmin(client);
				RemoveAdmin(AdminId:iAdminID);
				admin_tag[client] = false;

				LoadAdmin(client);
			}
		}
		else
			if(GetUserAdmin(client) == INVALID_ADMIN_ID)
				LoadAdmin(client);

	}
}


public LoadAdmin(client)
{
	new Handle:kv = CreateKeyValues("admin_tags");
	if (!FileToKeyValues(kv,"cfg/sourcemod/admin_tags.txt"))
	{
		SetFailState("File cfg/sourcemod/admin_tags.txt not found");
	}

	PrintToChatAll("archivo leido");

	decl String:tag[24];
	CS_GetClientClanTag(client, tag, sizeof(tag));

	if(!KvJumpToKey(kv, tag))
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			new MyEnum:iAdminID = MyEnum:GetUserAdmin(client);
			RemoveAdmin(AdminId:iAdminID);
		}
		admin_tag[client] = false;
	
	}
	else
	{
	  PrintToChatAll("tag encontrado");

	  PrintToChatAll("tag encontrado: %s",tag);


	  if(!admin_tag[client])
	  {
		new AdminId:admin = CreateAdmin("tempadmin");
		SetUserAdmin(client, admin);

		new MyEnum:iAdminID = MyEnum:GetUserAdmin(client)

        	decl String:flagsadm[24];
       		KvGetString(kv, "flags", flagsadm, sizeof(flagsadm));

		PrintToChatAll("flags leidas en el txt: %s", flagsadm);

		if (StrContains(flagsadm, "a"))
			SetAdminFlag(AdminId:iAdminID, Admin_Reservation, bool:true);

		if (StrContains(flagsadm, "b"))
			SetAdminFlag(AdminId:iAdminID, Admin_Generic, bool:true);

		if (StrContains(flagsadm, "c"))
			SetAdminFlag(AdminId:iAdminID, Admin_Kick, bool:true);

		if (StrContains(flagsadm, "d"))
			SetAdminFlag(AdminId:iAdminID, Admin_Ban, bool:true);

		if (StrContains(flagsadm, "e"))
			SetAdminFlag(AdminId:iAdminID, Admin_Unban, bool:true);

		if (StrContains(flagsadm, "f"))
			SetAdminFlag(AdminId:iAdminID, Admin_Slay, bool:true);

		if (StrContains(flagsadm, "g"))
			SetAdminFlag(AdminId:iAdminID, Admin_Changemap, bool:true);

		if (StrContains(flagsadm, "h"))
			SetAdminFlag(AdminId:iAdminID, Admin_Convars, bool:true);

		if (StrContains(flagsadm, "i"))
			SetAdminFlag(AdminId:iAdminID, Admin_Config, bool:true);

		if (StrContains(flagsadm, "j"))
			SetAdminFlag(AdminId:iAdminID, Admin_Chat, bool:true);

		if (StrContains(flagsadm, "k"))
			SetAdminFlag(AdminId:iAdminID, Admin_Vote, bool:true);

		if (StrContains(flagsadm, "l"))
			SetAdminFlag(AdminId:iAdminID, Admin_Password, bool:true);

		if (StrContains(flagsadm, "m"))
			SetAdminFlag(AdminId:iAdminID, Admin_RCON, bool:true);

		if (StrContains(flagsadm, "n"))
			SetAdminFlag(AdminId:iAdminID, Admin_Cheats, bool:true);

		if (StrContains(flagsadm, "z"))
		{
			SetAdminFlag(AdminId:iAdminID, Admin_Root, bool:true);
			PrintToChatAll("flag Z aplicada correctamente");
		}

		if (StrContains(flagsadm, "o"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom1, bool:true);

		if (StrContains(flagsadm, "p"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom2, bool:true);

		if (StrContains(flagsadm, "q"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom3, bool:true);

		if (StrContains(flagsadm, "r"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom4, bool:true);

		if (StrContains(flagsadm, "s"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom5, bool:true);

		if (StrContains(flagsadm, "t"))
			SetAdminFlag(AdminId:iAdminID, Admin_Custom6, bool:true);

		admin_tag[client] = true;

		g_Tag[client] = tag;

		PrintToChatAll("flags aplicadas");
	  }
	}

	KvGoBack(kv);
	
	CloseHandle(kv);

	PrintToChatAll("archivo cerrado correctamente");	
}