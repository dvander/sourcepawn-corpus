

// 22.9 -Look player class when change team (player_team)

char TFClassName[][] = {
	"unknow",
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavyweapons",
	"pyro",
	"spy",
	"engineer"
}

#define TFCLASS_TOTAL			10
#define PANEL_CLASS_BLUE		"class_blue"
#define PANEL_CLASS_RED		"class_red"

#include <tf2_stocks>

char ClassGroupConfigureFile[PLATFORM_MAX_PATH];
char ClassGroupName[100];
KeyValues kv;

public void OnPluginStart()
{
	BuildPath(Path_SM, ClassGroupConfigureFile, sizeof(ClassGroupConfigureFile), "configs/tf2_classgroup_cfg.txt");

	RegServerCmd("sm_tf2_setclassgroup", sm_tf2_setclassgroup, "Set TF2 Class Group restriction");

	AddCommandListener(listen, "joinclass"); //"joinclass"

	ReloadClassGroupSettings(kv);

	HookEvent("player_team", player_team);
}

public Action sm_tf2_setclassgroup(int args)
{
	if(args < 1)
	{
		PrintToServer("Current Class Group: %s", ClassGroupName);
		return Plugin_Handled;
	}

	ReloadClassGroupSettings(kv);

	GetCmdArg(1, ClassGroupName, sizeof(ClassGroupName));
	PrintToServer("Class Group set to: %s", ClassGroupName);
	return Plugin_Handled;
}

public void player_team(Event event, const char[] name, bool dontBroadcast)
{
/*
Server event "player_team", Tick 13124:
- "userid" = "13"
- "team" = "2"
- "oldteam" = "3"
- "disconnect" = "0"
- "autoteam" = "0"
- "silent" = "0"
- "name" = "'Bacardi"
*/

	if(event.GetInt("disconnect"))
		return;

	TFTeam team = view_as<TFTeam>(event.GetInt("team"));

	if(team <= TFTeam_Spectator)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsFakeClient(client))
		return;

	//PrintToServer("m_iDesiredPlayerClass %i", GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));

	TFClassType tf2_class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));

	//PrintToServer("TF2_GetPlayerClass  %i", TF2_GetPlayerClass(client));

	if(!CanPlayerChooseClass(client, team, tf2_class))
	{
		ForcePlayerSuicide(client); // we need kill player, or he will spawn without class
		TF2_SetPlayerClass(client, TFClass_Unknown, false, true);
		//SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TFClass_Unknown); // Removes Cancel-button. *above function does same
		ShowVGUIPanel(client, team == TFTeam_Red ? PANEL_CLASS_RED:PANEL_CLASS_BLUE, _, true);

		char buffer[120];

		// Keep class order same as in game class panel
		TFClassType order[] = {TFClass_Unknown,TFClass_Scout,TFClass_Soldier,TFClass_Pyro,TFClass_DemoMan,TFClass_Heavy,TFClass_Engineer,TFClass_Medic,TFClass_Sniper,TFClass_Spy};

		for(int x = 1; x < TFCLASS_TOTAL; x++)
		{
			if(CanPlayerChooseClass(client, team, order[x]))
				Format(buffer, sizeof(buffer), "%s\n%i. %s", buffer, x, TFClassName[order[x]]);
		}
	
		PrintCenterText(client, "This Class is restricted, you can pick one of these\n%s", buffer);
	}

}




