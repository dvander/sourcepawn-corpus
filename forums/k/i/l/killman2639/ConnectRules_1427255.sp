// Connect Rules by [GR|IPM] ThE_HeLl_DuDe {A}
/*
Connect Rules

This Plugin function is when the client connect it freezes him and it prints to the chat the rules,
Then it creates a menu that says "do you agree to our rules" if yes then stay and lets the player move if not
kick the client.
*/

#include <sourcemod>
#include <sdktools>

new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_sounds = INVALID_HANDLE;
new Handle:g_sound = INVALID_HANDLE;
new String:sound[32];

public Plugin:myinfo =
{
	name = "Connect-Rules",
	author = "[GR|IPM] ThE_HeLl_DuDe {A}",
	description = "Displays the server rules when a players joins the server, and it asks the client to agree them",
	version = "2.0",
	url = "ipmserver.co.cc",
};

public OnPluginStart()
{
	CreateDirectory("sound/custom/", 3);
	g_enabled = CreateConVar("sm_connectrules", "1", "Plugin status on/off", FCVAR_PLUGIN);
	g_sounds = CreateConVar("sm_connectrules_sounds", "0", "Connect sound status on/off", FCVAR_PLUGIN);
	g_sound = CreateConVar("sm_connectrules_sound", "Please enter a sound (with extension)", "Connect sound name (filename.mp3/wav)", FCVAR_PLUGIN);
	LoadTranslations("ConnectRules.phrases");
	AutoExecConfig(true, "ConnectRules_config");
}

public OnMapStart()
{
	new sounds = GetConVarInt(g_sounds);
	if(sounds == 1)
	{
		GetConVarString(g_sound, sound,sizeof(sound));
		decl String:buffer[PLATFORM_MAX_PATH];
		if (!StrEqual(sound, "", false))
		{	
		Format(buffer, PLATFORM_MAX_PATH, "sound/custom/%s", sound);
		if (FileExists(buffer, false))
		{
		Format(buffer, PLATFORM_MAX_PATH, "%s", sound);
		if (!PrecacheSound(buffer, true))
		{
        LogError("Connect rules: Could not pre-cache defined sound: %s", buffer);
        SetFailState("Connect rules: Could not pre-cache sound: %s", buffer);
		}
		else
		{
        Format(buffer, PLATFORM_MAX_PATH, "sound/custom/%s", sound);
        AddFileToDownloadsTable(buffer);
		}
		}
		}
	}
}	

public menuhandle1(Handle:rulez, MenuAction:action, Client, Press)
{
	if (action == MenuAction_Select)
	{
		decl String:Click[3];
		GetMenuItem(rulez, Press, Click, sizeof(Click));
		new agree = StringToInt(Click);
		if(agree == 1) 
		{
		SetEntityMoveType(Client, MOVETYPE_WALK);
		PrintToChat(Client, "\x04-[\x01CR\x04]- Have fun!");
		}
		if(agree == 2) 
		{
		KickClient(Client, "You must accept the rules to be able to play");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(rulez);
	}
}

public OnClientPutInServer(client)
{
	new activated = GetConVarInt(g_enabled);
	if(activated == 1)
	{
		new Handle:rulez = CreateMenu(menuhandle1);
		SetMenuTitle(rulez, "Do you agree to our rules?");
		AddMenuItem(rulez, "1", "Yes");
		AddMenuItem(rulez, "2", "No");
		SetMenuPagination(rulez, 7);
		DisplayMenu(rulez, client, 260);
		SetMenuExitButton(rulez, false);
		CreateTimer(1.0, freeze_timer, client);
	}
	return Plugin_Handled;
}

public Action:freeze_timer(Handle:timer, any:client)
{
	new activated = GetConVarInt(g_enabled);
	if(activated == 1)
	{
		if(IsClientConnected(client) && IsClientInGame(client))
		{
		SetEntityMoveType(client, MOVETYPE_NONE);
		PrintToChat(client, "[Rules] The rules:");
		PrintToChat(client, "[Rules] %t", "Rule 1");
		PrintToChat(client, "[Rules] %t", "Rule 2");
		PrintToChat(client, "[Rules] %t", "Rule 3");
		PrintToChat(client, "[Rules] %t", "Rule 4");
		PrintToChat(client, "[Rules] %t", "Rule 5");
		PrintToChat(client, "[Rules] %t", "Rule 6");
		PrintToChat(client, "[Rules] %t", "Rule 7");
		PrintToChat(client, "[Rules] %t", "Rule 8");
		PrintToChat(client, "[Rules] %t", "Rule 9");
		PrintToChat(client, "[Rules] %t", "Rule 10");
		PrintToChat(client, "\x04-[\x01CR\x04]-You have a menu press ESC to open it");
		new sounds = GetConVarInt(g_sounds);
		if(sounds == 1)
		{
		GetConVarString(g_sound, sound,sizeof(sound));
		ClientCommand(client, "play sound/custom/%s", sound);
		}
		}
	}
}