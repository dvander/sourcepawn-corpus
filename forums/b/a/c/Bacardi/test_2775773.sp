

#include <regex>
#include <sdktools>

KeyValues kvMapTriggers;
char kvMapTriggersFile[PLATFORM_MAX_PATH];


#define SAVE_SHOWLASERSFOREVER_DEFAULT 1 // Change this, do you want lasers to show forever -> when save new trigger

public void OnPluginStart()
{
	//RegConsoleCmd("sm_test", test);
}

public Action test(int client, int args)
{
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	if(kvMapTriggers != null)
		delete kvMapTriggers;

	kvMapTriggers = new KeyValues("triggers");

	BuildPath(Path_SM, kvMapTriggersFile, sizeof(kvMapTriggersFile), "configs/maptriggers/", kvMapTriggersFile);

	if(!DirExists(kvMapTriggersFile))
	{
		// o=rx,g=rwx,u=rwx
		int mode = FPERM_O_READ|FPERM_O_EXEC|FPERM_G_READ|FPERM_G_WRITE|FPERM_G_EXEC|FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC;

		if(!CreateDirectory(kvMapTriggersFile, mode))
		{
			SetFailState("Failed CreateDirectory '%s', mode %i", kvMapTriggersFile, mode)
		}
	}

	GetCurrentMap(kvMapTriggersFile, sizeof(kvMapTriggersFile));
	BuildPath(Path_SM, kvMapTriggersFile, sizeof(kvMapTriggersFile), "configs/maptriggers/%s.txt", kvMapTriggersFile);

	if(!FileExists(kvMapTriggersFile))
	{
		LogAction(-1, -1, "MapTriggers: map config file not exist '%s'", kvMapTriggersFile);
		return;
	}


	if(!kvMapTriggers.ImportFromFile(kvMapTriggersFile))
	{
		SetFailState("MapTriggers: Failed to import KeyValues file '%s'", kvMapTriggersFile);
	}

	CreateTriggers();
}


public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!client || !IsClientInGame(client) || !StrEqual(command, "say_team"))
		return;

	if(!StrEqual(sArgs, "save", true) && !StrEqual(sArgs, "showtriggers", true))
		return;

	if(!CheckCommandAccess(client, "sm_say_team_triggers", ADMFLAG_CHANGEMAP))
	{
		PrintToChat(client, "[SM] You have no access to this chat command");
		return;
	}


	if(StrEqual(sArgs, "showtriggers", true))
	{
		kvMapTriggers.Rewind();

		if(!kvMapTriggers.GotoFirstSubKey())
			return;

		char sectioname[PLATFORM_MAX_PATH];
		
		float origin[3], angles[3], m_vecMins[3], m_vecMaxs[3];
		float seconds = 1.0;

		do
		{
			sectioname[0] = '\0';
			origin = 	{0.0,0.0,0.0};
			angles = 	{0.0,0.0,0.0};
			m_vecMins =	{0.0,0.0,0.0};
			m_vecMaxs =	{0.0,0.0,0.0};

			if(!kvMapTriggers.GetSectionName(sectioname, sizeof(sectioname)))
				continue;

			if(!stringtovector(sectioname, origin))
				continue;

			if(kvMapTriggers.JumpToKey("trigger_once"))
			{
				//kvMapTriggers.GetVector("origin", origin);
				kvMapTriggers.GetVector("angles", angles);
				kvMapTriggers.GetVector("m_vecMins", m_vecMins);
				kvMapTriggers.GetVector("m_vecMaxs", m_vecMaxs);
				kvMapTriggers.GoBack();

				CreateBox(origin, angles, m_vecMins, m_vecMaxs, {255,128,0,255}, seconds);
				seconds += 0.1;
			}
		}
		while(kvMapTriggers.GotoNextKey())

		return;
	}



	// Get client position and YAW-rotation angle

	float origin[3], angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;


	char key[PLATFORM_MAX_PATH];
	Format(key, sizeof(key), "%f %f %f",
											origin[0],
											origin[1],
											origin[2]);
	
	kvMapTriggers.Rewind();
	kvMapTriggers.JumpToKey(key, true);

	char date[256];
	FormatTime(date, sizeof(date), "%Y.%m.%d %T");

	kvMapTriggers.SetString("date", date);

	// Get client collision box dimension
	// When player stand it is [{-16.0, -16.0, 0.0}, {16.0, 16.0, 72.0}]

	float m_vecMins[3], m_vecMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecMins", m_vecMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", m_vecMaxs);

	kvMapTriggers.JumpToKey("trigger_once", true);
	kvMapTriggers.SetVector("origin", origin);
	kvMapTriggers.SetVector("angles", angles);
	kvMapTriggers.SetVector("m_vecMins", m_vecMins);
	kvMapTriggers.SetVector("m_vecMaxs", m_vecMaxs);
	kvMapTriggers.SetNum("showlasersforever", SAVE_SHOWLASERSFOREVER_DEFAULT);
	kvMapTriggers.GoBack();



	kvMapTriggers.JumpToKey("game_end", true);
	kvMapTriggers.SetString("delay", "10.0");
	kvMapTriggers.GoBack();

	kvMapTriggers.JumpToKey("servercommands", true);
	kvMapTriggers.SetString("0", "say Hello World");
	kvMapTriggers.SetString("1", "mp_chattime 15");
	kvMapTriggers.SetString("2", "say Level is gonna change soon...");

	kvMapTriggers.Rewind();
	kvMapTriggers.ExportToFile(kvMapTriggersFile);


	if(!stringtovector(key, origin))
		return;

	CreateBox(origin, angles, m_vecMins, m_vecMaxs, {0,255,0,255}, 0.0);
}