public Action listen(int client, const char[] command, int args)
{
	if(client <= 0 || !IsClientInGame(client))
		return Plugin_Continue;

	char buffer[120];
	GetCmdArg(1, buffer, sizeof(buffer));

	TFTeam team = view_as<TFTeam>(GetClientTeam(client));

	if(team <= TFTeam_Spectator)
		return Plugin_Continue;

	TFClassType tf2_class = TF2_GetClass(buffer);

	// This will disable "random" "auto" options...
	if(tf2_class == TFClass_Unknown || !CanPlayerChooseClass(client, team, tf2_class))
	{
		ForcePlayerSuicide(client); // we need kill player, or he will spawn without class
		TF2_SetPlayerClass(client, TFClass_Unknown, false, true);
		//SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TFClass_Unknown); // Removes Cancel-button. *above function does same
		ShowVGUIPanel(client, team == TFTeam_Red ? PANEL_CLASS_RED:PANEL_CLASS_BLUE, _, true);

		buffer[0] = '\0';

		// Keep class order same as in game class panel
		TFClassType order[] = {TFClass_Unknown,TFClass_Scout,TFClass_Soldier,TFClass_Pyro,TFClass_DemoMan,TFClass_Heavy,TFClass_Engineer,TFClass_Medic,TFClass_Sniper,TFClass_Spy};

		for(int x = 1; x < TFCLASS_TOTAL; x++)
		{
			if(CanPlayerChooseClass(client, team, order[x]))
				Format(buffer, sizeof(buffer), "%s\n%i. %s", buffer, x, TFClassName[order[x]]);
		}
	
		PrintCenterText(client, "This Class is restricted, you can pick one of these\n%s", buffer);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


stock bool CanPlayerChooseClass(int client, TFTeam client_team, TFClassType client_class)
{
	kv.Rewind();

	char key[MAX_NAME_LENGTH];
	Format(key, sizeof(key), "%s/%s", ClassGroupName, client_team == TFTeam_Red ? PANEL_CLASS_RED:PANEL_CLASS_BLUE);

	// "example_group_name/class_red"

	if(!kv.JumpToKey(key, false))
		return true;



	// Why you use 0xFF value, it's 255 as decimal ?
	// - It is just for visibility when read code, I use it for recognise, is default value in use and not value set by user.
	// - 0xFF value is high enough, user would not set that kind value normally

	int classlimit = kv.GetNum(TFClassName[client_class], 0xFF);
	int total = kv.GetNum("total", 0xFF);

	// total zero = all class types included in this group are banned
	if(total == 0)
	{
		return classlimit == 0xFF;
	}


	// zero class limit, banned class
	if(classlimit == 0)
	{
		return false;
	}

	// Do we count bots too ?
	bool include_bots = true;
	kv.GetString("include_bots_in_player_count", key, sizeof(key), "false");

	if(StrEqual(key, "false", false)	 ||
		StrEqual(key, "no", false)	 ||
		strlen(key) == 0				 ||
		key[0] == '0')
	{
		include_bots = false;
	}


	// count all class types in team
	int array[TFCLASS_TOTAL];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != view_as<int>(client_team) || i == client)
			continue;

		if(!include_bots && IsFakeClient(i))
			continue;

		array[TF2_GetPlayerClass(i)]++;
	}

	array[TFClass_Unknown] = 0;


	char name[15];
	int totalnumclass = 0;
	TFClassType class;

	if(kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(name, sizeof(name));
			class = TF2_GetClass(name);

			// Don't count banned class types, example: bots have maybe take those
			if(kv.GetNum(name) != 0)
				totalnumclass += array[class];
		}
		while(kv.GotoNextKey(false))
	}


	if(total > 0 &&
		totalnumclass >= total &&
		classlimit != 0xFF)
	{
		// total num of players reached in this class group and client class is included in this group
		return false;
	}
	else if(classlimit > 0 && array[client_class] >= classlimit)
	{
		// When specific class type, limit reached
		return false;
	}

	return true;
}


void ReloadClassGroupSettings(KeyValues &kvsetting)
{
	delete kvsetting;

	kvsetting = new KeyValues("classgroups");

	if(FileExists(ClassGroupConfigureFile))
	{
		kvsetting.ImportFromFile(ClassGroupConfigureFile);
	}
	else
	{
		LogError("Missing configure file: %s", ClassGroupConfigureFile);
	}
}









