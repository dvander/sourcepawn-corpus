#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

public Plugin myinfo =
{
	name = "ZR Class Fix",
	author = "Franc1sco franug, Oylsister",
	description = "Fixing randomly give a human class to zombie player",
	version = "2.4",
	url = "http://www.zeuszombie.com/"
};


Handle kv;
Handle hPlayerClasses;
char sClassPath[PLATFORM_MAX_PATH] = "configs/zr/playerclasses.txt";

Handle array_classes;

enum struct Classes
{
	int Index;
	int health;
	char model[128];
}

public void OnPluginStart()
{
	array_classes = CreateArray(130);
	RegConsoleCmd("sm_testzrfix", Test);
}

public void OnPluginEnd()
{
	CloseHandle(array_classes);
}

public Action Test(int client, int args)
{
	Classes Items;
	for (int i = 0; i < GetArraySize(array_classes); ++i)
	{
		GetArrayArray(array_classes, i, Items);
		ReplyToCommand(client, "Zombie Class index %i with health %i and model %s", Items.Index, Items.health, Items.model);
	} 
	
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	if (hPlayerClasses != INVALID_HANDLE)
	{
		UnhookConVarChange(hPlayerClasses, OnClassPathChange);
		CloseHandle(hPlayerClasses);
	}
	if ((hPlayerClasses = FindConVar("zr_config_path_playerclasses")) == INVALID_HANDLE)
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
	HookConVarChange(hPlayerClasses, OnClassPathChange);
}

public void OnClassPathChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	strcopy(sClassPath, sizeof(sClassPath), newValue);
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	CreateTimer(0.2, OnConfigsExecutedPost);
}

public Action OnConfigsExecutedPost(Handle timer)
{
	if (kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
	}
	kv = CreateKeyValues("classes");
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "%s", sClassPath);
	
	if (!FileToKeyValues(kv, buffer))
	{
		SetFailState("Class data file \"%s\" not found", buffer);
	}
	
	
	if (KvGotoFirstSubKey(kv))
	{
		ClearArray(array_classes);

		char name[64];
		char enable[32]; 
		char class_default[32];

		Classes Items;

		do
		{
			KvGetString(kv, "enabled", enable, 32);

			//Is this skins default to everyone or not
			KvGetString(kv, "team_default", class_default, 32);

			// Only search for a class that set team_default as yes to prevent non-vip player getting vip skins but if you set vip class as default skin too it will not work
			if(StrEqual(enable, "yes") && StrEqual(class_default, "yes") && KvGetNum(kv, "team") == 0 && KvGetNum(kv, "flags") == 0) // check if is a enabled zombie class and no admin class
			{
				KvGetString(kv, "name", name, sizeof(name));
				Items.Index = ZR_GetClassByName(name);
				Items.health = KvGetNum(kv, "health", 5000);
				KvGetString(kv, "model_path", Items.model, 128);
				PushArrayArray(array_classes, Items); // save all info in the array
			}
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
}

public void ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	int vida = GetClientHealth(client);
	if(vida < 300)
	{
		CreateTimer(0.5, TimerApplyClasses, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TimerApplyClasses(Handle timer, any client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client)) 
		ApplyClasses(client);
}

void ApplyClasses(int client)
{
	Classes Items;
	int randomnum = GetRandomInt(0, GetArraySize(array_classes)-1); // random value in the array
	GetArrayArray(array_classes, randomnum, Items); // get class info from the array
	
	ZR_SelectClientClass(client, Items.Index, true, true); // set a valid class
	SetEntityHealth(client, Items.health); // apply health of the class selected
	if(strcmp(Items.model, "") != 0 && IsModelPrecached(Items.model)) // check if model is valid and is precached
		SetEntityModel(client, Items.model); // then apply it
}