void CreateTriggers()
{
	kvMapTriggers.Rewind();

	if(!kvMapTriggers.GotoFirstSubKey())
		return;

	char sectioname[PLATFORM_MAX_PATH];
	
	float origin[3], angles[3], m_vecMins[3], m_vecMaxs[3];
	int entity;
	bool showlasersforever = false;
	float seconds = 1.0;

	do
	{
		sectioname[0] = '\0';
		origin = 	{0.0,0.0,0.0};
		angles = 	{0.0,0.0,0.0};
		m_vecMins =	{0.0,0.0,0.0};
		m_vecMaxs =	{0.0,0.0,0.0};
		showlasersforever = false;
		entity = -1;

		if(!kvMapTriggers.GetSectionName(sectioname, sizeof(sectioname)))
			continue;

		if(!stringtovector(sectioname, origin))
			continue;

		if(kvMapTriggers.JumpToKey("trigger_once"))
		{
			//kvMapTriggers.GetVector("origin", origin);
			kvMapTriggers.GetVector("angles", angles);
			kvMapTriggers.GetVector("m_vecMins", m_vecMins);
			kvMapTriggers.GetVector("m_vecMaxs", m_vecMaxs);
			showlasersforever = kvMapTriggers.GetNum("showlasersforever", 0) != 0;
			kvMapTriggers.GoBack();

			entity = CreateEntityByName("trigger_once");

			if(entity != -1)
			{
				DispatchKeyValue(entity, "spawnflags", "1");
				DispatchKeyValue(entity, "StartDisabled", "0");
				TeleportEntity(entity, origin, angles, NULL_VECTOR);
				DispatchSpawn(entity);

				SetEntPropVector(entity, Prop_Data, "m_vecMins", m_vecMins);
				SetEntPropVector(entity, Prop_Data, "m_vecMaxs", m_vecMaxs);
				SetEntProp(entity, Prop_Data, "m_nSolidType", 2); // SOLID_BBOX //  [ANY] Trigger Multiple Commands (1.5)
				
				HookSingleEntityOutput(entity, "OnStartTouch", OnStartTouch);

				CreateBox(origin, angles, m_vecMins, m_vecMaxs, {255,0,0,255}, seconds, showlasersforever);
				seconds += 0.1;
			}
		}
	}
	while(kvMapTriggers.GotoNextKey())
}


