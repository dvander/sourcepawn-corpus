

// valid data key types are:
//   none   : value is not networked
//   string : a zero terminated string
//   bool   : unsigned int, 1 bit
//   byte   : unsigned int, 8 bit
//   short  : signed int, 16 bit
//   long   : signed int, 32 bit
//   float  : float, 32 bit


KeyValues KvEvents;

public void OnPluginStart()
{
	KvEvents = CreateKeyValues("data");

	if(FileExists("resource/KvEvents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/KvEvents.res");
	//if(FileExists("resource/gameevents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/gameevents.res");
	//if(FileExists("resource/hltvevents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/hltvevents.res");
	//if(FileExists("resource/modevents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/modevents.res");
	//if(FileExists("resource/replayevents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/replayevents.res");
	//if(FileExists("resource/serverevents.res", true, NULL_STRING)) KvEvents.ImportFromFile("resource/serverevents.res");

	KvEvents.ExportToFile("KvEvents.txt");

	char buffer[MAX_NAME_LENGTH];

	if(KvEvents.GotoFirstSubKey(true))
	{
		do
		{
			KvEvents.GetSectionName(buffer, sizeof(buffer));
			//PrintToServer(buffer);
			HookEventEx(buffer, events);
		}
		while(KvEvents.GotoNextKey(true))
	}
	KvEvents.Rewind();
}

public void events(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("\n %s", name);

	char key[MAX_NAME_LENGTH];
	char key_type[MAX_NAME_LENGTH];
	char buffer[PLATFORM_MAX_PATH];

	if(KvEvents.JumpToKey(name))
	{
		if(KvEvents.GotoFirstSubKey(false))
		{
			do
			{
				KvEvents.GetSectionName(key, sizeof(key));
				KvEvents.GetString(NULL_STRING, key_type, sizeof(key_type), NULL_STRING);

				if(StrEqual(key_type, "string", false))
				{
					event.GetString(key, buffer, sizeof(buffer));
					Format(buffer, sizeof(buffer), "%2s%13s%8s%s", "", key, key_type, buffer);
				}
				else if(StrEqual(key_type, "bool", false))
				{
					Format(buffer, sizeof(buffer), "%2s%13s%8s%s", "", key, key_type, event.GetBool(key) ? "TRUE":"FALSE");
				}
				else if(StrEqual(key_type, "byte", false) || StrEqual(key_type, "short", false) || StrEqual(key_type, "long", false))
				{
					Format(buffer, sizeof(buffer), "%2s%13s%8s%i", "", key, key_type, event.GetInt(key));
				}
				else if(StrEqual(key_type, "float", false))
				{
					Format(buffer, sizeof(buffer), "%2s%13s%8s%0.2f", "", key, key_type, event.GetFloat(key));
				}
				else
				{
					Format(buffer, sizeof(buffer), "%2s%13s%8s%s", "", key, key_type, "?");
				}


				PrintToServer(buffer);
			}
			while(KvEvents.GotoNextKey(false))
		}
	}
	KvEvents.Rewind();
}