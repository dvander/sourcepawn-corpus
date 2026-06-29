
KeyValues kv;
ConVar sm_humiliationannounce;

public void OnPluginStart()
{
	if(!HookEventEx("player_death", player_death))
		SetFailState("This game do not have event player_death");

	sm_humiliationannounce = CreateConVar("sm_humiliationannounce", "1", "Enable/Disable humiliation announce messages");
}

public void OnConfigsExecuted()
{

	delete kv;

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/humiliationannounce.kv");

	kv = new KeyValues("humiliation");

	if(!kv.ImportFromFile(buffer))
	{
		delete kv;
		LogError("Keyvalue file %s not found or it have error", buffer);
	}
}


public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_humiliationannounce.BoolValue || kv == null)
		return;

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon), NULL_STRING);

	kv.Rewind();

	if(kv.JumpToKey(weapon, false)) // found right section
	{
		int index = 0;
		
		if(kv.GotoFirstSubKey(false)) // section have first key value
		{
			index++;

			kv.SavePosition(); // This helps reset location on this place, after GotoNextKeys.

			while(kv.GotoNextKey(false)) // go through all key values under current section
			{
				index++;
			}
			
			index = GetRandomInt(1, index);
			kv.GoBack(); // reset location

			do
			{
				index--;

				if(index == 0)
					break;
			}
			while(kv.GotoNextKey(false))
		}

		char value[256];

		kv.GetString(NULL_STRING, value, sizeof(value));

		int victim = GetClientOfUserId(event.GetInt("userid"));

		PrintCustomMessage(value, victim);
	}
}

public void PrintCustomMessage(char[] value, any ...)
{
	char msg[256];

	VFormat(msg, sizeof(msg), value, 2);
	PrintToChatAll("%s", msg);
}