public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	float m_vecAbsOrigin[3];
	GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", m_vecAbsOrigin);

	char key[256];
	Format(key, sizeof(key), "%f %f %f",
							m_vecAbsOrigin[0],
							m_vecAbsOrigin[1],
							m_vecAbsOrigin[2]);

	kvMapTriggers.Rewind();

	if(!kvMapTriggers.JumpToKey(key))
	{
		return;
	}

	float game_end_delay = 0.0;
	
	game_end_delay = kvMapTriggers.GetFloat("game_end/delay", 0.0);
	
	if(game_end_delay > 0.0)
	{
		int entity = FindEntityByClassname(-1, "game_end");
		
		if(entity == -1)
		{
			entity = CreateEntityByName("game_end");
		}
		
		if(entity != -1)
		{
			char input[256];
			Format(input, sizeof(input), "!self,EndGame,,%0.2f,-1", game_end_delay);

			DispatchKeyValue(entity, "OnUser1", input);
			AcceptEntityInput(entity, "FireUser1", entity);

			PrintToChatAll("[SM] Player %N touch map trigger, game will end in %0.0f seconds", activator, game_end_delay);
		}
	}


	if(!kvMapTriggers.JumpToKey("servercommands") || !kvMapTriggers.GotoFirstSubKey(false))
	{
		return;
	}

	char consoleinput[256];
	float interval = 1.0;

	do
	{
		consoleinput[0] = '\0';

		kvMapTriggers.GetString(NULL_STRING, consoleinput, sizeof(consoleinput), "");

		if(strlen(consoleinput) < 1)
			continue;

		DataPack pack;
		CreateDataTimer(interval, servercommands, pack);
		pack.WriteString(consoleinput);

		interval += 1.0;
	}
	while(kvMapTriggers.GotoNextKey(false));
}



void CreateBox(float origin[3], float angles[3], float m_vecMins[3], float m_vecMaxs[3], int color[4] = {255, 0, 0, 255}, float seconds = 1.0, bool showlasersforever = false)
{
	// There is limitation to draw multiple sprites in same frame
	// Creating random timers we can draw more sprites
	DataPack pack;
	CreateDataTimer(seconds, delay, pack);
	WriteVector(pack, origin);
	WriteVector(pack, angles);
	WriteVector(pack, m_vecMins);
	WriteVector(pack, m_vecMaxs);
	pack.WriteCell(color[0]);
	pack.WriteCell(color[1]);
	pack.WriteCell(color[2]);
	pack.WriteCell(color[3]);
	pack.WriteCell(showlasersforever);
}

public Action delay(Handle timer, DataPack pack)
{
	float
	origin[3],
	angles[3],
	m_vecMins[3],
	m_vecMaxs[3];
	int color[4];
	float duration = 25.6;

	pack.Reset();
	ReadVector(pack, origin);
	ReadVector(pack, angles);
	ReadVector(pack, m_vecMins);
	ReadVector(pack, m_vecMaxs);
	color[0] = pack.ReadCell();
	color[1] = pack.ReadCell();
	color[2] = pack.ReadCell();
	color[3] = pack.ReadCell();

	if(pack.ReadCell() != 0)
		duration = 0.0;

	// looks odd but works


	// Make other points
	float
	pos1[3],
	pos2[3],
	pos3[3],
	pos4[3],
	pos5[3],
	pos6[3];

	pos1 = m_vecMins;
	pos2 = m_vecMins;
	pos3 = m_vecMins
	pos4 = m_vecMaxs;
	pos5 = m_vecMaxs;
	pos6 = m_vecMaxs;

	pos1[0] = m_vecMaxs[0];
	pos2[1] = m_vecMaxs[1];
	pos3[2] = m_vecMaxs[2];
	pos4[0] = m_vecMins[0];
	pos5[1] = m_vecMins[1];
	pos6[2] = m_vecMins[2];


	// Normalize (scale)
	float
	smins,
	smax,
	s1,
	s2,
	s3,
	s4,
	s5,
	s6;


	smins = NormalizeVector(m_vecMins, m_vecMins);
	smax = NormalizeVector(m_vecMaxs, m_vecMaxs);
	s1 = NormalizeVector(pos1, pos1);
	s2 = NormalizeVector(pos2, pos2);
	s3 = NormalizeVector(pos3, pos3);
	s4 = NormalizeVector(pos4, pos4);
	s5 = NormalizeVector(pos5, pos5);
	s6 = NormalizeVector(pos6, pos6);


	// Get angles of points
	float
	angmins[3],
	angmax[3],
	ang1[3],
	ang2[3],
	ang3[3],
	ang4[3],
	ang5[3],
	ang6[3];

	GetVectorAngles(m_vecMins, angmins);
	GetVectorAngles(m_vecMaxs, angmax);
	GetVectorAngles(pos1, ang1);
	GetVectorAngles(pos2, ang2);
	GetVectorAngles(pos3, ang3);
	GetVectorAngles(pos4, ang4);
	GetVectorAngles(pos5, ang5);
	GetVectorAngles(pos6, ang6);

	// Add angles
	AddVectors(angmins, angles, angmins);
	AddVectors(angmax, angles, angmax);
	AddVectors(ang1, angles, ang1);
	AddVectors(ang2, angles, ang2);
	AddVectors(ang3, angles, ang3);
	AddVectors(ang4, angles, ang4);
	AddVectors(ang5, angles, ang5);
	AddVectors(ang6, angles, ang6);

	// Convert back to vectors
	GetAngleVectors(angmins, m_vecMins, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(angmax, m_vecMaxs, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang1, pos1, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang2, pos2, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang3, pos3, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang4, pos4, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang5, pos5, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang6, pos6, NULL_VECTOR, NULL_VECTOR);

	// scale back
	ScaleVector(m_vecMins, smins);
	ScaleVector(m_vecMaxs, smax);
	ScaleVector(pos1, s1);
	ScaleVector(pos2, s2);
	ScaleVector(pos3, s3);
	ScaleVector(pos4, s4);
	ScaleVector(pos5, s5);
	ScaleVector(pos6, s6);


	// Add position
	AddVectors(m_vecMins, origin, m_vecMins);
	AddVectors(m_vecMaxs, origin, m_vecMaxs);
	AddVectors(pos1, origin, pos1);
	AddVectors(pos2, origin, pos2);
	AddVectors(pos3, origin, pos3);
	AddVectors(pos4, origin, pos4);
	AddVectors(pos5, origin, pos5);
	AddVectors(pos6, origin, pos6);



	int index = PrecacheModel("sprites/laser.vmt");

	TE_SetupBeamPoints(m_vecMins, pos1, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.1);
	TE_SetupBeamPoints(m_vecMins, pos2, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.2);
	TE_SetupBeamPoints(m_vecMins, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.3);
	
	TE_SetupBeamPoints(m_vecMaxs, pos4, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.4);
	TE_SetupBeamPoints(m_vecMaxs, pos5, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.5);
	TE_SetupBeamPoints(m_vecMaxs, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.6);
	
	TE_SetupBeamPoints(pos2, pos4, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.7);
	TE_SetupBeamPoints(pos1, pos5, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.8);
	TE_SetupBeamPoints(pos1, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(0.9);
	TE_SetupBeamPoints(pos2, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(1.0);
	TE_SetupBeamPoints(pos4, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(1.1);
	TE_SetupBeamPoints(pos5, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	TE_SendToAll(1.2);

	return Plugin_Continue;
}



public Action servercommands(Handle timer, DataPack pack)
{
	pack.Reset();
	char consoleinput[256];

	pack.ReadString(consoleinput, sizeof(consoleinput));

	ServerCommand("%s", consoleinput);

	return Plugin_Continue;
}


bool stringtovector(const char[] string, float vec[3])
{
	char buffer[30];

	// reset float input
	vec[0] = 0.0;
	vec[1] = 0.0;
	vec[2] = 0.0;


	char error[256];
	RegexError errcode = REGEX_ERROR_NONE;

	Regex regex_match_3float = new Regex("(-?\\d+\\.?\\d+) (-?\\d+\\.?\\d+) (-?\\d+\\.?\\d+)",
									_,
									error, sizeof(error), errcode);

	if(errcode != REGEX_ERROR_NONE)
	{
		LogError("Regex errcode: %s", error);

		delete regex_match_3float;
		return false;
	}


	int matches = regex_match_3float.Match(string);

	// -1 = no match
	// 1 = match, a whole string (index 0)
	// 4 = match, with substrings () (index 1 - 3)
	if(matches == 4)
	{
		for(int x = 1; x < matches; x++)
		{
			regex_match_3float.GetSubString(x, buffer, sizeof(buffer));
			vec[x-1] = StringToFloat(buffer);
		}
		
		delete regex_match_3float;
		return true;
	}

	delete regex_match_3float;
	return false;
}


void WriteVector(DataPack pack, float vec[3])
{
	pack.WriteFloat(vec[0]);
	pack.WriteFloat(vec[1]);
	pack.WriteFloat(vec[2]);
}

void ReadVector(DataPack pack, float vec[3])
{
	vec[0] = pack.ReadFloat();
	vec[1] = pack.ReadFloat();
	vec[2] = pack.ReadFloat();
}
